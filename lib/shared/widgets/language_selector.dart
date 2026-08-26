import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Seletor de idioma em siglas (PT · EN · ES).
///
/// Compacto de propósito: aparece no rodapé do cadastro, onde a tela já está
/// cheia, e no perfil. A troca vale na hora e é persistida.
class LanguageSelector extends ConsumerWidget {
  /// Centraliza as siglas. Usado no cadastro; no perfil elas ficam à esquerda.
  final bool centralizado;

  const LanguageSelector({super.key, this.centralizado = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atual = ref.watch(localeProvider);

    return Row(
      mainAxisAlignment:
          centralizado ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        for (final l in AppLocale.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => ref.read(localeProvider.notifier).trocar(l),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: l == atual
                      ? AppColors.primary
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: l == atual
                        ? AppColors.primary
                        : AppColors.surfaceContainerHigh,
                  ),
                ),
                child: Text(
                  l.sigla,
                  style: AppTypography.labelSm.copyWith(
                    color: l == atual
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                    fontWeight:
                        l == atual ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Versão em lista, com o nome do idioma escrito por extenso.
///
/// Cada nome aparece no próprio idioma — quem procura "Español" não reconhece
/// "Espanhol".
class LanguageListTile extends ConsumerWidget {
  const LanguageListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atual = ref.watch(localeProvider);

    return Column(
      children: [
        for (final l in AppLocale.values)
          ListTile(
            leading: Icon(
              l == atual
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: l == atual
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
              size: 20,
            ),
            title: Text(l.nome, style: AppTypography.bodyMd),
            trailing: Text(l.sigla,
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant)),
            onTap: () => ref.read(localeProvider.notifier).trocar(l),
          ),
      ],
    );
  }
}
