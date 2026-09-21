import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/document_model.dart';

class DocumentRepository {
  final FirebaseFirestore? firestore;
  final String businessId;

  DocumentRepository({
    this.firestore,
    this.businessId = 'house_of_siyas',
  });

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _documentsRef =>
      _db.collection('businesses').doc(businessId).collection('documents');

  /// Save generated document record. Strictly OWNER WRITE ONLY.
  Future<void> saveDocumentRecord(DocumentRecord record) async {
    await _documentsRef.doc(record.id).set(record.toMap());
  }

  /// Stream generated documents history. Strictly OWNER READ ONLY.
  Stream<List<DocumentRecord>> streamDocuments({DocumentType? type, String? entityId}) {
    Query<Map<String, dynamic>> query = _documentsRef;
    if (type != null) {
      query = query.where('documentType', isEqualTo: type.toDbString());
    }
    if (entityId != null) {
      query = query.where('entityId', isEqualTo: entityId);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => DocumentRecord.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return list;
    });
  }

  /// Get a single document record by ID
  Future<DocumentRecord?> getDocumentRecord(String id) async {
    final doc = await _documentsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return DocumentRecord.fromMap(doc.data()!, doc.id);
  }
}
