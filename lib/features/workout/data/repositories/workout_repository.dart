import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../models/workout_model.dart';

final workoutRepositoryProvider =
    Provider<WorkoutRepository>((_) => WorkoutRepository());

class WorkoutRepository {
  Future<List<WorkoutModel>> getWorkouts() async {
    final uid  = FB.uid;
    final snap = await FB.db
        .collection('workouts')
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(30)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return WorkoutModel.fromJson({...data, 'id': d.id});
    }).toList();
  }

  Future<WorkoutModel> createWorkout({
    required List<Map<String, dynamic>> exercises,
    String? notes,
  }) async {
    final uid   = FB.uid;
    final today = FB.today;

    final ref = await FB.db.collection('workouts').add({
      'userId':    uid,
      'date':      today,
      'notes':     notes,
      'completed': false,
      'exercises': exercises,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await ref.get();
    return WorkoutModel.fromJson({...doc.data()!, 'id': ref.id});
  }

  Future<WorkoutModel> completeWorkout(String workoutId) async {
    await FB.db
        .collection('workouts')
        .doc(workoutId)
        .update({'completed': true});
    final doc = await FB.db.collection('workouts').doc(workoutId).get();
    return WorkoutModel.fromJson({...doc.data()!, 'id': workoutId});
  }
}
