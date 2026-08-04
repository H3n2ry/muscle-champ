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

// ── Provider da Dieta Manual (montada pelo usuário) ───────────────────────────

final customDietPlanProvider =
    StateNotifierProvider.autoDispose<CustomDietPlanNotifier, DietPlan?>(
        (_) => CustomDietPlanNotifier());

class CustomDietPlanNotifier extends StateNotifier<DietPlan?> {
  static String _storageKey() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return uid != null ? 'custom_diet_plan_v1_$uid' : 'custom_diet_plan_v1';
  }

  CustomDietPlanNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey());
      if (raw == null) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (mounted) {
        state = DietPlan.fromJson(
            data, (data['target_calories'] as num?)?.toInt() ?? 0);
      }
    } catch (_) {
      // JSON inválido/desatualizado — ignora
    }
  }

  Future<void> _persist(DietPlan? plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (plan == null) {
        await prefs.remove(_storageKey());
      } else {
        await prefs.setString(_storageKey(), jsonEncode(plan.toJson()));
      }
    } catch (_) {}
  }

  void _set(DietPlan? plan) {
    state = plan;
    _persist(plan);
  }

  DietPlan _rebuild(DietPlan base, List<DietPlanMeal> meals) => DietPlan(
        targetCalories: base.targetCalories,
        goalProtein: base.goalProtein,
        goalCarbs: base.goalCarbs,
        goalFat: base.goalFat,
        meals: meals,
      );

  static const _emptyPlan = DietPlan(
    targetCalories: 0,
    goalProtein: 0,
    goalCarbs: 0,
    goalFat: 0,
    meals: [],
  );

  void addMeal(String type) {
    final plan = state ?? _emptyPlan;
    final meals = List<DietPlanMeal>.from(plan.meals)
      ..add(DietPlanMeal(type: type, foods: const []));
    _set(_rebuild(plan, meals));
  }

  void removeMeal(int mealIdx) {
    final plan = state;
    if (plan == null || mealIdx >= plan.meals.length) return;
    final meals = List<DietPlanMeal>.from(plan.meals)..removeAt(mealIdx);
    _set(meals.isEmpty ? null : _rebuild(plan, meals));
  }

  void addFood(int mealIdx, DietPlanFood food) {
    final plan = state;
    if (plan == null || mealIdx >= plan.meals.length) return;
    final meal = plan.meals[mealIdx];
    final foods = List<DietPlanFood>.from(meal.foods)..add(food);
    _set(plan.copyWithMeal(mealIdx, DietPlanMeal(type: meal.type, foods: foods)));
  }

  void removeFood(int mealIdx, int foodIdx) {
    final plan = state;
    if (plan == null || mealIdx >= plan.meals.length) return;
    final meal = plan.meals[mealIdx];
    if (foodIdx >= meal.foods.length) return;
    final foods = List<DietPlanFood>.from(meal.foods)..removeAt(foodIdx);
    _set(plan.copyWithMeal(mealIdx, DietPlanMeal(type: meal.type, foods: foods)));
  }

  void clear() => _set(null);
}
