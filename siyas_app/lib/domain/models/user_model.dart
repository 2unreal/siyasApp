enum UserRole {
  owner,
  manager,
  inactive;

  static UserRole fromString(String? role) {
    switch (role) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      default:
        return UserRole.inactive;
    }
  }

  String toRoleString() => name;
  bool get isOwner => this == UserRole.owner;
  bool get isManager => this == UserRole.manager;
}

class AppUser {
  final String userId;
  final String name;
  final String phone;
  final UserRole role;
  final bool isActive;
  final String businessId;
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  const AppUser({
    required this.userId,
    required this.name,
    required this.phone,
    required this.role,
    this.isActive = true,
    required this.businessId,
    required this.createdAt,
    this.lastActiveAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'role': role.toRoleString(),
      'isActive': isActive,
      'businessId': businessId,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      userId: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      isActive: map['isActive'] as bool? ?? true,
      businessId: map['businessId'] as String? ?? 'house_of_siyas',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastActiveAt: map['lastActiveAt'] != null
          ? DateTime.tryParse(map['lastActiveAt'] as String)
          : null,
    );
  }
}
