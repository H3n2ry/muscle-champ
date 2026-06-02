// ── Log de refeição ───────────────────────────────────────────────────────────

class DietLogModel {
  final String id;
  final String userId;
  final DateTime date;
  final String mealName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const DietLogModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory DietLogModel.fromJson(Map<String, dynamic> json) => DietLogModel(
        id:       json['id']       as String,
        userId:   json['user_id']  as String,
        date:     DateTime.parse(json['date'] as String),
        mealName: json['meal_name'] as String,
        calories: (json['calories'] as num).toInt(),
        protein:  (json['protein']  as num).toDouble(),
        carbs:    (json['carbs']    as num).toDouble(),
        fat:      (json['fat']      as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'meal_name': mealName,
        'calories':  calories,
        'protein':   protein,
        'carbs':     carbs,
        'fat':       fat,
      };
}

// ── Resumo do dia ─────────────────────────────────────────────────────────────

class DietSummaryModel {
  final int totalCalories;
  final int goalCalories;
  final String? goalType; // 'lose_weight' | 'gain_weight' | 'maintain'
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final bool goalMet;
  final List<DietLogModel> meals;

  const DietSummaryModel({
    required this.totalCalories,
    required this.goalCalories,
    this.goalType,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.goalMet,
    required this.meals,
  });

  double get calorieProgress =>
      goalCalories > 0 ? (totalCalories / goalCalories).clamp(0.0, 1.0) : 0;

  // Metas de macro derivadas das calorias (split padrão):
  //   Proteína 30 % → 4 kcal/g | Carboidrato 40 % → 4 kcal/g | Gordura 30 % → 9 kcal/g
  double get goalProtein => goalCalories * 0.30 / 4.0;
  double get goalCarbs   => goalCalories * 0.40 / 4.0;
  double get goalFat     => goalCalories * 0.30 / 9.0;

  double get proteinProgress =>
      goalProtein > 0 ? (totalProtein / goalProtein).clamp(0.0, 1.0) : 0.0;
  double get carbsProgress =>
      goalCarbs > 0 ? (totalCarbs / goalCarbs).clamp(0.0, 1.0) : 0.0;
  double get fatProgress =>
      goalFat > 0 ? (totalFat / goalFat).clamp(0.0, 1.0) : 0.0;

  factory DietSummaryModel.fromJson(Map<String, dynamic> json) =>
      DietSummaryModel(
        totalCalories: (json['total_calories'] as num).toInt(),
        goalCalories:  (json['goal_calories']  as num).toInt(),
        goalType:       json['goal_type']       as String?,
        totalProtein:  (json['total_protein']  as num).toDouble(),
        totalCarbs:    (json['total_carbs']    as num).toDouble(),
        totalFat:      (json['total_fat']      as num).toDouble(),
        goalMet:        json['goal_met']        as bool,
        meals: (json['meals'] as List)
            .map((e) => DietLogModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ── Modelos do Plano Alimentar IA ─────────────────────────────────────────────

class DietPlanFood {
  final String name;
  final double weightG;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const DietPlanFood({
    required this.name,
    required this.weightG,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory DietPlanFood.fromJson(Map<String, dynamic> j) => DietPlanFood(
        name:     j['name']     as String,
        weightG:  (j['weight_g'] as num).toDouble(),
        calories: (j['calories'] as num).toInt(),
        protein:  (j['protein']  as num).toDouble(),
        carbs:    (j['carbs']    as num).toDouble(),
        fat:      (j['fat']      as num).toDouble(),
      );

  /// Recalcula macros proporcionalmente para um novo peso.
  DietPlanFood withWeight(double newWeight) {
    if (weightG <= 0) return this;
    final ratio = newWeight / weightG;
    return DietPlanFood(
      name:     name,
      weightG:  newWeight,
      calories: (calories * ratio).round(),
      protein:  ((protein * ratio) * 10).round() / 10,
      carbs:    ((carbs   * ratio) * 10).round() / 10,
      fat:      ((fat     * ratio) * 10).round() / 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'name':     name,
        'weight_g': weightG,
        'calories': calories,
        'protein':  protein,
        'carbs':    carbs,
        'fat':      fat,
      };

  Map<String, dynamic> toLogMap() => {
        'meal_name': name,
        'calories':  calories,
        'protein':   protein,
        'carbs':     carbs,
        'fat':       fat,
      };
}

class DietPlanMeal {
  final String type; // 'Café da Manhã', 'Almoço', etc.
  final List<DietPlanFood> foods;

  const DietPlanMeal({required this.type, required this.foods});

  factory DietPlanMeal.fromJson(Map<String, dynamic> j) => DietPlanMeal(
        type:  j['type'] as String,
        foods: (j['foods'] as List)
            .map((e) => DietPlanFood.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int    get totalCalories => foods.fold(0,   (s, f) => s + f.calories);
  double get totalProtein  => foods.fold(0.0, (s, f) => s + f.protein);
  double get totalCarbs    => foods.fold(0.0, (s, f) => s + f.carbs);
  double get totalFat      => foods.fold(0.0, (s, f) => s + f.fat);

  Map<String, dynamic> toJson() => {
        'type':  type,
        'foods': foods.map((f) => f.toJson()).toList(),
      };

  DietPlanMeal copyWithFood(int idx, DietPlanFood food) {
    final updated = List<DietPlanFood>.from(foods);
    updated[idx] = food;
    return DietPlanMeal(type: type, foods: updated);
  }
}

class DietPlan {
  final int    targetCalories;
  final double goalProtein;
  final double goalCarbs;
  final double goalFat;
  final List<DietPlanMeal> meals;

  const DietPlan({
    required this.targetCalories,
    required this.goalProtein,
    required this.goalCarbs,
    required this.goalFat,
    required this.meals,
  });

  factory DietPlan.fromJson(Map<String, dynamic> j, int targetCalories) =>
      DietPlan(
        targetCalories: targetCalories,
        goalProtein:    (j['goal_protein_g'] as num).toDouble(),
        goalCarbs:      (j['goal_carbs_g']   as num).toDouble(),
        goalFat:        (j['goal_fat_g']     as num).toDouble(),
        meals: (j['meals'] as List)
            .map((e) => DietPlanMeal.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  int get totalCalories => meals.fold(0, (s, m) => s + m.totalCalories);

  Map<String, dynamic> toJson() => {
        'target_calories': targetCalories,
        'goal_protein_g':  goalProtein,
        'goal_carbs_g':    goalCarbs,
        'goal_fat_g':      goalFat,
        'meals':           meals.map((m) => m.toJson()).toList(),
      };

  DietPlan copyWithMeal(int idx, DietPlanMeal meal) {
    final updated = List<DietPlanMeal>.from(meals);
    updated[idx] = meal;
    return DietPlan(
      targetCalories: targetCalories,
      goalProtein:    goalProtein,
      goalCarbs:      goalCarbs,
      goalFat:        goalFat,
      meals:          updated,
    );
  }
}
