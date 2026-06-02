import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;

  const MkCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(
          color: borderColor ?? AppColors.surfaceContainerHigh,
        ),
      ),
      child: child,
    );
  }
}
