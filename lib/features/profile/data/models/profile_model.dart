class ProfileModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String goalType;
  final double currentWeight;
  final double targetWeight;
  final double heightCm;
  final int totalPoints;
  final int totalWorkouts;
  final int streak;
  final DateTime memberSince;

  // Bioimpedância (opcional)
  final double? bodyFatPct;   // % gordura corporal
  final double? muscleMassKg; // kg massa muscular
  final int? visceralFat;     // nível gordura visceral (1-20)
  final double? hydrationPct; // % hidratação
  final double? boneMassKg;   // kg massa óssea
  final int? bmrKcal;         // metabolismo basal (kcal)
  final DateTime? bioUpdatedAt;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.goalType,
    required this.currentWeight,
    required this.targetWeight,
    required this.heightCm,
    required this.totalPoints,
    required this.totalWorkouts,
    required this.streak,
    required this.memberSince,
    this.bodyFatPct,
    this.muscleMassKg,
    this.visceralFat,
    this.hydrationPct,
    this.boneMassKg,
    this.bmrKcal,
    this.bioUpdatedAt,
  });

  bool get hasBioimpedance =>
      bodyFatPct != null ||
      muscleMassKg != null ||
      visceralFat != null ||
      hydrationPct != null;

  /// IMC calculado (retorna null se dados insuficientes)
  double? get bmi {
    if (heightCm <= 0 || currentWeight <= 0) return null;
    final hm = heightCm / 100.0;
    return currentWeight / (hm * hm);
  }
}
