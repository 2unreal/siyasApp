import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/models/order_model.dart';
import '../../domain/models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final String businessId;

  PaymentRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    this.businessId = 'house_of_siyas',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      _firestore.collection('businesses').doc(businessId).collection('payments');

  CollectionReference<Map<String, dynamic>> get _refundsRef =>
      _firestore.collection('businesses').doc(businessId).collection('refunds');

  CollectionReference<Map<String, dynamic>> get _customerCreditsRef =>
      _firestore.collection('businesses').doc(businessId).collection('customerCredits');

  /// Atomically records a payment via serverless Cloud Function.
  /// Accessible by both Owner and Manager.
  /// Returns ONLY the step result ({ newBalance, creditAmount }), preserving privacy.
  Future<PaymentResult> recordPayment({
    required String entityType,
    required String entityId,
    required double amount,
    required String method,
    String? notes,
    String? customerId,
    String? studentId,
  }) async {
    final callable = _functions.httpsCallable('recordPayment');
    final response = await callable.call<Map<String, dynamic>>({
      'entityType': entityType,
      'entityId': entityId,
      'amount': amount,
      'method': method,
      'notes': notes,
      'customerId': customerId,
      'studentId': studentId,
    });

    return PaymentResult.fromMap(Map<String, dynamic>.from(response.data));
  }

  /// Issues a refund via serverless Cloud Function.
  /// OWNER ONLY.
  Future<RefundResult> issueRefund({
    required String entityType,
    required String entityId,
    required double amount,
    String method = 'cash',
    required String reason,
  }) async {
    final callable = _functions.httpsCallable('issueRefund');
    final response = await callable.call<Map<String, dynamic>>({
      'entityType': entityType,
      'entityId': entityId,
      'amount': amount,
      'method': method,
      'reason': reason,
    });

    return RefundResult.fromMap(Map<String, dynamic>.from(response.data));
  }

  /// Stream historical payments. Strictly OWNER READ ONLY.
  Stream<List<Payment>> streamOwnerPayments({String? entityId}) {
    Query<Map<String, dynamic>> query = _paymentsRef;
    if (entityId != null) {
      query = query.where('entityId', isEqualTo: entityId);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Payment.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      return list;
    });
  }

  /// Stream customer credits. Strictly OWNER READ ONLY.
  Stream<List<CustomerCredit>> streamOwnerCustomerCredits({String? customerId}) {
    Query<Map<String, dynamic>> query = _customerCreditsRef;
    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => CustomerCredit.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream refunds. Strictly OWNER READ ONLY.
  Stream<List<Refund>> streamOwnerRefunds({String? entityId}) {
    Query<Map<String, dynamic>> query = _refundsRef;
    if (entityId != null) {
      query = query.where('entityId', isEqualTo: entityId);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Refund.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.refundDate.compareTo(a.refundDate));
      return list;
    });
  }

  /// Stream protected order financial summary. Strictly OWNER READ ONLY.
  Stream<OrderFinancialSummary?> streamOrderFinancialSummary(String orderId) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('orders')
        .doc(orderId)
        .collection('financials')
        .doc('summary')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return OrderFinancialSummary.fromMap(doc.data()!, doc.id);
    });
  }
}
