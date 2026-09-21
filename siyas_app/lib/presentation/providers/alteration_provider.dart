import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/alteration_repository.dart';
import '../../domain/models/alteration_model.dart';

final alterationRepositoryProvider = Provider<AlterationRepository>((ref) {
  return AlterationRepository();
});

final alterationsProvider = StreamProvider<List<Alteration>>((ref) {
  final repo = ref.watch(alterationRepositoryProvider);
  return repo.streamAlterations();
});

final orderAlterationsProvider =
    StreamProvider.family<List<Alteration>, String>((ref, orderId) {
  final repo = ref.watch(alterationRepositoryProvider);
  return repo.streamAlterations(originalOrderId: orderId);
});

class AlterationController extends StateNotifier<AsyncValue<void>> {
  final AlterationRepository _repo;

  AlterationController(this._repo) : super(const AsyncValue.data(null));

  Future<void> createAlteration({
    required String originalOrderId,
    required String customerId,
    required String description,
    required String area,
    required DateTime expectedCompletionDate,
    double additionalCharge = 0.0,
    String? notes,
    required String createdBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      final alterationNumber = await _repo.generateNextAlterationNumber();
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      final alteration = Alteration(
        id: id,
        alterationNumber: alterationNumber,
        originalOrderId: originalOrderId,
        customerId: customerId,
        dateReceived: DateTime.now(),
        description: description,
        area: area,
        notes: notes,
        expectedCompletionDate: expectedCompletionDate,
        additionalCharge: additionalCharge,
        paymentStatus: additionalCharge > 0 ? 'unpaid' : 'waived',
        status: AlterationStatus.received,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: createdBy,
      );

      await _repo.saveAlteration(alteration);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateAlterationStatus({
    required Alteration alteration,
    required AlterationStatus newStatus,
    String? paymentStatus,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = Alteration(
        id: alteration.id,
        alterationNumber: alteration.alterationNumber,
        originalOrderId: alteration.originalOrderId,
        customerId: alteration.customerId,
        dateReceived: alteration.dateReceived,
        description: alteration.description,
        area: alteration.area,
        notes: alteration.notes,
        expectedCompletionDate: alteration.expectedCompletionDate,
        additionalCharge: alteration.additionalCharge,
        paymentStatus: paymentStatus ?? alteration.paymentStatus,
        status: newStatus,
        completionDate: newStatus == AlterationStatus.ready ? DateTime.now() : alteration.completionDate,
        deliveryDate: newStatus == AlterationStatus.delivered ? DateTime.now() : alteration.deliveryDate,
        createdAt: alteration.createdAt,
        updatedAt: DateTime.now(),
        createdBy: alteration.createdBy,
      );

      await _repo.saveAlteration(updated);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final alterationControllerProvider =
    StateNotifierProvider<AlterationController, AsyncValue<void>>((ref) {
  final repo = ref.watch(alterationRepositoryProvider);
  return AlterationController(repo);
});
