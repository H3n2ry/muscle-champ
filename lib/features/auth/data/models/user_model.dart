class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int totalPoints;
  final String? goalType; // 'lose_weight' | 'gain_weight' | 'maintain'
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.totalPoints,
    this.goalType,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatar_url'] as String?,
        totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
        goalType: json['goal_type'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'total_points': totalPoints,
        'goal_type': goalType,
        'created_at': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    int? totalPoints,
    String? goalType,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        totalPoints: totalPoints ?? this.totalPoints,
        goalType: goalType ?? this.goalType,
        createdAt: createdAt,
      );
}
