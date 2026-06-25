import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../providers/dashboard_provider.dart';
import '../../../../features/dashboard/data/models/dashboard_model.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Agenda o popup para depois do primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMondayWeightPrompt();
    });
  }

  Future<void> _checkMondayWeightPrompt() async {
    final now = DateTime.now();
    if (now.weekday != DateTime.monday) return;

    final prefs    = await SharedPreferences.getInstance();
    const key      = 'last_weight_prompt_monday';
    final todayStr = now.toIso8601String().substring(0, 10);
    if (prefs.getString(key) == todayStr) return;   // já exibiu hoje

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await _showWeightDialog();
    await prefs.setString(key, todayStr);
  }

  Future<void> _showWeightDialog() async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          return Dialog(
            backgroundColor: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.monitor_weight_outlined,
                          color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text('ATUALIZAÇÃO\nSEMANAL',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMd.copyWith(
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('Registre seu peso desta semana\npara acompanhar sua evolução.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    // Campo peso
                    TextFormField(
                      controller: ctrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: AppTypography.headlineMd.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val <= 0) return 'Peso inválido';
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: '80.0',
                        hintStyle: AppTypography.headlineMd.copyWith(
                            color: AppColors.onSurfaceVariant),
                        suffixText: 'kg',
                        suffixStyle: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurfaceVariant),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.surfaceContainerHigh),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.surfaceContainerHigh),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // Pular
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.surfaceContainerHigh),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('PULAR',
                                style: AppTypography.labelMd.copyWith(
                                    color: AppColors.onSurfaceVariant)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Salvar
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate())
                                      return;
                                    setSt(() => saving = true);
                                    try {
                                      final weight =
                                          double.parse(ctrl.text);
                                      await ref
                                          .read(profileRepositoryProvider)
                                          .updateWeight(weight);
                                      ref.invalidate(dashboardProvider);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Peso registrado: ${weight.toStringAsFixed(1)} kg'),
                                          backgroundColor: AppColors.primary,
                                          behavior:
                                              SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ));
                                      }
                                    } finally {
                                      if (ctx.mounted)
                                        setSt(() => saving = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                            ),
                            child: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.onPrimary))
                                : Text('SALVAR',
                                    style: AppTypography.labelMd.copyWith(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.w700,
                                    )),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user      = ref.watch(currentUserProvider).valueOrNull
                   ?? ref.watch(authControllerProvider).valueOrNull;
    final dashboard = ref.watch(dashboardProvider);

    final pendingCount =
        ref.watch(pendingRequestsCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header fixo (não rola) ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  // Nome
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BEM-VINDO,',
                          style: AppTypography.labelSm
                              .copyWith(letterSpacing: 2)),
                      Text(
                        user?.name.toUpperCase() ?? '---',
                        style: AppTypography.headlineLg.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Sino de notificações
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: pendingCount > 0
                                  ? AppColors.primary.withOpacity(0.6)
                                  : AppColors.surfaceContainerHigh,
                            ),
                          ),
                          child: Icon(
                            pendingCount > 0
                                ? Icons.notifications
                                : Icons.notifications_outlined,
                            color: pendingCount > 0
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                        if (pendingCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  pendingCount > 9 ? '9+' : '$pendingCount',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onPrimary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: AppColors.primary, width: 2),
                          shape: BoxShape.circle,
                          color: AppColors.surfaceContainer,
                        ),
                        child: user?.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(user!.avatarUrl!,
                                    fit: BoxFit.cover))
                            : const Icon(Icons.person,
                                color: AppColors.primary, size: 24),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('LVL 1',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 8,
                              )),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Conteúdo rolável ─────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceContainer,
                onRefresh: () => ref.refresh(dashboardProvider.future),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const SizedBox(height: 28),

                      dashboard.when(
                        loading: () => const _DashboardSkeleton(),
                        error:   (e, _) => _ErrorState(message: e.toString()),
                        data:    (data) => _DashboardContent(
                          data: data,
                          userName: user?.name ?? '',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final DashboardModel data;
  final String userName;
  const _DashboardContent({required this.data, required this.userName});

  double get _dailyProgress {
    int done = 0;
    if (data.workoutDoneToday) done++;
    if (data.dietGoalMetToday) done++;
    return done / 2.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero: Big circular progress ────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceContainerLow,
                  AppColors.surfaceContainerLowest,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.25), width: 1),
            ),
            child: Column(
              children: [
                // Circular progress + rank chips row
                Row(
                  children: [
                    // Large circle
                    _BigCircle(progress: _dailyProgress),
                    const SizedBox(width: 24),
                    // Right side info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MISSÃO DIÁRIA',
                              style: AppTypography.labelSm.copyWith(
                                letterSpacing: 2,
                                color: AppColors.onSurfaceVariant,
                              )),
                          const SizedBox(height: 6),
                          Text(
                            _dailyProgress == 1.0
                                ? 'Concluída!'
                                : _dailyProgress == 0.0
                                    ? 'Começe agora'
                                    : 'Em progresso',
                            style: AppTypography.headlineSm.copyWith(
                              color: AppColors.onSurface,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RankChip(
                              icon: Icons.public,
                              label: '#${data.globalRank} Global'),
                          const SizedBox(height: 8),
                          _RankChip(
                              icon: Icons.bolt,
                              label:
                                  '${data.totalPoints} pts',
                              accent: true),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Mini macros row
                Row(
                  children: [
                    _MiniStat(
                      label: 'TREINOS\nSEMANA',
                      value: '${data.weeklyWorkouts}',
                      max: '${data.weeklyWorkoutGoal}',
                    ),
                    const SizedBox(width: 1),
                    _MiniDivider(),
                    const SizedBox(width: 1),
                    _MiniStat(
                      label: 'PESO\nATUAL',
                      value: '${data.currentWeight.toStringAsFixed(1)}',
                      max: 'kg',
                    ),
                    const SizedBox(width: 1),
                    _MiniDivider(),
                    const SizedBox(width: 1),
                    _MiniStat(
                      label: 'META\nPESO',
                      value: '${data.targetWeight.toStringAsFixed(1)}',
                      max: 'kg',
                      accent: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── Daily Protocols ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('PROTOCOLOS DIÁRIOS',
              style: AppTypography.labelSm.copyWith(
                letterSpacing: 2,
                color: AppColors.onSurfaceVariant,
              )),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: _ProtocolCard(
                  icon: Icons.fitness_center,
                  title: 'TREINO',
                  done: data.workoutDoneToday,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ProtocolCard(
                  icon: Icons.restaurant,
                  title: 'DIETA',
                  done: data.dietGoalMetToday,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Weekly progress ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text('PROGRESSO SEMANAL',
              style: AppTypography.labelSm.copyWith(
                letterSpacing: 2,
                color: AppColors.onSurfaceVariant,
              )),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.surfaceContainerHigh),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Treinos Completados',
                        style: AppTypography.bodyMd),
                    Text(
                      '${data.weeklyWorkouts} / ${data.weeklyWorkoutGoal}',
                      style: AppTypography.headlineSm
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: data.weeklyWorkoutGoal > 0
                        ? (data.weeklyWorkouts /
                                data.weeklyWorkoutGoal)
                            .clamp(0.0, 1.0)
                        : 0,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    data.weeklyWorkoutGoal.clamp(0, 7),
                    (i) => Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: i < data.weeklyWorkouts
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: i < data.weeklyWorkouts
                          ? const Icon(Icons.check,
                              color: AppColors.onPrimary, size: 16)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Point history chart ────────────────────────────────────
        if (data.pointHistory.isNotEmpty) ...[
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('HISTÓRICO DE PONTOS',
                style: AppTypography.labelSm.copyWith(
                  letterSpacing: 2,
                  color: AppColors.onSurfaceVariant,
                )),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.surfaceContainerHigh),
              ),
              child: _PointHistoryChart(
                  history: data.pointHistory),
            ),
          ),
        ],

        // ── Next Milestone ─────────────────────────────────────────
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _NextMilestoneCard(points: data.totalPoints),
        ),

        // bottom padding that clears the nav bar on all devices
        SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

// ── Big circle widget ─────────────────────────────────────────────────────────

class _BigCircle extends StatelessWidget {
  final double progress;
  const _BigCircle({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 9,
              backgroundColor:
                  AppColors.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation(
                  AppColors.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pct%',
                style: AppTypography.headlineLg.copyWith(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('completo',
                  style: AppTypography.labelSm.copyWith(
                    fontSize: 10,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Rank chip ─────────────────────────────────────────────────────────────────

class _RankChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool accent;
  const _RankChip(
      {required this.icon, required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: accent
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label,
              style: AppTypography.labelSm.copyWith(
                color: accent
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontSize: 11,
              )),
        ],
      ),
    );
  }
}

// ── Mini stat ─────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String max;
  final bool accent;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.max,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headlineMd.copyWith(
              color:
                  accent ? AppColors.primary : AppColors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(max,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              )),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTypography.labelSm.copyWith(
                fontSize: 9,
                letterSpacing: 0.5,
              )),
        ],
      ),
    );
  }
}

class _MiniDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 40, color: AppColors.surfaceContainerHigh);
  }
}

// ── Protocol card ─────────────────────────────────────────────────────────────

class _ProtocolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool done;
  const _ProtocolCard({
    required this.icon,
    required this.title,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done
            ? AppColors.primary.withOpacity(0.08)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? AppColors.primary.withOpacity(0.6)
              : AppColors.surfaceContainerHigh,
          width: done ? 1.5 : 1,
        ),
        boxShadow: done
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 14,
                  spreadRadius: 0,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  done ? Icons.emoji_events : icon,
                  size: 22,
                  color: done
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
              if (done)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: AppColors.onPrimary, size: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: AppTypography.labelMd.copyWith(letterSpacing: 1)),
          const SizedBox(height: 6),
          if (done)
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.primary, size: 12),
                const SizedBox(width: 4),
                Text(
                  'CONQUISTADO',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            )
          else
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                '+10 PTS',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Point history chart ───────────────────────────────────────────────────────

class _PointHistoryChart extends StatelessWidget {
  final List<PointHistoryEntry> history;
  const _PointHistoryChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final maxPts = history.fold<int>(
        1, (m, e) => e.points > m ? e.points : m);

    return BarChart(
      BarChartData(
        maxY: maxPts * 1.3,
        barGroups: history.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.points.toDouble(),
                color: AppColors.primary,
                width: 10,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i >= history.length) return const SizedBox();
                final day = history[i].date.substring(8);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(day,
                      style: AppTypography.labelSm
                          .copyWith(fontSize: 9)),
                );
              },
              reservedSize: 22,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.surfaceContainerHigh,
            strokeWidth: 1,
          ),
        ),
      ),
    );
  }
}

// ── Next Milestone card ───────────────────────────────────────────────────────

class _NextMilestoneCard extends StatelessWidget {
  final int points;
  const _NextMilestoneCard({required this.points});

  @override
  Widget build(BuildContext context) {
    // Milestones at every 100
    final nextMilestone = ((points ~/ 100) + 1) * 100;
    final progress = points / nextMilestone;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.military_tech,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('PRÓXIMO MARCO',
                  style: AppTypography.labelSm.copyWith(
                    letterSpacing: 2,
                    color: AppColors.primary,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$points pts',
                  style: AppTypography.headlineSm),
              Text('$nextMilestone pts',
                  style: AppTypography.headlineSm
                      .copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${nextMilestone - points} pontos para o próximo nível',
            style: AppTypography.bodySm,
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _shimmer(height: 200, radius: 24),
          const SizedBox(height: 16),
          _shimmer(height: 100, radius: 16),
          const SizedBox(height: 16),
          _shimmer(height: 120, radius: 16),
        ],
      ),
    );
  }

  Widget _shimmer({required double height, double radius = 8}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.wifi_off,
              color: AppColors.onSurfaceVariant, size: 48),
          const SizedBox(height: 16),
          Text('Erro ao carregar',
              style: AppTypography.headlineSm),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm),
        ],
      ),
    );
  }
}
