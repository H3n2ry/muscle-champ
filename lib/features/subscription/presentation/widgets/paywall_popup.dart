import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/cota_ia.dart';
import '../../data/models/plano.dart';
import '../providers/assinatura_provider.dart';

/// Convite ao Pro em forma de pop-up.
///
/// Mostra o que o plano gratuito DÁ antes de dizer o que o Pro libera. Não é
/// generosidade: quem acabou de se cadastrar não sabe que existe cota, e
/// descobrir o limite batendo nele é a pior forma de descobrir. Aqui o convite
/// e o aviso de cota são a mesma tela.
///
/// Sempre dispensável — "Continuar no plano gratuito" tem o mesmo peso visual
/// que o botão de planos. Pop-up que encurrala converte pior e ainda arrisca
/// reprovação na revisão da Play Store.
class PaywallPopup extends ConsumerWidget {
  /// Logo após o cadastro o tom é de boas-vindas; nas aberturas seguintes é
  /// de convite. Mesma tela, chamada diferente.
  final bool recemCadastrado;

  const PaywallPopup({super.key, this.recemCadastrado = false});

  static Future<void> mostrar(
    BuildContext context, {
    bool recemCadastrado = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaywallPopup(recemCadastrado: recemCadastrado),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 14, 24, 20 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.14),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: const Icon(Icons.workspace_premium,
                  size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              recemCadastrado ? l.pop_titulo : l.pop_tituloRecorrente,
              textAlign: TextAlign.center,
              style: AppTypography.headlineSm
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              l.pop_subtitulo(Planos.diasDeTrial),
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 22),

            // ── O que o grátis dá ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.pop_noGratisVoceTem,
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        color: AppColors.onSurfaceVariant,
                      )),
                  const SizedBox(height: 10),
                  _Linha(
                      icone: Icons.photo_camera_outlined,
                      texto: l.pop_linhaFoto(
                          RecursoIa.fotoRefeicao.limiteGratis)),
                  _Linha(
                      icone: Icons.auto_awesome,
                      texto: l.pop_linhaTexto(
                          RecursoIa.macrosTexto.limiteGratis)),
                  _Linha(
                      icone: Icons.fitness_center,
                      texto: l.pop_linhaTreino(
                          RecursoIa.gerarTreino.limiteGratis)),
                  _Linha(
                      icone: Icons.restaurant_menu,
                      texto:
                          l.pop_linhaDieta(RecursoIa.planoDieta.limiteGratis),
                      ultima: true),
                ],
              ),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.all_inclusive,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.pop_comPro,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/assinatura');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(l.cota_verPlanos,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    )),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.pop_continuarGratis,
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final IconData icone;
  final String texto;
  final bool ultima;
  const _Linha({required this.icone, required this.texto, this.ultima = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultima ? 0 : 8),
      child: Row(
        children: [
          Icon(icone, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: AppTypography.bodySm.copyWith(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Já mostrou o convite nesta sessão?
///
/// Em memória de propósito: reseta a cada abertura do app (na web, a cada
/// recarga), que é exatamente a cadência pedida — uma vez por entrada, e não
/// uma vez a cada troca de aba.
final conviteProMostradoProvider = StateProvider<bool>((_) => false);

/// Decide e dispara o convite.
///
/// Ponto único: se um dia a regra virar "1× por dia" ou "a cada 3 aberturas",
/// muda aqui e em mais lugar nenhum.
Future<void> talvezMostrarConvitePro(
  BuildContext context,
  WidgetRef ref,
) async {
  if (ref.read(conviteProMostradoProvider)) return;

  final assinatura = await ref.read(assinaturaProvider.future);
  if (assinatura?.ativa ?? false) return; // assinante não vê convite

  if (!context.mounted) return;
  ref.read(conviteProMostradoProvider.notifier).state = true;
  await PaywallPopup.mostrar(context);
}
