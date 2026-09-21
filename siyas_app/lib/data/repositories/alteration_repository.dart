import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/alteration_model.dart';

class AlterationRepository {
  final FirebaseFirestore? firestore;
  final String businessId;

  AlterationRepository({
    this.firestore,
    this.businessId = 'house_of_siyas',
  });

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _alterationsRef =>
      _db.collection('businesses').doc(businessId).collection('alterations');

  Stream<List<Alteration>> streamAlterations({String? customerId, String? originalOrderId}) {
    Query<Map<String, dynamic>> query = _alterationsRef;
    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    if (originalOrderId != null) {
      query = query.where('originalOrderId', isEqualTo: originalOrderId);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Alteration.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.dateReceived.compareTo(a.dateReceived));
      return list;
    });
  }

  Future<void> saveAlteration(Alteration alteration) async {
    await _alterationsRef.doc(alteration.id).set(alteration.toMap(), SetOptions(merge: true));
  }

  Future<Alteration?> getAlteration(String id) async {
    final doc = await _alterationsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Alteration.fromMap(doc.data()!, doc.id);
  }

  /// Generate next alteration sequence: HS-ALT-0001
  Future<String> generateNextAlterationNumber() async {
    final snapshot = await _alterationsRef
        .orderBy('alterationNumber', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'HS-ALT-0001';
    }

    final highest = snapshot.docs.first.data()['alterationNumber'] as String? ?? 'HS-ALT-0000';
    final parts = highest.split('-');
    final currentSeq = int.tryParse(parts.last) ?? 0;
    final nextSeq = (currentSeq + 1).toString().padLeft(4, '0');
    return 'HS-ALT-$nextSeq';
  }
}
