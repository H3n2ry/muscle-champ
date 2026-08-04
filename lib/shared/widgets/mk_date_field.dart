import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Campo de data no estilo Obsidian Kinetic. Ao tocar, abre um seletor de data
/// (dark). Usado para a data de nascimento no cadastro e na edição de perfil.
class MkDateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hint;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const MkDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'DD/MM/AAAA',
    this.errorText,
    this.firstDate,
    this.lastDate,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: firstDate ?? DateTime(1920),
      lastDate: lastDate ?? now,
      helpText: 'DATA DE NASCIMENTO',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            surface: AppColors.surfaceContainerLow,
            onSurface: AppColors.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _pick(context),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    hasError ? AppColors.error : AppColors.surfaceContainerHigh,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined,
                    size: 18, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 12),
                Text(
                  value != null ? _fmt(value!) : hint,
                  style: AppTypography.bodyMd.copyWith(
                    color: value != null
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(errorText!,
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.error, fontSize: 12)),
          ),
      ],
    );
  }
}
