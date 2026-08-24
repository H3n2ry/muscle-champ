import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Faixa que marca a tela como simulação.
///
/// Fica visível o tempo todo, e não só num rodapé, de propósito: uma tela de
/// pagamento convincente que na verdade não cobra nada é o tipo de coisa que
/// vaza para produção sem ninguém notar. Enquanto esta faixa estiver aqui,
/// não tem como confundir.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.warning.withOpacity(0.14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_outlined,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.demo_faixa,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.warning,
                      fontSize: 10,
                      letterSpacing: 1.5,
                    )),
                const SizedBox(height: 2),
                Text(l.demo_explicacao,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
