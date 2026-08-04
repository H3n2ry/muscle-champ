/// Resumo diário de hidratação.
class WaterSummary {
  final int totalMl; // consumido hoje
  final int goalMl;  // meta diária sugerida (goals.daily_water_ml)

  const WaterSummary({required this.totalMl, required this.goalMl});

  double get progress =>
      goalMl > 0 ? (totalMl / goalMl).clamp(0.0, 1.0) : 0.0;

  int get remainingMl =>
      goalMl > 0 ? (goalMl - totalMl).clamp(0, goalMl) : 0;

  bool get goalMet => goalMl > 0 && totalMl >= goalMl;
}
