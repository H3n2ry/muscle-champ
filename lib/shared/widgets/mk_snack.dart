import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Snackbars padronizados no design Obsidian Kinetic.
abstract class MkSnack {
  MkSnack._();

  /// ✅ Sucesso — fundo lime, texto dark.
  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.onPrimary,
      textColor: AppColors.onPrimary,
      bg: AppColors.primary,
      duration: const Duration(seconds: 3),
    );
  }

  /// ❌ Erro — fundo vermelho escuro, texto vermelho claro.
  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.error,
      textColor: AppColors.error,
      bg: AppColors.errorContainer,
      duration: const Duration(seconds: 4),
    );
  }

  /// ℹ️ Info — fundo surface, texto padrão.
  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.onSurfaceVariant,
      textColor: AppColors.onSurface,
      bg: AppColors.surfaceContainerHighest,
      duration: const Duration(seconds: 3),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
    required Color bg,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodySm.copyWith(
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: duration,
          elevation: 4,
        ),
      );
  }
}
