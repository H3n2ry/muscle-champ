import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cota_ia.dart';
import '../../data/repositories/cota_ia_repository.dart';
import 'assinatura_provider.dart';

/// Saldo de todos os recursos hoje.
final saldosDeCotaProvider =
    FutureProvider<Map<RecursoIa, SaldoDeCota>>((ref) async {
  final assinatura = await ref.watch(assinaturaProvider.future);
  final ilimitado = assinatura?.ativa ?? false;
  final usos = await ref.watch(cotaIaRepositoryProvider).usosDeHoje();

  return {
    for (final r in RecursoIa.values)
      r: SaldoDeCota(
        recurso: r,
        usados: usos[r.chave] ?? 0,
        ilimitado: ilimitado,
      ),
  };
});

/// Saldo de UM recurso — o que as telas normalmente querem.
final saldoDeCotaProvider =
    FutureProvider.family<SaldoDeCota, RecursoIa>((ref, recurso) async {
  final todos = await ref.watch(saldosDeCotaProvider.future);
  return todos[recurso]!;
});

class CotaIaController {
  CotaIaController(this._ref);
  final Ref _ref;

  /// Consulta antes de chamar a IA. Não consome nada.
  Future<bool> podeUsar(RecursoIa recurso) async {
    final saldo = await _ref.read(saldoDeCotaProvider(recurso).future);
    return saldo.podeUsar;
  }

  /// Registra o uso DEPOIS que a IA respondeu com sucesso.
  ///
  /// A ordem importa: consumir antes gastaria o único uso do dia numa queda
  /// de rede, e o usuário ficaria sem entender por que perdeu a foto.
  Future<void> registrarUso(RecursoIa recurso) async {
    final assinatura = await _ref.read(assinaturaProvider.future);
    if (assinatura?.ativa ?? false) return; // Pro não tem contador
    await _ref.read(cotaIaRepositoryProvider).consumir(recurso);
    _ref.invalidate(saldosDeCotaProvider);
  }
}

final cotaIaControllerProvider =
    Provider<CotaIaController>(CotaIaController.new);
