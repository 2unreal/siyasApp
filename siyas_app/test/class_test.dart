import 'package:flutter_test/flutter_test.dart';
import 'package:siyas_app/domain/models/student_model.dart';

void main() {
  group('Milestone 11 Classes & Student Fee Tracking Tests', () {
    test('Student model serialization and deserialization', () {
      final now = DateTime(2026, 9, 21, 10, 0);
      final student = Student(
        id: 'std_1',
        studentName: 'Kavitha Ramaswamy',
        mobile: '9444123456',
        whatsapp: '9444123456',
        address: 'Pallavaram, Chennai',
        courseName: 'Aari & Zardozi Embroidery',
        totalFee: 15000.0,
        paidFee: 5000.0,
        balanceFee: 10000.0,
        notes: 'Weekend Batch',
        isActive: true,
        enrolledDate: now,
        updatedAt: now,
      );

      final map = student.toMap();
      expect(map['id'], 'std_1');
      expect(map['studentName'], 'Kavitha Ramaswamy');
      expect(map['courseName'], 'Aari & Zardozi Embroidery');
      expect(map['totalFee'], 15000.0);
      expect(map['paidFee'], 5000.0);
      expect(map['balanceFee'], 10000.0);

      final deserialized = Student.fromMap(map, 'std_1');
      expect(deserialized.id, 'std_1');
      expect(deserialized.studentName, 'Kavitha Ramaswamy');
      expect(deserialized.balanceFee, 10000.0);
      expect(deserialized.isActive, isTrue);
    });

    test('Student fee payment calculation with multiple partial installments', () {
      const totalFee = 15000.0;
      double paidFee = 0.0;
      double balanceFee = totalFee;

      // Installment 1: Advance ₹5000
      double payment1 = 5000.0;
      paidFee += payment1;
      balanceFee = totalFee - paidFee;
      expect(paidFee, 5000.0);
      expect(balanceFee, 10000.0);

      // Installment 2: Mid-course fee ₹5000
      double payment2 = 5000.0;
      paidFee += payment2;
      balanceFee = totalFee - paidFee;
      expect(paidFee, 10000.0);
      expect(balanceFee, 5000.0);

      // Installment 3: Final settlement ₹5000
      double payment3 = 5000.0;
      paidFee += payment3;
      balanceFee = totalFee - paidFee;
      expect(paidFee, 15000.0);
      expect(balanceFee, 0.0);
    });
  });
}
