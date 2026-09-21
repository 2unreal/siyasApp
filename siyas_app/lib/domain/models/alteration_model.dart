enum AlterationStatus {
  received,
  inProgress,
  ready,
  delivered,
  cancelled;

  static AlterationStatus fromString(String? val) {
    switch (val) {
      case 'received':
        return AlterationStatus.received;
      case 'in_progress':
      case 'inProgress':
        return AlterationStatus.inProgress;
      case 'ready':
        return AlterationStatus.ready;
      case 'delivered':
        return AlterationStatus.delivered;
      case 'cancelled':
        return AlterationStatus.cancelled;
      default:
        return AlterationStatus.received;
    }
  }

  String toDbString() => this == AlterationStatus.inProgress ? 'in_progress' : name;
}

class Alteration {
  final String id;
  final String alterationNumber; // e.g. "HS-ALT-0001"
  final String originalOrderId;
  final String customerId;
  final DateTime dateReceived;
  final String description;
  final String area;
  final String? notes;
  final DateTime expectedCompletionDate;
  final double additionalCharge; // 0 for free alteration
  final String paymentStatus; // 'unpaid' | 'paid' | 'waived'
  final AlterationStatus status;
  final DateTime? completionDate;
  final DateTime? deliveryDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const Alteration({
    required this.id,
    required this.alterationNumber,
    required this.originalOrderId,
    required this.customerId,
    required this.dateReceived,
    required this.description,
    required this.area,
    this.notes,
    required this.expectedCompletionDate,
    this.additionalCharge = 0.0,
    this.paymentStatus = 'unpaid',
    this.status = AlterationStatus.received,
    this.completionDate,
    this.deliveryDate,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  bool get isFree => additionalCharge == 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alterationNumber': alterationNumber,
      'originalOrderId': originalOrderId,
      'customerId': customerId,
      'dateReceived': dateReceived.toIso8601String(),
      'description': description,
      'area': area,
      'notes': notes,
      'expectedCompletionDate': expectedCompletionDate.toIso8601String(),
      'additionalCharge': additionalCharge,
      'paymentStatus': paymentStatus,
      'status': status.toDbString(),
      'completionDate': completionDate?.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory Alteration.fromMap(Map<String, dynamic> map, String id) {
    return Alteration(
      id: id,
      alterationNumber: map['alterationNumber'] as String? ?? '',
      originalOrderId: map['originalOrderId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      dateReceived: map['dateReceived'] != null
          ? DateTime.tryParse(map['dateReceived'] as String) ?? DateTime.now()
          : DateTime.now(),
      description: map['description'] as String? ?? '',
      area: map['area'] as String? ?? '',
      notes: map['notes'] as String?,
      expectedCompletionDate: map['expectedCompletionDate'] != null
          ? DateTime.tryParse(map['expectedCompletionDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      additionalCharge: (map['additionalCharge'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['paymentStatus'] as String? ?? 'unpaid',
      status: AlterationStatus.fromString(map['status'] as String?),
      completionDate: map['completionDate'] != null
          ? DateTime.tryParse(map['completionDate'] as String)
          : null,
      deliveryDate: map['deliveryDate'] != null
          ? DateTime.tryParse(map['deliveryDate'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }
}
