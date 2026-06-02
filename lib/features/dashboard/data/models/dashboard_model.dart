class DashboardModel {
  final int totalPoints;
  final int globalRank;
  final int friendsRank;
  final bool workoutDoneToday;
  final bool dietGoalMetToday;
  final double currentWeight;
  final double targetWeight;
  final int weeklyWorkouts;
  final int weeklyWorkoutGoal;
  final List<PointHistoryEntry> pointHistory;

  const DashboardModel({
    required this.totalPoints,
    required this.globalRank,
    required this.friendsRank,
    required this.workoutDoneToday,
    required this.dietGoalMetToday,
    required this.currentWeight,
    required this.targetWeight,
    required this.weeklyWorkouts,
    required this.weeklyWorkoutGoal,
    required this.pointHistory,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        totalPoints: (json['total_points'] as num).toInt(),
        globalRank: (json['global_rank'] as num).toInt(),
        friendsRank: (json['friends_rank'] as num).toInt(),
        workoutDoneToday: json['workout_done_today'] as bool,
        dietGoalMetToday: json['diet_goal_met_today'] as bool,
        currentWeight: (json['current_weight'] as num).toDouble(),
        targetWeight: (json['target_weight'] as num).toDouble(),
        weeklyWorkouts: (json['weekly_workouts'] as num).toInt(),
        weeklyWorkoutGoal: (json['weekly_workout_goal'] as num).toInt(),
        pointHistory: (json['point_history'] as List)
            .map((e) => PointHistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PointHistoryEntry {
  final String date;
  final int points;

  const PointHistoryEntry({required this.date, required this.points});

  factory PointHistoryEntry.fromJson(Map<String, dynamic> json) =>
      PointHistoryEntry(
        date: json['date'] as String,
        points: (json['points'] as num).toInt(),
      );
}
