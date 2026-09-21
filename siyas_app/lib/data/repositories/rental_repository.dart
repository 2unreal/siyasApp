import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/rental_model.dart';

class RentalRepository {
  final FirebaseFirestore? firestore;
  final String businessId;

  RentalRepository({
    this.firestore,
    this.businessId = 'house_of_siyas',
  });

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _db.collection('businesses').doc(businessId).collection('rentalItems');

  CollectionReference<Map<String, dynamic>> get _rentalsRef =>
      _db.collection('businesses').doc(businessId).collection('rentals');

  // --- CATALOGUE ITEMS ---

  Stream<List<RentalItem>> streamRentalItems({bool activeOnly = false}) {
    Query<Map<String, dynamic>> query = _itemsRef;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => RentalItem.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => a.itemName.compareTo(b.itemName));
      return list;
    });
  }

  Future<void> saveRentalItem(RentalItem item) async {
    await _itemsRef.doc(item.id).set(item.toMap(), SetOptions(merge: true));
  }

  Future<RentalItem?> getRentalItem(String id) async {
    final doc = await _itemsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return RentalItem.fromMap(doc.data()!, doc.id);
  }

  // --- TRANSACTIONS ---

  Stream<List<RentalTransaction>> streamRentals({String? customerId, RentalStatus? status}) {
    Query<Map<String, dynamic>> query = _rentalsRef;
    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => RentalTransaction.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.rentalStartDate.compareTo(a.rentalStartDate));
      return list;
    });
  }

  Future<void> saveRentalTransaction(RentalTransaction transaction) async {
    await _rentalsRef.doc(transaction.id).set(transaction.toMap(), SetOptions(merge: true));
  }

  Future<RentalTransaction?> getRentalTransaction(String id) async {
    final doc = await _rentalsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return RentalTransaction.fromMap(doc.data()!, doc.id);
  }

  /// Double Booking Check:
  /// Verifies if the same item is already reserved or rented for overlapping dates.
  /// Overlap condition:
  /// existing.rentalStartDate < newReturnDate AND existing.returnDate > newStartDate
  Future<bool> checkDoubleBooking({
    required String rentalItemId,
    required DateTime startDate,
    required DateTime returnDate,
    String? excludeTransactionId,
  }) async {
    final snapshot = await _rentalsRef
        .where('rentalItemId', isEqualTo: rentalItemId)
        .get();

    for (final doc in snapshot.docs) {
      if (excludeTransactionId != null && doc.id == excludeTransactionId) {
        continue;
      }
      final data = doc.data();
      final statusStr = data['status'] as String?;
      final status = RentalStatus.fromString(statusStr);

      // Only active bookings (reserved or rented) block new bookings
      if (status == RentalStatus.reserved || status == RentalStatus.rented) {
        final existingStart = DateTime.tryParse(data['rentalStartDate'] as String? ?? '');
        final existingReturn = DateTime.tryParse(data['returnDate'] as String? ?? '');

        if (existingStart != null && existingReturn != null) {
          final overlaps = existingStart.isBefore(returnDate) && existingReturn.isAfter(startDate);
          if (overlaps) {
            return true; // Overlap detected!
          }
        }
      }
    }
    return false; // Available
  }
}
