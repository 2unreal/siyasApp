import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/core/config/app_environment.dart';
import 'package:siyas_app/core/services/audit_service.dart';
import 'package:siyas_app/core/services/backup_service.dart';
import 'package:siyas_app/domain/models/customer_model.dart';
import 'package:siyas_app/domain/models/order_model.dart';
import 'package:siyas_app/domain/models/settings_model.dart';
import 'package:siyas_app/main.dart';
import 'package:siyas_app/presentation/providers/auth_provider.dart';
import 'package:siyas_app/presentation/screens/auth/pin_lock_screen.dart';

void main() {
  setUp(() {
    AppConfig.initialize(AppEnvironment.dev);
  });

  group('Milestone 16 Audit Service & Immutability Tests', () {
    test('AuditService logs critical operational actions with actor and timestamp', () async {
      final audit = AuditService();
      final event = await audit.logEvent(
        action: 'PAYMENT_RECORDED',
        actorUid: 'manager_456',
        actorRole: 'manager',
        details: {'amount': 5000, 'orderId': 'HS-ORD-0001'},
      );

      expect(event.id, startsWith('AUDIT-'));
      expect(event.action, 'PAYMENT_RECORDED');
      expect(event.actorUid, 'manager_456');
      expect(event.actorRole, 'manager');
      expect(event.details['amount'], 5000);

      final managerLogs = audit.getLogsForActor('manager_456');
      expect(managerLogs, isNotEmpty);
      expect(managerLogs.any((e) => e.id == event.id), isTrue);

      final paymentLogs = audit.getLogsByAction('PAYMENT_RECORDED');
      expect(paymentLogs, isNotEmpty);
    });

    test('AuditEvent serialization and deserialization roundtrip', () {
      final now = DateTime(2026, 9, 21, 14, 30);
      final original = AuditEvent(
        id: 'AUDIT-001',
        action: 'REFUND_ISSUED',
        actorUid: 'owner_001',
        actorRole: 'owner',
        details: {'refundAmount': 1500, 'reason': 'Client cancelled'},
        timestamp: now,
      );

      final map = original.toMap();
      final restored = AuditEvent.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.action, original.action);
      expect(restored.actorUid, original.actorUid);
      expect(restored.details['refundAmount'], 1500);
    });
  });

  group('Milestone 16 Backup Service & Disaster Recovery Tests', () {
    test('BackupService creates structured JSON snapshot for Owner', () {
      final backup = BackupService();
      final settings = StudioSettings.defaultSettings();
      final customers = [
        Customer(
          id: 'cus_1',
          customerId: 'CUS-0001',
          name: 'Priya Sharma',
          mobile: '9876543210',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'owner_test',
          updatedBy: 'owner_test',
        ),
      ];
      final orders = [
        Order(
          id: 'ord_1',
          orderNumber: 'HS-ORD-0001',
          customerId: 'cus_1',
          customerName: 'Priya Sharma',
          items: [],
          subtotal: 12000,
          totalAmount: 12000,
          deliveryDate: DateTime.now(),
          status: OrderStatus.inProgress,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'owner_test',
          updatedBy: 'owner_test',
        ),
      ];

      final snapshot = backup.createBackup(
        isOwner: true,
        actorUid: 'owner_test',
        settings: settings,
        customers: customers,
        orders: orders,
      );

      expect(snapshot.version, '1.0.0');
      expect(snapshot.exportedBy, 'owner_test');
      expect(snapshot.customers.length, 1);
      expect(snapshot.orders.length, 1);

      final jsonStr = snapshot.toJsonString();
      expect(jsonStr, contains('Priya Sharma'));
      expect(jsonStr, contains('HS-ORD-0001'));
      expect(jsonStr, contains('House of SIYA\'s'));
    });

    test('BackupService rejects non-Owner execution with RBAC StateError', () {
      final backup = BackupService();
      final settings = StudioSettings.defaultSettings();

      expect(
        () => backup.createBackup(
          isOwner: false, // Manager attempting backup
          actorUid: 'manager_test',
          settings: settings,
        ),
        throwsStateError,
      );
    });
  });

  group('Milestone 16 PIN Lock & Security Shield Tests', () {
    testWidgets('PinLockScreen verifies correct PIN and unlocks', (WidgetTester tester) async {
      bool unlocked = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PinLockScreen(
              correctPin: '1234',
              onUnlocked: () => unlocked = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter 4-Digit Security PIN'), findsOneWidget);

      // Enter 1, 2, 3, 4
      await tester.tap(find.widgetWithText(OutlinedButton, '1'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '2'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '3'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '4'));
      await tester.pumpAndSettle();

      expect(unlocked, isTrue);
    });

    testWidgets('PinLockScreen displays error on incorrect PIN', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PinLockScreen(
              correctPin: '1234',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter 9, 9, 9, 9
      await tester.tap(find.widgetWithText(OutlinedButton, '9'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '9'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '9'));
      await tester.pump();
      await tester.tap(find.widgetWithText(OutlinedButton, '9'));
      await tester.pumpAndSettle();

      expect(find.text('Incorrect PIN. Attempt 1 of 5.'), findsOneWidget);
    });

    testWidgets('HouseOfSiyasApp overlays PinLockScreen when isAppLocked is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final n = AuthNotifier();
              n.lockApp(); // Start locked
              return n;
            }),
          ],
          child: const HouseOfSiyasApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PinLockScreen), findsOneWidget);
      expect(find.text('Enter 4-Digit Security PIN'), findsOneWidget);
    });
  });
}
