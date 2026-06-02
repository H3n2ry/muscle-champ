import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ranking_model.dart';
import '../../data/repositories/ranking_repository.dart';

final globalRankingProvider =
    FutureProvider.autoDispose<List<RankingEntryModel>>((ref) {
  return ref.watch(rankingRepositoryProvider).getGlobalRanking();
});

final friendsRankingProvider =
    FutureProvider.autoDispose<List<RankingEntryModel>>((ref) {
  return ref.watch(rankingRepositoryProvider).getFriendsRanking();
});
