enum UserRole { owner, rep }

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final int avatarIndex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatarIndex = 0,
    this.isActive = true,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      role: (json['role'] as String) == 'owner' ? UserRole.owner : UserRole.rep,
      avatarIndex: (json['avatar_index'] as int?) ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLoginAt: DateTime.parse(json['last_login_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role == UserRole.owner ? 'owner' : 'rep',
      'avatar_index': avatarIndex,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? phone,
    UserRole? role,
    int? avatarIndex,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
