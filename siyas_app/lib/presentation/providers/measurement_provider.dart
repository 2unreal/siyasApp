import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/measurement_repository.dart';
import '../../domain/models/measurement_model.dart';
import 'auth_provider.dart';

final measurementRepositoryProvider = Provider<MeasurementRepository>((ref) {
  return MeasurementRepository();
});

/// Streams active measurement templates
final measurementTemplatesProvider = StreamProvider<List<MeasurementTemplate>>((ref) {
  final repo = ref.watch(measurementRepositoryProvider);
  return repo.streamTemplates();
});

/// Streams customer measurement sets history
final customerMeasurementsProvider =
    StreamProvider.family<List<MeasurementSet>, String>((ref, customerId) {
  final repo = ref.watch(measurementRepositoryProvider);
  return repo.streamCustomerMeasurements(customerId);
});

/// State for active measurement entry (unit selection)
final measurementUnitProvider = StateProvider<String>((ref) => 'inches');

class MeasurementController extends StateNotifier<AsyncValue<void>> {
  final MeasurementRepository _repo;
  final Ref _ref;

  MeasurementController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> saveMeasurementSet({
    required String customerId,
    required String templateId,
    required String garmentType,
    required Map<String, double> values,
    required String displayUnit, // 'inches' | 'cm'
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final auth = _ref.read(authProvider);
      final currentUserId = auth.uid ?? 'system';

      final docId = DateTime.now().millisecondsSinceEpoch.toString();
      final newSet = MeasurementSet(
        id: docId,
        customerId: customerId,
        templateId: templateId,
        garmentType: garmentType,
        values: values,
        unit: displayUnit,
        notes: notes?.trim(),
        createdAt: DateTime.now(),
        createdBy: currentUserId,
      );

      // Append-only write (Never overwrites existing records)
      await _repo.createMeasurementSet(newSet);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final measurementControllerProvider =
    StateNotifierProvider<MeasurementController, AsyncValue<void>>((ref) {
  final repo = ref.watch(measurementRepositoryProvider);
  return MeasurementController(repo, ref);
});
