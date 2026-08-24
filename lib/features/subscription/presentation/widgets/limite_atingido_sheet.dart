import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/cota_ia.dart';

/// Folha que aparece quando a cota diária acaba.
///
/// Não é um erro — é um convite. Por isso o tom é "volta amanhã OU libera",
/// com a saída sem custo ("Espero até amanhã") tão visível quanto o botão de
/// planos. Paywall que encurrala converte pior e irrita mais.
class LimiteAtingidoSheet extends StatelessWidget {
  final RecursoIa recurso;
  const LimiteAtingidoSheet({super.key, required this.recurso});

  static Future<void> mostrar(BuildContext context, RecursoIa recurso) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LimiteAtingidoSheet(recurso: recurso),
    );
  }

  String _mensagem(L l) => switch (recurso) {
        RecursoIa.fotoRefeicao => l.cota_limiteFoto(recurso.limiteGratis),
        RecursoIa.macrosTexto => l.cota_limiteTexto(recurso.limiteGratis),
        RecursoIa.gerarTreino => l.cota_limiteTreino(recurso.limiteGratis),
        RecursoIa.planoDieta => l.cota_limiteDieta(recurso.limiteGratis),
      };

  IconData get _icone => switch (recurso) {
        RecursoIa.fotoRefeicao => Icons.photo_camera_outlined,
        RecursoIa.macrosTexto => Icons.auto_awesome,
        RecursoIa.gerarTreino => Icons.fitness_center,
        RecursoIa.planoDieta => Icons.restaurant_menu,
      };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          const SizedBox(height: 22),
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: Icon(_icone, size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 18),
          Text(l.cota_limiteTitulo,
              textAlign: TextAlign.center,
              style: AppTypography.headlineSm
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(_mensagem(l),
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              )),
          const SizedBox(height: 22),
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
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cota_esperarAmanha,
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

/// Selo "2 de 3 hoje" para pôr ao lado do botão de IA.
///
/// Mostrar o saldo ANTES de acabar é o que separa limite de armadilha: a
/// pessoa decide se gasta a foto do dia agora ou guarda para o jantar.
class SeloDeCota extends StatelessWidget {
  final SaldoDeCota saldo;
  const SeloDeCota({super.key, required this.saldo});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final acabou = !saldo.ilimitado && !saldo.podeUsar;

    // Assinante também vê selo, dizendo "Sem limite no Pro". Esconder o selo
    // fazia "sou Pro" ficar visualmente idêntico a "a cota não funciona" — e
    // foi exatamente essa ambiguidade que atrapalhou o primeiro teste.
    final texto = saldo.ilimitado
        ? l.cota_semLimitePro
        : l.cota_restantesHoje(saldo.restantes, saldo.recurso.limiteGratis);

    final cor = saldo.ilimitado
        ? AppColors.primary
        : (acabou ? AppColors.warning : AppColors.onSurfaceVariant);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: saldo.ilimitado
            ? AppColors.primary.withOpacity(0.14)
            : (acabou
                ? AppColors.warning.withOpacity(0.16)
                : AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: AppTypography.labelSm.copyWith(fontSize: 9, color: cor),
      ),
    );
  }
}
