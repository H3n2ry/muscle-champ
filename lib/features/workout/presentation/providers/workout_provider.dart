import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/workout_model.dart';
import '../../data/repositories/workout_repository.dart';

final workoutsProvider =
    FutureProvider.autoDispose<List<WorkoutModel>>((ref) {
  return ref.watch(workoutRepositoryProvider).getWorkouts();
});

final workoutControllerProvider =
    AsyncNotifierProvider.autoDispose<WorkoutController, List<WorkoutModel>>(
        WorkoutController.new);

class WorkoutController extends AutoDisposeAsyncNotifier<List<WorkoutModel>> {
  @override
  Future<List<WorkoutModel>> build() {
    return ref.watch(workoutRepositoryProvider).getWorkouts();
  }

  Future<void> createWorkout({
    required List<Map<String, dynamic>> exercises,
    String? notes,
  }) async {
    final repo = ref.read(workoutRepositoryProvider);
    final newWorkout = await repo.createWorkout(
      exercises: exercises,
      notes: notes,
    );
    state = AsyncData([newWorkout, ...?state.valueOrNull]);
  }

  Future<void> completeWorkout(String workoutId) async {
    final updated = await ref
        .read(workoutRepositoryProvider)
        .completeWorkout(workoutId);
    state = AsyncData(
      state.valueOrNull
              ?.map((w) => w.id == workoutId ? updated : w)
              .toList() ??
          [updated],
    );
  }
}
