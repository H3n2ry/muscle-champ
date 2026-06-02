import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ranking_model.dart';

final rankingRepositoryProvider =
    Provider<RankingRepository>((_) => RankingRepository());

class RankingRepository {
  final _client = Supabase.instance.client;

  Future<List<RankingEntryModel>> getGlobalRanking() async {
    final userId = _client.auth.currentUser!.id;
    final data   = await _client.rpc('get_global_ranking',
        params: {'p_user_id': userId});
    return (data as List)
        .map((e) => RankingEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RankingEntryModel>> getFriendsRanking() async {
    final userId = _client.auth.currentUser!.id;
    final data   = await _client.rpc('get_friends_ranking',
        params: {'p_user_id': userId});
    return (data as List)
        .map((e) => RankingEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Busca usuários por nome para adicionar como amigo.
  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final userId = _client.auth.currentUser!.id;
    final data   = await _client.rpc('search_users', params: {
      'p_query':            query.trim(),
      'p_current_user_id':  userId,
    });
    return (data as List)
        .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendFriendRequest(String friendId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('friendships').upsert({
      'user_id':   userId,
      'friend_id': friendId,
      'status':    'pending',
    }, onConflict: 'user_id, friend_id');
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _client
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', requestId);
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await _client
        .from('friendships')
        .delete()
        .eq('id', requestId);
  }

  Future<void> removeFriend(String friendId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('friendships').delete().match({
      'user_id':   userId,
      'friend_id': friendId,
    });
    await _client.from('friendships').delete().match({
      'user_id':   friendId,
      'friend_id': userId,
    });
  }

  Future<List<FriendRequestModel>> getPendingRequests() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client.rpc('get_pending_requests',
        params: {'p_user_id': userId});
    return (data as List)
        .map((e) => FriendRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getPendingRequestsCount() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client.rpc('get_pending_requests_count',
        params: {'p_user_id': userId});
    return (data as int?) ?? 0;
  }
}

// ── User search result model ───────────────────────────────────────────────────

class UserSearchResult {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int totalPoints;
  final bool isFriend;
  final bool isPending;
  final String? requestId;

  const UserSearchResult({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.totalPoints,
    required this.isFriend,
    required this.isPending,
    this.requestId,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> j) =>
      UserSearchResult(
        userId:      j['user_id'] as String,
        userName:    j['user_name'] as String,
        avatarUrl:   j['avatar_url'] as String?,
        totalPoints: (j['total_points'] as num?)?.toInt() ?? 0,
        isFriend:    j['is_friend'] as bool? ?? false,
        isPending:   j['is_pending'] as bool? ?? false,
        requestId:   j['request_id'] as String?,
      );
}

// ── Friend Request model ──────────────────────────────────────────────────────

class FriendRequestModel {
  final String requestId;
  final String requesterId;
  final String requesterName;
  final String? requesterAvatar;
  final int requesterPoints;
  final DateTime createdAt;

  const FriendRequestModel({
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatar,
    required this.requesterPoints,
    required this.createdAt,
  });

  factory FriendRequestModel.fromJson(Map<String, dynamic> j) =>
      FriendRequestModel(
        requestId:       j['request_id'] as String,
        requesterId:     j['requester_id'] as String,
        requesterName:   j['requester_name'] as String,
        requesterAvatar: j['requester_avatar'] as String?,
        requesterPoints: (j['requester_points'] as num?)?.toInt() ?? 0,
        createdAt:       DateTime.parse(j['created_at'] as String),
      );
}
