import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../models/workout_template_model.dart';

final workoutTemplateRepositoryProvider =
    Provider<WorkoutTemplateRepository>((_) => WorkoutTemplateRepository());

class WorkoutTemplateRepository {
  // ── Listar templates com status de hoje ────────────────────────────
  Future<List<WorkoutTemplateModel>> getTemplates() async {
    final uid   = FB.uid;
    final today = FB.today;

    final results = await Future.wait([
      FB.db
          .collection('workout_templates')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt')
          .get(),
      FB.db
          .collection('workout_completions')
          .where('userId', isEqualTo: uid)
          .where('completedDate', isEqualTo: today)
          .get(),
    ]);

    final templatesSnap  = results[0] as QuerySnapshot;
    final completionsSnap = results[1] as QuerySnapshot;

    final doneTodayIds = completionsSnap.docs
        .map((d) => (d.data() as Map<String, dynamic>)['templateId'] as String)
        .toSet();

    return templatesSnap.docs.map((doc) {
      final data      = doc.data() as Map<String, dynamic>;
      final exercises = data['exercises'] as List? ?? [];
      return WorkoutTemplateModel(
        id:            doc.id,
        name:          data['name'] as String,
        doneToday:     doneTodayIds.contains(doc.id),
        exerciseCount: exercises.length,
      );
    }).toList();
  }

  // ── Exercícios de um template ──────────────────────────────────────
  Future<List<TemplateExerciseModel>> getExercises(String templateId) async {
    final doc       = await FB.db.collection('workout_templates').doc(templateId).get();
    final exercises = (doc.data()?['exercises'] as List? ?? []);
    return exercises.asMap().entries.map((e) {
      final ex = e.value as Map<String, dynamic>;
      return TemplateExerciseModel(
        id:          ex['id'] as String? ?? e.key.toString(),
        templateId:  templateId,
        name:        ex['name'] as String,
        sets:        (ex['sets'] as num).toInt(),
        reps:        (ex['reps'] as num).toInt(),
        weightKg:    (ex['weightKg'] as num?)?.toDouble() ?? 0,
        orderIndex:  (ex['orderIndex'] as num?)?.toInt() ?? e.key,
      );
    }).toList();
  }

  // ── Criar template ─────────────────────────────────────────────────
  Future<WorkoutTemplateModel> createTemplate({
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final uid = FB.uid;
    final exercisesWithId = exercises.asMap().entries.map((e) => {
          'id':         FB.db.collection('_').doc().id,
          'name':       e.value['name'] as String,
          'sets':       e.value['sets'] as int,
          'reps':       e.value['reps'] as int,
          'weightKg':   (e.value['weight_kg'] as num?)?.toDouble() ?? 0.0,
          'orderIndex': e.key,
        }).toList();

    final ref = await FB.db.collection('workout_templates').add({
      'userId':    uid,
      'name':      name,
      'exercises': exercisesWithId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return WorkoutTemplateModel(
      id:            ref.id,
      name:          name,
      doneToday:     false,
      exerciseCount: exercises.length,
    );
  }

  // ── Editar nome do template ────────────────────────────────────────
  Future<void> updateTemplateName(String templateId, String name) async {
    await FB.db
        .collection('workout_templates')
        .doc(templateId)
        .update({'name': name});
  }

  // ── Atualizar exercícios do template (substitui todos) ─────────────
  Future<void> updateExercises(
    String templateId,
    List<Map<String, dynamic>> exercises,
  ) async {
    final exercisesWithId = exercises.asMap().entries.map((e) => {
          'id':         e.value['id'] as String? ?? FB.db.collection('_').doc().id,
          'name':       e.value['name'] as String,
          'sets':       e.value['sets'] as int,
          'reps':       e.value['reps'] as int,
          'weightKg':   (e.value['weight_kg'] as num?)?.toDouble() ?? 0.0,
          'orderIndex': e.key,
        }).toList();
    await FB.db
        .collection('workout_templates')
        .doc(templateId)
        .update({'exercises': exercisesWithId});
  }

  // ── Deletar template ───────────────────────────────────────────────
  Future<void> deleteTemplate(String templateId) async {
    await FB.db.collection('workout_templates').doc(templateId).delete();
  }

  // ── Concluir treino do dia ─────────────────────────────────────────
  Future<Map<String, dynamic>> completeTemplate({
    required String templateId,
    required List<TemplateExerciseModel> exercises,
  }) async {
    final uid          = FB.uid;
    final today        = FB.today;
    final completionId = '${templateId}_${uid}_$today';

    // Verificar se já feito hoje
    final existing = await FB.db
        .collection('workout_completions')
        .doc(completionId)
        .get();
    if (existing.exists) {
      return {'already_done': true, 'progression': 0};
    }

    // Buscar pesos anteriores do template
    final templateDoc   = await FB.db.collection('workout_templates').doc(templateId).get();
    final prevExercises = (templateDoc.data()?['exercises'] as List? ?? []);
    final Map<String, double> prevWeights = {};
    for (final ex in prevExercises) {
      final exMap = ex as Map<String, dynamic>;
      prevWeights[exMap['id'] as String] =
          (exMap['weightKg'] as num?)?.toDouble() ?? 0;
    }

    // Detectar progressão e preparar exercícios atualizados
    int progression = 0;
    final updatedExercises = exercises.map((ex) {
      final prev = prevWeights[ex.id] ?? 0;
      if (ex.weightKg > prev) progression++;
      return {
        'id':         ex.id,
        'name':       ex.name,
        'sets':       ex.sets,
        'reps':       ex.reps,
        'weightKg':   ex.weightKg,
        'orderIndex': ex.orderIndex,
      };
    }).toList();

    // Salvar completion
    await FB.db.collection('workout_completions').doc(completionId).set({
      'userId':        uid,
      'templateId':    templateId,
      'completedDate': today,
      'progression':   progression,
      'createdAt':     FieldValue.serverTimestamp(),
    });

    // Atualizar pesos no template
    await FB.db
        .collection('workout_templates')
        .doc(templateId)
        .update({'exercises': updatedExercises});

    // Pontos: +10 por treino
    int totalPoints = 10;
    await FB.db.collection('points').add({
      'userId':      uid,
      'amount':      10,
      'reason':      'workout_completed',
      'referenceId': templateId,
      'createdAt':   FieldValue.serverTimestamp(),
    });

    // Pontos: +5 por exercício com progressão
    if (progression > 0) {
      final progressionPts = progression * 5;
      totalPoints += progressionPts;
      await FB.db.collection('points').add({
        'userId':    uid,
        'amount':    progressionPts,
        'reason':    'load_progression',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Atualizar totalPoints no usuário com transaction
    await FB.db.runTransaction((tx) async {
      final userRef = FB.db.collection('users').doc(uid);
      final userDoc = await tx.get(userRef);
      final current = userDoc.data()?['totalPoints'] as int? ?? 0;
      tx.update(userRef, {'totalPoints': current + totalPoints});
    });

    return {'already_done': false, 'progression': progression};
  }
}
