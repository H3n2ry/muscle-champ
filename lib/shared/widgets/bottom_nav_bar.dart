import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'tutorial_overlay.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    (path: '/dashboard', icon: Icons.bolt,           label: 'INÍCIO'),
    (path: '/workout',   icon: Icons.fitness_center,  label: 'TREINO'),
    (path: '/diet',      icon: Icons.restaurant,      label: 'DIETA'),
    (path: '/ranking',   icon: Icons.emoji_events,    label: 'RANKING'),
    (path: '/profile',   icon: Icons.person,          label: 'PERFIL'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final tutorialState = ref.watch(tutorialProvider);

    final scaffold = Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: const Border(
            top: BorderSide(color: AppColors.surfaceContainerHigh, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final active = i == currentIndex;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(_tabs[i].path),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: active
                              ? BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                )
                              : null,
                          child: Icon(
                            _tabs[i].icon,
                            size: 22,
                            color: active
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _tabs[i].label,
                          style: AppTypography.labelSm.copyWith(
                            fontSize: 9,
                            color: active
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );

    // Show tutorial overlay for new users on first login
    if (tutorialState.loading || !tutorialState.show) return scaffold;

    return Stack(
      children: [
        scaffold,
        Positioned.fill(
          child: TutorialOverlay(
            step: tutorialState.step,
            onNext: () => ref.read(tutorialProvider.notifier).next(),
            onSkip: () => ref.read(tutorialProvider.notifier).skip(),
          ),
        ),
      ],
    );
  }
}
