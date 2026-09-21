import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/service_repository.dart';
import '../../domain/models/order_model.dart';
import 'auth_provider.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository();
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final servicesListProvider = StreamProvider<List<ServiceItem>>((ref) {
  return ref.watch(serviceRepositoryProvider).streamServices();
});

final orderStatusFilterProvider = StateProvider<OrderStatus?>((ref) => null);
final orderSearchQueryProvider = StateProvider<String>((ref) => '');

/// Streams operational orders filtered by status and query
final filteredOrdersProvider = StreamProvider<List<Order>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  final status = ref.watch(orderStatusFilterProvider);
  final query = ref.watch(orderSearchQueryProvider).trim().toLowerCase();

  return repo.streamOrders(statusFilter: status).map((orders) {
    if (query.isEmpty) return orders;
    return orders.where((o) {
      final numberMatches = o.orderNumber.toLowerCase().contains(query);
      final noteMatches = o.generalNote?.toLowerCase().contains(query) ?? false;
      return numberMatches || noteMatches;
    }).toList();
  });
});

/// Streams orders for a specific customer
final customerOrdersProvider = StreamProvider.family<List<Order>, String>((ref, customerId) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.streamCustomerOrders(customerId);
});

class OrderController extends StateNotifier<AsyncValue<void>> {
  final OrderRepository _repo;
  final Ref _ref;

  OrderController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> createOrder({
    required String customerId,
    String customerName = '',
    String? customerMobile,
    String? measurementSetId,
    required List<OrderItem> items,
    required double subtotal,
    required double discount,
    required double totalAmount,
    required DateTime deliveryDate,
    OrderStatus status = OrderStatus.confirmed,
    bool isUrgent = false,
    String? generalNote,
    List<String> photoUrls = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      final auth = _ref.read(authProvider);
      final currentUserId = auth.uid ?? 'system';

      final orderNumber = await _repo.generateNextOrderNumber();
      final docId = DateTime.now().millisecondsSinceEpoch.toString();

      final order = Order(
        id: docId,
        orderNumber: orderNumber,
        customerId: customerId,
        customerName: customerName,
        customerMobile: customerMobile,
        measurementSetId: measurementSetId,
        items: items,
        subtotal: subtotal,
        discount: discount,
        totalAmount: totalAmount,
        status: status,
        isUrgent: isUrgent,
        deliveryDate: deliveryDate,
        photoUrls: photoUrls,
        generalNote: generalNote,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentUserId,
        updatedBy: currentUserId,
      );

      await _repo.createOrder(order);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus(String orderId, OrderStatus newStatus) async {
    final auth = _ref.read(authProvider);
    await _repo.updateOrderStatus(orderId, newStatus, auth.uid ?? 'system');
  }
}

final orderControllerProvider =
    StateNotifierProvider<OrderController, AsyncValue<void>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrderController(repo, ref);
});
