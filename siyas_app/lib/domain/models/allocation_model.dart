enum AllocationDocumentType {
  order,
  invoice,
  payment,
  rental,
  classDoc,
  alteration,
  customer;

  static AllocationDocumentType fromString(String? val) {
    switch (val) {
      case 'order':
        return AllocationDocumentType.order;
      case 'invoice':
        return AllocationDocumentType.invoice;
      case 'payment':
        return AllocationDocumentType.payment;
      case 'rental':
        return AllocationDocumentType.rental;
      case 'class':
      case 'classDoc':
        return AllocationDocumentType.classDoc;
      case 'alteration':
        return AllocationDocumentType.alteration;
      case 'customer':
        return AllocationDocumentType.customer;
      default:
        return AllocationDocumentType.order;
    }
  }

  String toDbString() => this == AllocationDocumentType.classDoc ? 'class' : name;
}

class DeviceNumberAllocation {
  final String deviceId;
  final AllocationDocumentType documentType;
  final int rangeStart; // e.g. 51
  final int rangeEnd; // e.g. 100
  final int currentAllocated; // e.g. 58
  final DateTime reservedAt;

  const DeviceNumberAllocation({
    required this.deviceId,
    required this.documentType,
    required this.rangeStart,
    required this.rangeEnd,
    required this.currentAllocated,
    required this.reservedAt,
  });

  bool get isExhausted => currentAllocated > rangeEnd;
  int get remainingCount => (rangeEnd - currentAllocated + 1).clamp(0, rangeEnd - rangeStart + 1);

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'documentType': documentType.toDbString(),
      'rangeStart': rangeStart,
      'rangeEnd': rangeEnd,
      'currentAllocated': currentAllocated,
      'reservedAt': reservedAt.toIso8601String(),
    };
  }

  factory DeviceNumberAllocation.fromMap(Map<String, dynamic> map, String id) {
    return DeviceNumberAllocation(
      deviceId: map['deviceId'] as String? ?? id,
      documentType: AllocationDocumentType.fromString(map['documentType'] as String?),
      rangeStart: map['rangeStart'] as int? ?? 1,
      rangeEnd: map['rangeEnd'] as int? ?? 50,
      currentAllocated: map['currentAllocated'] as int? ?? (map['rangeStart'] as int? ?? 1),
      reservedAt: map['reservedAt'] != null
          ? DateTime.tryParse(map['reservedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
