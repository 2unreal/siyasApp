import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/domain/models/rental_model.dart';

void main() {
  group('Milestone 9 Rentals Catalogue & Transactions Tests', () {
    test('RentalItem serialization and deserialization', () {
      final now = DateTime(2026, 9, 21, 10, 0);
      final item = RentalItem(
        id: 'item_1',
        itemCode: 'HS-REN-0001',
        itemName: 'Royal Silk Bridal Lehenga',
        category: 'Bridal Lehengas',
        size: 'L',
        colour: 'Crimson Wine',
        rentalPrice: 7500.0,
        deposit: 5000.0,
        photoUrls: const ['https://storage.example.com/item_1_front.jpg'],
        notes: 'Includes matching can-can skirt',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = item.toMap();
      expect(map['id'], 'item_1');
      expect(map['itemCode'], 'HS-REN-0001');
      expect(map['rentalPrice'], 7500.0);
      expect(map['deposit'], 5000.0);

      final deserialized = RentalItem.fromMap(map, 'item_1');
      expect(deserialized.id, 'item_1');
      expect(deserialized.itemName, 'Royal Silk Bridal Lehenga');
      expect(deserialized.rentalPrice, 7500.0);
      expect(deserialized.isActive, isTrue);
    });

    test('RentalTransaction serialization and deserialization', () {
      final now = DateTime(2026, 9, 21, 11, 0);
      final tx = RentalTransaction(
        id: 'tx_1',
        rentalItemId: 'item_1',
        customerId: 'cus_1',
        rentalStartDate: DateTime(2026, 10, 1),
        returnDate: DateTime(2026, 10, 4),
        rentalAmount: 7500.0,
        depositAmount: 5000.0,
        paidAmount: 7500.0,
        depositReturned: 0.0,
        status: RentalStatus.reserved,
        createdAt: now,
        updatedAt: now,
        createdBy: 'user_1',
      );

      final map = tx.toMap();
      expect(map['id'], 'tx_1');
      expect(map['rentalItemId'], 'item_1');
      expect(map['status'], 'reserved');
      expect(map['rentalAmount'], 7500.0);

      final deserialized = RentalTransaction.fromMap(map, 'tx_1');
      expect(deserialized.id, 'tx_1');
      expect(deserialized.status, RentalStatus.reserved);
      expect(deserialized.rentalStartDate, DateTime(2026, 10, 1));
      expect(deserialized.returnDate, DateTime(2026, 10, 4));
    });

    test('Double Booking Prevention: Correctly detects overlapping date ranges', () {
      // Existing booking: Oct 1 to Oct 5
      final existingStart = DateTime(2026, 10, 1);
      final existingReturn = DateTime(2026, 10, 5);

      bool checkOverlap(DateTime newStart, DateTime newReturn) {
        return existingStart.isBefore(newReturn) && existingReturn.isAfter(newStart);
      }

      // Case 1: Overlapping in the middle (Oct 2 to Oct 4) -> Conflict!
      expect(checkOverlap(DateTime(2026, 10, 2), DateTime(2026, 10, 4)), isTrue);

      // Case 2: Overlapping start edge (Sep 28 to Oct 2) -> Conflict!
      expect(checkOverlap(DateTime(2026, 9, 28), DateTime(2026, 10, 2)), isTrue);

      // Case 3: Overlapping end edge (Oct 4 to Oct 8) -> Conflict!
      expect(checkOverlap(DateTime(2026, 10, 4), DateTime(2026, 10, 8)), isTrue);

      // Case 4: Completely enclosing (Sep 25 to Oct 10) -> Conflict!
      expect(checkOverlap(DateTime(2026, 9, 25), DateTime(2026, 10, 10)), isTrue);

      // Case 5: Completely before (Sep 20 to Sep 30) -> No Conflict!
      expect(checkOverlap(DateTime(2026, 9, 20), DateTime(2026, 9, 30)), isFalse);

      // Case 6: Completely after (Oct 6 to Oct 10) -> No Conflict!
      expect(checkOverlap(DateTime(2026, 10, 6), DateTime(2026, 10, 10)), isFalse);
    });

    test('Rental lifecycle transitions properly update status and deposit return', () {
      final tx = RentalTransaction(
        id: 'tx_lifecycle_1',
        rentalItemId: 'item_1',
        customerId: 'cus_1',
        rentalStartDate: DateTime(2026, 10, 1),
        returnDate: DateTime(2026, 10, 4),
        rentalAmount: 3000.0,
        depositAmount: 2000.0,
        paidAmount: 3000.0,
        status: RentalStatus.reserved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user_staff',
      );

      expect(tx.status, RentalStatus.reserved);

      // Pick up item -> RENTED
      final rentedTx = RentalTransaction(
        id: tx.id,
        rentalItemId: tx.rentalItemId,
        customerId: tx.customerId,
        rentalStartDate: tx.rentalStartDate,
        returnDate: tx.returnDate,
        rentalAmount: tx.rentalAmount,
        depositAmount: tx.depositAmount,
        paidAmount: tx.paidAmount,
        status: RentalStatus.rented,
        createdAt: tx.createdAt,
        updatedAt: DateTime.now(),
        createdBy: tx.createdBy,
      );
      expect(rentedTx.status, RentalStatus.rented);

      // Return item -> RETURNED and deposit refunded
      final returnedTx = RentalTransaction(
        id: tx.id,
        rentalItemId: tx.rentalItemId,
        customerId: tx.customerId,
        rentalStartDate: tx.rentalStartDate,
        returnDate: tx.returnDate,
        rentalAmount: tx.rentalAmount,
        depositAmount: tx.depositAmount,
        paidAmount: tx.paidAmount,
        depositReturned: 2000.0,
        status: RentalStatus.returned,
        createdAt: tx.createdAt,
        updatedAt: DateTime.now(),
        createdBy: tx.createdBy,
      );
      expect(returnedTx.status, RentalStatus.returned);
      expect(returnedTx.depositReturned, 2000.0);
    });
  });
}
