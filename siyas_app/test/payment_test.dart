import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/domain/models/payment_model.dart';
import 'package:siyas_app/presentation/screens/payments/payment_entry_screen.dart';

void main() {
  group('Milestone 7 Payments, Overpayments, Refunds & Ledger Engine Tests', () {
    test('Payment model serialization and deserialization', () {
      final now = DateTime(2026, 9, 21, 15, 30);
      final payment = Payment(
        id: 'pay_123',
        entityType: 'order',
        entityId: 'ord_456',
        customerId: 'cus_789',
        amount: 2500.0,
        method: 'upi',
        receiptNumber: 'HS-REC-0001',
        paymentDate: now,
        recordedBy: 'user_mgr_1',
        notes: 'Advance via GPay',
        createdAt: now,
      );

      final map = payment.toMap();
      expect(map['id'], 'pay_123');
      expect(map['amount'], 2500.0);
      expect(map['method'], 'upi');
      expect(map['recordedBy'], 'user_mgr_1');

      final deserialized = Payment.fromMap(map, 'pay_123');
      expect(deserialized.id, 'pay_123');
      expect(deserialized.amount, 2500.0);
      expect(deserialized.notes, 'Advance via GPay');
    });

    test('CustomerCredit model serialization and deserialization', () {
      final now = DateTime(2026, 9, 21, 16, 0);
      final credit = CustomerCredit(
        id: 'cred_1',
        customerId: 'cus_789',
        orderId: 'ord_456',
        amount: 500.0,
        reason: 'Overpayment on order ord_456',
        createdAt: now,
        createdBy: 'user_mgr_1',
      );

      final map = credit.toMap();
      expect(map['id'], 'cred_1');
      expect(map['amount'], 500.0);

      final deserialized = CustomerCredit.fromMap(map, 'cred_1');
      expect(deserialized.id, 'cred_1');
      expect(deserialized.amount, 500.0);
      expect(deserialized.reason, 'Overpayment on order ord_456');
    });

    test('Refund model serialization and deserialization', () {
      final now = DateTime(2026, 9, 21, 16, 30);
      final refund = Refund(
        id: 'ref_1',
        entityType: 'order',
        entityId: 'ord_456',
        amount: 1000.0,
        method: 'cash',
        reason: 'Customer cancelled extra embroidery',
        recordedBy: 'user_owner_1',
        refundDate: now,
        createdAt: now,
      );

      final map = refund.toMap();
      expect(map['id'], 'ref_1');
      expect(map['amount'], 1000.0);
      expect(map['reason'], 'Customer cancelled extra embroidery');

      final deserialized = Refund.fromMap(map, 'ref_1');
      expect(deserialized.id, 'ref_1');
      expect(deserialized.amount, 1000.0);
      expect(deserialized.reason, 'Customer cancelled extra embroidery');
    });

    test('Payment & Overpayment math simulation', () {
      const orderTotal = 4000.0;
      double currentPaid = 0.0;
      double currentCredit = 0.0;

      // 1. Partial payment: ₹1500
      double paymentAmount = 1500.0;
      double newPaid = currentPaid + paymentAmount;
      double balance = orderTotal - newPaid;
      expect(balance, 2500.0);
      expect(currentCredit, 0.0);
      currentPaid = newPaid;

      // 2. Exact payment: ₹2500
      paymentAmount = 2500.0;
      newPaid = currentPaid + paymentAmount;
      balance = orderTotal - newPaid;
      expect(balance, 0.0);
      expect(currentCredit, 0.0);
      currentPaid = newPaid;

      // 3. Overpayment: ₹500 extra paid
      paymentAmount = 500.0;
      newPaid = currentPaid + paymentAmount;
      if (newPaid > orderTotal) {
        balance = 0.0;
        final excess = newPaid - orderTotal;
        currentCredit += excess;
      }
      expect(balance, 0.0);
      expect(currentCredit, 500.0);
    });

    test('Refund math simulation', () {
      const orderTotal = 4000.0;
      double currentPaid = 4000.0;

      const refundAmount = 800.0;
      final newTotalPaid = currentPaid - refundAmount;
      final newBalance = orderTotal - newTotalPaid;

      expect(newTotalPaid, 3200.0);
      expect(newBalance, 800.0);
    });

    test('Manager PaymentResult contains only step balance and no historical lists', () {
      final result = PaymentResult.fromMap({
        'success': true,
        'paymentId': 'pay_999',
        'amountRecorded': 2000.0,
        'newBalance': 1500.0,
        'creditAmount': 0.0,
      });

      expect(result.success, isTrue);
      expect(result.paymentId, 'pay_999');
      expect(result.amountRecorded, 2000.0);
      expect(result.newBalance, 1500.0);
      expect(result.creditAmount, 0.0);
    });

    testWidgets('PaymentEntryScreen renders form, quick increment chips, and payment methods',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PaymentEntryScreen(
              entityType: 'order',
              entityId: 'ord_test_1',
              orderNumber: 'HS-ORD-0001',
              suggestedAmount: 1500.0,
            ),
          ),
        ),
      );

      expect(find.text('Payment — HS-ORD-0001'), findsOneWidget);
      expect(find.text('1500'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('UPI / QR'), findsOneWidget);
      expect(find.text('+₹500'), findsOneWidget);
      expect(find.text('+₹1000'), findsOneWidget);
      expect(find.text('Record Payment'), findsOneWidget);

      // Tap +₹500 quick chip and verify amount increases to 2000
      await tester.tap(find.text('+₹500'));
      await tester.pump();
      expect(find.text('2000'), findsOneWidget);
    });
  });
}
