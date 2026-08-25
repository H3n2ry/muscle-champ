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
