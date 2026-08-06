/// A locally saved sales-rep profile.
///
/// This is intentionally lightweight — no password, no server call — it's a
/// device-level "who is using this tablet right now" switcher, similar to
/// profile switching on a shared family device. Wire [creditLimit]-style
/// server auth later if the business needs real accounts; this model only
/// tracks what the UI needs to greet the rep and remember their device.
class RepProfileModel {
  final String id;
  final String name;

  /// Index into the shared avatar preset list (see RepAvatarPicker.presets).
  final int avatarIndex;

  final DateTime createdAt;
  final DateTime lastLoginAt;

  const RepProfileModel({
    required this.id,
    required this.name,
    required this.avatarIndex,
    required this.createdAt,
    required this.lastLoginAt,
  });

  RepProfileModel copyWith({DateTime? lastLoginAt}) {
    return RepProfileModel(
      id: id,
      name: name,
      avatarIndex: avatarIndex,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarIndex': avatarIndex,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt.toIso8601String(),
      };

  factory RepProfileModel.fromJson(Map<String, dynamic> json) {
    return RepProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarIndex: json['avatarIndex'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
    );
  }
}
