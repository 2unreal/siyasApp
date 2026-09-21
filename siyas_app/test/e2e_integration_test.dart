import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/core/config/app_environment.dart';
import 'package:siyas_app/core/services/audit_service.dart';
import 'package:siyas_app/core/services/backup_service.dart';
import 'package:siyas_app/data/services/numbering_service.dart';
import 'package:siyas_app/domain/models/allocation_model.dart';
import 'package:siyas_app/domain/models/alteration_model.dart';
import 'package:siyas_app/domain/models/customer_model.dart';
import 'package:siyas_app/domain/models/document_model.dart';
import 'package:siyas_app/domain/models/measurement_model.dart';
import 'package:siyas_app/domain/models/order_model.dart';
import 'package:siyas_app/domain/models/payment_model.dart';
import 'package:siyas_app/domain/models/rental_model.dart';
import 'package:siyas_app/domain/models/settings_model.dart';
import 'package:siyas_app/domain/models/student_model.dart';

void main() {
  setUp(() {
    AppConfig.initialize(AppEnvironment.dev);
  });

  group('Milestone 17 — End-to-End Enterprise Hardening & Integration Suite', () {
    test('Complete Business Lifecycle: Customer -> Measurement -> Order -> Payment -> Rental -> Alteration -> Class', () async {
      final now = DateTime.now();

      // 1. Create Customer
      final customer = Customer(
        id: 'cus_e2e_1',
        customerId: 'CUS-0001',
        name: 'Ananya Iyer',
        mobile: '9840123456',
        whatsappMobile: '9840123456',
        whatsappSameAsMobile: true,
        address: 'Mylapore, Chennai',
        createdAt: now,
        updatedAt: now,
        createdBy: 'manager_1',
        updatedBy: 'manager_1',
      );
      expect(customer.name, 'Ananya Iyer');
      expect(customer.isArchived, isFalse);

      // 2. Add Measurement Set
      final measurements = MeasurementSet(
        id: 'meas_e2e_1',
        customerId: customer.id,
        templateId: 'blouse_std',
        garmentType: 'Blouse',
        values: {'bust': 36.0, 'waist': 30.0, 'length': 15.0},
        unit: 'inches',
        createdAt: now,
        createdBy: 'manager_1',
      );
      expect(measurements.values['bust'], 36.0);

      // 3. Create Custom Order
      final orderItem = const OrderItem(
        id: 'item_1',
        serviceName: 'Bridal Blouse Stitching',
        description: 'Heavy zardosi embroidery work',
        quantity: 1,
        unitRate: 4500.0,
        lineTotal: 4500.0,
      );
      final order = Order(
        id: 'ord_e2e_1',
        orderNumber: 'HS-ORD-0001',
        customerId: customer.id,
        customerName: customer.name,
        customerMobile: customer.mobile,
        measurementSetId: measurements.id,
        items: [orderItem],
        subtotal: 4500.0,
        totalAmount: 4500.0,
        deliveryDate: now.add(const Duration(days: 7)),
        status: OrderStatus.inProgress,
        createdAt: now,
        updatedAt: now,
        createdBy: 'manager_1',
        updatedBy: 'manager_1',
      );
      expect(order.totalAmount, 4500.0);

      // 4. Record Advance Payment
      final payment = Payment(
        id: 'pay_e2e_1',
        entityType: 'order',
        entityId: order.id,
        customerId: customer.id,
        amount: 2000.0,
        method: 'upi',
        receiptNumber: 'HS-REC-0001',
        notes: 'GPay advance',
        recordedBy: 'manager_1',
        paymentDate: now,
        createdAt: now,
      );
      expect(payment.amount, 2000.0);
      expect(payment.method, 'upi');

      // 5. Create Rental Transaction
      final rentalItem = RentalItem(
        id: 'rent_item_1',
        itemCode: 'ITEM-001',
        itemName: 'Kundhan Bridal Set',
        category: 'Jewellery',
        size: 'Standard',
        colour: 'Antique Gold',
        rentalPrice: 3500.0,
        deposit: 5000.0,
        createdAt: now,
        updatedAt: now,
      );
      final rentalTx = RentalTransaction(
        id: 'rent_tx_1',
        rentalItemId: rentalItem.id,
        customerId: customer.id,
        rentalStartDate: now,
        returnDate: now.add(const Duration(days: 3)),
        rentalAmount: 3500.0,
        depositAmount: 5000.0,
        status: RentalStatus.rented,
        createdAt: now,
        updatedAt: now,
        createdBy: 'manager_1',
      );
      expect(rentalTx.rentalAmount, 3500.0);

      // 6. Record Alteration
      final alteration = Alteration(
        id: 'alt_e2e_1',
        alterationNumber: 'HS-ALT-0001',
        originalOrderId: order.id,
        customerId: customer.id,
        dateReceived: now,
        description: 'Take in 1.5 inches at sides',
        area: 'Waist & Chest',
        expectedCompletionDate: now.add(const Duration(days: 2)),
        additionalCharge: 500.0,
        status: AlterationStatus.inProgress,
        createdAt: now,
        updatedAt: now,
        createdBy: 'manager_1',
      );
      expect(alteration.additionalCharge, 500.0);

      // 7. Enroll Student in Classes
      final student = Student(
        id: 'stu_e2e_1',
        studentName: 'Deepika Raman',
        mobile: '9840999888',
        courseName: 'Aari & Zardosi Embroidery',
        totalFee: 15000.0,
        paidFee: 5000.0,
        balanceFee: 10000.0,
        enrolledDate: now,
        updatedAt: now,
      );
      expect(student.balanceFee, 10000.0);

      // 8. Audit Logging Verification
      final audit = AuditService();
      final auditEvent = await audit.logEvent(
        action: 'E2E_WORKFLOW_COMPLETED',
        actorUid: 'manager_1',
        actorRole: 'manager',
        details: {
          'customerId': customer.id,
          'orderId': order.id,
          'paymentId': payment.id,
        },
      );
      expect(auditEvent.action, 'E2E_WORKFLOW_COMPLETED');

      // 9. Disaster Recovery Backup Generation (Owner Only)
      final backup = BackupService();
      final settings = StudioSettings.defaultSettings();
      final backupSnapshot = backup.createBackup(
        isOwner: true,
        actorUid: 'owner_1',
        settings: settings,
        customers: [customer],
        orders: [order],
        rentals: [rentalTx],
        students: [student],
      );
      expect(backupSnapshot.customers.length, 1);
      expect(backupSnapshot.orders.length, 1);
      expect(backupSnapshot.rentals.length, 1);
      expect(backupSnapshot.students.length, 1);
    });

    test('Zero-Trust Role Hardening: Manager cannot execute Owner privileged operations', () {
      final backup = BackupService();
      final settings = StudioSettings.defaultSettings();

      // Manager cannot create backups
      expect(
        () => backup.createBackup(
          isOwner: false,
          actorUid: 'manager_1',
          settings: settings,
        ),
        throwsStateError,
      );

      // Operational order model exposes no running financial balances or ledger records
      final operationalOrder = Order(
        id: 'ord_safe_1',
        orderNumber: 'HS-ORD-0002',
        customerId: 'cus_1',
        items: [],
        subtotal: 1000.0,
        totalAmount: 1000.0,
        deliveryDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'manager_1',
        updatedBy: 'manager_1',
      );

      final map = operationalOrder.toMap();
      expect(map.containsKey('balanceDue'), isFalse);
      expect(map.containsKey('advancePaid'), isFalse);
      expect(map.containsKey('totalPaid'), isFalse);
    });

    test('Offline Numbering Hardening: Offline allocation block falls back to PENDING when exhausted', () async {
      final numbering = NumberingService();
      final allocation = DeviceNumberAllocation(
        deviceId: 'device_primary',
        documentType: AllocationDocumentType.invoice,
        rangeStart: 1,
        rangeEnd: 2,
        currentAllocated: 1,
        reservedAt: DateTime.now(),
      );
      numbering.setAllocation(allocation);

      final doc1 = await numbering.consumeNextDocumentNumber(docType: DocumentType.invoice, isOnline: false);
      expect(doc1, 'HS-INV-0001');

      final doc2 = await numbering.consumeNextDocumentNumber(docType: DocumentType.invoice, isOnline: false);
      expect(doc2, 'HS-INV-0002');

      // Block exhausted -> PENDING- fallback
      final fallback = await numbering.consumeNextDocumentNumber(docType: DocumentType.invoice, isOnline: false);
      expect(fallback, startsWith('PENDING-'));
    });
  });
}
