import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/business_defaults.dart';
import '../../domain/models/customer_model.dart';

class CustomerNote {
  final String id;
  final String note;
  final DateTime createdAt;
  final String authorId;
  final String authorName;

  const CustomerNote({
    required this.id,
    required this.note,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'authorId': authorId,
      'authorName': authorName,
    };
  }

  factory CustomerNote.fromMap(Map<String, dynamic> map, String id) {
    return CustomerNote(
      id: id,
      note: map['note'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
    );
  }
}

class CustomerRepository {
  final FirebaseFirestore _firestore;
  final String businessId;

  CustomerRepository({
    FirebaseFirestore? firestore,
    this.businessId = 'house_of_siyas',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customersRef =>
      _firestore.collection('businesses').doc(businessId).collection('customers');

  /// Stream customers filtered by status ('active' or 'archived')
  Stream<List<Customer>> streamCustomers({required String status}) {
    return _customersRef
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in memory by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Get a single customer by document ID
  Stream<Customer?> streamCustomer(String id) {
    return _customersRef.doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Customer.fromMap(doc.data()!, doc.id);
    });
  }

  /// Check for existing customers with the same mobile number
  Future<List<Customer>> findCustomersByMobile(String mobile) async {
    final cleaned = mobile.trim();
    if (cleaned.isEmpty) return [];

    final snapshot = await _customersRef
        .where('mobile', isEqualTo: cleaned)
        .where('status', isEqualTo: 'active')
        .get();

    return snapshot.docs
        .map((doc) => Customer.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Generate next sequential Customer ID (e.g. CUS-0001) using highest sequence + 1
  Future<String> generateNextCustomerId() async {
    try {
      final snapshot = await _customersRef
          .orderBy('customerId', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final lastId = snapshot.docs.first.data()['customerId'] as String? ?? '';
        final match = RegExp(r'\d+').firstMatch(lastId);
        if (match != null) {
          final nextNum = (int.tryParse(match.group(0)!) ?? 0) + 1;
          return '${BusinessDefaults.prefixCustomer}${nextNum.toString().padLeft(4, '0')}';
        }
      }
    } catch (_) {
      // Fallback if offline or index building
    }
    return '${BusinessDefaults.prefixCustomer}0001';
  }

  /// Create a new customer
  Future<void> createCustomer(Customer customer) async {
    await _customersRef.doc(customer.id).set(customer.toMap());
  }

  /// Update an existing customer
  Future<void> updateCustomer(Customer customer) async {
    await _customersRef.doc(customer.id).update({
      'name': customer.name,
      'mobile': customer.mobile,
      'whatsappMobile': customer.whatsappMobile,
      'whatsappSameAsMobile': customer.whatsappSameAsMobile,
      'address': customer.address,
      'generalNote': customer.generalNote,
      'photoUrl': customer.photoUrl,
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': customer.updatedBy,
    });
  }

  /// Archive customer (Owner only)
  Future<void> archiveCustomer(String id, String userId) async {
    await _customersRef.doc(id).update({
      'status': 'archived',
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': userId,
    });
  }

  /// Restore customer (Owner only)
  Future<void> restoreCustomer(String id, String userId) async {
    await _customersRef.doc(id).update({
      'status': 'active',
      'updatedAt': DateTime.now().toIso8601String(),
      'updatedBy': userId,
    });
  }

  /// Stream dated notes history for a customer
  Stream<List<CustomerNote>> streamNotesHistory(String customerId) {
    return _customersRef
        .doc(customerId)
        .collection('notesHistory')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CustomerNote.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Add a dated note to customer's notes history
  Future<void> addCustomerNote({
    required String customerId,
    required String note,
    required String authorId,
    required String authorName,
  }) async {
    final noteDoc = _customersRef.doc(customerId).collection('notesHistory').doc();
    final customerNote = CustomerNote(
      id: noteDoc.id,
      note: note.trim(),
      createdAt: DateTime.now(),
      authorId: authorId,
      authorName: authorName,
    );
    await noteDoc.set(customerNote.toMap());
  }
}
