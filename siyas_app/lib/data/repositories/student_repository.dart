import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/student_model.dart';

class StudentRepository {
  final FirebaseFirestore? firestore;
  final String businessId;

  StudentRepository({
    this.firestore,
    this.businessId = 'house_of_siyas',
  });

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _studentsRef =>
      _db.collection('businesses').doc(businessId).collection('students');

  Stream<List<Student>> streamStudents({bool activeOnly = false}) {
    Query<Map<String, dynamic>> query = _studentsRef;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => Student.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => a.studentName.compareTo(b.studentName));
      return list;
    });
  }

  Future<void> saveStudent(Student student) async {
    await _studentsRef.doc(student.id).set(student.toMap(), SetOptions(merge: true));

    // Also maintain financials/summary for consistent serverless payment calculations
    await _studentsRef
        .doc(student.id)
        .collection('financials')
        .doc('summary')
        .set({
      'totalFee': student.totalFee,
      'paidFee': student.paidFee,
      'balanceFee': student.balanceFee,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Student?> getStudent(String id) async {
    final doc = await _studentsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Student.fromMap(doc.data()!, doc.id);
  }
}
