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

  // ── Ordem manual dos treinos ───────────────────────────────────────

  /// Persiste a ordem da lista. [ids] vem na sequência final desejada.
  ///
  /// A RPC filtra por `user_id`, então mandar o id de outro usuário
  /// simplesmente não afeta linha nenhuma.
  Future<void> reorderTemplates(List<String> ids) =>
      _client.rpc('reorder_workout_templates', params: {'p_ids': ids});

  /// Próximo índice livre, para o template novo entrar no fim.
  Future<int> _proximaOrdem() async {
    try {
      final r = await _client.rpc('next_template_order');
      return (r as num?)?.toInt() ?? 0;
    } catch (_) {
      // Falhar aqui não pode impedir a criação do treino: o template entra
      // com 0 e o usuário reordena se quiser.
      return 0;
    }
  }

  // ── Exercícios de um template ──────────────────────────────────────
  Future<List<TemplateExerciseModel>> getExercises(String templateId) async {
    final data = await _client
        .from('template_exercises')
        .select()
        .eq('template_id', templateId)
        // ⚠️ `ascending` é OBRIGATÓRIO aqui: ao contrário do SQL, o
        // postgrest-dart assume `ascending: false`. Sem isto os exercícios
        // saíam de trás para frente, e a ordem escolhida pelo usuário aparecia
        // invertida no card — parecia ordenação alfabética por coincidência.
        .order('order_index', ascending: true);
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

    // Entra no fim da lista. Sem isso o template novo cai com order_index 0 e
    // aparece no topo, misturado com o primeiro da ordem que o usuário montou.
    final proximaOrdem = await _proximaOrdem();

    final template = await _client
        .from('workout_templates')
        .insert({'user_id': userId, 'name': name, 'order_index': proximaOrdem})
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
    // Remove os registros dependentes antes do template. Isso evita erro de
    // foreign key caso as constraints no banco não tenham ON DELETE CASCADE —
    // que fazia a exclusão lançar exceção e quebrar a tela.
    await _client
        .from('template_exercises')
        .delete()
        .eq('template_id', templateId);
    await _client
        .from('workout_completions')
        .delete()
        .eq('template_id', templateId);
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
