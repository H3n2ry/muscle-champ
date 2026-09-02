import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import '../../core/auth/completude_do_perfil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../features/subscription/presentation/widgets/paywall_popup.dart';
import 'barra_liquida.dart';
import 'tutorial_overlay.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {

  /// As tres secoes que vivem dentro do botao central.
  static List<DestinoRadial> _destinos(BuildContext c) => [
        DestinoRadial(
            rota: '/workout',
            icone: Icons.fitness_center,
            rotulo: L.of(c).navTreino),
        DestinoRadial(
            rota: '/diet', icone: Icons.restaurant, rotulo: L.of(c).navDieta),
        DestinoRadial(
            rota: '/ranking',
            icone: Icons.emoji_events,
            rotulo: L.of(c).navRanking),
      ];

  /// 0 = casa · 1 = centro · 2 = perfil.
  ///
  /// Treino, Dieta e Ranking devolvem 1: nao tem alvo proprio na barra, entao
  /// o botao central representa "onde voce esta" enquanto se navega por eles.
  int _indiceAtivo(String rota) {
    if (rota.startsWith('/profile')) return 2;
    if (rota.startsWith('/dashboard')) return 0;
    return 1;
  }

  /// Icone que o botao central assume. Nulo na home e no perfil, onde ele
  /// volta a ser o "+".
  IconData? _iconeCentral(String rota, BuildContext c) {
    for (final d in _destinos(c)) {
      if (rota.startsWith(d.rota)) return d.icone;
    }
    return null;
  }

  /// Esconde a barra ao rolar para baixo, mostra ao rolar para cima.
  bool _barraVisivel = true;

  bool _aoRolar(UserScrollNotification n) {
    // So o eixo vertical da tela inteira interessa; listas horizontais dentro
    // das paginas (carrossel de treinos) nao devem mexer na barra.
    if (n.metrics.axis != Axis.vertical) return false;
    final visivel = switch (n.direction) {
      ScrollDirection.reverse => false,
      ScrollDirection.forward => true,
      ScrollDirection.idle => _barraVisivel,
    };
    if (visivel != _barraVisivel) setState(() => _barraVisivel = visivel);
    return false;
  }

  /// Dispara a checagem de completude e leva para /completar-perfil quando
  /// falta algo.
  ///
  /// O `ref.listen` so reage a MUDANCA de estado — diferente de navegar direto
  /// do `build`, que foi a primeira versao e entrou em laco: cada rebuild
  /// agendava outra navegacao, e a navegacao causava rebuild.
  ///
  /// Quem impede voltar para as abas depois e o `redirect` do GoRouter, lendo
  /// `PerfilIncompleto.valor`. Este listen so cobre o primeiro momento, quando
  /// a resposta do banco ainda nao existia e o redirect nao tinha o que decidir.
  void _ouveCompletude() {
    ref.listen<AsyncValue<CompletudeDoPerfil>>(completudeDoPerfilProvider,
        (_, proximo) {
      final c = proximo.valueOrNull;
      if (c != null && !c.completo && mounted) {
        context.go('/completar-perfil');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _ouveCompletude();
    final rota = GoRouterState.of(context).matchedLocation;
    final indiceAtivo = _indiceAtivo(rota);
    final tutorialState = ref.watch(tutorialProvider);

    // Convite ao Pro a cada abertura, para quem nao assina. Espera o tutorial
    // terminar: os dois juntos numa conta nova seria uma parede de modais.
    if (!tutorialState.loading && !tutorialState.show) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) talvezMostrarConvitePro(context, ref);
      });
    }

    final scaffold = Scaffold(
      // `extendBody` deixa o conteudo passar POR BAIXO da barra — sem isso o
      // vidro nao teria o que borrar e o efeito sumiria.
      extendBody: true,
      // A barra vai no BODY, nao em `bottomNavigationBar`. O menu radial abre
      // ACIMA dela, e um filho de bottomNavigationBar nao recebe toque fora da
      // propria caixa — os botoes do arco apareciam e nao clicavam.
      body: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: _aoRolar,
            child: widget.child,
          ),
          Positioned.fill(
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              offset: _barraVisivel ? Offset.zero : const Offset(0, 0.35),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _barraVisivel ? 1 : 0,
                child: SafeArea(
                  top: false,
                  child: BarraLiquida(
                    indiceAtivo: indiceAtivo,
                    iconeCentral: _iconeCentral(rota, context),
                    destinos: _destinos(context),
                    rotuloCasa: L.of(context).navInicio,
                    rotuloPerfil: L.of(context).navPerfil,
                    onNavegar: context.go,
                  ),
                ),
              ),
            ),
          ),
        ],
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
