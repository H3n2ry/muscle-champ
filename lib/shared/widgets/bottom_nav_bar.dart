import 'package:flutter/material.dart';
import '../../core/auth/completude_do_perfil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../features/subscription/presentation/widgets/paywall_popup.dart';
import 'tutorial_overlay.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {

  // Só rota e ícone ficam aqui; o rótulo vem da tradução no build, porque
  // uma lista `const` não pode chamar L.of(context).
  static const _tabs = [
    (path: '/dashboard', icon: Icons.bolt),
    (path: '/workout',   icon: Icons.fitness_center),
    (path: '/diet',      icon: Icons.restaurant),
    (path: '/ranking',   icon: Icons.emoji_events),
    (path: '/profile',   icon: Icons.person),
  ];

  static List<String> _labels(BuildContext c) => [
        L.of(c).navInicio,
        L.of(c).navTreino,
        L.of(c).navDieta,
        L.of(c).navRanking,
        L.of(c).navPerfil,
      ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  /// Impede usar o app com perfil incompleto.
  ///
  /// Mora aqui, e nao no `redirect` do GoRouter, porque a checagem consulta o
  /// banco e o `redirect` e SINCRONO — nao da para aguardar ali dentro. Como o
  /// MainScaffold embrulha as cinco abas, toda entrada no app passa por este
  /// ponto.
  ///
  /// So dispara quando a resposta chegou (`valueOrNull`): enquanto carrega, o
  /// app aparece normalmente. O custo e um piscar para quem esta incompleto —
  /// preferivel a segurar a interface inteira num spinner por causa de uma
  /// condicao que quase ninguem tem.
  void _guardaPerfilIncompleto() {
    final completude = ref.watch(completudeDoPerfilProvider).valueOrNull;
    if (completude == null || completude.completo) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/completar-perfil');
    });
  }

  @override
  Widget build(BuildContext context) {
    _guardaPerfilIncompleto();
    final currentIndex = _currentIndex(context);
    final tutorialState = ref.watch(tutorialProvider);

    // Convite ao Pro a cada abertura, para quem nao assina. Espera o tutorial
    // terminar: os dois juntos numa conta nova seria uma parede de modais.
    if (!tutorialState.loading && !tutorialState.show) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) talvezMostrarConvitePro(context, ref);
      });
    }

    final scaffold = Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          border: Border(
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
                          _labels(context)[i],
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
