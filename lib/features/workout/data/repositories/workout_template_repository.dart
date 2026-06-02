import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_template_model.dart';

final workoutTemplateRepositoryProvider =
    Provider<WorkoutTemplateRepository>((_) => WorkoutTemplateRepository());

class WorkoutTemplateRepository {
  final _client = Supabase.instance.client;

  // ── Listar templates com status de hoje ────────────────────────────
  Future<List<WorkoutTemplateModel>> getTemplates() async {
    final userId = _client.auth.currentUser!.id;
    final data = await _client.rpc('get_workout_templates',
        params: {'p_user_id': userId});
    return (data as List)
        .map((e) => WorkoutTemplateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Exercícios de um template ──────────────────────────────────────
  Future<List<TemplateExerciseModel>> getExercises(String templateId) async {
    final data = await _client
        .from('template_exercises')
        .select()
        .eq('template_id', templateId)
        .order('order_index');
    return (data as List)
        .map((e) => TemplateExerciseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Criar template ─────────────────────────────────────────────────
  Future<WorkoutTemplateModel> createTemplate({
    required String name,
    required List<Map<String, dynamic>> exercises,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final template = await _client
        .from('workout_templates')
        .insert({'user_id': userId, 'name': name})
        .select()
        .single();

    final templateId = template['id'] as String;

    if (exercises.isNotEmpty) {
      await _client.from('template_exercises').insert(
        exercises.asMap().entries.map((entry) => {
          'template_id': templateId,
          'name':        entry.value['name'] as String,
          'sets':        entry.value['sets'] as int,
          'reps':        entry.value['reps'] as int,
          'weight_kg':   entry.value['weight_kg'] as double,
          'order_index': entry.key,
        }).toList(),
      );
    }

    return WorkoutTemplateModel(
      id:            templateId,
      name:          name,
      doneToday:     false,
      exerciseCount: exercises.length,
    );
  }

  // ── Editar nome do template ────────────────────────────────────────
  Future<void> updateTemplateName(String templateId, String name) async {
    await _client
        .from('workout_templates')
        .update({'name': name})
        .eq('id', templateId);
  }

  // ── Atualizar exercícios do template (substitui todos) ─────────────
  Future<void> updateExercises(
    String templateId,
    List<Map<String, dynamic>> exercises,
  ) async {
    await _client
        .from('template_exercises')
        .delete()
        .eq('template_id', templateId);

    if (exercises.isNotEmpty) {
      await _client.from('template_exercises').insert(
        exercises.asMap().entries.map((entry) => {
          'template_id': templateId,
          'name':        entry.value['name'] as String,
          'sets':        entry.value['sets'] as int,
          'reps':        entry.value['reps'] as int,
          'weight_kg':   entry.value['weight_kg'] as double,
          'order_index': entry.key,
        }).toList(),
      );
    }
  }

  // ── Deletar template ───────────────────────────────────────────────
  Future<void> deleteTemplate(String templateId) async {
    await _client
        .from('workout_templates')
        .delete()
        .eq('id', templateId);
  }

  // ── Concluir treino do dia ─────────────────────────────────────────
  Future<Map<String, dynamic>> completeTemplate({
    required String templateId,
    required List<TemplateExerciseModel> exercises,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final exercisesJson = exercises.map((e) => {
      'id':        e.id,
      'weight_kg': e.weightKg,
      'sets':      e.sets,
      'reps':      e.reps,
    }).toList();

    final result = await _client.rpc('complete_workout_template', params: {
      'p_user_id':     userId,
      'p_template_id': templateId,
      'p_exercises':   exercisesJson,
    });

    return result as Map<String, dynamic>;
  }
}
