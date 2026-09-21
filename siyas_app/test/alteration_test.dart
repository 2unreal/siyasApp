import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/domain/models/alteration_model.dart';

void main() {
  group('Milestone 10 Alterations Workflow Tests', () {
    test('Alteration model serialization and free vs paid validation', () {
      final now = DateTime(2026, 9, 21, 14, 0);

      // 1. Free alteration (Warranty / Adjustment)
      final freeAlt = Alteration(
        id: 'alt_1',
        alterationNumber: 'HS-ALT-0001',
        originalOrderId: 'HS-ORD-0001',
        customerId: 'cus_1',
        dateReceived: now,
        description: 'Blouse waist needs 0.5 inch loosening',
        area: 'Blouse Waist',
        expectedCompletionDate: DateTime(2026, 9, 23),
        additionalCharge: 0.0,
        paymentStatus: 'waived',
        status: AlterationStatus.received,
        createdAt: now,
        updatedAt: now,
        createdBy: 'mgr_1',
      );

      expect(freeAlt.isFree, isTrue);
      expect(freeAlt.additionalCharge, 0.0);
      expect(freeAlt.paymentStatus, 'waived');

      final map = freeAlt.toMap();
      expect(map['alterationNumber'], 'HS-ALT-0001');
      expect(map['originalOrderId'], 'HS-ORD-0001');
      expect(map['status'], 'received');

      final deserialized = Alteration.fromMap(map, 'alt_1');
      expect(deserialized.id, 'alt_1');
      expect(deserialized.alterationNumber, 'HS-ALT-0001');
      expect(deserialized.isFree, isTrue);

      // 2. Paid alteration (Extra restyling request)
      final paidAlt = Alteration(
        id: 'alt_2',
        alterationNumber: 'HS-ALT-0002',
        originalOrderId: 'HS-ORD-0001',
        customerId: 'cus_1',
        dateReceived: now,
        description: 'Add matching tassels and deep neck restyling',
        area: 'Back Neck & Dori',
        expectedCompletionDate: DateTime(2026, 9, 24),
        additionalCharge: 450.0,
        paymentStatus: 'unpaid',
        status: AlterationStatus.received,
        createdAt: now,
        updatedAt: now,
        createdBy: 'mgr_1',
      );

      expect(paidAlt.isFree, isFalse);
      expect(paidAlt.additionalCharge, 450.0);
      expect(paidAlt.paymentStatus, 'unpaid');
    });

    test('Alteration lifecycle transitions preserve integrity of original order', () {
      final now = DateTime(2026, 9, 21);
      final alt = Alteration(
        id: 'alt_life_1',
        alterationNumber: 'HS-ALT-0003',
        originalOrderId: 'HS-ORD-0045',
        customerId: 'cus_88',
        dateReceived: now,
        description: 'Shorten sleeve length by 1 inch',
        area: 'Sleeves',
        expectedCompletionDate: DateTime(2026, 9, 23),
        status: AlterationStatus.received,
        createdAt: now,
        updatedAt: now,
        createdBy: 'staff',
      );

      expect(alt.status, AlterationStatus.received);
      expect(alt.originalOrderId, 'HS-ORD-0045');

      // Move to inProgress
      final inProg = Alteration(
        id: alt.id,
        alterationNumber: alt.alterationNumber,
        originalOrderId: alt.originalOrderId,
        customerId: alt.customerId,
        dateReceived: alt.dateReceived,
        description: alt.description,
        area: alt.area,
        expectedCompletionDate: alt.expectedCompletionDate,
        status: AlterationStatus.inProgress,
        createdAt: alt.createdAt,
        updatedAt: DateTime.now(),
        createdBy: alt.createdBy,
      );
      expect(inProg.status, AlterationStatus.inProgress);
      // Original order ID must remain intact
      expect(inProg.originalOrderId, 'HS-ORD-0045');

      // Ready -> Delivered
      final delivered = Alteration(
        id: alt.id,
        alterationNumber: alt.alterationNumber,
        originalOrderId: alt.originalOrderId,
        customerId: alt.customerId,
        dateReceived: alt.dateReceived,
        description: alt.description,
        area: alt.area,
        expectedCompletionDate: alt.expectedCompletionDate,
        status: AlterationStatus.delivered,
        completionDate: DateTime(2026, 9, 23),
        deliveryDate: DateTime(2026, 9, 23),
        createdAt: alt.createdAt,
        updatedAt: DateTime.now(),
        createdBy: alt.createdBy,
      );
      expect(delivered.status, AlterationStatus.delivered);
      expect(delivered.deliveryDate, isNotNull);
    });
  });
}
