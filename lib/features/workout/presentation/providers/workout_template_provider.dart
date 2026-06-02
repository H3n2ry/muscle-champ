import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/workout_template_model.dart';
import '../../data/repositories/workout_template_repository.dart';

final workoutTemplatesProvider =
    FutureProvider.autoDispose<List<WorkoutTemplateModel>>((ref) {
  return ref.watch(workoutTemplateRepositoryProvider).getTemplates();
});

final templateExercisesProvider = FutureProvider.autoDispose
    .family<List<TemplateExerciseModel>, String>((ref, templateId) {
  return ref
      .watch(workoutTemplateRepositoryProvider)
      .getExercises(templateId);
});
