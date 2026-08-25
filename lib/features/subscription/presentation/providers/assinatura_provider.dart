import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/plano.dart';
import '../../data/repositories/assinatura_repository.dart';

/// Assinatura atual, ou null se não houver.
///
/// `autoDispose` desde que o estado saiu do aparelho e passou a ser da CONTA:
/// sem isso, sair e entrar com outro usuário mostraria a assinatura do
/// anterior, porque o valor ficava cacheado na raiz para sempre.
final assinaturaProvider = FutureProvider.autoDispose<Assinatura?>((ref) async {
  return ref.watch(assinaturaRepositoryProvider).carregar();
});

/// É conta de desenvolvimento? Só elas veem o atalho de zerar cota.
final contaDeTesteProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.watch(assinaturaRepositoryProvider).souContaDeTeste();
});

/// Ações de assinatura. Invalida [assinaturaProvider] ao final para a tela
/// inteira reagir sem cada widget ter que se lembrar de recarregar.
class AssinaturaController {
  AssinaturaController(this._ref);
  final Ref _ref;

  Future<Assinatura> assinar(Plano plano) async {
    final r = await _ref.read(assinaturaRepositoryProvider).assinar(plano);
    _ref.invalidate(assinaturaProvider);
    return r;
  }

  Future<void> cancelar() async {
    await _ref.read(assinaturaRepositoryProvider).cancelar();
    _ref.invalidate(assinaturaProvider);
  }
}

final assinaturaControllerProvider =
    Provider<AssinaturaController>(AssinaturaController.new);
