import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/plano.dart';
import '../../data/repositories/assinatura_repository.dart';

/// Assinatura atual, ou null se não houver.
///
/// Não é `autoDispose`: o perfil e o paywall leem a mesma coisa e trocar de
/// aba não deveria refazer a leitura.
final assinaturaProvider = FutureProvider<Assinatura?>((ref) async {
  return ref.watch(assinaturaRepositoryProvider).carregar();
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
