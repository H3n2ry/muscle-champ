import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/perfil_publico.dart';

/// Perfil de outro competidor.
///
/// `autoDispose` porque é tela de visita: sair dela e voltar depois deve
/// mostrar os pontos e a sequência atualizados, não o que estava em cache.
final perfilPublicoProvider =
    FutureProvider.autoDispose.family<PerfilPublico?, String>((ref, id) async {
  final r = await Supabase.instance.client
      .rpc('get_perfil_publico', params: {'p_user_id': id});
  if (r == null) return null;
  return PerfilPublico.doJson(Map<String, dynamic>.from(r as Map));
});

/// Copia um treino de outro competidor para os seus.
///
/// A RPC recusa copiar o proprio treino e zera as cargas: o supino de 100 kg
/// de outra pessoa nao diz nada sobre o seu, e um iniciante tentando repetir
/// e risco de lesao. O app ja preenche carga na hora do treino.
final copiarTreinoProvider = Provider<Future<void> Function(String, String)>(
  (ref) => (String templateId, String nome) async {
    await Supabase.instance.client.rpc(
      'copiar_treino',
      params: {'p_template_id': templateId, 'p_nome': nome},
    );
  },
);