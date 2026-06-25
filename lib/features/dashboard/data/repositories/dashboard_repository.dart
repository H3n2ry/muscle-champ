import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../models/dashboard_model.dart';

final dashboardRepositoryProvider =
    Provider<DashboardRepository>((_) => DashboardRepository());

class DashboardRepository {
  Future<DashboardModel> getDashboard() async {
    final uid         = FB.uid;
    final today       = FB.today;
    final weekStart   = _weekStart();
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final results = await Future.wait([
      FB.db.collection('users').doc(uid).get(),
      FB.db.collection('workout_completions')
          .where('userId', isEqualTo: uid)
          .where('completedDate', isEqualTo: today)
          .limit(1)
          .get(),
      FB.db.collection('points')
          .where('userId', isEqualTo: uid)
          .where('reason', isEqualTo: 'diet_goal_met')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.parse(today)))
          .limit(1)
          .get(),
      FB.db.collection('workout_completions')
          .where('userId', isEqualTo: uid)
          .where('completedDate', isGreaterThanOrEqualTo: weekStart)
          .get(),
      FB.db.collection('points')
          .where('userId', isEqualTo: uid)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get(),
      FB.db
          .collection('users')
          .orderBy('totalPoints', descending: true)
          .limit(100)
          .get(),
    ]);

    final userDoc       = results[0] as DocumentSnapshot;
    final todayWorkouts = (results[1] as QuerySnapshot).docs;
    final dietPoints    = (results[2] as QuerySnapshot).docs;
    final weekWorkouts  = (results[3] as QuerySnapshot).docs;
    final histPoints    = (results[4] as QuerySnapshot).docs;
    final allUsers      = (results[5] as QuerySnapshot).docs;

    final userData = userDoc.data() as Map<String, dynamic>? ?? {};

    // Rank global
    int globalRank = 1;
    for (int i = 0; i < allUsers.length; i++) {
      if (allUsers[i].id == uid) {
        globalRank = i + 1;
        break;
      }
    }

    // Histórico de pontos agrupado por dia
    final Map<String, int> dayMap = {};
    for (final d in histPoints) {
      final data = d.data() as Map<String, dynamic>;
      final ts   = (data['createdAt'] as Timestamp?)?.toDate();
      if (ts == null) continue;
      final day = ts.toIso8601String().substring(0, 10);
      dayMap[day] = (dayMap[day] ?? 0) + (data['amount'] as int? ?? 0);
    }

    return DashboardModel(
      totalPoints:       userData['totalPoints'] as int? ?? 0,
      globalRank:        globalRank,
      friendsRank:       globalRank,
      workoutDoneToday:  todayWorkouts.isNotEmpty,
      dietGoalMetToday:  dietPoints.isNotEmpty,
      currentWeight:     (userData['currentWeight'] as num?)?.toDouble() ?? 0,
      targetWeight:      (userData['targetWeight']  as num?)?.toDouble() ?? 0,
      weeklyWorkouts:    weekWorkouts.length,
      weeklyWorkoutGoal: userData['weeklyWorkoutGoal'] as int? ?? 3,
      pointHistory: dayMap.entries
          .map((e) => PointHistoryEntry(date: e.key, points: e.value))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date)),
    );
  }

  String _weekStart() {
    final now = DateTime.now();
    return now
        .subtract(Duration(days: now.weekday - 1))
        .toIso8601String()
        .substring(0, 10);
  }
}
