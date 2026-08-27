enum UserRole { owner, rep }

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final int avatarIndex;
  final bool isActive;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatarIndex = 0,
    this.isActive = true,
    required this.createdAt,
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
    );
  }
}
