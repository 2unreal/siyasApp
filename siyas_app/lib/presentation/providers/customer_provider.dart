import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/customer_repository.dart';
import '../../domain/models/customer_model.dart';
import 'auth_provider.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final customerSearchQueryProvider = StateProvider<String>((ref) => '');
final customerStatusFilterProvider = StateProvider<String>((ref) => 'active');

/// Streams customers filtered by status and search query (ID, Name, Mobile, WhatsApp)
final filteredCustomersProvider = StreamProvider<List<Customer>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  final status = ref.watch(customerStatusFilterProvider);
  final query = ref.watch(customerSearchQueryProvider).trim().toLowerCase();

  return repo.streamCustomers(status: status).map((customers) {
    if (query.isEmpty) return customers;
    return customers.where((c) {
      final nameMatches = c.name.toLowerCase().contains(query);
      final idMatches = c.customerId.toLowerCase().contains(query);
      final mobileMatches = c.mobile != null && c.mobile!.contains(query);
      final whatsappMatches = c.whatsappMobile != null && c.whatsappMobile!.contains(query);
      return nameMatches || idMatches || mobileMatches || whatsappMatches;
    }).toList();
  });
});

/// Streams notes history for a single customer
final customerNotesProvider = StreamProvider.family<List<CustomerNote>, String>((ref, customerId) {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.streamNotesHistory(customerId);
});

/// Controller for Customer operations
class CustomerController extends StateNotifier<AsyncValue<void>> {
  final CustomerRepository _repo;
  final Ref _ref;

  CustomerController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<List<Customer>> checkDuplicateMobile(String mobile) async {
    return _repo.findCustomersByMobile(mobile);
  }

  Future<void> saveCustomer({
    String? existingId,
    String? existingCustomerId,
    required String name,
    String? mobile,
    String? whatsappMobile,
    bool whatsappSameAsMobile = true,
    String? address,
    String? generalNote,
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final auth = _ref.read(authProvider);
      final currentUserId = auth.uid ?? 'system';

      if (existingId != null) {
        // Update
        final updated = Customer(
          id: existingId,
          customerId: existingCustomerId ?? '',
          name: name.trim(),
          mobile: mobile?.trim().isEmpty ?? true ? null : mobile!.trim(),
          whatsappMobile: whatsappSameAsMobile
              ? (mobile?.trim().isEmpty ?? true ? null : mobile!.trim())
              : (whatsappMobile?.trim().isEmpty ?? true ? null : whatsappMobile!.trim()),
          whatsappSameAsMobile: whatsappSameAsMobile,
          address: address?.trim(),
          generalNote: generalNote?.trim(),
          photoUrl: photoUrl,
          createdAt: DateTime.now(), // Ignored in update
          updatedAt: DateTime.now(),
          createdBy: currentUserId,
          updatedBy: currentUserId,
        );
        await _repo.updateCustomer(updated);
      } else {
        // Create new
        final customerId = await _repo.generateNextCustomerId();
        final docId = DateTime.now().millisecondsSinceEpoch.toString();
        final newCustomer = Customer(
          id: docId,
          customerId: customerId,
          name: name.trim(),
          mobile: mobile?.trim().isEmpty ?? true ? null : mobile!.trim(),
          whatsappMobile: whatsappSameAsMobile
              ? (mobile?.trim().isEmpty ?? true ? null : mobile!.trim())
              : (whatsappMobile?.trim().isEmpty ?? true ? null : whatsappMobile!.trim()),
          whatsappSameAsMobile: whatsappSameAsMobile,
          address: address?.trim(),
          generalNote: generalNote?.trim(),
          photoUrl: photoUrl,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: currentUserId,
          updatedBy: currentUserId,
        );
        await _repo.createCustomer(newCustomer);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> archiveCustomer(String customerId) async {
    state = const AsyncValue.loading();
    try {
      final auth = _ref.read(authProvider);
      await _repo.archiveCustomer(customerId, auth.uid ?? 'system');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> restoreCustomer(String customerId) async {
    state = const AsyncValue.loading();
    try {
      final auth = _ref.read(authProvider);
      await _repo.restoreCustomer(customerId, auth.uid ?? 'system');
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> addNote({
    required String customerId,
    required String note,
  }) async {
    final auth = _ref.read(authProvider);
    await _repo.addCustomerNote(
      customerId: customerId,
      note: note,
      authorId: auth.uid ?? 'system',
      authorName: auth.isOwner ? 'Owner' : 'Manager',
    );
  }
}

final customerControllerProvider =
    StateNotifierProvider<CustomerController, AsyncValue<void>>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return CustomerController(repo, ref);
});
