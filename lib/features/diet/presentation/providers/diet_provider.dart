import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/diet_model.dart';
import '../../data/repositories/diet_repository.dart';
import '../../../../core/groq/groq_service.dart';

// ── Provider de resumo diário ─────────────────────────────────────────────────

final dietControllerProvider =
    AsyncNotifierProvider.autoDispose<DietController, DietSummaryModel?>(
        DietController.new);

class DietController extends AutoDisposeAsyncNotifier<DietSummaryModel?> {
  @override
  Future<DietSummaryModel?> build() {
    return ref.watch(dietRepositoryProvider).getTodaySummary();
  }

  Future<void> addMeal(Map<String, dynamic> data) async {
    await ref.read(dietRepositoryProvider).addMeal(data);
    final updated = await ref.read(dietRepositoryProvider).getTodaySummary();
    state = AsyncData(updated);
  }

  Future<void> deleteMeal(String mealId) async {
    await ref.read(dietRepositoryProvider).deleteMeal(mealId);
    final updated = await ref.read(dietRepositoryProvider).getTodaySummary();
    state = AsyncData(updated);
  }
}

// ── Provider do Plano IA ──────────────────────────────────────────────────────

class AiDietPlanState {
  final DietPlan? plan;
  final bool isLoading;
  final String? error;

  const AiDietPlanState({
    this.plan,
    this.isLoading = false,
    this.error,
  });
}

final aiDietPlanProvider =
    StateNotifierProvider.autoDispose<AiDietPlanNotifier, AiDietPlanState>(
        (_) => AiDietPlanNotifier());

class AiDietPlanNotifier extends StateNotifier<AiDietPlanState> {
  // Chave única por usuário — evita que contas diferentes compartilhem o plano
  static String _storageKey() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid != null ? 'ai_diet_plan_v1_$uid' : 'ai_diet_plan_v1';
  }

  AiDietPlanNotifier() : super(const AiDietPlanState()) {
    _loadFromStorage();
  }

  // ── Persistência ─────────────────────────────────────────────────────────

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey());
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final plan = DietPlan.fromJson(data, data['target_calories'] as int);
      if (mounted) state = AiDietPlanState(plan: plan);
    } catch (_) {
      // JSON inválido ou modelo desatualizado — ignora
    }
  }

  Future<void> _saveToStorage(DietPlan plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey(), jsonEncode(plan.toJson()));
    } catch (_) {}
  }

  Future<void> _clearStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey());
    } catch (_) {}
  }

  // ── Ações ─────────────────────────────────────────────────────────────────

  Future<void> generate(
    int calories,
    String goalType, {
    double? goalProtein,
    double? goalCarbs,
    double? goalFat,
  }) async {
    state = const AiDietPlanState(isLoading: true);
    try {
      final json = await GroqService.generateDietPlan(
        calories, goalType,
        goalProtein: goalProtein,
        goalCarbs:   goalCarbs,
        goalFat:     goalFat,
      );
      final plan = DietPlan.fromJson(json, calories);
      state = AiDietPlanState(plan: plan);
      await _saveToStorage(plan);
    } catch (_) {
      state = const AiDietPlanState(
          error: 'Não foi possível gerar a dieta. Tente novamente.');
    }
  }

  /// Troca ou reajusta um alimento específico no plano — persiste a troca.
  void swapFood(int mealIdx, int foodIdx, DietPlanFood newFood) {
    final plan = state.plan;
    if (plan == null) return;
    final updatedMeal  = plan.meals[mealIdx].copyWithFood(foodIdx, newFood);
    final updatedPlan  = plan.copyWithMeal(mealIdx, updatedMeal);
    state = AiDietPlanState(plan: updatedPlan);
    _saveToStorage(updatedPlan);
  }

  void reset() {
    state = const AiDietPlanState();
    _clearStorage();
  }
}
