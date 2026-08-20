import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/diet_model.dart';

final dietRepositoryProvider =
    Provider<DietRepository>((_) => DietRepository());

class DietRepository {
  final _client = Supabase.instance.client;

  Future<DietSummaryModel> getTodaySummary() async {
    final userId = _client.auth.currentUser!.id;
    final today  = DateTime.now().toIso8601String().substring(0, 10);

    final results = await Future.wait([
      _client
          .from('diet_logs')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          // Direção explícita: o postgrest-dart assume `ascending: false`,
          // então isto sempre foi decrescente — refeição mais recente no topo.
          // Mantido como está para não mudar o comportamento; o ponto é que
          // agora está escrito, e não dependendo de um padrão surpreendente.
          .order('created_at', ascending: false),
      _client
          .from('goals')
          .select('daily_calories, goal_type')
          .eq('user_id', userId)
          .maybeSingle(),
      // Check if diet goal already awarded today
      _client
          .from('points')
          .select('id')
          .eq('user_id', userId)
          .eq('reason', 'diet_goal_met')
          .gte('created_at', today),
    ]);

    final meals        = results[0] as List;
    final goal         = results[1] as Map<String, dynamic>?;
    final goalCalories = (goal?['daily_calories'] as int?) ?? 2000;
    final goalType     = goal?['goal_type'] as String?;

    final totals = meals.fold(
      (calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0),
      (acc, m) => (
        calories: acc.calories + (m['calories'] as int),
        protein:  acc.protein  + (m['protein']  as num).toDouble(),
        carbs:    acc.carbs    + (m['carbs']    as num).toDouble(),
        fat:      acc.fat      + (m['fat']      as num).toDouble(),
      ),
    );

    final goalMet = totals.calories >= goalCalories * 0.9 &&
                    totals.calories <= goalCalories * 1.1;

    return DietSummaryModel(
      totalCalories: totals.calories,
      goalCalories:  goalCalories,
      goalType:      goalType,
      totalProtein:  totals.protein,
      totalCarbs:    totals.carbs,
      totalFat:      totals.fat,
      goalMet:       goalMet,
      meals: meals
          .map((e) => DietLogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<DietLogModel> addMeal(Map<String, dynamic> data) async {
    final userId = _client.auth.currentUser!.id;
    final today  = DateTime.now().toIso8601String().substring(0, 10);

    final inserted = await _client
        .from('diet_logs')
        .insert({...data, 'user_id': userId, 'date': today})
        .select()
        .single();

    return DietLogModel.fromJson(inserted);
  }

  Future<void> deleteMeal(String mealId) async {
    await _client.from('diet_logs').delete().eq('id', mealId);
  }
}
