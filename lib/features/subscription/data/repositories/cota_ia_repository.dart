import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cota_ia.dart';

final cotaIaRepositoryProvider =
    Provider<CotaIaRepository>((_) => CotaIaRepository());

/// Contador diário de uso de IA.
///
/// Guarda `{"dia": "2026-08-24", "usos": {"foto": 1, "texto": 2}}`. Virou o
/// dia, o mapa inteiro é descartado — não guarda histórico, porque a única
/// pergunta que interessa é "quanto sobrou hoje".
///
/// ⚠️ Ponto de troca: quando o entitlement virar real, este contador sai do
/// aparelho e vai para o `groq-proxy`. A interface (`consumir`, `saldo`) foi
/// desenhada para essa mudança não vazar para as telas.
class CotaIaRepository {
  /// Escopo por usuário. Tolera Supabase não inicializado — em teste ele não
  /// está, e sem isso o contador seria impossível de exercitar fora do app.
  String get _chave {
    var uid = 'anon';
    try {
      uid = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
    } catch (_) {}
    return 'cota_ia_v1_$uid';
  }

  String get _hoje {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, int>> _usosDeHoje(SharedPreferences prefs) async {
    final bruto = prefs.getString(_chave);
    if (bruto == null) return {};
    try {
      final m = jsonDecode(bruto) as Map<String, dynamic>;
      if (m['dia'] != _hoje) return {}; // virou o dia
      return Map<String, int>.from(
          (m['usos'] as Map).map((k, v) => MapEntry(k as String, v as int)));
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, int>> usosDeHoje() async =>
      _usosDeHoje(await SharedPreferences.getInstance());

  /// Registra UM uso e devolve o saldo depois dele.
  ///
  /// Chamar só quando a chamada de IA deu certo. Cobrar cota por erro de rede
  /// gasta o único uso do dia sem entregar nada.
  Future<void> consumir(RecursoIa recurso) async {
    final prefs = await SharedPreferences.getInstance();
    final usos = await _usosDeHoje(prefs);
    usos[recurso.chave] = (usos[recurso.chave] ?? 0) + 1;
    await prefs.setString(_chave, jsonEncode({'dia': _hoje, 'usos': usos}));
  }

  /// Zera tudo. Só para o desenvolvimento poder testar sem esperar meia-noite.
  Future<void> zerar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}
