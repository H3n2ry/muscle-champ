import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

final profileRepositoryProvider =
    Provider<ProfileRepository>((_) => ProfileRepository());

class ProfileRepository {
  final _client = Supabase.instance.client;

  // ── Leitura ─────────────────────────────────────────────────────

  Future<ProfileModel> getProfile() async {
    final userId = _client.auth.currentUser!.id;

    final results = await Future.wait<dynamic>([
      _client.from('profiles').select().eq('id', userId).single(),
      _client.from('goals').select().eq('user_id', userId).maybeSingle(),
      _client.from('points').select('amount').eq('user_id', userId),
      _client.from('workouts').select('id').eq('user_id', userId).eq('completed', true),
      _client.rpc('get_streak', params: {'p_user_id': userId}),
      // Última leitura de bioimpedância (opcional)
      _client
          .from('bioimpedance_logs')
          .select()
          .eq('user_id', userId)
          .order('measured_at', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);

    final profile     = results[0] as Map<String, dynamic>;
    final goal        = results[1] as Map<String, dynamic>?;
    final points      = results[2] as List;
    final workouts    = results[3] as List;
    final streak      = results[4] as int? ?? 0;
    final bio         = results[5] as Map<String, dynamic>?;
    final totalPoints = points.fold<int>(0, (s, p) => s + (p['amount'] as int));

    return ProfileModel(
      id:            profile['id'] as String,
      name:          profile['name'] as String,
      email:         _client.auth.currentUser!.email ?? '',
      avatarUrl:     profile['avatar_url'] as String?,
      goalType:      goal?['goal_type'] as String? ?? 'maintain',
      currentWeight: (goal?['current_weight'] as num?)?.toDouble() ?? 0,
      targetWeight:  (goal?['target_weight']  as num?)?.toDouble() ?? 0,
      heightCm:      (goal?['height_cm']       as num?)?.toDouble() ?? 0,
      totalPoints:   totalPoints,
      totalWorkouts: workouts.length,
      streak:        streak,
      memberSince:   DateTime.parse(profile['created_at'] as String),
      // Bioimpedância
      bodyFatPct:   (bio?['body_fat_pct']   as num?)?.toDouble(),
      muscleMassKg: (bio?['muscle_mass_kg'] as num?)?.toDouble(),
      visceralFat:  (bio?['visceral_fat']   as num?)?.toInt(),
      hydrationPct: (bio?['hydration_pct']  as num?)?.toDouble(),
      boneMassKg:   (bio?['bone_mass_kg']   as num?)?.toDouble(),
      bmrKcal:      (bio?['bmr_kcal']       as num?)?.toInt(),
      bioUpdatedAt: bio?['measured_at'] != null
          ? DateTime.parse(bio!['measured_at'] as String)
          : null,
    );
  }

  // ── Edição de perfil ─────────────────────────────────────────────

  Future<void> updateName(String name) async {
    await _client
        .from('profiles')
        .update({'name': name})
        .eq('id', _client.auth.currentUser!.id);
  }

  Future<void> updateWeight(double weight) async {
    final userId = _client.auth.currentUser!.id;
    final today  = DateTime.now().toIso8601String().substring(0, 10);
    await Future.wait([
      _client
          .from('goals')
          .update({
            'current_weight': weight,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId),
      _client.from('weight_logs').upsert({
        'user_id': userId,
        'weight':  weight,
        'date':    today,
      }, onConflict: 'user_id,date'),
    ]);
  }

  Future<void> updateHeight(double heightCm) async {
    await _client
        .from('goals')
        .update({
          'height_cm':  heightCm,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', _client.auth.currentUser!.id);
  }

  Future<void> updateGoal(String goalType, double targetWeight) async {
    await _client
        .from('goals')
        .update({
          'goal_type':     goalType,
          'target_weight': targetWeight,
          'updated_at':    DateTime.now().toIso8601String(),
        })
        .eq('user_id', _client.auth.currentUser!.id);
  }

  // ── Bioimpedância ─────────────────────────────────────────────────

  Future<void> saveBioimpedance({
    double? bodyFatPct,
    double? muscleMassKg,
    int? visceralFat,
    double? hydrationPct,
    double? boneMassKg,
    int? bmrKcal,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final today  = DateTime.now().toIso8601String().substring(0, 10);

    await _client.from('bioimpedance_logs').upsert(
      {
        'user_id':        userId,
        'body_fat_pct':   bodyFatPct,
        'muscle_mass_kg': muscleMassKg,
        'visceral_fat':   visceralFat,
        'hydration_pct':  hydrationPct,
        'bone_mass_kg':   boneMassKg,
        'bmr_kcal':       bmrKcal,
        'measured_at':    today,
      },
      onConflict: 'user_id, measured_at',
    );
  }

  // ── Upload de avatar ─────────────────────────────────────────────

  Future<String> uploadAvatar(Uint8List bytes, String ext) async {
    final userId      = _client.auth.currentUser!.id;
    final storagePath = '$userId/avatar.$ext';
    final mimeMap = {
      'jpg':  'image/jpeg',
      'jpeg': 'image/jpeg',
      'png':  'image/png',
      'webp': 'image/webp',
      'heic': 'image/heic',
    };
    final mime = mimeMap[ext.toLowerCase()] ?? 'image/jpeg';

    await _client.storage.from('avatars').uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(contentType: mime, upsert: true),
    );

    final baseUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
    final url     = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';

    await _client
        .from('profiles')
        .update({'avatar_url': url})
        .eq('id', userId);

    return url;
  }
}
