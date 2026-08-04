import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/water_model.dart';

final waterRepositoryProvider =
    Provider<WaterRepository>((_) => WaterRepository());

class WaterRepository {
  final _client = Supabase.instance.client;

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  /// Total consumido hoje + meta diária (calculada no banco pela idade/peso).
  Future<WaterSummary> getTodaySummary() async {
    final userId = _client.auth.currentUser!.id;

    final results = await Future.wait<dynamic>([
      _client
          .from('water_logs')
          .select('amount_ml')
          .eq('user_id', userId)
          .eq('date', _today),
      _client
          .from('goals')
          .select('daily_water_ml')
          .eq('user_id', userId)
          .maybeSingle(),
    ]);

    final logs = results[0] as List;
    final goal = results[1] as Map<String, dynamic>?;

    final total = logs.fold<int>(
        0, (s, l) => s + ((l['amount_ml'] as num?)?.toInt() ?? 0));
    final goalMl = (goal?['daily_water_ml'] as num?)?.toInt() ?? 0;

    return WaterSummary(totalMl: total, goalMl: goalMl);
  }

  /// Registra um consumo de água (ml).
  Future<void> addWater(int ml) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('water_logs').insert({
      'user_id':   userId,
      'date':      _today,
      'amount_ml': ml,
    });
  }

  /// Remove o registro mais recente de hoje (botão "desfazer").
  Future<void> undoLast() async {
    final userId = _client.auth.currentUser!.id;
    final last = await _client
        .from('water_logs')
        .select('id')
        .eq('user_id', userId)
        .eq('date', _today)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (last != null) {
      await _client.from('water_logs').delete().eq('id', last['id']);
    }
  }
}
