import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/groq/groq_config.dart';
import '../../../../core/groq/groq_service.dart';
import '../../data/datasources/food_database.dart';
import '../../data/models/diet_model.dart';
import '../providers/diet_provider.dart';

// ── Modo de entrada de refeição ───────────────────────────────────────────────

enum _MealInputMode { banco, ia, foto }

// ── Diet Page ─────────────────────────────────────────────────────────────────

class DietPage extends ConsumerWidget {
  const DietPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dietControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: summary.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
              child: Text('Erro ao carregar dieta',
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.error))),
          data: (data) => _DietContent(
            data: data,
            onAdd: () => _showAddMealSheet(context, ref),
            onDelete: (id) =>
                ref.read(dietControllerProvider.notifier).deleteMeal(id),
          ),
        ),
      ),
    );
  }

  void _showAddMealSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SmartMealSheet(
        onSave: (mealData) async {
          await ref.read(dietControllerProvider.notifier).addMeal(mealData);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _DietContent extends StatelessWidget {
  final DietSummaryModel? data;
  final VoidCallback onAdd;
  final void Function(String id) onDelete;

  const _DietContent({
    required this.data,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (data == null) return _EmptyDiet(onAdd: onAdd);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NUTRIÇÃO',
                        style: AppTypography.labelSm.copyWith(
                            letterSpacing: 2,
                            color: AppColors.onSurfaceVariant)),
                    Text('DIETA',
                        style: AppTypography.headlineLg.copyWith(
                            fontSize: 28, fontWeight: FontWeight.w700)),
                  ],
                ),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add,
                        color: AppColors.onPrimary, size: 24),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── AI banner ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED).withOpacity(0.15),
                      AppColors.primary.withOpacity(0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Color(0xFF7C3AED), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('IA ATIVA',
                              style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 10,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            'Digite qualquer alimento ou tire uma foto',
                            style: AppTypography.bodySm
                                .copyWith(color: AppColors.onSurface, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Color(0xFF7C3AED), size: 14),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Calorie hero card ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    data!.goalMet
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.surfaceContainerLow,
                    AppColors.surfaceContainerLowest,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: data!.goalMet
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.surfaceContainerHigh,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('CALORIAS DO DIA',
                          style: AppTypography.labelSm
                              .copyWith(letterSpacing: 2)),
                      const Spacer(),
                      if (data!.goalMet)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('META +10 PTS',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 10,
                              )),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${data!.totalCalories}',
                          style: AppTypography.headlineLg.copyWith(
                            color: AppColors.primary,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                          )),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(' / ${data!.goalCalories} kcal',
                            style: AppTypography.bodyMd
                                .copyWith(color: AppColors.onSurfaceVariant)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: data!.calorieProgress,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Gráficos circulares de macros ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MACROS DO DIA',
                    style: AppTypography.labelSm
                        .copyWith(letterSpacing: 2, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MacroRing(
                      label: 'PROTEÍNA',
                      current: data!.totalProtein,
                      goal: data!.goalProtein,
                      color: const Color(0xFF5B8DF6),
                    ),
                    const SizedBox(width: 12),
                    _MacroRing(
                      label: 'CARBOIDRATO',
                      current: data!.totalCarbs,
                      goal: data!.goalCarbs,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    _MacroRing(
                      label: 'GORDURA',
                      current: data!.totalFat,
                      goal: data!.goalFat,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Plano do Dia IA ───────────────────────────────────────────
          _AiDietSection(
            goalCalories: data!.goalCalories,
            goalType:     data!.goalType ?? 'maintain',
            goalProtein:  data!.goalProtein,
            goalCarbs:    data!.goalCarbs,
            goalFat:      data!.goalFat,
          ),

          const SizedBox(height: 24),

          // ── Refeições logadas ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('REFEIÇÕES DO DIA',
                style: AppTypography.labelSm.copyWith(
                    letterSpacing: 2, color: AppColors.onSurfaceVariant)),
          ),
          const SizedBox(height: 12),

          if (data!.meals.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.restaurant,
                        color: AppColors.onSurfaceVariant, size: 40),
                    const SizedBox(height: 12),
                    Text('Nenhuma refeição registrada hoje',
                        style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            ...data!.meals.map((meal) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: _MealCard(
                    meal: meal,
                    onDelete: () => onDelete(meal.id),
                  ),
                )),

          SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MACRO RING — gráfico circular animado
// ─────────────────────────────────────────────────────────────────────────────

class _MacroRing extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final Color color;

  const _MacroRing({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final exceeded = goal > 0 && current > goal;

    return Expanded(
      child: Column(
        children: [
          // Anel animado
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) {
              return LayoutBuilder(
                builder: (_, constraints) {
                  final size = constraints.maxWidth.clamp(60.0, 110.0);
                  return SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size(size, size),
                          painter: _RingPainter(
                            progress: value,
                            color: exceeded ? const Color(0xFFFF6B6B) : color,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: current.toInt().toString(),
                                    style: TextStyle(
                                      color: exceeded
                                          ? const Color(0xFFFF6B6B)
                                          : color,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'g',
                                    style: TextStyle(
                                      color: (exceeded
                                              ? const Color(0xFFFF6B6B)
                                              : color)
                                          .withOpacity(0.7),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '/${goal.toInt()}g',
                              style: AppTypography.labelSm.copyWith(
                                fontSize: 9,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelSm
                .copyWith(fontSize: 9, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;

  static const _strokeWidth = 7.0;

  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _strokeWidth / 2;

    // Track de fundo
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withOpacity(0.12)
        ..strokeWidth = _strokeWidth
        ..style = PaintingStyle.stroke,
    );

    if (progress <= 0) return;

    // Arco de progresso
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // começa no topo
      progress * 2 * pi,
      false,
      Paint()
        ..color = color
        ..strokeWidth = _strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// SEÇÃO PLANO IA
// ─────────────────────────────────────────────────────────────────────────────

class _AiDietSection extends ConsumerWidget {
  final int    goalCalories;
  final String goalType;
  final double goalProtein;
  final double goalCarbs;
  final double goalFat;

  const _AiDietSection({
    required this.goalCalories,
    required this.goalType,
    required this.goalProtein,
    required this.goalCarbs,
    required this.goalFat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planState = ref.watch(aiDietPlanProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header da seção ──────────────────────────────────────────
          Row(
            children: [
              Text('PLANO DO DIA',
                  style: AppTypography.labelSm.copyWith(
                      letterSpacing: 2, color: AppColors.onSurfaceVariant)),
              const Spacer(),
              if (planState.plan != null)
                GestureDetector(
                  onTap: () => ref
                      .read(aiDietPlanProvider.notifier)
                      .generate(goalCalories, goalType,
                          goalProtein: goalProtein,
                          goalCarbs: goalCarbs,
                          goalFat: goalFat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF7C3AED).withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh,
                            color: Color(0xFF7C3AED), size: 12),
                        const SizedBox(width: 4),
                        Text('REGENERAR',
                            style: AppTypography.labelSm.copyWith(
                              color: Color(0xFF7C3AED),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Estados ──────────────────────────────────────────────────

          // Carregando
          if (planState.isLoading)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: const Column(
                children: [
                  CircularProgressIndicator(
                      color: Color(0xFF7C3AED), strokeWidth: 2.5),
                  SizedBox(height: 14),
                  Text('Gerando seu plano personalizado...',
                      style: TextStyle(
                          color: AppColors.onSurfaceVariant, fontSize: 13)),
                ],
              ),
            )

          // Erro
          else if (planState.error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.error.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(planState.error!,
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            )

          // Sem plano → botão de gerar
          else if (planState.plan == null)
            GestureDetector(
              onTap: () => ref
                  .read(aiDietPlanProvider.notifier)
                  .generate(goalCalories, goalType),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED).withOpacity(0.10),
                      AppColors.primary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF7C3AED).withOpacity(0.35)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.restaurant_menu_outlined,
                          color: Color(0xFF7C3AED), size: 24),
                    ),
                    const SizedBox(height: 12),
                    Text('GERAR PLANO DO DIA',
                        style: AppTypography.labelSm.copyWith(
                          color: Color(0xFF7C3AED),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      'A IA cria uma dieta personalizada para ${goalCalories} kcal',
                      style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )

          // Plano gerado
          else ...[
            // Resumo de macros do plano
            _PlanMacroSummary(plan: planState.plan!),
            const SizedBox(height: 14),
            // Refeições
            ...planState.plan!.meals.asMap().entries.map((entry) {
              final mealIdx = entry.key;
              final meal    = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanMealCard(
                  meal: meal,
                  mealIdx: mealIdx,
                  onSwapFood: (foodIdx, newFood) => ref
                      .read(aiDietPlanProvider.notifier)
                      .swapFood(mealIdx, foodIdx, newFood),
                  onAddToLog: (foodData) => ref
                      .read(dietControllerProvider.notifier)
                      .addMeal(foodData),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── Resumo de macros do plano ─────────────────────────────────────────────────

class _PlanMacroSummary extends StatelessWidget {
  final DietPlan plan;
  const _PlanMacroSummary({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF7C3AED).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome,
              color: Color(0xFF7C3AED), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${plan.totalCalories} kcal  •  '
              'P ${plan.meals.fold(0.0, (s, m) => s + m.totalProtein).toStringAsFixed(0)}g  '
              'C ${plan.meals.fold(0.0, (s, m) => s + m.totalCarbs).toStringAsFixed(0)}g  '
              'G ${plan.meals.fold(0.0, (s, m) => s + m.totalFat).toStringAsFixed(0)}g',
              style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.w500),
            ),
          ),
          Text('META ${plan.targetCalories} kcal',
              style: AppTypography.labelSm.copyWith(
                  fontSize: 9,
                  color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Card de refeição do plano ─────────────────────────────────────────────────

class _PlanMealCard extends StatefulWidget {
  final DietPlanMeal meal;
  final int mealIdx;
  final void Function(int foodIdx, DietPlanFood newFood) onSwapFood;
  final Future<void> Function(Map<String, dynamic>) onAddToLog;

  const _PlanMealCard({
    required this.meal,
    required this.mealIdx,
    required this.onSwapFood,
    required this.onAddToLog,
  });

  @override
  State<_PlanMealCard> createState() => _PlanMealCardState();
}

class _PlanMealCardState extends State<_PlanMealCard> {
  bool _expanded = true;
  // Guarda quais alimentos foram registrados
  final Set<int> _logged = {};

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          // ── Header da refeição ─────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant_menu,
                        color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(meal.type,
                        style: AppTypography.labelMd.copyWith(
                            letterSpacing: 0.5,
                            color: AppColors.onSurface)),
                  ),
                  // Totais da refeição
                  Text(
                    '${meal.totalCalories} kcal  '
                    'P${meal.totalProtein.toInt()}  '
                    'C${meal.totalCarbs.toInt()}  '
                    'G${meal.totalFat.toInt()}',
                    style: AppTypography.bodySm.copyWith(fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // ── Lista de alimentos ──────────────────────────────────
          if (_expanded) ...[
            const Divider(
                height: 1, color: AppColors.surfaceContainerHigh),
            ...meal.foods.asMap().entries.map((entry) {
              final foodIdx = entry.key;
              final food    = entry.value;
              final isLast  = foodIdx == meal.foods.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                    child: Row(
                      children: [
                        // Info do alimento
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(food.name,
                                        style: AppTypography.bodyMd.copyWith(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text('${food.weightG.toInt()}g',
                                        style: AppTypography.labelSm
                                            .copyWith(fontSize: 10)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Macros explícitos
                              Row(
                                children: [
                                  _MacroPill(
                                      label: 'Prot',
                                      value:
                                          '${food.protein.toStringAsFixed(1)}g',
                                      color: const Color(0xFF5B8DF6)),
                                  const SizedBox(width: 6),
                                  _MacroPill(
                                      label: 'Carb',
                                      value:
                                          '${food.carbs.toStringAsFixed(1)}g',
                                      color: AppColors.warning),
                                  const SizedBox(width: 6),
                                  _MacroPill(
                                      label: 'Gord',
                                      value:
                                          '${food.fat.toStringAsFixed(1)}g',
                                      color: const Color(0xFFFF6B6B)),
                                  const SizedBox(width: 6),
                                  _MacroPill(
                                      label: 'kcal',
                                      value: '${food.calories}',
                                      color: AppColors.primary),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Botões
                        Column(
                          children: [
                            // ALTERAR
                            GestureDetector(
                              onTap: () => _showSwapSheet(
                                  context, foodIdx, food),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('ALTERAR',
                                    style: AppTypography.labelSm.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurfaceVariant)),
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Registrar
                            GestureDetector(
                              onTap: _logged.contains(foodIdx)
                                  ? null
                                  : () => _logFood(foodIdx, food),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _logged.contains(foodIdx)
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _logged.contains(foodIdx)
                                      ? '✓'
                                      : '+LOG',
                                  style: AppTypography.labelSm.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: _logged.contains(foodIdx)
                                        ? AppColors.primary
                                        : AppColors.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1,
                        color: AppColors.surfaceContainerHigh,
                        indent: 14,
                        endIndent: 14),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _logFood(int idx, DietPlanFood food) async {
    await widget.onAddToLog(food.toLogMap());
    if (mounted) setState(() => _logged.add(idx));
  }

  void _showSwapSheet(
      BuildContext context, int foodIdx, DietPlanFood food) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SwapFoodSheet(
        food: food,
        onConfirm: (newFood) {
          widget.onSwapFood(foodIdx, newFood);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── Pílula de macro ───────────────────────────────────────────────────────────

class _MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MacroPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SWAP FOOD SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _SwapFoodSheet extends StatefulWidget {
  final DietPlanFood food;
  final void Function(DietPlanFood) onConfirm;

  const _SwapFoodSheet({required this.food, required this.onConfirm});

  @override
  State<_SwapFoodSheet> createState() => _SwapFoodSheetState();
}

class _SwapFoodSheetState extends State<_SwapFoodSheet> {
  late double _weight;
  final _searchCtrl = TextEditingController();
  List<FoodItem> _results  = [];
  FoodItem? _replacement;

  @override
  void initState() {
    super.initState();
    _weight = widget.food.weightG;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Ao selecionar um substituto, recalcula o peso para manter as calorias
  /// do alimento original (mesmo valor calórico, novos macros do alimento).
  void _selectReplacement(FoodItem item) {
    double newWeight = widget.food.weightG;
    if (item.kcalPer100g > 0) {
      newWeight = (widget.food.calories / item.kcalPer100g * 100)
          .clamp(5.0, 2000.0);
    }
    setState(() {
      _replacement = item;
      _weight      = newWeight;
      _searchCtrl.clear();
      _results = [];
    });
  }

  DietPlanFood get _preview {
    if (_replacement != null) {
      final n = _replacement!.calculate(_weight);
      return DietPlanFood(
        name:     _replacement!.name,
        weightG:  _weight,
        calories: n.calories,
        protein:  n.protein,
        carbs:    n.carbs,
        fat:      n.fat,
      );
    }
    return widget.food.withWeight(_weight);
  }

  void _onSearch(String q) {
    setState(() => _results = q.length > 1 ? FoodDatabase.search(q) : []);
  }

  @override
  Widget build(BuildContext context) {
    final p = _preview;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('ALTERAR ALIMENTO',
                style: AppTypography.headlineMd),
            const SizedBox(height: 4),
            Text(widget.food.name,
                style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),

            const SizedBox(height: 20),

            // ── Preview atual ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SwapMacroItem(
                      label: 'Prot',
                      value: '${p.protein.toStringAsFixed(1)}g',
                      color: const Color(0xFF5B8DF6)),
                  _SwapMacroItem(
                      label: 'Carb',
                      value: '${p.carbs.toStringAsFixed(1)}g',
                      color: AppColors.warning),
                  _SwapMacroItem(
                      label: 'Gord',
                      value: '${p.fat.toStringAsFixed(1)}g',
                      color: const Color(0xFFFF6B6B)),
                  _SwapMacroItem(
                      label: 'kcal',
                      value: '${p.calories}',
                      color: AppColors.primary),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Ajuste de peso ─────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.tune_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('AJUSTAR PESO',
                    style: AppTypography.labelSm
                        .copyWith(letterSpacing: 1.5, fontSize: 10)),
                const Spacer(),
                Text('${_weight.round()}g',
                    style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.primary.withOpacity(0.15),
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.1),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _weight.clamp(20.0, 600.0),
                min: 20,
                max: 600,
                divisions: 58,
                onChanged: (v) => setState(() => _weight = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['20g', '150g', '300g', '450g', '600g']
                  .map((l) => Text(l,
                      style: AppTypography.bodySm.copyWith(
                          fontSize: 9,
                          color: AppColors.onSurfaceVariant)))
                  .toList(),
            ),

            // ── Nota de recálculo automático ──────────────────────────
            if (_replacement != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 13, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Peso recalculado para manter ~${widget.food.calories} kcal do alimento original',
                        style: AppTypography.bodySm.copyWith(
                          color: const Color(0xFF7C3AED),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // ── Trocar alimento ────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.swap_horiz,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('TROCAR ALIMENTO',
                    style: AppTypography.labelSm.copyWith(
                        letterSpacing: 1.5,
                        fontSize: 10,
                        color: AppColors.onSurfaceVariant)),
                if (_replacement != null) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _replacement = null;
                      _searchCtrl.clear();
                      _results = [];
                    }),
                    child: Text('limpar',
                        style: AppTypography.bodySm.copyWith(
                            fontSize: 11,
                            color: AppColors.error,
                            decoration: TextDecoration.underline)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            if (_replacement != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_replacement!.name,
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )
            else ...[
              // Campo de busca
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: AppTypography.bodyMd,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Buscar alternativa...',
                    hintStyle: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.onSurfaceVariant, size: 18),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.surfaceContainerHigh),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppColors.surfaceContainerHigh,
                        indent: 14,
                        endIndent: 14),
                    itemBuilder: (_, i) {
                      final item = _results[i];
                      return InkWell(
                        onTap: () => _selectReplacement(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: AppTypography.bodyMd.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                '${item.kcalPer100g.toInt()} kcal  '
                                'P${item.proteinPer100g}g  '
                                'C${item.carbsPer100g}g  '
                                'G${item.fatPer100g}g  /100g',
                                style: AppTypography.bodySm,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),

            // ── Botão confirmar ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => widget.onConfirm(_preview),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text('CONFIRMAR',
                    style: AppTypography.labelMd.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SwapMacroItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SwapMacroItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: AppTypography.labelSm
                .copyWith(fontSize: 9, color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MEAL CARD (refeições logadas)
// ─────────────────────────────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final dynamic meal;
  final VoidCallback onDelete;

  const _MealCard({required this.meal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.restaurant_menu,
                color: AppColors.onSurfaceVariant, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.mealName as String,
                    style: AppTypography.bodyMd
                        .copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MacroPill(
                        label: 'P',
                        value: '${(meal.protein as double).toStringAsFixed(1)}g',
                        color: const Color(0xFF5B8DF6)),
                    const SizedBox(width: 5),
                    _MacroPill(
                        label: 'C',
                        value: '${(meal.carbs as double).toStringAsFixed(1)}g',
                        color: AppColors.warning),
                    const SizedBox(width: 5),
                    _MacroPill(
                        label: 'G',
                        value: '${(meal.fat as double).toStringAsFixed(1)}g',
                        color: const Color(0xFFFF6B6B)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${meal.calories} kcal',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                    )),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline,
                    size: 16, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyDiet extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDiet({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 40),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.15),
                  AppColors.primary.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Color(0xFF7C3AED), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('IA ATIVA · GROQ',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        'Calcule macros de qualquer alimento ou tire uma foto',
                        style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurface, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.restaurant,
                color: AppColors.onSurfaceVariant, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Configure sua meta calórica no perfil',
              style: AppTypography.bodyMd),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('REGISTRAR REFEIÇÃO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMART MEAL SHEET — 3 modos: BANCO · IA · FOTO
// ─────────────────────────────────────────────────────────────────────────────

class _SmartMealSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _SmartMealSheet({required this.onSave});

  @override
  State<_SmartMealSheet> createState() => _SmartMealSheetState();
}

class _SmartMealSheetState extends State<_SmartMealSheet> {
  _MealInputMode _mode = _MealInputMode.banco;

  // ── BANCO ──────────────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _weightFocus = FocusNode();
  List<FoodItem> _results = [];
  FoodItem? _selected;
  NutritionResult? _preview;

  // ── IA ─────────────────────────────────────────────────────────────────────
  final _aiCtrl = TextEditingController();
  Map<String, dynamic>? _aiResult;
  bool _aiLoading = false;
  String? _aiError;

  // ── FOTO ───────────────────────────────────────────────────────────────────
  Uint8List? _photoBytes;
  Map<String, dynamic>? _photoResult;
  bool _photoLoading = false;
  String? _photoError;
  String? _portionHint;
  double? _adjustedWeight;

  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _weightCtrl.dispose();
    _weightFocus.dispose();
    _aiCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _selected = null;
      _preview = null;
      _weightCtrl.clear();
      _results = FoodDatabase.search(query);
    });
  }

  void _selectFood(FoodItem food) {
    setState(() {
      _selected = food;
      _results = [];
      _searchCtrl.text = food.name;
      _preview = null;
    });
    Future.microtask(
        () => FocusScope.of(context).requestFocus(_weightFocus));
  }

  void _onWeightChanged(String raw) {
    final w = double.tryParse(raw.replaceAll(',', '.'));
    if (_selected == null || w == null || w <= 0) {
      setState(() => _preview = null);
      return;
    }
    setState(() => _preview = _selected!.calculate(w));
  }

  void _clearSelection() {
    setState(() {
      _selected = null;
      _preview = null;
      _results = [];
      _searchCtrl.clear();
      _weightCtrl.clear();
    });
  }

  Future<void> _calculateWithAi() async {
    final desc = _aiCtrl.text.trim();
    if (desc.isEmpty) return;
    if (!GroqConfig.isConfigured) {
      setState(() => _aiError = 'Configure a chave Groq em groq_config.dart');
      return;
    }
    setState(() {
      _aiLoading = true;
      _aiError = null;
      _aiResult = null;
    });
    try {
      final result = await GroqService.calculateFoodMacros(desc);
      if (mounted) setState(() => _aiResult = result);
    } catch (_) {
      if (mounted) {
        setState(
            () => _aiError = 'Não foi possível calcular. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1024);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    if (!GroqConfig.isConfigured) {
      setState(
          () => _photoError = 'Configure a chave Groq em groq_config.dart');
      return;
    }
    setState(() {
      _photoBytes = bytes;
      _photoLoading = true;
      _photoError = null;
      _photoResult = null;
      _adjustedWeight = null;
    });
    try {
      final b64 = base64Encode(bytes);
      final result =
          await GroqService.analyzeFoodPhoto(b64, portionHint: _portionHint);
      if (mounted) {
        if (result.containsKey('error')) {
          setState(() => _photoError = result['error'] as String);
        } else {
          setState(() => _photoResult = result);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
            () => _photoError = 'Erro ao analisar foto. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  Map<String, dynamic>? get _activeMeal {
    if (_mode == _MealInputMode.banco && _preview != null) {
      return {
        'meal_name': _preview!.foodName,
        'calories': _preview!.calories,
        'protein': _preview!.protein,
        'carbs': _preview!.carbs,
        'fat': _preview!.fat,
      };
    }
    if (_mode == _MealInputMode.ia && _aiResult != null) {
      return {
        'meal_name': _aiResult!['name'] ?? 'Alimento',
        'calories': (_aiResult!['calories'] as num).toInt(),
        'protein': (_aiResult!['protein'] as num).toDouble(),
        'carbs': (_aiResult!['carbs'] as num).toDouble(),
        'fat': (_aiResult!['fat'] as num).toDouble(),
      };
    }
    if (_mode == _MealInputMode.foto && _photoResult != null) {
      final aiWeight =
          (_photoResult!['weight_g'] as num?)?.toDouble() ?? 100;
      final w = _adjustedWeight ?? aiWeight;
      final ratio = aiWeight > 0 ? w / aiWeight : 1.0;
      return {
        'meal_name': _photoResult!['name'] ?? 'Alimento (foto)',
        'calories': ((_photoResult!['calories'] as num) * ratio).round(),
        'protein': ((_photoResult!['protein'] as num) * ratio * 10).round() /
            10,
        'carbs':
            ((_photoResult!['carbs'] as num) * ratio * 10).round() / 10,
        'fat': ((_photoResult!['fat'] as num) * ratio * 10).round() / 10,
      };
    }
    return null;
  }

  bool get _canSave => !_saving && _activeMeal != null;

  Future<void> _save() async {
    final meal = _activeMeal;
    if (meal == null) return;
    setState(() => _saving = true);
    await widget.onSave(meal);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text('REGISTRAR REFEIÇÃO', style: AppTypography.headlineMd),
          const SizedBox(height: 16),

          // Seletor de modo
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _ModeTab(
                  label: 'BANCO',
                  icon: Icons.search,
                  selected: _mode == _MealInputMode.banco,
                  onTap: () => setState(() => _mode = _MealInputMode.banco),
                ),
                _ModeTab(
                  label: 'IA',
                  icon: Icons.auto_awesome,
                  selected: _mode == _MealInputMode.ia,
                  onTap: () => setState(() => _mode = _MealInputMode.ia),
                  accentColor: const Color(0xFF7C3AED),
                ),
                _ModeTab(
                  label: 'FOTO',
                  icon: Icons.camera_alt_outlined,
                  selected: _mode == _MealInputMode.foto,
                  onTap: () => setState(() => _mode = _MealInputMode.foto),
                  accentColor: const Color(0xFF0EA5E9),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_mode == _MealInputMode.banco) _buildBancoMode(),
          if (_mode == _MealInputMode.ia) _buildIaMode(),
          if (_mode == _MealInputMode.foto) _buildFotoMode(),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _canSave ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.onPrimary))
                  : Text(
                      _activeMeal != null
                          ? 'ADICIONAR  •  ${_activeMeal!['calories']} kcal'
                          : 'ADICIONAR REFEIÇÃO',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBancoMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepLabel(number: '1', label: 'ALIMENTO'),
        const SizedBox(height: 10),

        if (_selected == null) ...[
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: AppTypography.bodyMd,
              autofocus: _mode == _MealInputMode.banco,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Ex: frango, arroz, aveia...',
                hintStyle: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.onSurfaceVariant, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppColors.onSurfaceVariant, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.surfaceContainerHigh,
                    indent: 16,
                    endIndent: 16),
                itemBuilder: (_, i) => _FoodResultTile(
                  item: _results[i],
                  onTap: () => _selectFood(_results[i]),
                ),
              ),
            ),
          ],
          if (_results.isEmpty && _searchCtrl.text.length > 1) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_off,
                      color: AppColors.onSurfaceVariant, size: 18),
                  const SizedBox(width: 10),
                  Text('Nenhum alimento encontrado',
                      style: AppTypography.bodySm),
                ],
              ),
            ),
          ],
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selected!.name,
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          )),
                      Text(
                        'Por 100g: ${_selected!.kcalPer100g.toInt()} kcal  '
                        'P ${_selected!.proteinPer100g}g  '
                        'C ${_selected!.carbsPer100g}g  '
                        'G ${_selected!.fatPer100g}g',
                        style: AppTypography.bodySm,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close,
                      size: 18, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        _StepLabel(number: '2', label: 'PESO (gramas)'),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _selected != null
                      ? AppColors.surfaceContainerHigh
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selected != null
                        ? AppColors.primary.withOpacity(0.4)
                        : AppColors.surfaceContainerHigh,
                  ),
                ),
                child: TextField(
                  controller: _weightCtrl,
                  focusNode: _weightFocus,
                  enabled: _selected != null,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTypography.bodyMd,
                  textAlign: TextAlign.center,
                  onChanged: _onWeightChanged,
                  decoration: InputDecoration(
                    hintText: _selected != null ? '100' : '—',
                    hintStyle: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text('g',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          ],
        ),

        if (_selected != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [50, 100, 150, 200, 300]
                .map((w) => GestureDetector(
                      onTap: () {
                        _weightCtrl.text = w.toString();
                        _onWeightChanged(w.toString());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${w}g',
                            style: AppTypography.labelSm),
                      ),
                    ))
                .toList(),
          ),
        ],

        if (_preview != null) ...[
          const SizedBox(height: 16),
          _StepLabel(number: '3', label: 'RESULTADO CALCULADO'),
          const SizedBox(height: 10),
          _NutritionPreview(
            name: _preview!.foodName,
            weightG: _preview!.weightGrams,
            calories: _preview!.calories,
            protein: _preview!.protein,
            carbs: _preview!.carbs,
            fat: _preview!.fat,
          ),
        ],
      ],
    );
  }

  Widget _buildIaMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 13),
              ),
            ),
            const SizedBox(width: 8),
            Text('DESCREVA O ALIMENTO',
                style:
                    AppTypography.labelSm.copyWith(letterSpacing: 2)),
          ],
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _aiCtrl,
          style: AppTypography.bodyMd,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText:
                'Ex: "200g de frango grelhado"\n"arroz integral com feijão"',
            hintStyle: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant, fontSize: 13),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.surfaceContainerHigh),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.surfaceContainerHigh),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFF7C3AED), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: _aiLoading || _aiCtrl.text.trim().isEmpty
                ? null
                : _calculateWithAi,
            icon: _aiLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.bolt, size: 16),
            label: Text(
                _aiLoading ? 'CALCULANDO...' : 'CALCULAR MACROS',
                style: AppTypography.labelSm
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        if (_aiError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_aiError!,
                style:
                    AppTypography.bodySm.copyWith(color: AppColors.error)),
          ),
        ],

        if (_aiResult != null) ...[
          const SizedBox(height: 16),
          _NutritionPreview(
            name: _aiResult!['name'] as String? ?? 'Alimento',
            weightG:
                (_aiResult!['weight_g'] as num?)?.toDouble() ?? 100,
            calories: (_aiResult!['calories'] as num).toInt(),
            protein: (_aiResult!['protein'] as num).toDouble(),
            carbs: (_aiResult!['carbs'] as num).toDouble(),
            fat: (_aiResult!['fat'] as num).toDouble(),
            isAi: true,
          ),
        ],
      ],
    );
  }

  Widget _buildFotoMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Icon(Icons.camera_alt_outlined,
                    color: Colors.white, size: 13),
              ),
            ),
            const SizedBox(width: 8),
            Text('FOTO DO ALIMENTO',
                style:
                    AppTypography.labelSm.copyWith(letterSpacing: 2)),
          ],
        ),
        const SizedBox(height: 12),

        if (_photoBytes == null) ...[
          Text('TAMANHO DA PORÇÃO (opcional)',
              style: AppTypography.labelSm.copyWith(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final p in [
                ('PEQUENA', 'pequena'),
                ('MÉDIA', 'media'),
                ('GRANDE', 'grande'),
                ('PRATO', 'prato_cheio'),
              ]) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() =>
                        _portionHint =
                            _portionHint == p.$2 ? null : p.$2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _portionHint == p.$2
                            ? const Color(0xFF0EA5E9).withOpacity(0.18)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _portionHint == p.$2
                              ? const Color(0xFF0EA5E9)
                              : AppColors.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        p.$1,
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSm.copyWith(
                          fontSize: 9,
                          color: _portionHint == p.$2
                              ? const Color(0xFF0EA5E9)
                              : AppColors.onSurfaceVariant,
                          fontWeight: _portionHint == p.$2
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                if (p.$2 != 'prato_cheio') const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PhotoButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'CÂMERA',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PhotoButton(
                  icon: Icons.photo_library_outlined,
                  label: 'GALERIA',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_outlined,
                    color: Color(0xFF0EA5E9), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dica: coloque um garfo, colher ou a mão perto do alimento para melhor estimativa de peso.',
                    style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  _photoBytes!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _photoBytes = null;
                    _photoResult = null;
                    _photoError = null;
                    _adjustedWeight = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 16),
                  ),
                ),
              ),
              if (_photoLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                        SizedBox(height: 10),
                        Text('Analisando...',
                            style: TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],

        if (_photoError != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_photoError!,
                style:
                    AppTypography.bodySm.copyWith(color: AppColors.error)),
          ),
        ],

        if (_photoResult != null) ...[
          const SizedBox(height: 14),
          Builder(builder: (context) {
            final aiWeight =
                (_photoResult!['weight_g'] as num?)?.toDouble() ?? 100;
            final w = _adjustedWeight ?? aiWeight;
            final ratio = aiWeight > 0 ? w / aiWeight : 1.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NutritionPreview(
                  name: _photoResult!['name'] as String? ??
                      'Alimento (foto)',
                  weightG: w,
                  calories:
                      ((_photoResult!['calories'] as num) * ratio).round(),
                  protein: ((_photoResult!['protein'] as num) * ratio * 10)
                          .round() /
                      10,
                  carbs:
                      ((_photoResult!['carbs'] as num) * ratio * 10).round() /
                          10,
                  fat:
                      ((_photoResult!['fat'] as num) * ratio * 10).round() /
                          10,
                  isAi: true,
                  aiLabel: 'VISÃO IA',
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.outline.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('AJUSTAR PESO',
                              style: AppTypography.labelSm.copyWith(
                                  fontSize: 10, letterSpacing: 1.5)),
                          const Spacer(),
                          Text('${w.round()}g',
                              style: AppTypography.labelSm.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                          if (_adjustedWeight != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _adjustedWeight = null),
                              child: Text('resetar',
                                  style: AppTypography.bodySm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 11,
                                      decoration:
                                          TextDecoration.underline)),
                            ),
                          ],
                        ],
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor:
                              AppColors.primary.withOpacity(0.15),
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withOpacity(0.1),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: w.clamp(20, 800),
                          min: 20,
                          max: 800,
                          divisions: 78,
                          onChanged: (v) =>
                              setState(() => _adjustedWeight = v),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('20g',
                              style: AppTypography.bodySm.copyWith(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant)),
                          Text('800g',
                              style: AppTypography.bodySm.copyWith(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ],
    );
  }
}

// ── Mode Tab ──────────────────────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? accentColor;

  const _ModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: color.withOpacity(0.5))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color:
                      selected ? color : AppColors.onSurfaceVariant,
                  size: 18),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTypography.labelSm.copyWith(
                    fontSize: 10,
                    color: selected ? color : AppColors.onSurfaceVariant,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Photo Button ──────────────────────────────────────────────────────────────

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF0EA5E9).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF0EA5E9).withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0EA5E9), size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: AppTypography.labelSm.copyWith(
                    color: const Color(0xFF0EA5E9),
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Step label ────────────────────────────────────────────────────────────────

class _StepLabel extends StatelessWidget {
  final String number;
  final String label;

  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(number,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: AppTypography.labelSm.copyWith(letterSpacing: 2)),
      ],
    );
  }
}

// ── Food result tile ──────────────────────────────────────────────────────────

class _FoodResultTile extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onTap;

  const _FoodResultTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant,
                  color: AppColors.onSurfaceVariant, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: AppTypography.bodyMd
                          .copyWith(fontWeight: FontWeight.w500)),
                  Text(
                    '${item.kcalPer100g.toInt()} kcal  •  '
                    'P ${item.proteinPer100g}g  '
                    'C ${item.carbsPer100g}g  '
                    'G ${item.fatPer100g}g  '
                    '/ 100g',
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(item.category,
                  style: AppTypography.labelSm.copyWith(fontSize: 9)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nutrition preview card ────────────────────────────────────────────────────

class _NutritionPreview extends StatelessWidget {
  final String name;
  final double weightG;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool isAi;
  final String aiLabel;

  const _NutritionPreview({
    required this.name,
    required this.weightG,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.isAi = false,
    this.aiLabel = 'IA',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.primary.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: AppTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    )),
              ),
              if (isAi)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(aiLabel,
                      style: AppTypography.labelSm.copyWith(
                        color: Color(0xFF7C3AED),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              const SizedBox(width: 8),
              Text('${weightG.toInt()}g',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PreviewMacro(
                  label: 'CALORIAS',
                  value: '$calories',
                  unit: 'kcal',
                  color: AppColors.primary,
                  big: true),
              _PreviewMacro(
                  label: 'PROTEÍNA',
                  value: protein.toStringAsFixed(1),
                  unit: 'g',
                  color: const Color(0xFF5B8DF6)),
              _PreviewMacro(
                  label: 'CARBO',
                  value: carbs.toStringAsFixed(1),
                  unit: 'g',
                  color: AppColors.warning),
              _PreviewMacro(
                  label: 'GORDURA',
                  value: fat.toStringAsFixed(1),
                  unit: 'g',
                  color: const Color(0xFFFF6B6B)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewMacro extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final bool big;

  const _PreviewMacro({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: AppTypography.headlineSm.copyWith(
                  color: color,
                  fontSize: big ? 22 : 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: unit,
                style: AppTypography.labelSm.copyWith(
                  color: color.withOpacity(0.7),
                  fontSize: big ? 11 : 9,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: AppTypography.labelSm
                .copyWith(fontSize: 9, letterSpacing: 0.5)),
      ],
    );
  }
}
