import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/data/services/communication_service.dart';

void main() {
  group('Milestone 13 Notifications & Communication Service Tests', () {
    const commService = CommunicationService();

    test('formatIndianMobile formats 10-digit mobile number with +91', () {
      expect(commService.formatIndianMobile('9876543210'), '+919876543210');
      expect(commService.formatIndianMobile('+919876543210'), '+919876543210');
      expect(commService.formatIndianMobile('919876543210'), '+919876543210');
    });

    test('buildWhatsAppUrl creates correct wa.me link with encoded text', () {
      final url = commService.buildWhatsAppUrl(
        mobile: '9876543210',
        message: 'Hello from House of SIYA\'s!',
      );

      expect(url.startsWith('https://wa.me/919876543210?text='), isTrue);
      expect(url.contains('Hello%20from%20House%20of%20SIYA'), isTrue);
    });

    test('generateOrderUpdateMessage creates professional branded notification', () {
      final msg = commService.generateOrderUpdateMessage(
        customerName: 'Ananya',
        orderNumber: 'HS-ORD-0001',
        statusDisplayName: 'Ready for Trial',
        deliveryDate: DateTime(2026, 10, 5),
      );

      expect(msg.contains('Dear Ananya'), isTrue);
      expect(msg.contains('House of SIYA\'s'), isTrue);
      expect(msg.contains('Ready for Trial'), isTrue);
      expect(msg.contains('5/10/2026'), isTrue);
    });

    test('generatePaymentReminderMessage creates polite payment reminder', () {
      final msg = commService.generatePaymentReminderMessage(
        customerName: 'Meera',
        orderNumber: 'HS-ORD-0012',
        balanceAmount: 2500.0,
      );

      expect(msg.contains('Dear Meera'), isTrue);
      expect(msg.contains('₹2500'), isTrue);
      expect(msg.contains('HS-ORD-0012'), isTrue);
    });

    test('NotificationService tracks and acknowledges local reminders', () {
      final notifService = NotificationService();

      final reminder = AppReminder(
        id: 'rem_1',
        type: ReminderType.orderDelivery,
        title: 'Order Delivery Today',
        message: 'Order HS-ORD-0001 delivery scheduled today.',
        scheduledTime: DateTime(2026, 9, 21, 17, 0),
        entityId: 'HS-ORD-0001',
      );

      notifService.scheduleReminder(reminder);
      expect(notifService.activeReminders.length, 1);
      expect(notifService.activeReminders.first.id, 'rem_1');

      notifService.acknowledgeReminder('rem_1');
      expect(notifService.activeReminders.length, 0);
    });
  });
}
