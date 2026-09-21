class Student {
  final String id;
  final String studentName;
  final String mobile;
  final String? whatsapp;
  final String? address;
  final String courseName;
  final double totalFee;
  final double paidFee;
  final double balanceFee;
  final String? notes;
  final bool isActive;
  final DateTime enrolledDate;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.studentName,
    required this.mobile,
    this.whatsapp,
    this.address,
    required this.courseName,
    required this.totalFee,
    this.paidFee = 0.0,
    required this.balanceFee,
    this.notes,
    this.isActive = true,
    required this.enrolledDate,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'mobile': mobile,
      'whatsapp': whatsapp,
      'address': address,
      'courseName': courseName,
      'totalFee': totalFee,
      'paidFee': paidFee,
      'balanceFee': balanceFee,
      'notes': notes,
      'isActive': isActive,
      'enrolledDate': enrolledDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, String id) {
    return Student(
      id: id,
      studentName: map['studentName'] as String? ?? '',
      mobile: map['mobile'] as String? ?? '',
      whatsapp: map['whatsapp'] as String?,
      address: map['address'] as String?,
      courseName: map['courseName'] as String? ?? '',
      totalFee: (map['totalFee'] as num?)?.toDouble() ?? 0.0,
      paidFee: (map['paidFee'] as num?)?.toDouble() ?? 0.0,
      balanceFee: (map['balanceFee'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      enrolledDate: map['enrolledDate'] != null
          ? DateTime.tryParse(map['enrolledDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
