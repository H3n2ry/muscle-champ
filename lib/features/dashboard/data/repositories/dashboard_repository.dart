import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dashboard_model.dart';

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((_) => DashboardRepository());

class DashboardRepository {
  final _client = Supabase.instance.client;

  Future<DashboardModel> getDashboard() async {
    final userId = _client.auth.currentUser!.id;
    final today  = DateTime.now().toIso8601String().substring(0, 10);
    final weekStart = _weekStart();
    final sevenDaysAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String();

    // Queries individuais — mais fácil de depurar e resilientes a dados ausentes
    final pointsData = await _safe(
      _client.from('points').select('amount').eq('user_id', userId),
      defaultValue: [],
    );

    final todayWorkout = await _safe(
      _client.from('workouts').select('id')
          .eq('user_id', userId).eq('date', today).eq('completed', true),
      defaultValue: [],
    );

    final dietDoneToday = await _safe(
      _client.from('points').select('id')
          .eq('user_id', userId).eq('reason', 'diet_goal_met')
          .gte('created_at', today),
      defaultValue: [],
    );

    final goal = await _safe(
      _client.from('goals').select().eq('user_id', userId).maybeSingle(),
      defaultValue: null,
    );

    final weekWorkouts = await _safe(
      _client.from('workouts').select('id')
          .eq('user_id', userId).eq('completed', true)
          .gte('date', weekStart),
      defaultValue: [],
    );

    final history = await _safe(
      _client.from('points').select('amount, created_at')
          .eq('user_id', userId).gte('created_at', sevenDaysAgo),
      defaultValue: [],
    );

    // Ranking calculado localmente (evita falha de RPC)
    int globalRank = 1;
    int friendsRank = 1;
    try {
      final allPoints = await _client
          .from('points')
          .select('user_id, amount');
      final Map<String, int> totals = {};
      for (final p in allPoints as List) {
        final uid = p['user_id'] as String;
        totals[uid] = (totals[uid] ?? 0) + (p['amount'] as int);
      }
      final sorted = totals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final idx = sorted.indexWhere((e) => e.key == userId);
      globalRank = idx >= 0 ? idx + 1 : sorted.length + 1;
      friendsRank = globalRank;
    } catch (_) {}

    final totalPoints = (pointsData as List)
        .fold<int>(0, (s, p) => s + (p['amount'] as int));

    // Agrupar histórico por dia
    final Map<String, int> dayMap = {};
    for (final p in history as List) {
      final day = (p['created_at'] as String).substring(0, 10);
      dayMap[day] = (dayMap[day] ?? 0) + (p['amount'] as int);
    }

    final goalMap = goal as Map<String, dynamic>?;

    return DashboardModel(
      totalPoints:       totalPoints,
      globalRank:        globalRank,
      friendsRank:       friendsRank,
      workoutDoneToday:  (todayWorkout as List).isNotEmpty,
      dietGoalMetToday:  (dietDoneToday as List).isNotEmpty,
      currentWeight:     (goalMap?['current_weight'] as num?)?.toDouble() ?? 0,
      targetWeight:      (goalMap?['target_weight']  as num?)?.toDouble() ?? 0,
      weeklyWorkouts:    (weekWorkouts as List).length,
      weeklyWorkoutGoal: (goalMap?['weekly_workout_goal'] as int?) ?? 5,
      pointHistory: dayMap.entries
          .map((e) => PointHistoryEntry(date: e.key, points: e.value))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date)),
    );
  }

  Future<dynamic> _safe(Future<dynamic> query, {required dynamic defaultValue}) async {
    try {
      return await query;
    } catch (_) {
      return defaultValue;
    }
  }

  String _weekStart() {
    final now = DateTime.now();
    return now
        .subtract(Duration(days: now.weekday - 1))
        .toIso8601String()
        .substring(0, 10);
  }
}
