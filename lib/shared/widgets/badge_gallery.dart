/// Galeria de conquistas.
///
/// Saiu de dentro de `profile_page` quando o perfil público passou a mostrar
/// as mesmas conquistas: duas cópias significariam alguém desbloquear uma
/// medalha no próprio perfil e não vê-la no que os outros enxergam.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';

class BadgeGallery extends StatelessWidget {
  final int totalPoints;
  final int totalWorkouts;
  final int streak;

  const BadgeGallery({
    super.key,
    required this.totalPoints,
    required this.totalWorkouts,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final badges = [
      _Badge(
          icon: Icons.fitness_center,
          label: l.conq_primeiroTreino,
          unlocked: totalWorkouts >= 1),
      _Badge(
          icon: Icons.local_fire_department,
          label: l.perfil_sequencia7Dias,
          unlocked: streak >= 7),
      _Badge(
          icon: Icons.bolt,
          label: l.conq_100pontos,
          unlocked: totalPoints >= 100),
      _Badge(
          icon: Icons.emoji_events,
          label: l.conq_10treinos,
          unlocked: totalWorkouts >= 10),
      _Badge(
          icon: Icons.star,
          label: l.conq_500pontos,
          unlocked: totalPoints >= 500),
      _Badge(
          icon: Icons.military_tech,
          label: l.conq_muscleChamp,
          unlocked: totalPoints >= 1000),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: badges.map((b) => _BadgeTile(badge: b)).toList(),
    );
  }
}

class _Badge {
  final IconData icon;
  final String label;
  final bool unlocked;
  const _Badge(
      {required this.icon, required this.label, required this.unlocked});
}

class _BadgeTile extends StatelessWidget {
  final _Badge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: badge.unlocked
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badge.unlocked
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.surfaceContainerHigh,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badge.icon,
              size: 26,
              color: badge.unlocked
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 6),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            style: AppTypography.labelSm.copyWith(
              fontSize: 9,
              color: badge.unlocked
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
