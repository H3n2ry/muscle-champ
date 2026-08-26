import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Banner de erro inline com animação de altura.
/// Passe [message] como null para esconder o banner.
/// Passe [onDismiss] para mostrar o botão X.
class MkErrorBanner extends StatelessWidget {
  final String? message;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry padding;

  const MkErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.padding = const EdgeInsets.only(top: 14),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      child: message != null
          ? Padding(
              padding: padding,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.error_outline,
                          color: AppColors.error, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message!,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.error,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (onDismiss != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDismiss,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.close,
                              color: AppColors.error, size: 15),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Estado de erro para tela inteira (ex: falha ao carregar dados).
class MkErrorState extends StatelessWidget {
  /// Nulo = usa o texto padrão traduzido. Não dá para pôr o default aqui:
  /// valor de parâmetro precisa ser constante, e a tradução depende do context.
  final String? title;
  final String? subtitle;
  final VoidCallback? onRetry;

  const MkErrorState({
    super.key,
    this.title,
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: const Icon(Icons.cloud_off_outlined,
                  color: AppColors.onSurfaceVariant, size: 30),
            ),
            const SizedBox(height: 18),
            Text(
              title ?? L.of(context).comum_algoDeuErrado,
              style: AppTypography.bodyLg
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle ?? L.of(context).erro_verifiqueConexao,
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(L.of(context).comum_tentarNovamente),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: AppTypography.labelSm.copyWith(
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
