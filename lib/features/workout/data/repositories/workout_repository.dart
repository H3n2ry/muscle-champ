import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_model.dart';

final workoutRepositoryProvider =
    Provider<WorkoutRepository>((_) => WorkoutRepository());

class WorkoutRepository {
  final _client = Supabase.instance.client;

  Future<List<WorkoutModel>> getWorkouts() async {
    final userId = _client.auth.currentUser!.id;

    final data = await _client
        .from('workouts')
        .select('*, exercises(*)')
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(30);

    return (data as List)
        .map((e) => WorkoutModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutModel> createWorkout({
    required List<Map<String, dynamic>> exercises,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final today  = DateTime.now().toIso8601String().substring(0, 10);

    final workout = await _client
        .from('workouts')
        .insert({'user_id': userId, 'date': today, 'notes': notes})
        .select()
        .single();

    final workoutId = workout['id'] as String;
    final insertedExercises = <Map<String, dynamic>>[];

    for (final ex in exercises) {
      // Get previous weight for this exercise
      final prev = await _client
          .from('exercises')
          .select('weight, workouts!inner(date)')
          .eq('name', ex['name'] as String)
          .eq('workouts.user_id', userId)
          .order('workouts(date)', ascending: false)
          .limit(1)
          .maybeSingle();

      final prevWeight = (prev?['weight'] as num?)?.toDouble();

      final inserted = await _client
          .from('exercises')
          .insert({
            'workout_id':      workoutId,
            'name':            ex['name'],
            'sets':            ex['sets'] ?? 3,
            'reps':            ex['reps'] ?? 10,
            'weight':          ex['weight'] ?? 0,
            'previous_weight': prevWeight,
          })
          .select()
          .single();

      insertedExercises.add(inserted as Map<String, dynamic>);
    }

    return WorkoutModel.fromJson({
      ...workout as Map<String, dynamic>,
      'exercises': insertedExercises,
    });
  }

  Future<WorkoutModel> completeWorkout(String workoutId) async {
    final updated = await _client
        .from('workouts')
        .update({'completed': true})
        .eq('id', workoutId)
        .select('*, exercises(*)')
        .single();

    return WorkoutModel.fromJson(updated as Map<String, dynamic>);
  }
}
