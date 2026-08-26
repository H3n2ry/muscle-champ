import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cota_ia.dart';

final cotaIaRepositoryProvider =
    Provider<CotaIaRepository>((_) => CotaIaRepository());

/// Contador diário de uso de IA — no servidor.
///
/// Já morou em SharedPreferences e tinha dois furos por causa disso: a cota
/// era por APARELHO (1 foto no celular + 1 no navegador = 2) e a data era a
/// local (adiantar o relógio rendia cota nova).
///
/// Agora as três operações são RPC `SECURITY DEFINER`. A tabela
/// `cota_ia_diaria` tem RLS **só de leitura**: sem política de escrita, nem o
/// dono consegue zerar o próprio contador por fora. E o "hoje" vem de
/// `app_today()`, o mesmo que o resto do app usa.
class CotaIaRepository {
  final _client = Supabase.instance.client;

  /// `{"foto": 1, "texto": 2}` — só o dia de hoje.
  Future<Map<String, int>> usosDeHoje() async {
    try {
      final r = await _client.rpc('get_cota_ia');
      if (r is! Map) return {};
      return {
        for (final e in r.entries)
          e.key as String: (e.value as num).toInt(),
      };
    } catch (_) {
      // Rede caída não pode virar bloqueio: sem saber o consumo, o app deixa
      // passar. Errar liberando um uso a mais é melhor que travar quem pagou
      // — e o custo de uma chamada de IA é fração de centavo.
      return {};
    }
  }

  /// Registra um uso. Chamar só quando a IA respondeu com sucesso.
  Future<void> consumir(RecursoIa recurso) async {
    await _client.rpc('consumir_cota_ia', params: {'p_recurso': recurso.chave});
  }

  /// Zera a cota do dia. Só para o modo demonstração poder testar o limite
  /// sem esperar a meia-noite.
  Future<void> zerar() async {
    await _client.rpc('zerar_cota_ia');
  }
}
