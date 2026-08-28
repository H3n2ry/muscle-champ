import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/plano.dart';
import '../widgets/demo_banner.dart';

/// Confirmação da assinatura.
///
/// Repete a data e o valor da primeira cobrança de propósito. É a última tela
/// onde o usuário ainda está prestando atenção, e "não vi que ia cobrar" é o
/// motivo número um de chargeback em assinatura com trial.
class AssinaturaSucessoPage extends ConsumerStatefulWidget {
  final Plano plano;
  const AssinaturaSucessoPage({super.key, required this.plano});

  @override
  ConsumerState<AssinaturaSucessoPage> createState() =>
      _AssinaturaSucessoPageState();
}

class _AssinaturaSucessoPageState extends ConsumerState<AssinaturaSucessoPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String get _data {
    final d = DateTime.now().add(const Duration(days: Planos.diasDeTrial));
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const DemoBanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: CurvedAnimation(
                        parent: _anim,
                        curve: Curves.elasticOut,
                      ),
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.14),
                          border:
                              Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Icon(Icons.check_rounded,
                            size: 48, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(l.suc_titulo,
                        textAlign: TextAlign.center,
                        style: AppTypography.display.copyWith(
                          fontSize: 26,
                          color: AppColors.primary,
                        )),
                    const SizedBox(height: 8),
                    Text(l.suc_bemVindo,
                        style: AppTypography.bodyLg
                            .copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.surfaceContainerHigh),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event_available_outlined,
                                  size: 15,
                                  color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(l.suc_trialAte(_data),
                                    style: AppTypography.bodySm.copyWith(
                                        color: AppColors.onSurface)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.payments_outlined,
                                  size: 15,
                                  color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                    l.suc_primeiraCobranca(
                                        formatarBRL(widget.plano.entrada),
                                        _data),
                                    style: AppTypography.bodySm.copyWith(
                                        color: AppColors.onSurfaceVariant)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l.suc_comecar,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
