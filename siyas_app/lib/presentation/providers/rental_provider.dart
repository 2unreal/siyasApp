import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/rental_repository.dart';
import '../../domain/models/rental_model.dart';
import 'auth_provider.dart';

final rentalRepositoryProvider = Provider<RentalRepository>((ref) {
  return RentalRepository();
});

final rentalItemsProvider = StreamProvider<List<RentalItem>>((ref) {
  final repo = ref.watch(rentalRepositoryProvider);
  return repo.streamRentalItems();
});

final activeRentalItemsProvider = StreamProvider<List<RentalItem>>((ref) {
  final repo = ref.watch(rentalRepositoryProvider);
  return repo.streamRentalItems(activeOnly: true);
});

final rentalTransactionsProvider = StreamProvider<List<RentalTransaction>>((ref) {
  final repo = ref.watch(rentalRepositoryProvider);
  return repo.streamRentals();
});

final customerRentalsProvider =
    StreamProvider.family<List<RentalTransaction>, String>((ref, customerId) {
  final repo = ref.watch(rentalRepositoryProvider);
  return repo.streamRentals(customerId: customerId);
});

class RentalController extends StateNotifier<AsyncValue<void>> {
  final RentalRepository _repo;
  final Ref _ref;

  RentalController(this._repo, this._ref) : super(const AsyncValue.data(null));

  /// Save or update a rental catalogue item. Strictly OWNER WRITE ONLY.
  Future<void> saveRentalItem(RentalItem item) async {
    final auth = _ref.read(authProvider);
    if (!auth.isOwner) {
      throw Exception('Permission denied: Only the Business Owner can manage the rental catalogue.');
    }

    state = const AsyncValue.loading();
    try {
      await _repo.saveRentalItem(item);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Create a rental transaction with mandatory double-booking prevention.
  Future<void> createRentalTransaction(RentalTransaction transaction) async {
    state = const AsyncValue.loading();
    try {
      final isDoubleBooked = await _repo.checkDoubleBooking(
        rentalItemId: transaction.rentalItemId,
        startDate: transaction.rentalStartDate,
        returnDate: transaction.returnDate,
      );

      if (isDoubleBooked) {
        throw Exception(
            'Double Booking Conflict: This rental item is already booked for the selected dates.');
      }

      await _repo.saveRentalTransaction(transaction);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Update transaction status (e.g., mark as returned, rented, or cancelled).
  Future<void> updateRentalStatus({
    required RentalTransaction transaction,
    required RentalStatus newStatus,
    double? depositReturned,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updated = RentalTransaction(
        id: transaction.id,
        rentalItemId: transaction.rentalItemId,
        customerId: transaction.customerId,
        rentalStartDate: transaction.rentalStartDate,
        returnDate: transaction.returnDate,
        rentalAmount: transaction.rentalAmount,
        depositAmount: transaction.depositAmount,
        paidAmount: transaction.paidAmount,
        depositReturned: depositReturned ?? transaction.depositReturned,
        notes: notes ?? transaction.notes,
        status: newStatus,
        beforeRentalPhotoUrls: transaction.beforeRentalPhotoUrls,
        returnConditionPhotoUrls: transaction.returnConditionPhotoUrls,
        createdAt: transaction.createdAt,
        updatedAt: DateTime.now(),
        createdBy: transaction.createdBy,
      );

      await _repo.saveRentalTransaction(updated);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final rentalControllerProvider =
    StateNotifierProvider<RentalController, AsyncValue<void>>((ref) {
  final repo = ref.watch(rentalRepositoryProvider);
  return RentalController(repo, ref);
});
