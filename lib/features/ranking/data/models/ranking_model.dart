class RankingEntryModel {
  final int position;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int points;
  final bool isCurrentUser;
  final bool isFriend;

  const RankingEntryModel({
    required this.position,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.points,
    required this.isCurrentUser,
    required this.isFriend,
  });

  factory RankingEntryModel.fromJson(Map<String, dynamic> json) =>
      RankingEntryModel(
        // RPC retorna 'rank_position' e 'total_points'
        position:      (json['rank_position'] as num).toInt(),
        userId:        json['user_id'] as String,
        userName:      json['user_name'] as String,
        avatarUrl:     json['avatar_url'] as String?,
        points:        (json['total_points'] as num).toInt(),
        isCurrentUser: json['is_current_user'] as bool? ?? false,
        isFriend:      json['is_friend'] as bool? ?? false,
      );
}
