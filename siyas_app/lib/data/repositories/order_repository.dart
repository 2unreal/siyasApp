import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../core/config/business_defaults.dart';
import '../../domain/models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;
  final String businessId;

  OrderRepository({
    FirebaseFirestore? firestore,
    this.businessId = 'house_of_siyas',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('businesses').doc(businessId).collection('orders');

  /// Stream operational orders (optionally filtered by status)
  Stream<List<Order>> streamOrders({OrderStatus? statusFilter}) {
    Query<Map<String, dynamic>> query = _ordersRef.where('isArchived', isEqualTo: false);
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.toDbString());
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)).toList();
      // Sort chronologically descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream a single operational order by ID
  Stream<Order?> streamOrder(String id) {
    return _ordersRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Order.fromMap(doc.data()!, doc.id);
    });
  }

  /// Stream orders for a specific customer
  Stream<List<Order>> streamCustomerOrders(String customerId) {
    return _ordersRef
        .where('customerId', isEqualTo: customerId)
        .where('isArchived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Generate next sequential Order Number (e.g. HS-ORD-0001) using highest sequence + 1
  Future<String> generateNextOrderNumber() async {
    try {
      final snapshot = await _ordersRef
          .orderBy('orderNumber', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final lastNumber = snapshot.docs.first.data()['orderNumber'] as String? ?? '';
        final match = RegExp(r'\d+').firstMatch(lastNumber);
        if (match != null) {
          final nextNum = (int.tryParse(match.group(0)!) ?? 0) + 1;
          return '${BusinessDefaults.prefixOrder}${nextNum.toString().padLeft(4, '0')}';
        }
      }
    } catch (_) {
      // Fallback
    }
    return '${BusinessDefaults.prefixOrder}0001';
  }

  /// Create an operational Order and atomically initialize protected financial summary
  Future<void> createOrder(Order order) async {
    final orderDoc = _ordersRef.doc(order.id);
    final financialsDoc = orderDoc.collection('financials').doc('summary');

    final batch = _firestore.batch();

    // 1. Operational Order Document (Contains NO running payment/balance fields)
    batch.set(orderDoc, order.toMap());

    // 2. Protected Financial Summary (Owner Read Only)
    final initialFinancials = OrderFinancialSummary(
      orderId: order.id,
      orderTotal: order.totalAmount,
      totalPaid: 0.0,
      balanceAmount: order.totalAmount,
      creditAmount: 0.0,
      updatedAt: DateTime.now(),
    );
    batch.set(financialsDoc, initialFinancials.toMap());

    // 3. Initial Order Activity
    final activityDoc = orderDoc.collection('orderActivities').doc();
    batch.set(activityDoc, {
      'id': activityDoc.id,
      'action': 'ORDER_CREATED',
      'details': 'Order ${order.orderNumber} created with total ₹${order.totalAmount}',
      'timestamp': DateTime.now().toIso8601String(),
      'performedBy': order.createdBy,
    });

    await batch.commit();
  }

  /// Update operational status of an order
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus, String userId) async {
    final orderDoc = _ordersRef.doc(orderId);
    final activityDoc = orderDoc.collection('orderActivities').doc();

    final batch = _firestore.batch();

    batch.update(orderDoc, {
      'status': newStatus.toDbString(),
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': userId,
    });

    batch.set(activityDoc, {
      'id': activityDoc.id,
      'action': 'STATUS_CHANGE',
      'details': 'Status changed to ${newStatus.name}',
      'timestamp': DateTime.now().toIso8601String(),
      'performedBy': userId,
    });

    await batch.commit();
  }
}
