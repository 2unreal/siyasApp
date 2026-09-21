import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/domain/models/allocation_model.dart';
import 'package:siyas_app/domain/models/alteration_model.dart';
import 'package:siyas_app/domain/models/customer_model.dart';
import 'package:siyas_app/domain/models/measurement_model.dart';
import 'package:siyas_app/domain/models/order_model.dart';
import 'package:siyas_app/domain/models/payment_model.dart';
import 'package:siyas_app/domain/models/rental_model.dart';
import 'package:siyas_app/domain/models/student_model.dart';
import 'package:siyas_app/domain/models/user_model.dart';

void main() {
  group('Milestone 2 Domain Model Tests', () {
    test('AppUser serialization and role helpers', () {
      final user = AppUser(
        userId: 'u1',
        name: 'Priya',
        phone: '+919999999999',
        role: UserRole.manager,
        isActive: true,
        businessId: 'house_of_siyas',
        createdAt: DateTime(2026, 9, 21),
      );

      final map = user.toMap();
      expect(map['role'], 'manager');
      expect(user.role.isManager, isTrue);
      expect(user.role.isOwner, isFalse);

      final deserialized = AppUser.fromMap(map, 'u1');
      expect(deserialized.name, 'Priya');
      expect(deserialized.role, UserRole.manager);
    });

    test('Measurement template and set serialization', () {
      final template = MeasurementTemplate(
        id: 't1',
        garmentType: 'Blouse',
        fields: const [
          MeasurementField(id: 'bust', label: 'Bust Round', sortOrder: 1),
          MeasurementField(id: 'waist', label: 'Waist Round', sortOrder: 2),
        ],
      );

      final set = MeasurementSet(
        id: 'm1',
        customerId: 'c1',
        templateId: 't1',
        garmentType: 'Blouse',
        values: {'bust': 36.5, 'waist': 30.0},
        createdAt: DateTime(2026, 9, 21),
        createdBy: 'u1',
      );

      expect(template.fields.length, 2);
      expect(set.values['bust'], 36.5);
    });

    test('Customer model with optional fields and serialization', () {
      final customer = Customer(
        id: 'c1',
        customerId: 'CUS-0001',
        name: 'Ananya Sharma',
        mobile: '9876543210',
        whatsappSameAsMobile: true,
        status: 'active',
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
        createdBy: 'u1',
        updatedBy: 'u1',
      );

      final map = customer.toMap();
      expect(map['customerId'], 'CUS-0001');
      expect(customer.isArchived, isFalse);

      final deserialized = Customer.fromMap(map, 'c1');
      expect(deserialized.name, 'Ananya Sharma');
      expect(deserialized.mobile, '9876543210');
    });

    test('Order and decoupled OrderFinancialSummary separation', () {
      final order = Order(
        id: 'o1',
        orderNumber: 'HS-ORD-0001',
        customerId: 'c1',
        items: const [
          OrderItem(
            id: 'item1',
            serviceName: 'Bridal Blouse',
            description: 'Aari embroidery with padding',
            quantity: 1,
            unitRate: 4500.0,
            lineTotal: 4500.0,
          ),
        ],
        subtotal: 4500.0,
        discount: 500.0,
        totalAmount: 4000.0,
        status: OrderStatus.inProgress,
        deliveryDate: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
        createdBy: 'u1',
        updatedBy: 'u1',
      );

      final orderMap = order.toMap();
      // Operational order does NOT contain payment running totals
      expect(orderMap.containsKey('totalPaid'), isFalse);
      expect(orderMap.containsKey('balanceAmount'), isFalse);
      expect(orderMap['status'], 'in_progress');

      // Decoupled financial summary contains the protected financial metrics
      final financials = OrderFinancialSummary(
        orderId: 'o1',
        orderTotal: 4000.0,
        totalPaid: 2500.0,
        balanceAmount: 1500.0,
        creditAmount: 0.0,
        updatedAt: DateTime(2026, 9, 21),
      );

      final finMap = financials.toMap();
      expect(finMap['totalPaid'], 2500.0);
      expect(finMap['balanceAmount'], 1500.0);
    });

    test('Payment model for Order and Class payments', () {
      final orderPayment = Payment(
        id: 'p1',
        entityType: 'order',
        entityId: 'o1',
        customerId: 'c1',
        amount: 2500.0,
        method: 'upi',
        receiptNumber: 'HS-REC-0001',
        paymentDate: DateTime(2026, 9, 21),
        recordedBy: 'u1',
        createdAt: DateTime(2026, 9, 21),
      );

      final pMap = orderPayment.toMap();
      expect(pMap['entityType'], 'order');
      expect(pMap['amount'], 2500.0);

      final classPayment = Payment(
        id: 'p2',
        entityType: 'class',
        entityId: 's1',
        studentId: 's1',
        amount: 5000.0,
        method: 'cash',
        receiptNumber: 'HS-CLS-0001',
        paymentDate: DateTime(2026, 9, 21),
        recordedBy: 'u1',
        createdAt: DateTime(2026, 9, 21),
      );

      expect(classPayment.entityType, 'class');
      expect(classPayment.receiptNumber, 'HS-CLS-0001');
    });

    test('RentalItem and RentalTransaction serialization', () {
      final item = RentalItem(
        id: 'r1',
        itemCode: 'HS-REN-0001',
        itemName: 'Kanjeevaram Bridal Lehenga',
        category: 'Bridal',
        size: 'M',
        colour: 'Wine Red',
        rentalPrice: 3500.0,
        deposit: 5000.0,
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
      );

      final txn = RentalTransaction(
        id: 't1',
        rentalItemId: 'r1',
        customerId: 'c1',
        rentalStartDate: DateTime(2026, 10, 1),
        returnDate: DateTime(2026, 10, 4),
        rentalAmount: 3500.0,
        depositAmount: 5000.0,
        paidAmount: 8500.0,
        status: RentalStatus.reserved,
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
        createdBy: 'u1',
      );

      expect(item.rentalPrice, 3500.0);
      expect(txn.status, RentalStatus.reserved);
      final deserialized = RentalTransaction.fromMap(txn.toMap(), 't1');
      expect(deserialized.paidAmount, 8500.0);
    });

    test('Alteration model with free vs paid validation', () {
      final freeAlt = Alteration(
        id: 'alt1',
        alterationNumber: 'HS-ALT-0001',
        originalOrderId: 'o1',
        customerId: 'c1',
        dateReceived: DateTime(2026, 9, 21),
        description: 'Waist loosening 0.5 inch',
        area: 'Waist',
        expectedCompletionDate: DateTime(2026, 9, 25),
        additionalCharge: 0.0,
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
        createdBy: 'u1',
      );

      expect(freeAlt.isFree, isTrue);

      final paidAlt = Alteration(
        id: 'alt2',
        alterationNumber: 'HS-ALT-0002',
        originalOrderId: 'o1',
        customerId: 'c1',
        dateReceived: DateTime(2026, 9, 21),
        description: 'Add extra sleeves lining and tassels',
        area: 'Sleeves',
        expectedCompletionDate: DateTime(2026, 9, 25),
        additionalCharge: 400.0,
        paymentStatus: 'unpaid',
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
        createdBy: 'u1',
      );

      expect(paidAlt.isFree, isFalse);
      expect(paidAlt.additionalCharge, 400.0);
    });

    test('Student and DeviceNumberAllocation serialization', () {
      final student = Student(
        id: 's1',
        studentName: 'Kavitha R',
        mobile: '9888877777',
        courseName: 'Aari Embroidery Masterclass',
        totalFee: 15000.0,
        paidFee: 5000.0,
        balanceFee: 10000.0,
        enrolledDate: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
      );

      expect(student.balanceFee, 10000.0);

      final alloc = DeviceNumberAllocation(
        deviceId: 'dev_phone_1',
        documentType: AllocationDocumentType.invoice,
        rangeStart: 1,
        rangeEnd: 50,
        currentAllocated: 12,
        reservedAt: DateTime(2026, 9, 21),
      );

      expect(alloc.isExhausted, isFalse);
      expect(alloc.remainingCount, 39);
    });
  });
}
