import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'paleta.dart';
import 'paleta_provider.dart';

/// Fileira de cores para o usuário escolher o acento do app.
///
/// Mostra amostras e não nomes: "âmbar" e "coral" não dizem nada até você ver,
/// e assim a lista não cresce em altura com sete linhas de texto. O nome vai no
/// rótulo de acessibilidade, que é onde ele serve para alguma coisa.
class SeletorDeCor extends ConsumerWidget {
  const SeletorDeCor({super.key});

  static String nomeDe(L l, Paleta p) => switch (p.id) {
        'roxo' => l.cor_roxo,
        'ciano' => l.cor_ciano,
        'ambar' => l.cor_ambar,
        'coral' => l.cor_coral,
        'azul' => l.cor_azul,
        'rosa' => l.cor_rosa,
        _ => l.cor_limao,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final atual = ref.watch(paletaProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.cor_descricao,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // Quebra em vez de rolar: sete amostras cabem em duas fileiras até em
          // aparelho estreito, e uma lista horizontal esconderia as últimas.
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final p in Paleta.todas)
                _Amostra(
                  paleta: p,
                  nome: nomeDe(l, p),
                  escolhida: p.id == atual.id,
                  aoTocar: () => ref.read(paletaProvider.notifier).trocar(p),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l.cor_segueAConta,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Amostra extends StatelessWidget {
  final Paleta paleta;
  final String nome;
  final bool escolhida;
  final VoidCallback aoTocar;

  const _Amostra({
    required this.paleta,
    required this.nome,
    required this.escolhida,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: nome,
      selected: escolhida,
      button: true,
      child: InkWell(
        onTap: aoTocar,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: paleta.primary,
            shape: BoxShape.circle,
            // O anel fica FORA da amostra, na cor do texto, e não na cor da
            // própria paleta: um anel colorido sobre a mesma cor some.
            border: Border.all(
              color: escolhida ? AppColors.onSurface : Colors.transparent,
              width: 2.5,
            ),
          ),
          // Espaço entre o anel e a cor, para o anel não parecer parte dela.
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: BoxDecoration(
              color: paleta.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.surfaceContainerLow,
                width: escolhida ? 2 : 0,
              ),
            ),
            child: escolhida
                ? Icon(Icons.check, size: 20, color: paleta.onPrimary)
                : null,
          ),
        ),
      ),
    );
  }
}
