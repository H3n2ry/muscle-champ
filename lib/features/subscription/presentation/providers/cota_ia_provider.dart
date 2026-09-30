import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/cota_ia.dart';
import '../../data/repositories/cota_ia_repository.dart';
import 'assinatura_provider.dart';

/// Saldo de todos os recursos hoje.
///
/// `autoDispose` pelo mesmo motivo da assinatura: a cota agora e da conta. De
/// quebra, cada verificacao antes de chamar a IA passa a reler do servidor em
/// vez de confiar num numero que pode ter mudado no outro aparelho.
final saldosDeCotaProvider =
    FutureProvider.autoDispose<Map<RecursoIa, SaldoDeCota>>((ref) async {
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
final saldoDeCotaProvider = FutureProvider.autoDispose
    .family<SaldoDeCota, RecursoIa>((ref, recurso) async {
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

  /// Relê o saldo depois de uma chamada de IA, para o selo "2 de 3 hoje" não
  /// ficar mostrando o número de antes.
  ///
  /// ⚠️ NÃO cobra nada. Até 30/09/2026 esta função se chamava `registrarUso`
  /// e era ela quem cobrava a cota — o que queria dizer que quem chamasse o
  /// proxy direto, sem passar pelo app, nunca era cobrado. Agora quem cobra é o
  /// `groq-proxy`: reserva antes de chamar a Groq e devolve se falhar. Cobrar
  /// aqui também contaria cada uso duas vezes.
  void atualizarSaldo() => _ref.invalidate(saldosDeCotaProvider);
}

final cotaIaControllerProvider =
    Provider<CotaIaController>(CotaIaController.new);
