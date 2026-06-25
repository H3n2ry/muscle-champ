import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/firebase/firebase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

// ── Spotlight target ───────────────────────────────────────────────────────

enum SpotTarget {
  nav0, nav1, nav2, nav3, nav4, // bottom nav tabs
  pageTop,                       // ~22% of page body height
  pageMiddle,                    // ~50%
  pageBottom,                    // ~75%
}

// ── State ──────────────────────────────────────────────────────────────────

class TutorialState {
  final bool loading;
  final bool show;
  final int step;

  const TutorialState({this.loading = true, this.show = false, this.step = 0});

  TutorialState copyWith({bool? loading, bool? show, int? step}) =>
      TutorialState(
        loading: loading ?? this.loading,
        show: show ?? this.show,
        step: step ?? this.step,
      );
}

class TutorialNotifier extends StateNotifier<TutorialState> {
  TutorialNotifier() : super(const TutorialState()) {
    _init();
  }

  static const int totalSteps = 12;

  Future<void> _init() async {
    final uid = FB.auth.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(loading: false, show: false);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('tutorial_seen_$uid') ?? false;
    state = TutorialState(loading: false, show: !seen, step: 0);
  }

  void next() {
    if (state.step >= totalSteps - 1) {
      _complete();
      return;
    }
    state = state.copyWith(step: state.step + 1);
  }

  Future<void> skip() => _complete();

  Future<void> _complete() async {
    final uid = FB.auth.currentUser?.uid;
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tutorial_seen_$uid', true);
    }
    state = const TutorialState(loading: false, show: false);
  }
}

final tutorialProvider =
    StateNotifierProvider.autoDispose<TutorialNotifier, TutorialState>(
  (_) => TutorialNotifier(),
);

// ── Step definitions ───────────────────────────────────────────────────────

typedef _TStep = ({
  String route,
  SpotTarget target,
  String title,
  String body,
});

// 12 steps across 5 sections (INÍCIO 0-1, TREINO 2-3, DIETA 4-7, RANKING 8-9, PERFIL 10-11)
const List<_TStep> _kSteps = [
  // ── INÍCIO ─────────────────────────────────────
  (
    route: '/dashboard',
    target: SpotTarget.nav0,
    title: 'Bem-vindo ao Muscle Champ!',
    body:
        'Seu hub de fitness gamificado. Ganhe pontos treinando e comendo bem, e suba no ranking superando seus amigos.',
  ),
  (
    route: '/dashboard',
    target: SpotTarget.pageTop,
    title: 'Pontos, Rank e Streak',
    body:
        'Veja aqui seus pontos acumulados, posição no ranking global e entre amigos, e sua sequência de dias ativos.',
  ),
  // ── TREINO ─────────────────────────────────────
  (
    route: '/workout',
    target: SpotTarget.nav1,
    title: 'Treinos com IA',
    body:
        'Gere treinos personalizados com inteligência artificial ou registre treinos livres com séries, repetições e cargas.',
  ),
  (
    route: '/workout',
    target: SpotTarget.pageTop,
    title: 'Gerar Treino com IA',
    body:
        'Toque em "Gerar Treino", escolha o grupo muscular e a IA monta o plano completo com exercícios, séries e descanso.',
  ),
  // ── DIETA ──────────────────────────────────────
  (
    route: '/diet',
    target: SpotTarget.nav2,
    title: 'Dieta e Nutrição',
    body:
        'Registre tudo que você come — por texto ou foto — e a IA calcula calorias, proteínas, carboidratos e gorduras.',
  ),
  (
    route: '/diet',
    target: SpotTarget.pageTop,
    title: 'Registrar Refeição por Texto',
    body:
        'Descreva o que comeu ("100g frango grelhado + arroz branco") e a IA calcula os macros na hora.',
  ),
  (
    route: '/diet',
    target: SpotTarget.pageMiddle,
    title: 'Foto do Prato — Análise por IA',
    body:
        'Tire uma foto do seu prato e a IA identifica os alimentos e estima automaticamente os macros e calorias.',
  ),
  (
    route: '/diet',
    target: SpotTarget.pageBottom,
    title: 'Plano de Dieta com IA',
    body:
        'Gere um cardápio completo para o dia baseado nas suas metas. Troque alimentos com um toque — a IA recalcula os macros para manter as calorias.',
  ),
  // ── RANKING ────────────────────────────────────
  (
    route: '/ranking',
    target: SpotTarget.nav3,
    title: 'Ranking e Competição',
    body:
        'Dispute posições com todos os usuários do app. Cada treino registrado e meta de dieta atingida vale pontos!',
  ),
  (
    route: '/ranking',
    target: SpotTarget.pageTop,
    title: 'Ranking Global e Amigos',
    body:
        'Alterne entre o ranking global e o ranking só com seus amigos. Busque usuários pelo nome e mande solicitação de amizade.',
  ),
  // ── PERFIL ─────────────────────────────────────
  (
    route: '/profile',
    target: SpotTarget.nav4,
    title: 'Seu Perfil',
    body:
        'Configure seus dados físicos, defina metas e personalize sua foto de perfil para aparecer no ranking.',
  ),
  (
    route: '/profile',
    target: SpotTarget.pageMiddle,
    title: 'Metas e Bioimpedância',
    body:
        'Defina peso alvo, calorias diárias e objetivo (ganhar massa / perder peso / manter). Registre medidas de bioimpedância para acompanhar sua evolução corporal.',
  ),
];

// Returns 0-4 (which of the 5 nav sections this step belongs to)
int _sectionOf(int step) {
  if (step <= 1) return 0;
  if (step <= 3) return 1;
  if (step <= 7) return 2;
  if (step <= 9) return 3;
  return 4;
}

// ── Overlay widget ─────────────────────────────────────────────────────────

class TutorialOverlay extends StatefulWidget {
  final int step;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const TutorialOverlay({
    super.key,
    required this.step,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fade;
  late final AnimationController _pulse;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _fadeAnim = CurvedAnimation(parent: _fade, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _fade.forward();
    _pulse.repeat(reverse: true);

    // Navigate to step 0 route (should already be there, but just in case)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(_kSteps[widget.step].route);
    });
  }

  @override
  void didUpdateWidget(TutorialOverlay old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) {
      _fade.reset();
      _fade.forward();
      // Navigate when section changes
      final newRoute = _kSteps[widget.step].route;
      if (_kSteps[old.step].route != newRoute) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(newRoute);
        });
      }
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Offset _spotCenter(SpotTarget target, Size size, EdgeInsets padding) {
    const navH = 64.0;
    final tabW = size.width / 5;
    final botPad = padding.bottom;
    final topPad = padding.top;
    final bodyH = size.height - topPad - navH - botPad;

    switch (target) {
      case SpotTarget.nav0:
        return Offset(tabW * 0.5, size.height - botPad - navH / 2);
      case SpotTarget.nav1:
        return Offset(tabW * 1.5, size.height - botPad - navH / 2);
      case SpotTarget.nav2:
        return Offset(tabW * 2.5, size.height - botPad - navH / 2);
      case SpotTarget.nav3:
        return Offset(tabW * 3.5, size.height - botPad - navH / 2);
      case SpotTarget.nav4:
        return Offset(tabW * 4.5, size.height - botPad - navH / 2);
      case SpotTarget.pageTop:
        return Offset(size.width / 2, topPad + bodyH * 0.22);
      case SpotTarget.pageMiddle:
        return Offset(size.width / 2, topPad + bodyH * 0.50);
      case SpotTarget.pageBottom:
        return Offset(size.width / 2, topPad + bodyH * 0.75);
    }
  }

  double _spotRadius(SpotTarget target) =>
      target.name.startsWith('nav') ? 38.0 : 52.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    final s = _kSteps[widget.step];
    final spotCenter = _spotCenter(s.target, size, padding);
    final spotR = _spotRadius(s.target);
    final isLast = widget.step == TutorialNotifier.totalSteps - 1;
    final section = _sectionOf(widget.step);

    // Card layout
    const cardW = 272.0;
    final cardL =
        (spotCenter.dx - cardW / 2).clamp(8.0, size.width - cardW - 8.0);

    // Card is below the spotlight when the spotlight is in the upper 45% of screen
    final cardBelow = spotCenter.dy < size.height * 0.45;

    // Arrow horizontal alignment within card width
    final arrowAlignX =
        ((spotCenter.dx - cardL) / cardW * 2 - 1).clamp(-0.85, 0.85);

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // ── spotlight ──────────────────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => CustomPaint(
                  painter: _SpotlightPainter(
                    center: spotCenter,
                    innerR: spotR,
                    pulseT: _pulseAnim.value,
                  ),
                ),
              ),
            ),

            // ── card + arrow (spotlight in upper half → card below) ──
            if (cardBelow)
              Positioned(
                left: cardL,
                top: spotCenter.dy + spotR + 4,
                width: cardW,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment(arrowAlignX, 0),
                      child: CustomPaint(
                        size: const Size(16, 10),
                        painter: _UpArrowPainter(),
                      ),
                    ),
                    _TutorialCard(
                      title: s.title,
                      body: s.body,
                      step: widget.step,
                      section: section,
                      isLast: isLast,
                      onNext: widget.onNext,
                      onSkip: widget.onSkip,
                    ),
                  ],
                ),
              )
            // ── card + arrow (spotlight in lower half → card above) ──
            else
              Positioned(
                left: cardL,
                bottom: size.height - spotCenter.dy + spotR + 4,
                width: cardW,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TutorialCard(
                      title: s.title,
                      body: s.body,
                      step: widget.step,
                      section: section,
                      isLast: isLast,
                      onNext: widget.onNext,
                      onSkip: widget.onSkip,
                    ),
                    Align(
                      alignment: Alignment(arrowAlignX, 0),
                      child: CustomPaint(
                        size: const Size(16, 10),
                        painter: _DownArrowPainter(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────

class _TutorialCard extends StatelessWidget {
  final String title;
  final String body;
  final int step;
  final int section; // 0-4 (which nav section)
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TutorialCard({
    required this.title,
    required this.body,
    required this.step,
    required this.section,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  static const _sectionIcons = [
    Icons.bolt,            // INÍCIO
    Icons.fitness_center,  // TREINO
    Icons.restaurant,      // DIETA
    Icons.emoji_events,    // RANKING
    Icons.person,          // PERFIL
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.14),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section icons progress + step counter + skip
          Row(
            children: [
              // 5 section icon dots
              for (int i = 0; i < 5; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: i == section ? 22 : 18,
                  height: i == section ? 22 : 18,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: i < section
                        ? AppColors.primary.withOpacity(0.35)
                        : i == section
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _sectionIcons[i],
                    size: i == section ? 13 : 11,
                    color: i == section
                        ? Colors.black
                        : i < section
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.5),
                  ),
                ),

              const Spacer(),

              // Step counter
              Text(
                '${step + 1}/${TutorialNotifier.totalSteps}',
                style: AppTypography.labelSm.copyWith(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),

              // Skip
              GestureDetector(
                onTap: onSkip,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'PULAR',
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: AppTypography.headlineSm.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            body,
            style: AppTypography.bodyMd.copyWith(
              fontSize: 13,
              height: 1.45,
              color: AppColors.onSurface.withOpacity(0.82),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                isLast ? 'COMEÇAR!' : 'PRÓXIMO  →',
                style: AppTypography.labelSm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painters ───────────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Offset center;
  final double innerR;
  final double pulseT; // 0..1

  const _SpotlightPainter({
    required this.center,
    required this.innerR,
    required this.pulseT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xC8000000),
    );

    // Pulsing glow ring
    final pulseR = innerR + 6 + 14 * pulseT;
    canvas.drawCircle(
      center,
      pulseR,
      Paint()
        ..color = AppColors.primary.withOpacity(0.16 * (1 - pulseT))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Cut spotlight hole
    canvas.drawCircle(center, innerR, Paint()..blendMode = BlendMode.clear);

    canvas.restore();

    // Lime ring (drawn outside saveLayer so it's always visible)
    canvas.drawCircle(
      center,
      innerR + 2,
      Paint()
        ..color = AppColors.primary.withOpacity(0.45 + 0.3 * pulseT)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.center != center || old.innerR != innerR || old.pulseT != pulseT;
}

class _DownArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.surfaceContainerLow);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_DownArrowPainter _) => false;
}

class _UpArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.surfaceContainerLow);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_UpArrowPainter _) => false;
}
