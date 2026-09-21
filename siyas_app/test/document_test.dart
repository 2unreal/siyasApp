import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/data/repositories/document_repository.dart';
import 'package:siyas_app/data/services/numbering_service.dart';
import 'package:siyas_app/data/services/pdf_generator_service.dart';
import 'package:siyas_app/domain/models/allocation_model.dart';
import 'package:siyas_app/domain/models/customer_model.dart';
import 'package:siyas_app/domain/models/document_model.dart';
import 'package:siyas_app/domain/models/order_model.dart';
import 'package:siyas_app/domain/models/payment_model.dart';
import 'package:siyas_app/domain/models/user_model.dart';
import 'package:siyas_app/presentation/providers/auth_provider.dart';
import 'package:siyas_app/presentation/providers/document_provider.dart';

void main() {
  group('Milestone 8 Client-Side PDF Generation & Reserved Numbering System Tests', () {
    test('DocumentRecord serialization and deserialization', () {
      final now = DateTime(2026, 9, 21, 12, 0);
      final record = DocumentRecord(
        id: 'doc_1',
        documentType: DocumentType.invoice,
        documentNumber: 'HS-INV-0001',
        entityType: 'order',
        entityId: 'ord_100',
        customerId: 'cus_1',
        customerName: 'Ananya Sharma',
        customerMobile: '9876543210',
        totalAmount: 4500.0,
        paidAmount: 2000.0,
        balanceAmount: 2500.0,
        generatedBy: 'owner_uid',
        generatedAt: now,
        isPendingSync: false,
      );

      final map = record.toMap();
      expect(map['id'], 'doc_1');
      expect(map['documentNumber'], 'HS-INV-0001');
      expect(map['documentType'], 'invoice');
      expect(map['totalAmount'], 4500.0);

      final deserialized = DocumentRecord.fromMap(map, 'doc_1');
      expect(deserialized.id, 'doc_1');
      expect(deserialized.documentNumber, 'HS-INV-0001');
      expect(deserialized.customerName, 'Ananya Sharma');
      expect(deserialized.isPendingSync, isFalse);
    });

    test('Critical Document Numbering: Two devices allocate non-overlapping ranges (Section 88)', () async {
      // Device A reserves 1–50
      final serviceA = NumberingService(deviceId: 'device_A');
      serviceA.setAllocation(
        DeviceNumberAllocation(
          deviceId: 'device_A',
          documentType: AllocationDocumentType.invoice,
          rangeStart: 1,
          rangeEnd: 50,
          currentAllocated: 1,
          reservedAt: DateTime.now(),
        ),
      );

      // Device B reserves 51–100
      final serviceB = NumberingService(deviceId: 'device_B');
      serviceB.setAllocation(
        DeviceNumberAllocation(
          deviceId: 'device_B',
          documentType: AllocationDocumentType.invoice,
          rangeStart: 51,
          rangeEnd: 100,
          currentAllocated: 51,
          reservedAt: DateTime.now(),
        ),
      );

      // Device A consumes documents
      final docA1 = await serviceA.consumeNextDocumentNumber(docType: DocumentType.invoice, isOnline: false);
      final docA2 = await serviceA.consumeNextDocumentNumber(docType: DocumentType.invoice, isOnline: false);

      // Device B consumes documents
      final docB1 = await serviceB.consumeNextDocumentNumber(docType: DocumentType.invoice, isOnline: false);
      final docB2 = await serviceB.consumeNextDocumentNumber(docType: DocumentType.invoice, isOnline: false);

      expect(docA1, 'HS-INV-0001');
      expect(docA2, 'HS-INV-0002');
      expect(docB1, 'HS-INV-0051');
      expect(docB2, 'HS-INV-0052');

      // Guarantee no collision
      expect({docA1, docA2}.intersection({docB1, docB2}), isEmpty);

      // Audit Rule: Device A used 1-2, unused 3-50 remain attached to Device A and never re-allocated
      expect(serviceA.getRemainingCount(AllocationDocumentType.invoice), 48);
    });

    test('Block Exhaustion Fallback: Gracefully generates PENDING- sequence when offline', () async {
      final service = NumberingService(deviceId: 'device_offline');
      // Set allocation at last number (50/50)
      service.setAllocation(
        DeviceNumberAllocation(
          deviceId: 'device_offline',
          documentType: AllocationDocumentType.invoice,
          rangeStart: 1,
          rangeEnd: 50,
          currentAllocated: 50,
          reservedAt: DateTime.now(),
        ),
      );

      // Number 50 consumed
      final lastNum = await service.consumeNextDocumentNumber(docType: DocumentType.invoice, isOnline: false);
      expect(lastNum, 'HS-INV-0050');

      // 51st attempt while offline -> block exhausted
      final exhaustedNum = await service.consumeNextDocumentNumber(docType: DocumentType.invoice, isOnline: false);
      expect(exhaustedNum.startsWith('PENDING-INV-'), isTrue);
    });

    test('Client-Side PDF Generator: Renders valid Invoice PDF bytes on device', () async {
      const service = PdfGeneratorService();

      final record = DocumentRecord(
        id: 'doc_inv_1',
        documentType: DocumentType.invoice,
        documentNumber: 'HS-INV-0001',
        entityType: 'order',
        entityId: 'ord_1',
        customerId: 'cus_1',
        customerName: 'Priya Sundar',
        customerMobile: '6385876999',
        totalAmount: 4000.0,
        paidAmount: 1500.0,
        balanceAmount: 2500.0,
        generatedBy: 'owner',
        generatedAt: DateTime.now(),
      );

      final order = Order(
        id: 'ord_1',
        orderNumber: 'HS-ORD-0001',
        customerId: 'cus_1',
        items: const [
          OrderItem(
            id: '1',
            serviceName: 'Bridal Blouse',
            description: 'Intricate zardozi embroidery',
            quantity: 1,
            unitRate: 3500.0,
            lineTotal: 3500.0,
          ),
          OrderItem(
            id: '2',
            serviceName: 'Saree Pre-pleating & Draping',
            description: 'Box folding',
            quantity: 1,
            unitRate: 500.0,
            lineTotal: 500.0,
          ),
        ],
        subtotal: 4000.0,
        discount: 0.0,
        totalAmount: 4000.0,
        status: OrderStatus.inProgress,
        deliveryDate: DateTime(2026, 10, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'owner',
        updatedBy: 'owner',
      );

      final customer = Customer(
        id: 'cus_1',
        customerId: 'CUS-0001',
        name: 'Priya Sundar',
        mobile: '6385876999',
        address: 'Periyapanichery, Chennai',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'owner',
        updatedBy: 'owner',
      );

      final pdfBytes = await service.generateOrderInvoicePdf(
        documentRecord: record,
        order: order,
        customer: customer,
        totalPaid: 1500.0,
        balanceAmount: 2500.0,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF magic header
      final header = utf8.decode(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('Client-Side PDF Generator: Renders valid Payment Receipt PDF bytes on device', () async {
      const service = PdfGeneratorService();

      final record = DocumentRecord(
        id: 'doc_rec_1',
        documentType: DocumentType.paymentReceipt,
        documentNumber: 'HS-REC-0001',
        entityType: 'order',
        entityId: 'ord_1',
        customerId: 'cus_1',
        customerName: 'Priya Sundar',
        totalAmount: 4000.0,
        paidAmount: 2000.0,
        balanceAmount: 2000.0,
        generatedBy: 'owner',
        generatedAt: DateTime.now(),
      );

      final payment = Payment(
        id: 'pay_1',
        entityType: 'order',
        entityId: 'ord_1',
        customerId: 'cus_1',
        amount: 2000.0,
        method: 'upi',
        paymentDate: DateTime.now(),
        recordedBy: 'owner',
        notes: 'GPay ref #12345',
        createdAt: DateTime.now(),
      );

      final pdfBytes = await service.generatePaymentReceiptPdf(
        documentRecord: record,
        payment: payment,
        orderTotal: 4000.0,
        resultingBalance: 2000.0,
        creditAmount: 0.0,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      final header = utf8.decode(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('Security / RBAC: Manager cannot generate Invoices or Receipts (Section 67 & 90)', () async {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            // Assign Manager role
            notifier.setRole(UserRole.manager);
            return notifier;
          }),
          documentRepositoryProvider.overrideWithValue(DocumentRepository(firestore: null)),
        ],
      );

      final order = Order(
        id: 'ord_1',
        orderNumber: 'HS-ORD-0001',
        customerId: 'cus_1',
        items: const [],
        subtotal: 1000.0,
        discount: 0.0,
        totalAmount: 1000.0,
        status: OrderStatus.confirmed,
        deliveryDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'mgr',
        updatedBy: 'mgr',
      );

      final controller = container.read(documentControllerProvider.notifier);

      expect(
        () async => await controller.generateOrderInvoice(
          order: order,
          totalPaid: 0.0,
          balanceAmount: 1000.0,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
