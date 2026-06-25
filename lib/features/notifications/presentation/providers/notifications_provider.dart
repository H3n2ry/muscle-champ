import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ranking/data/repositories/ranking_repository.dart';
import '../../../../core/firebase/firebase_service.dart';

// ── Lista de solicitações (com Realtime via Firestore snapshots) ──────────────

final pendingRequestsProvider =
    StreamProvider.autoDispose<List<FriendRequestModel>>((ref) {
  final uid = FB.auth.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  final repo = ref.watch(rankingRepositoryProvider);

  return FB.db
      .collection('friendships')
      .where('friendId', isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .asyncMap((_) => repo.getPendingRequests());
});

// ── Contagem de solicitações (com Realtime via Firestore snapshots) ───────────

final pendingRequestsCountProvider =
    StreamProvider.autoDispose<int>((ref) {
  final uid = FB.auth.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FB.db
      .collection('friendships')
      .where('friendId', isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((snap) => snap.docs.length);
});
