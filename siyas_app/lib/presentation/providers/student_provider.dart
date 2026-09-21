import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/student_repository.dart';
import '../../domain/models/student_model.dart';
import 'auth_provider.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

final studentsProvider = StreamProvider<List<Student>>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isOwner) {
    return Stream.value([]);
  }
  final repo = ref.watch(studentRepositoryProvider);
  return repo.streamStudents();
});

class StudentController extends StateNotifier<AsyncValue<void>> {
  final StudentRepository _repo;
  final Ref _ref;

  StudentController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> enrollStudent({
    required String studentName,
    required String mobile,
    String? whatsapp,
    String? address,
    required String courseName,
    required double totalFee,
    double advancePaid = 0.0,
    String? notes,
  }) async {
    final auth = _ref.read(authProvider);
    if (!auth.isOwner) {
      throw Exception('Permission denied: Only the Business Owner can manage Classes and Students.');
    }

    state = const AsyncValue.loading();
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final balance = totalFee - advancePaid;

      final student = Student(
        id: id,
        studentName: studentName,
        mobile: mobile,
        whatsapp: whatsapp,
        address: address,
        courseName: courseName,
        totalFee: totalFee,
        paidFee: advancePaid,
        balanceFee: balance,
        notes: notes,
        isActive: true,
        enrolledDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _repo.saveStudent(student);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateStudentFeePayment({
    required Student student,
    required double additionalPayment,
  }) async {
    final auth = _ref.read(authProvider);
    if (!auth.isOwner) {
      throw Exception('Permission denied: Only the Business Owner can record class fee payments.');
    }

    state = const AsyncValue.loading();
    try {
      final newPaid = student.paidFee + additionalPayment;
      final newBalance = (student.totalFee - newPaid).clamp(0.0, student.totalFee);

      final updated = Student(
        id: student.id,
        studentName: student.studentName,
        mobile: student.mobile,
        whatsapp: student.whatsapp,
        address: student.address,
        courseName: student.courseName,
        totalFee: student.totalFee,
        paidFee: newPaid,
        balanceFee: newBalance,
        notes: student.notes,
        isActive: student.isActive,
        enrolledDate: student.enrolledDate,
        updatedAt: DateTime.now(),
      );

      await _repo.saveStudent(updated);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final studentControllerProvider =
    StateNotifierProvider<StudentController, AsyncValue<void>>((ref) {
  final repo = ref.watch(studentRepositoryProvider);
  return StudentController(repo, ref);
});
