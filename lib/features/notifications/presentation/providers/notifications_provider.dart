import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../ranking/data/repositories/ranking_repository.dart';

// ── Lista de solicitações (com Realtime) ──────────────────────────────────────

final pendingRequestsProvider =
    StreamProvider.autoDispose<List<FriendRequestModel>>((ref) {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser!.id;
  final repo    = ref.watch(rankingRepositoryProvider);

  final controller = StreamController<List<FriendRequestModel>>();

  // Busca inicial
  repo.getPendingRequests().then((list) {
    if (!controller.isClosed) controller.add(list);
  });

  // Escuta Realtime: qualquer mudança na tabela friendships onde friend_id = eu
  final channel = client
      .channel('pending_requests_$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'friendships',
        callback: (payload) async {
          final list = await repo.getPendingRequests();
          if (!controller.isClosed) controller.add(list);
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

// ── Contagem de solicitações (com Realtime) ───────────────────────────────────

final pendingRequestsCountProvider =
    StreamProvider.autoDispose<int>((ref) {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser!.id;
  final repo    = ref.watch(rankingRepositoryProvider);

  final controller = StreamController<int>();

  // Busca inicial
  repo.getPendingRequestsCount().then((count) {
    if (!controller.isClosed) controller.add(count);
  });

  // Escuta Realtime: qualquer mudança em friendships
  final channel = client
      .channel('pending_count_$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'friendships',
        callback: (payload) async {
          final count = await repo.getPendingRequestsCount();
          if (!controller.isClosed) controller.add(count);
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});
