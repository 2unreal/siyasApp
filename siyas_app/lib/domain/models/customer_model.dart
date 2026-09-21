class Customer {
  final String id;
  final String customerId; // e.g. "CUS-0001"
  final String name;
  final String? mobile;
  final String? whatsappMobile;
  final bool whatsappSameAsMobile;
  final String? address;
  final String? generalNote;
  final String? photoUrl;
  final String status; // 'active' | 'archived'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  const Customer({
    required this.id,
    required this.customerId,
    required this.name,
    this.mobile,
    this.whatsappMobile,
    this.whatsappSameAsMobile = true,
    this.address,
    this.generalNote,
    this.photoUrl,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  bool get isArchived => status == 'archived';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'name': name,
      'mobile': mobile,
      'whatsappMobile': whatsappMobile,
      'whatsappSameAsMobile': whatsappSameAsMobile,
      'address': address,
      'generalNote': generalNote,
      'photoUrl': photoUrl,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map, String id) {
    return Customer(
      id: id,
      customerId: map['customerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      mobile: map['mobile'] as String?,
      whatsappMobile: map['whatsappMobile'] as String?,
      whatsappSameAsMobile: map['whatsappSameAsMobile'] as bool? ?? true,
      address: map['address'] as String?,
      generalNote: map['generalNote'] as String?,
      photoUrl: map['photoUrl'] as String?,
      status: map['status'] as String? ?? 'active',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
      updatedBy: map['updatedBy'] as String? ?? '',
    );
  }
}
