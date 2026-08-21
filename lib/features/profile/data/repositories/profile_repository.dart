import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

final profileRepositoryProvider =
    Provider<ProfileRepository>((_) => ProfileRepository());

/// Um dia da faixa de 7 dias que o card de sequência desenha.
class DayActivity {
  final DateTime dia;
  /// 1 = segunda … 7 = domingo (ISO)
  final int weekday;
  final bool treinou;

  const DayActivity({
    required this.dia,
    required this.weekday,
    required this.treinou,
  });

  /// Inicial do dia da semana em português: S T Q Q S S D
  String get inicial => const ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'][weekday - 1];
}

/// Os 7 dias terminando HOJE, com o dia da semana real de cada um.
///
/// Vem do servidor porque o "hoje" precisa ser o mesmo que o banco usa para
/// gravar — o relógio do aparelho pode divergir do fuso resolvido lá.
final weekActivityProvider =
    FutureProvider.autoDispose<List<DayActivity>>((ref) {
  return ref.watch(profileRepositoryProvider).getWeekActivity();
});

/// Uma barra do gráfico de evolução: quanto o usuário tinha ao fim da semana.
class WeeklyPoints {
  /// Segunda-feira que abre a semana (UTC, só a data importa).
  final DateTime inicioDaSemana;

  /// Pontos ganhos dentro desta semana.
  final int ganhos;

  /// Total acumulado até o fim desta semana.
  final int acumulado;

  const WeeklyPoints({
    required this.inicioDaSemana,
    required this.ganhos,
    required this.acumulado,
  });
}

/// Recebe o total já conhecido pelo perfil em vez de somar a tabela de novo:
/// `getProfile()` acabou de fazer essa soma, e refazê-la só para descobrir o
/// ponto de partida da curva seria uma varredura duplicada.
final pointsEvolutionProvider =
    FutureProvider.autoDispose.family<List<WeeklyPoints>, int>(
  (ref, totalPoints) =>
      ref.watch(profileRepositoryProvider).getPointsEvolution(totalPoints),
);

class ProfileRepository {
  final _client = Supabase.instance.client;

  /// Quantas semanas o gráfico de evolução mostra.
  static const semanasNoGrafico = 6;

  Future<List<DayActivity>> getWeekActivity() async {
    final rows = await _client.rpc('get_week_activity');
    return (rows as List)
        .map((r) => DayActivity(
              dia: DateTime.parse(r['dia'] as String),
              weekday: (r['dow'] as num).toInt(),
              treinou: r['treinou'] as bool? ?? false,
            ))
        .toList();
  }

  /// Curva acumulada de pontos nas últimas [semanasNoGrafico] semanas.
  ///
  /// É acumulado, não ganho por semana: o dashboard já mostra o ganho diário
  /// dos últimos 7 dias, e o rótulo aqui é "evolução". A última barra fecha
  /// exatamente em [totalPoints].
  Future<List<WeeklyPoints>> getPointsEvolution(int totalPoints) async {
    final userId = _client.auth.currentUser!.id;
    final hoje = await _serverToday();
    final semanaAtual = _segundaFeiraDe(hoje);
    final inicioJanela = semanaAtual
        .subtract(const Duration(days: 7 * (semanasNoGrafico - 1)));

    final naJanela = await _opcional<List>(
      _client
          .from('points')
          .select('amount, created_at')
          .eq('user_id', userId)
          .gte('created_at',
              '${inicioJanela.toIso8601String().substring(0, 10)}T00:00:00-03:00'),
      const [],
    );

    return montarEvolucao(
      totalPoints: totalPoints,
      inicioJanela: inicioJanela,
      lancamentos: [
        for (final p in naJanela)
          (diaUtc(p['created_at'] as String), (p['amount'] as num).toInt()),
      ],
    );
  }

  /// Parte pura de [getPointsEvolution]: distribui [lancamentos] nas semanas e
  /// acumula. Separada do banco para poder ser testada — é aritmética que erra
  /// em silêncio, sem estourar exceção nenhuma.
  static List<WeeklyPoints> montarEvolucao({
    required int totalPoints,
    required DateTime inicioJanela,
    required List<(DateTime, int)> lancamentos,
  }) {
    final ganhos = List<int>.filled(semanasNoGrafico, 0);
    for (final (dia, valor) in lancamentos) {
      // clamp: o filtro no banco é por timestamptz e o balde aqui é por data,
      // então um ponto gravado na virada pode cair um dia antes da janela.
      // Encostar na borda é melhor que sumir — se sumisse, a última barra não
      // fecharia no total do perfil.
      final i = (dia.difference(inicioJanela).inDays ~/ 7)
          .clamp(0, semanasNoGrafico - 1);
      ganhos[i] += valor;
    }

    // O que já existia antes da janela: a curva começa daí, não do zero.
    var acumulado = totalPoints - ganhos.fold<int>(0, (s, g) => s + g);

    return List.generate(semanasNoGrafico, (i) {
      acumulado += ganhos[i];
      return WeeklyPoints(
        inicioDaSemana: inicioJanela.add(Duration(days: 7 * i)),
        ganhos: ganhos[i],
        acumulado: acumulado,
      );
    });
  }

  /// Data de hoje no fuso do usuário, resolvida pelo servidor.
  Future<String> _serverToday() async {
    try {
      final r = await _client.rpc('app_today');
      return (r as String).substring(0, 10);
    } catch (_) {
      return DateTime.now().toIso8601String().substring(0, 10);
    }
  }

  /// Meia-noite UTC do dia de [iso] — normalizar evita que horário de verão
  /// transforme `.inDays` em 6 ou 8 dias no lugar de 7.
  static DateTime diaUtc(String iso) {
    final d = DateTime.parse(iso.substring(0, 10));
    return DateTime.utc(d.year, d.month, d.day);
  }

  /// Segunda-feira da semana de [iso] (ISO 8601: semana começa na segunda).
  DateTime _segundaFeiraDe(String iso) {
    final d = diaUtc(iso);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  // ── Leitura ─────────────────────────────────────────────────────

  /// Executa [query] e devolve [fallback] se ela falhar.
  ///
  /// `Future.wait` rejeita inteiro quando qualquer futuro lança. Uma RPC
  /// secundária quebrada derrubava o perfil TODO — foi o que aconteceu quando
  /// `get_streak` passou a lançar `date - bigint`: a tela ficou vazia inteira
  /// por causa de um número no card de sequência. Só `profiles` é essencial;
  /// o resto degrada.
  Future<T> _opcional<T>(Future<dynamic> query, T fallback) async {
    try {
      return (await query) as T;
    } catch (_) {
      return fallback;
    }
  }

  Future<ProfileModel> getProfile() async {
    final userId = _client.auth.currentUser!.id;

    final results = await Future.wait<dynamic>([
      // Essencial: sem perfil não há tela.
      _client.from('profiles').select().eq('id', userId).single(),

      _opcional<Map<String, dynamic>?>(
          _client.from('goals').select().eq('user_id', userId).maybeSingle(), null),
      _opcional<List>(
          _client.from('points').select('amount').eq('user_id', userId), const []),
      // workout_completions é o sistema atual; `workouts` é legado e ficou
      // parado, entao o total de treinos aparecia congelado.
      _opcional<List>(
          _client.from('workout_completions').select('id').eq('user_id', userId),
          const []),
      _opcional<int?>(
          _client.rpc('get_streak', params: {'p_user_id': userId}), 0),
      // Última leitura de bioimpedância (opcional)
      _opcional<Map<String, dynamic>?>(
          _client
              .from('bioimpedance_logs')
              .select()
              .eq('user_id', userId)
              .order('measured_at', ascending: false)
              .limit(1)
              .maybeSingle(),
          null),
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
      birthDate:     goal?['birth_date'] != null
          ? DateTime.parse(goal!['birth_date'] as String)
          : null,
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

  Future<void> updateBirthDate(DateTime? birthDate) async {
    await _client
        .from('goals')
        .update({
          'birth_date': birthDate?.toIso8601String().substring(0, 10),
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
