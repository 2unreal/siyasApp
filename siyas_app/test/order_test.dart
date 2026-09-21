import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/core/config/app_environment.dart';
import 'package:siyas_app/data/repositories/order_repository.dart';
import 'package:siyas_app/data/repositories/service_repository.dart';
import 'package:siyas_app/domain/models/order_model.dart';
import 'package:siyas_app/domain/models/user_model.dart';
import 'package:siyas_app/presentation/providers/auth_provider.dart';
import 'package:siyas_app/presentation/providers/customer_provider.dart';
import 'package:siyas_app/presentation/providers/order_provider.dart';
import 'package:siyas_app/presentation/providers/payment_provider.dart';
import 'package:siyas_app/presentation/screens/orders/order_detail_screen.dart';
import 'package:siyas_app/presentation/screens/orders/order_form_screen.dart';
import 'package:siyas_app/presentation/screens/orders/order_list_screen.dart';

class MockOrderRepository implements OrderRepository {
  final List<Order> _orders = [];
  final _ordersStreamController = StreamController<List<Order>>.broadcast();

  @override
  String get businessId => 'house_of_siyas';

  @override
  Stream<List<Order>> streamOrders({OrderStatus? statusFilter}) async* {
    List<Order> getFiltered() {
      var list = List<Order>.from(_orders);
      if (statusFilter != null) {
        list = list.where((o) => o.status == statusFilter).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }

    yield getFiltered();
    yield* _ordersStreamController.stream.map((_) => getFiltered());
  }

  @override
  Stream<Order?> streamOrder(String id) async* {
    yield _orders.cast<Order?>().firstWhere((o) => o?.id == id, orElse: () => null);
    yield* _ordersStreamController.stream.map(
      (list) => list.cast<Order?>().firstWhere((o) => o?.id == id, orElse: () => null),
    );
  }

  @override
  Stream<List<Order>> streamCustomerOrders(String customerId) async* {
    yield _orders.where((o) => o.customerId == customerId).toList();
    yield* _ordersStreamController.stream.map(
      (list) => list.where((o) => o.customerId == customerId).toList(),
    );
  }

  @override
  Future<String> generateNextOrderNumber() async {
    final count = _orders.length + 1;
    return 'HS-ORD-${count.toString().padLeft(4, '0')}';
  }

  @override
  Future<void> createOrder(Order order) async {
    _orders.add(order);
    _ordersStreamController.add(List.from(_orders));
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus, String userId) async {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final old = _orders[idx];
      _orders[idx] = Order(
        id: old.id,
        orderNumber: old.orderNumber,
        customerId: old.customerId,
        customerName: old.customerName,
        customerMobile: old.customerMobile,
        items: old.items,
        subtotal: old.subtotal,
        discount: old.discount,
        totalAmount: old.totalAmount,
        status: newStatus,
        isUrgent: old.isUrgent,
        deliveryDate: old.deliveryDate,
        photoUrls: old.photoUrls,
        generalNote: old.generalNote,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
        createdBy: old.createdBy,
        updatedBy: userId,
      );
      _ordersStreamController.add(List.from(_orders));
    }
  }
}

void main() {
  setUp(() {
    AppConfig.initialize(AppEnvironment.dev);
  });

  group('Milestone 6 — Service Catalog & Pricing Engine', () {
    test('Service catalogue seeding contains core business services', () {
      final services = ServiceRepository.initialServices;
      expect(services.length, 7);
      expect(services.any((s) => s.name == 'Tailoring'), isTrue);
      expect(services.any((s) => s.name == 'Aari Embroidery'), isTrue);
      expect(services.any((s) => s.name == 'Bridal Blouse'), isTrue);
      expect(services.any((s) => s.name == 'Saree Pre-pleating & Draping'), isTrue);
    });

    test('Order calculation: subtotal, discount, and total amount calculation', () {
      final items = [
        const OrderItem(
          id: '1',
          serviceName: 'Bridal Blouse',
          description: 'Zari and stone work',
          quantity: 1,
          unitRate: 3500.0,
          lineTotal: 3500.0,
        ),
        const OrderItem(
          id: '2',
          serviceName: 'Saree Pre-pleating & Draping',
          description: 'Box folding',
          quantity: 2,
          unitRate: 500.0,
          lineTotal: 1000.0,
        ),
      ];

      final subtotal = items.fold(0.0, (sum, i) => sum + i.lineTotal);
      expect(subtotal, 4500.0);

      const discount = 500.0;
      final total = subtotal - discount;
      expect(total, 4000.0);

      final order = Order(
        id: 'ord_1',
        orderNumber: 'HS-ORD-0001',
        customerId: 'cus_1',
        customerName: 'Meenakshi',
        items: items,
        subtotal: subtotal,
        discount: discount,
        totalAmount: total,
        status: OrderStatus.confirmed,
        isUrgent: true,
        deliveryDate: DateTime(2026, 10, 5),
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
        createdBy: 'u1',
        updatedBy: 'u1',
      );

      expect(order.orderNumber, 'HS-ORD-0001');
      expect(order.totalAmount, 4000.0);
      expect(order.customerName, 'Meenakshi');
      expect(order.isUrgent, isTrue);

      // Verify strict decoupled financial architecture
      final map = order.toMap();
      expect(map.containsKey('totalPaid'), isFalse);
      expect(map.containsKey('balanceAmount'), isFalse);
      expect(map.containsKey('creditAmount'), isFalse);
      expect(map['isUrgent'], isTrue);
    });

    test('OrderStatus conversion and display mapping', () {
      expect(OrderStatus.inProgress.toDbString(), 'in_progress');
      expect(OrderStatus.readyForTrial.toDbString(), 'ready_for_trial');
      expect(OrderStatus.fromString('in_progress'), OrderStatus.inProgress);
      expect(OrderStatus.fromString('ready_for_trial'), OrderStatus.readyForTrial);
    });
  });

  group('Milestone 6 — Order UI, Workflow & Manager Privacy Tests', () {
    late MockOrderRepository mockRepo;

    setUp(() {
      mockRepo = MockOrderRepository();
    });

    testWidgets('OrderFormScreen validates mandatory customer and items', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockRepo),
            filteredCustomersProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(home: OrderFormScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Submit without customer
      await tester.tap(find.text('Save Order'));
      await tester.pump();

      expect(find.text('Please select or link a customer.'), findsOneWidget);
    });

    testWidgets('OrderListScreen displays order number, customer name, and URGENT badge', (WidgetTester tester) async {
      final order = Order(
        id: 'ord_1',
        orderNumber: 'HS-ORD-0001',
        customerId: 'c1',
        customerName: 'Deepika S',
        items: const [
          OrderItem(id: '1', serviceName: 'Bridal Blouse', description: '', unitRate: 3500, lineTotal: 3500),
        ],
        subtotal: 3500,
        totalAmount: 3500,
        status: OrderStatus.inProgress,
        isUrgent: true,
        deliveryDate: DateTime(2026, 10, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u1',
        updatedBy: 'u1',
      );

      await mockRepo.createOrder(order);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: OrderListScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('HS-ORD-0001'), findsOneWidget);
      expect(find.text('Deepika S'), findsOneWidget);
      expect(find.text('URGENT'), findsOneWidget);
      expect(find.text('IN_PROGRESS'), findsOneWidget);
    });

    testWidgets('OrderDetailScreen: Manager PRIVACY verifies financial summary and invoice hidden', (WidgetTester tester) async {
      final order = Order(
        id: 'ord_1',
        orderNumber: 'HS-ORD-0001',
        customerId: 'c1',
        customerName: 'Deepika S',
        items: const [
          OrderItem(id: '1', serviceName: 'Bridal Blouse', description: '', unitRate: 3500, lineTotal: 3500),
        ],
        subtotal: 3500,
        totalAmount: 3500,
        status: OrderStatus.confirmed,
        deliveryDate: DateTime(2026, 10, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u1',
        updatedBy: 'u1',
      );

      await mockRepo.createOrder(order);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockRepo),
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.setRole(UserRole.manager);
              return notifier;
            }),
          ],
          child: MaterialApp(home: OrderDetailScreen(orderId: 'ord_1', initialOrder: order)),
        ),
      );
      await tester.pumpAndSettle();

      // Operational order details ARE visible to Manager
      expect(find.text('HS-ORD-0001'), findsOneWidget);
      expect(find.text('CONFIRMED'), findsWidgets);
      expect(find.text('Total Amount:'), findsOneWidget);
      expect(find.text('₹3500'), findsWidgets);

      // Financial balance summary is HIDDEN from Manager
      expect(find.text('Payment & Balance Status (Owner Only)'), findsNothing);
      expect(find.text('Total Paid:'), findsNothing);
      expect(find.text('Current Balance:'), findsNothing);

      // Invoice generation is HIDDEN from Manager
      expect(find.text('Generate Invoice (PDF)'), findsNothing);

      // Record Payment button IS visible
      expect(find.text('Record Payment'), findsOneWidget);
    });

    testWidgets('OrderDetailScreen: Owner can see financial summary and generate invoice', (WidgetTester tester) async {
      final order = Order(
        id: 'ord_1',
        orderNumber: 'HS-ORD-0001',
        customerId: 'c1',
        customerName: 'Deepika S',
        items: const [
          OrderItem(id: '1', serviceName: 'Bridal Blouse', description: '', unitRate: 3500, lineTotal: 3500),
        ],
        subtotal: 3500,
        totalAmount: 3500,
        status: OrderStatus.confirmed,
        deliveryDate: DateTime(2026, 10, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'u1',
        updatedBy: 'u1',
      );

      await mockRepo.createOrder(order);

      final summary = OrderFinancialSummary(
        orderId: 'ord_1',
        orderTotal: 3500,
        totalPaid: 1500,
        balanceAmount: 2000,
        creditAmount: 0,
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(mockRepo),
            orderFinancialSummaryProvider('ord_1').overrideWith((ref) => Stream.value(summary)),
            authProvider.overrideWith((ref) {
              final notifier = AuthNotifier();
              notifier.setRole(UserRole.owner);
              return notifier;
            }),
          ],
          child: MaterialApp(home: OrderDetailScreen(orderId: 'ord_1', initialOrder: order)),
        ),
      );
      await tester.pumpAndSettle();

      // Owner sees protected financial status
      expect(find.text('Payment & Balance Status (Owner Only)'), findsOneWidget);
      expect(find.text('Total Paid:'), findsOneWidget);
      expect(find.text('₹1500.00'), findsOneWidget);
      expect(find.text('Current Balance:'), findsOneWidget);
      expect(find.text('₹2000.00'), findsOneWidget);

      // Owner sees Invoice generation
      expect(find.text('Generate Invoice (PDF)'), findsOneWidget);
    });
  });
}
