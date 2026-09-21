import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/domain/models/order_model.dart';
import 'package:siyas_app/domain/models/user_model.dart';
import 'package:siyas_app/presentation/providers/auth_provider.dart';
import 'package:siyas_app/presentation/providers/order_provider.dart';
import 'package:siyas_app/presentation/providers/payment_provider.dart';
import 'package:siyas_app/presentation/providers/rental_provider.dart';
import 'package:siyas_app/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:siyas_app/presentation/screens/reports/reports_hub_screen.dart';

void main() {
  group('Milestone 14 Dashboard, Reports & Export Tests', () {
    testWidgets('Dashboard renders operational cards and quick actions for both roles', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final auth = AuthNotifier();
              auth.setRole(UserRole.manager);
              return auth;
            }),
            filteredOrdersProvider.overrideWith((ref) => Stream.value([
              Order(
                id: 'ord_1',
                orderNumber: 'HS-ORD-0001',
                customerId: 'cus_1',
                items: const [],
                subtotal: 3000.0,
                discount: 0.0,
                totalAmount: 3000.0,
                status: OrderStatus.inProgress,
                deliveryDate: DateTime.now(),
                isUrgent: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                createdBy: 'staff',
                updatedBy: 'staff',
              ),
            ])),
            rentalTransactionsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Studio Dashboard'), findsOneWidget);
      expect(find.text('New Customer'), findsOneWidget);
      expect(find.text('New Order'), findsOneWidget);
      expect(find.text('Record Payment'), findsOneWidget);
      expect(find.text('Orders Due Today'), findsOneWidget);
      expect(find.text('Active In-Flight'), findsOneWidget);
      expect(find.text('Urgent Rush'), findsOneWidget);

      // Financial highlights must be HIDDEN for Manager
      expect(find.text('Financial Highlights'), findsNothing);
      expect(find.text('Today\'s Collections'), findsNothing);
    });

    testWidgets('Dashboard renders Financial Highlights when user is Owner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final auth = AuthNotifier();
              auth.setRole(UserRole.owner);
              return auth;
            }),
            filteredOrdersProvider.overrideWith((ref) => Stream.value([])),
            rentalTransactionsProvider.overrideWith((ref) => Stream.value([])),
            ownerPaymentsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Financial highlights must be VISIBLE for Owner
      expect(find.text('Financial Highlights'), findsOneWidget);
      expect(find.text('Today\'s Collections'), findsOneWidget);
      expect(find.text('Total Cumulative'), findsOneWidget);
    });

    testWidgets('ReportsHubScreen restricts Manager with access restriction message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final auth = AuthNotifier();
              auth.setRole(UserRole.manager);
              return auth;
            }),
          ],
          child: const MaterialApp(home: ReportsHubScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Reports Restricted'), findsOneWidget);
      expect(find.text('Standard Business Reports'), findsNothing);
    });

    testWidgets('ReportsHubScreen displays export options when user is Owner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) {
              final auth = AuthNotifier();
              auth.setRole(UserRole.owner);
              return auth;
            }),
          ],
          child: const MaterialApp(home: ReportsHubScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Standard Business Reports'), findsOneWidget);
      expect(find.text('Daily & Monthly Sales / Collections'), findsOneWidget);
      expect(find.text('Outstanding Orders & Balances'), findsOneWidget);
      expect(find.text('Master Customer Directory'), findsOneWidget);
    });
  });
}
