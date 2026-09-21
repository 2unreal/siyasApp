import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/core/config/app_environment.dart';
import 'package:siyas_app/core/config/business_defaults.dart';
import 'package:siyas_app/domain/models/settings_model.dart';
import 'package:siyas_app/domain/models/user_model.dart';
import 'package:siyas_app/presentation/providers/auth_provider.dart';
import 'package:siyas_app/presentation/providers/settings_provider.dart';
import 'package:siyas_app/presentation/screens/settings/settings_screen.dart';

void main() {
  setUp(() {
    AppConfig.initialize(AppEnvironment.dev);
  });

  group('Milestone 15 Settings Model & State Tests', () {
    test('StudioSettings initializes with approved business defaults', () {
      final settings = StudioSettings.defaultSettings();
      expect(settings.studioName, BusinessDefaults.businessName);
      expect(settings.phone, BusinessDefaults.contactPhone);
      expect(settings.orderPrefix, BusinessDefaults.prefixOrder);
      expect(settings.invoicePrefix, BusinessDefaults.prefixInvoice);
      expect(settings.receiptPrefix, BusinessDefaults.prefixPaymentReceipt);
      expect(settings.rentalPrefix, BusinessDefaults.prefixRental);
      expect(settings.alterationPrefix, BusinessDefaults.prefixAlteration);
      expect(settings.classPrefix, BusinessDefaults.prefixClass);
    });

    test('StudioSettings serialization and deserialization roundtrip', () {
      final now = DateTime(2026, 9, 21, 12, 0);
      final original = StudioSettings(
        studioName: "House of SIYA's Custom",
        phone: '9876543210',
        whatsapp: '9876543210',
        address: 'Test Street, Chennai',
        taxGst: '33AAAAA0000A1Z5',
        orderPrefix: 'CUSTOM-ORD-',
        invoicePrefix: 'CUSTOM-INV-',
        receiptPrefix: 'CUSTOM-REC-',
        rentalPrefix: 'CUSTOM-REN-',
        alterationPrefix: 'CUSTOM-ALT-',
        classPrefix: 'CUSTOM-CLS-',
        currencySymbol: '₹',
        updatedAt: now,
        updatedBy: 'owner_123',
      );

      final map = original.toMap();
      final restored = StudioSettings.fromMap(map);

      expect(restored.studioName, original.studioName);
      expect(restored.phone, original.phone);
      expect(restored.taxGst, original.taxGst);
      expect(restored.orderPrefix, original.orderPrefix);
      expect(restored.invoicePrefix, original.invoicePrefix);
      expect(restored.updatedBy, original.updatedBy);
    });

    test('SettingsNotifier updates profile, prefixes, and resets to defaults', () {
      final notifier = SettingsNotifier();
      expect(notifier.state.studioName, BusinessDefaults.businessName);

      notifier.updateStudioProfile(studioName: 'Renamed Boutique');
      expect(notifier.state.studioName, 'Renamed Boutique');

      notifier.updatePrefixes(orderPrefix: 'MOD-ORD-');
      expect(notifier.state.orderPrefix, 'MOD-ORD-');

      notifier.resetToDefaults();
      expect(notifier.state.studioName, BusinessDefaults.businessName);
      expect(notifier.state.orderPrefix, BusinessDefaults.prefixOrder);
    });
  });

  group('Milestone 15 Settings UI & Zero-Trust RBAC Tests', () {
    testWidgets('Owner can view Studio Settings with all configuration sections', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final n = AuthNotifier();
              n.setRole(UserRole.owner);
              return n;
            }),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Studio Settings'), findsOneWidget);
      expect(find.text('Studio Profile & Branding'), findsOneWidget);
      expect(find.text('Document Numbering Prefixes'), findsOneWidget);
      expect(find.text('Communication Templates'), findsOneWidget);
      expect(find.text('Zero-Trust Role & Access Control'), findsOneWidget);
      expect(find.text('System & Environment Information'), findsOneWidget);
      expect(find.text('Save Studio Settings'), findsOneWidget);
    });

    testWidgets('Owner can modify studio information and save', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final n = AuthNotifier();
              n.setRole(UserRole.owner);
              return n;
            }),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Studio Name field and enter new name
      final nameField = find.widgetWithText(TextFormField, 'Studio Name');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'House of SIYA\'s Flagship');

      // Tap Save
      await tester.tap(find.text('Save Studio Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings saved successfully.'), findsOneWidget);
    });

    testWidgets('Manager role is blocked with strict Access Denied banner', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final n = AuthNotifier();
              n.setRole(UserRole.manager);
              return n;
            }),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Access Denied'), findsOneWidget);
      expect(
        find.text('Studio Settings and business configuration are strictly restricted to the Owner role.'),
        findsOneWidget,
      );
      // Ensure configuration inputs are NOT rendered for Manager
      expect(find.text('Studio Profile & Branding'), findsNothing);
      expect(find.text('Save Studio Settings'), findsNothing);
    });
  });
}
