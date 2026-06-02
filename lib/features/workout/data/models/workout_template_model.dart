class WorkoutTemplateModel {
  final String id;
  final String name;
  final bool doneToday;
  final int exerciseCount;
  final List<TemplateExerciseModel> exercises;

  const WorkoutTemplateModel({
    required this.id,
    required this.name,
    required this.doneToday,
    required this.exerciseCount,
    this.exercises = const [],
  });

  factory WorkoutTemplateModel.fromJson(Map<String, dynamic> j) =>
      WorkoutTemplateModel(
        id:            j['id'] as String,
        name:          j['name'] as String,
        doneToday:     j['done_today'] as bool? ?? false,
        exerciseCount: (j['exercise_count'] as num?)?.toInt() ?? 0,
      );

  WorkoutTemplateModel copyWith({
    String? name,
    bool? doneToday,
    List<TemplateExerciseModel>? exercises,
  }) =>
      WorkoutTemplateModel(
        id:            id,
        name:          name ?? this.name,
        doneToday:     doneToday ?? this.doneToday,
        exerciseCount: exercises?.length ?? exerciseCount,
        exercises:     exercises ?? this.exercises,
      );
}

class TemplateExerciseModel {
  final String id;
  final String templateId;
  final String name;
  final int sets;
  final int reps;
  final double weightKg;
  final int orderIndex;

  const TemplateExerciseModel({
    required this.id,
    required this.templateId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.orderIndex,
  });

  factory TemplateExerciseModel.fromJson(Map<String, dynamic> j) =>
      TemplateExerciseModel(
        id:          j['id'] as String,
        templateId:  j['template_id'] as String,
        name:        j['name'] as String,
        sets:        (j['sets'] as num).toInt(),
        reps:        (j['reps'] as num).toInt(),
        weightKg:    (j['weight_kg'] as num).toDouble(),
        orderIndex:  (j['order_index'] as num?)?.toInt() ?? 0,
      );

  TemplateExerciseModel copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weightKg,
  }) =>
      TemplateExerciseModel(
        id:         id,
        templateId: templateId,
        name:       name ?? this.name,
        sets:       sets ?? this.sets,
        reps:       reps ?? this.reps,
        weightKg:   weightKg ?? this.weightKg,
        orderIndex: orderIndex,
      );
}
