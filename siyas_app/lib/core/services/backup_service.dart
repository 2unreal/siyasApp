import 'dart:convert';
import '../../domain/models/customer_model.dart';
import '../../domain/models/order_model.dart';
import '../../domain/models/rental_model.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/models/student_model.dart';

class BackupSnapshot {
  final String version;
  final DateTime exportedAt;
  final String exportedBy;
  final Map<String, dynamic> studioSettings;
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> rentals;
  final List<Map<String, dynamic>> students;

  BackupSnapshot({
    required this.version,
    required this.exportedAt,
    required this.exportedBy,
    required this.studioSettings,
    required this.customers,
    required this.orders,
    required this.rentals,
    required this.students,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'exportedBy': exportedBy,
      'metadata': {
        'totalCustomers': customers.length,
        'totalOrders': orders.length,
        'totalRentals': rentals.length,
        'totalStudents': students.length,
      },
      'studioSettings': studioSettings,
      'customers': customers,
      'orders': orders,
      'rentals': rentals,
      'students': students,
    };
  }

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toMap());
}

class BackupService {
  static const String currentBackupVersion = '1.0.0';

  BackupSnapshot createBackup({
    required bool isOwner,
    required String actorUid,
    required StudioSettings settings,
    List<Customer> customers = const [],
    List<Order> orders = const [],
    List<RentalTransaction> rentals = const [],
    List<Student> students = const [],
  }) {
    if (!isOwner) {
      throw StateError('Access Denied: Full studio backup export is strictly restricted to the Owner role.');
    }

    return BackupSnapshot(
      version: currentBackupVersion,
      exportedAt: DateTime.now(),
      exportedBy: actorUid,
      studioSettings: settings.toMap(),
      customers: customers.map((c) => c.toMap()).toList(),
      orders: orders.map((o) => o.toMap()).toList(),
      rentals: rentals.map((r) => r.toMap()).toList(),
      students: students.map((s) => s.toMap()).toList(),
    );
  }
}
