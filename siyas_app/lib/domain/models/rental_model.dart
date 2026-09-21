class RentalItem {
  final String id;
  final String itemCode; // e.g. "HS-REN-0001"
  final String itemName;
  final String category;
  final String size;
  final String colour;
  final double rentalPrice;
  final double deposit;
  final List<String> photoUrls;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RentalItem({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.category,
    required this.size,
    required this.colour,
    required this.rentalPrice,
    required this.deposit,
    this.photoUrls = const [],
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemCode': itemCode,
      'itemName': itemName,
      'category': category,
      'size': size,
      'colour': colour,
      'rentalPrice': rentalPrice,
      'deposit': deposit,
      'photoUrls': photoUrls,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RentalItem.fromMap(Map<String, dynamic> map, String id) {
    return RentalItem(
      id: id,
      itemCode: map['itemCode'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      size: map['size'] as String? ?? '',
      colour: map['colour'] as String? ?? '',
      rentalPrice: (map['rentalPrice'] as num?)?.toDouble() ?? 0.0,
      deposit: (map['deposit'] as num?)?.toDouble() ?? 0.0,
      photoUrls: List<String>.from(map['photoUrls'] as List<dynamic>? ?? []),
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

enum RentalStatus {
  available,
  reserved,
  rented,
  returned,
  cancelled;

  static RentalStatus fromString(String? val) {
    switch (val) {
      case 'available':
        return RentalStatus.available;
      case 'reserved':
        return RentalStatus.reserved;
      case 'rented':
        return RentalStatus.rented;
      case 'returned':
        return RentalStatus.returned;
      case 'cancelled':
        return RentalStatus.cancelled;
      default:
        return RentalStatus.reserved;
    }
  }
}

class RentalTransaction {
  final String id;
  final String rentalItemId;
  final String customerId;
  final DateTime rentalStartDate;
  final DateTime returnDate;
  final double rentalAmount;
  final double depositAmount;
  final double paidAmount;
  final double depositReturned;
  final String? notes;
  final RentalStatus status;
  final List<String> beforeRentalPhotoUrls;
  final List<String> returnConditionPhotoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const RentalTransaction({
    required this.id,
    required this.rentalItemId,
    required this.customerId,
    required this.rentalStartDate,
    required this.returnDate,
    required this.rentalAmount,
    required this.depositAmount,
    this.paidAmount = 0.0,
    this.depositReturned = 0.0,
    this.notes,
    this.status = RentalStatus.reserved,
    this.beforeRentalPhotoUrls = const [],
    this.returnConditionPhotoUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rentalItemId': rentalItemId,
      'customerId': customerId,
      'rentalStartDate': rentalStartDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'rentalAmount': rentalAmount,
      'depositAmount': depositAmount,
      'paidAmount': paidAmount,
      'depositReturned': depositReturned,
      'notes': notes,
      'status': status.name,
      'beforeRentalPhotoUrls': beforeRentalPhotoUrls,
      'returnConditionPhotoUrls': returnConditionPhotoUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory RentalTransaction.fromMap(Map<String, dynamic> map, String id) {
    return RentalTransaction(
      id: id,
      rentalItemId: map['rentalItemId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      rentalStartDate: map['rentalStartDate'] != null
          ? DateTime.tryParse(map['rentalStartDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      returnDate: map['returnDate'] != null
          ? DateTime.tryParse(map['returnDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      rentalAmount: (map['rentalAmount'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (map['depositAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      depositReturned: (map['depositReturned'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      status: RentalStatus.fromString(map['status'] as String?),
      beforeRentalPhotoUrls:
          List<String>.from(map['beforeRentalPhotoUrls'] as List<dynamic>? ?? []),
      returnConditionPhotoUrls:
          List<String>.from(map['returnConditionPhotoUrls'] as List<dynamic>? ?? []),
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
