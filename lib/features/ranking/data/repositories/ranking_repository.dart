import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../models/ranking_model.dart';

final rankingRepositoryProvider =
    Provider<RankingRepository>((_) => RankingRepository());

class RankingRepository {
  Future<List<RankingEntryModel>> getGlobalRanking() async {
    final uid  = FB.uid;
    final snap = await FB.db
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .limit(100)
        .get();

    final friendUids = await _getFriendUids();

    return snap.docs.asMap().entries.map((e) {
      final data = e.value.data();
      return RankingEntryModel(
        position:      e.key + 1,
        userId:        e.value.id,
        userName:      data['name'] as String? ?? '',
        avatarUrl:     data['avatarUrl'] as String?,
        points:        data['totalPoints'] as int? ?? 0,
        isCurrentUser: e.value.id == uid,
        isFriend:      friendUids.contains(e.value.id),
      );
    }).toList();
  }

  Future<List<RankingEntryModel>> getFriendsRanking() async {
    final uid     = FB.uid;
    final friends = await _getFriendUids();
    final allUids = [...friends, uid];

    if (allUids.length == 1) {
      final doc  = await FB.db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      return [
        RankingEntryModel(
          position:      1,
          userId:        uid,
          userName:      data['name'] as String? ?? '',
          avatarUrl:     data['avatarUrl'] as String?,
          points:        data['totalPoints'] as int? ?? 0,
          isCurrentUser: true,
          isFriend:      false,
        )
      ];
    }

    final snaps = await Future.wait(
      allUids.map((id) => FB.db.collection('users').doc(id).get()),
    );

    final entries = snaps.where((d) => d.exists).map((d) {
      final data = d.data()!;
      return RankingEntryModel(
        position:      0, // será preenchido abaixo
        userId:        d.id,
        userName:      data['name'] as String? ?? '',
        avatarUrl:     data['avatarUrl'] as String?,
        points:        data['totalPoints'] as int? ?? 0,
        isCurrentUser: d.id == uid,
        isFriend:      friends.contains(d.id),
      );
    }).toList()
      ..sort((a, b) => b.points.compareTo(a.points));

    // Reindexar posições
    final indexed = <RankingEntryModel>[];
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      indexed.add(RankingEntryModel(
        position:      i + 1,
        userId:        e.userId,
        userName:      e.userName,
        avatarUrl:     e.avatarUrl,
        points:        e.points,
        isCurrentUser: e.isCurrentUser,
        isFriend:      e.isFriend,
      ));
    }
    return indexed;
  }

  /// Busca usuários por nome para adicionar como amigo.
  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final uid = FB.uid;
    final q   = query.trim().toLowerCase();

    final snap = await FB.db
        .collection('users')
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThan: '${q}z')
        .limit(20)
        .get();

    final friendUids  = await _getFriendUids();
    final pendingUids = await _getPendingUids();

    return snap.docs.where((d) => d.id != uid).map((d) {
      final data = d.data();
      return UserSearchResult(
        userId:      d.id,
        userName:    data['name'] as String? ?? '',
        avatarUrl:   data['avatarUrl'] as String?,
        totalPoints: data['totalPoints'] as int? ?? 0,
        isFriend:    friendUids.contains(d.id),
        isPending:   pendingUids.containsKey(d.id),
        requestId:   pendingUids[d.id],
      );
    }).toList();
  }

  Future<Set<String>> _getFriendUids() async {
    final uid = FB.uid;
    final results = await Future.wait([
      FB.db
          .collection('friendships')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .get(),
      FB.db
          .collection('friendships')
          .where('friendId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .get(),
    ]);
    return {
      ...(results[0] as QuerySnapshot)
          .docs
          .map((d) => (d.data() as Map<String, dynamic>)['friendId'] as String),
      ...(results[1] as QuerySnapshot)
          .docs
          .map((d) => (d.data() as Map<String, dynamic>)['userId'] as String),
    };
  }

  Future<Map<String, String>> _getPendingUids() async {
    final uid  = FB.uid;
    final snap = await FB.db
        .collection('friendships')
        .where('userId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();
    return {
      for (final d in snap.docs)
        (d.data() as Map<String, dynamic>)['friendId'] as String: d.id
    };
  }

  Future<void> sendFriendRequest(String friendId) async {
    final uid = FB.uid;
    await FB.db.collection('friendships').add({
      'userId':    uid,
      'friendId':  friendId,
      'status':    'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await FB.db
        .collection('friendships')
        .doc(requestId)
        .update({'status': 'accepted'});
  }

  Future<void> rejectFriendRequest(String requestId) async {
    await FB.db.collection('friendships').doc(requestId).delete();
  }

  Future<void> removeFriend(String friendId) async {
    final uid = FB.uid;
    final results = await Future.wait([
      FB.db
          .collection('friendships')
          .where('userId', isEqualTo: uid)
          .where('friendId', isEqualTo: friendId)
          .get(),
      FB.db
          .collection('friendships')
          .where('userId', isEqualTo: friendId)
          .where('friendId', isEqualTo: uid)
          .get(),
    ]);
    final batch = FB.db.batch();
    for (final snap in results) {
      for (final d in (snap as QuerySnapshot).docs) {
        batch.delete(d.reference);
      }
    }
    await batch.commit();
  }

  Future<List<FriendRequestModel>> getPendingRequests() async {
    final uid  = FB.uid;
    final snap = await FB.db
        .collection('friendships')
        .where('friendId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return Future.wait(snap.docs.map((d) async {
      final data        = d.data() as Map<String, dynamic>;
      final requesterId = data['userId'] as String;
      final userDoc     = await FB.db.collection('users').doc(requesterId).get();
      final userData    = userDoc.data() ?? {};
      return FriendRequestModel(
        requestId:       d.id,
        requesterId:     requesterId,
        requesterName:   userData['name'] as String? ?? '',
        requesterAvatar: userData['avatarUrl'] as String?,
        requesterPoints: userData['totalPoints'] as int? ?? 0,
        createdAt:       (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }));
  }

  Future<int> getPendingRequestsCount() async {
    final uid  = FB.uid;
    final snap = await FB.db
        .collection('friendships')
        .where('friendId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs.length;
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
        userId:      j['user_id']     as String,
        userName:    j['user_name']   as String,
        avatarUrl:   j['avatar_url']  as String?,
        totalPoints: (j['total_points'] as num?)?.toInt() ?? 0,
        isFriend:    j['is_friend']   as bool? ?? false,
        isPending:   j['is_pending']  as bool? ?? false,
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
        requestId:       j['request_id']    as String,
        requesterId:     j['requester_id']  as String,
        requesterName:   j['requester_name'] as String,
        requesterAvatar: j['requester_avatar'] as String?,
        requesterPoints: (j['requester_points'] as num?)?.toInt() ?? 0,
        createdAt:       DateTime.parse(j['created_at'] as String),
      );
}
