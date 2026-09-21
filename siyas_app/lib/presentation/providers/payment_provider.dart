import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/payment_repository.dart';
import '../../domain/models/order_model.dart';
import '../../domain/models/payment_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

/// Owner-only stream of all payments
final ownerPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.streamOwnerPayments();
});

/// Owner-only stream of payments for a specific order
final orderPaymentsProvider = StreamProvider.family<List<Payment>, String>((ref, orderId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.streamOwnerPayments(entityId: orderId);
});

/// Owner-only stream of all refunds
final ownerRefundsProvider = StreamProvider<List<Refund>>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.streamOwnerRefunds();
});

/// Owner-only stream of customer credits
final ownerCustomerCreditsProvider = StreamProvider<List<CustomerCredit>>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.streamOwnerCustomerCredits();
});

/// Owner-only stream of customer credits for a specific customer
final customerCreditsProvider = StreamProvider.family<List<CustomerCredit>, String>((ref, customerId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.streamOwnerCustomerCredits(customerId: customerId);
});

/// Owner-only stream of order financial summary
final orderFinancialSummaryProvider =
    StreamProvider.family<OrderFinancialSummary?, String>((ref, orderId) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.streamOrderFinancialSummary(orderId);
});

class PaymentController extends StateNotifier<AsyncValue<PaymentResult?>> {
  final PaymentRepository _repo;

  PaymentController(this._repo) : super(const AsyncValue.data(null));

  Future<PaymentResult> recordPayment({
    required String entityType,
    required String entityId,
    required double amount,
    required String method,
    String? notes,
    String? customerId,
    String? studentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.recordPayment(
        entityType: entityType,
        entityId: entityId,
        amount: amount,
        method: method,
        notes: notes,
        customerId: customerId,
        studentId: studentId,
      );
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<RefundResult> issueRefund({
    required String entityType,
    required String entityId,
    required double amount,
    String method = 'cash',
    required String reason,
  }) async {
    try {
      return await _repo.issueRefund(
        entityType: entityType,
        entityId: entityId,
        amount: amount,
        method: method,
        reason: reason,
      );
    } catch (e) {
      rethrow;
    }
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, AsyncValue<PaymentResult?>>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return PaymentController(repo);
});
