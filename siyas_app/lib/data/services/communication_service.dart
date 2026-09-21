import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReminderType {
  orderDelivery,
  rentalReturn,
  outstandingPayment,
  alterationDue,
  custom,
}

class AppReminder {
  final String id;
  final ReminderType type;
  final String title;
  final String message;
  final DateTime scheduledTime;
  final String entityId;
  final String? customerMobile;
  final bool isAcknowledged;

  const AppReminder({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.scheduledTime,
    required this.entityId,
    this.customerMobile,
    this.isAcknowledged = false,
  });

  AppReminder copyWith({bool? isAcknowledged}) {
    return AppReminder(
      id: id,
      type: type,
      title: title,
      message: message,
      scheduledTime: scheduledTime,
      entityId: entityId,
      customerMobile: customerMobile,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }
}

class NotificationService {
  final List<AppReminder> _scheduledReminders = [];

  List<AppReminder> get activeReminders =>
      _scheduledReminders.where((r) => !r.isAcknowledged).toList();

  /// Schedule a local reminder (order delivery, rental return, alteration due, payment follow-up)
  void scheduleReminder(AppReminder reminder) {
    _scheduledReminders.removeWhere((r) => r.id == reminder.id);
    _scheduledReminders.add(reminder);
    _scheduledReminders.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    debugPrint('Scheduled reminder [${reminder.type.name}]: ${reminder.title} at ${reminder.scheduledTime}');
  }

  void acknowledgeReminder(String id) {
    final idx = _scheduledReminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _scheduledReminders[idx] = _scheduledReminders[idx].copyWith(isAcknowledged: true);
    }
  }

  void clearAll() {
    _scheduledReminders.clear();
  }
}

class CommunicationService {
  const CommunicationService();

  /// Formats customer phone number with standard Indian country code (+91)
  String formatIndianMobile(String mobile) {
    final cleaned = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }
    if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+$cleaned';
    }
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    return '+$cleaned';
  }

  /// Builds standardized pre-formatted WhatsApp message URL.
  /// Does not require WhatsApp Business API in V1.
  String buildWhatsAppUrl({
    required String mobile,
    required String message,
  }) {
    final cleanPhone = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final fullPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final encodedMessage = Uri.encodeComponent(message);
    return 'https://wa.me/$fullPhone?text=$encodedMessage';
  }

  /// Generates order update message template for WhatsApp/SMS
  String generateOrderUpdateMessage({
    required String customerName,
    required String orderNumber,
    required String statusDisplayName,
    DateTime? deliveryDate,
  }) {
    final delivery = deliveryDate != null
        ? ' Scheduled Delivery: ${deliveryDate.day}/${deliveryDate.month}/${deliveryDate.year}.'
        : '';
    return 'Dear $customerName, greetings from House of SIYA\'s! Your order $orderNumber is currently $statusDisplayName.$delivery Thank you for choosing us.';
  }

  /// Generates outstanding payment reminder message template
  String generatePaymentReminderMessage({
    required String customerName,
    required String orderNumber,
    required double balanceAmount,
  }) {
    return 'Dear $customerName, greetings from House of SIYA\'s! A friendly reminder that a balance of ₹${balanceAmount.toStringAsFixed(0)} is pending for Order $orderNumber. Thank you.';
  }

  /// Generates rental return reminder message template
  String generateRentalReturnReminderMessage({
    required String customerName,
    required String itemName,
    required DateTime returnDate,
  }) {
    return 'Dear $customerName, greetings from House of SIYA\'s! This is a reminder that the rental item "$itemName" is due for return on ${returnDate.day}/${returnDate.month}/${returnDate.year}. Thank you.';
  }

  /// Builds direct phone call URI
  String buildTelUri(String mobile) {
    final cleaned = mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    return 'tel:$cleaned';
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final communicationServiceProvider = Provider<CommunicationService>((ref) {
  return const CommunicationService();
});
