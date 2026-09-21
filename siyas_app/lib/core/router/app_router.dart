import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/customer_model.dart';
import '../../domain/models/measurement_model.dart';
import '../../domain/models/order_model.dart';
import '../../presentation/screens/customers/customer_detail_screen.dart';
import '../../presentation/screens/customers/customer_form_screen.dart';
import '../../presentation/screens/customers/customer_list_screen.dart';
import '../../presentation/screens/measurements/measurement_entry_screen.dart';
import '../../presentation/screens/measurements/measurement_history_screen.dart';
import '../../presentation/screens/documents/document_history_screen.dart';
import '../../presentation/screens/orders/order_detail_screen.dart';
import '../../presentation/screens/orders/order_form_screen.dart';
import '../../presentation/screens/orders/order_list_screen.dart';
import '../../presentation/screens/alterations/alteration_hub_screen.dart';
import '../../presentation/screens/classes/class_hub_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/reports/reports_hub_screen.dart';
import '../../presentation/screens/payments/payment_entry_screen.dart';
import '../../presentation/screens/payments/payment_hub_screen.dart';
import '../../presentation/screens/rentals/rental_hub_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/widgets/responsive_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ResponsiveShell(navigationShell: navigationShell);
      },
      branches: [
        // 0: Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        // 1: Customers Hub
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/customers',
              builder: (context, state) => const CustomerListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const CustomerFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final customer = state.extra as Customer?;
                    return CustomerDetailScreen(customerId: id, initialCustomer: customer);
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final customer = state.extra as Customer?;
                        return CustomerFormScreen(initialCustomer: customer);
                      },
                    ),
                    GoRoute(
                      path: 'measurements',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        final customerName = (state.extra as String?) ?? 'Customer';
                        return MeasurementHistoryScreen(customerId: id, customerName: customerName);
                      },
                      routes: [
                        GoRoute(
                          path: 'new',
                          parentNavigatorKey: _rootNavigatorKey,
                          builder: (context, state) {
                            final id = state.pathParameters['id']!;
                            String customerName = 'Customer';
                            MeasurementSet? initialSet;
                            if (state.extra is String) {
                              customerName = state.extra as String;
                            } else if (state.extra is Map<String, dynamic>) {
                              final map = state.extra as Map<String, dynamic>;
                              customerName = map['customerName'] as String? ?? 'Customer';
                              initialSet = map['initialSet'] as MeasurementSet?;
                            }
                            return MeasurementEntryScreen(
                              customerId: id,
                              customerName: customerName,
                              initialSet: initialSet,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // 2: Orders Hub
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              builder: (context, state) => const OrderListScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final preselectedCustomer = state.extra as Customer?;
                    return OrderFormScreen(preselectedCustomer: preselectedCustomer);
                  },
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    final order = state.extra as Order?;
                    return OrderDetailScreen(orderId: id, initialOrder: order);
                  },
                ),
              ],
            ),
          ],
        ),
        // 3: Payments
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/payments',
              builder: (context, state) => const PaymentHubScreen(),
              routes: [
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final entityType = state.uri.queryParameters['entityType'] ?? 'order';
                    final entityId = state.uri.queryParameters['entityId'] ?? '';
                    final customerId = state.uri.queryParameters['customerId'];
                    final orderNumber = state.uri.queryParameters['orderNumber'];
                    final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '');
                    return PaymentEntryScreen(
                      entityType: entityType,
                      entityId: entityId,
                      customerId: customerId,
                      orderNumber: orderNumber,
                      suggestedAmount: amount,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // 4: Rentals
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/rentals',
              builder: (context, state) => const RentalHubScreen(),
            ),
          ],
        ),
        // 5: Alterations
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alterations',
              builder: (context, state) => const AlterationHubScreen(),
            ),
          ],
        ),
        // 6: Classes (Owner Only)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/classes',
              builder: (context, state) => const ClassHubScreen(),
            ),
          ],
        ),
        // 7: Reports (Owner Only)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsHubScreen(),
            ),
          ],
        ),
        // 8: Settings (Owner Only)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/documents',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DocumentHistoryScreen(),
    ),
  ],
);
