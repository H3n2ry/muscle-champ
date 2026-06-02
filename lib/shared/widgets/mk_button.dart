import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class MkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool _outlined;

  const MkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  }) : _outlined = false;

  const MkButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  }) : _outlined = true;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onPrimary,
            ),
          )
        : Text(label.toUpperCase(), style: AppTypography.labelMd);

    if (_outlined) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(onPressed: onPressed, child: child),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(onPressed: onPressed, child: child),
    );
  }
}
