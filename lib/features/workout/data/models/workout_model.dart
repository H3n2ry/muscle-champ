class WorkoutModel {
  final String id;
  final String userId;
  final DateTime date;
  final bool completed;
  final String? notes;
  final List<ExerciseModel> exercises;

  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.completed,
    this.notes,
    required this.exercises,
  });

  factory WorkoutModel.fromJson(Map<String, dynamic> json) => WorkoutModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        date: DateTime.parse(json['date'] as String),
        completed: json['completed'] as bool,
        notes: json['notes'] as String?,
        exercises: (json['exercises'] as List? ?? [])
            .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'date': date.toIso8601String(),
        'completed': completed,
        'notes': notes,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };
}

class ExerciseModel {
  final String? id;
  final String name;
  final int sets;
  final int reps;
  final double weight;
  final double? previousWeight;

  const ExerciseModel({
    this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    this.previousWeight,
  });

  bool get hasProgression =>
      previousWeight != null && weight > previousWeight!;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) => ExerciseModel(
        id: json['id'] as String?,
        name: json['name'] as String,
        sets: (json['sets'] as num).toInt(),
        reps: (json['reps'] as num).toInt(),
        weight: (json['weight'] as num).toDouble(),
        previousWeight: (json['previous_weight'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
      };
}
