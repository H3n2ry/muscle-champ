import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/groq/groq_config.dart';
import '../../../../core/groq/groq_service.dart';
import '../../../../shared/widgets/mk_error_banner.dart';
import '../../../../shared/widgets/mk_snack.dart';
import '../../data/models/workout_template_model.dart';
import '../../data/repositories/workout_template_repository.dart';
import '../../data/datasources/exercise_library.dart';
import '../providers/workout_template_provider.dart';

class WorkoutPage extends ConsumerWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(workoutTemplatesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MISSÕES',
                          style: AppTypography.labelSm.copyWith(
                            letterSpacing: 2,
                            color: AppColors.onSurfaceVariant,
                          )),
                      Text('TREINO',
                          style: AppTypography.headlineLg.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                  const Spacer(),
                  // Botão IA
                  GestureDetector(
                    onTap: () => _showAiSheet(context, ref),
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: Color(0xFF7C3AED), size: 20),
                    ),
                  ),
                  // Botão criar manual
                  GestureDetector(
                    onTap: () => _showCreateSheet(context, ref),
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

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Text('MEUS TREINOS',
                  style: AppTypography.labelSm.copyWith(
                    letterSpacing: 2,
                    color: AppColors.onSurfaceVariant,
                  )),
            ),

            // ── Lista de templates ───────────────────────────────────
            Expanded(
              child: templates.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
                error: (e, _) => MkErrorState(
                  onRetry: () => ref.invalidate(workoutTemplatesProvider),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return _EmptyState(
                        onManual: () => _showCreateSheet(context, ref),
                        onAi: () => _showAiSheet(context, ref));
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceContainer,
                    onRefresh: () async =>
                        ref.invalidate(workoutTemplatesProvider),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                          24, 4, 24,
                          80 + MediaQuery.of(context).padding.bottom),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => _TemplateCard(
                        template: list[i],
                        onDo: () => _showDoWorkoutSheet(
                            context, ref, list[i]),
                        onEdit: () => _showEditSheet(
                            context, ref, list[i]),
                        onDelete: () async {
                          try {
                            await ref
                                .read(workoutTemplateRepositoryProvider)
                                .deleteTemplate(list[i].id);
                            ref.invalidate(workoutTemplatesProvider);
                          } catch (e) {
                            if (context.mounted) {
                              MkSnack.error(context,
                                  'Não foi possível excluir o treino. Tente novamente.');
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiWorkoutSheet(
        onSave: (name, exercises) async {
          await ref
              .read(workoutTemplateRepositoryProvider)
              .createTemplate(name: name, exercises: exercises);
          ref.invalidate(workoutTemplatesProvider);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemplateSheet(
        onSave: (name, exercises) async {
          await ref
              .read(workoutTemplateRepositoryProvider)
              .createTemplate(name: name, exercises: exercises);
          ref.invalidate(workoutTemplatesProvider);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditSheet(
      BuildContext context, WidgetRef ref, WorkoutTemplateModel template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TemplateSheet(
        initialName: template.name,
        templateId: template.id,
        onSave: (name, exercises) async {
          final repo = ref.read(workoutTemplateRepositoryProvider);
          await repo.updateTemplateName(template.id, name);
          await repo.updateExercises(template.id, exercises);
          ref.invalidate(workoutTemplatesProvider);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showDoWorkoutSheet(
      BuildContext context, WidgetRef ref, WorkoutTemplateModel template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DoWorkoutSheet(
        template: template,
        onComplete: (exercises) async {
          final result = await ref
              .read(workoutTemplateRepositoryProvider)
              .completeTemplate(
                  templateId: template.id, exercises: exercises);
          ref.invalidate(workoutTemplatesProvider);
          if (context.mounted) {
            Navigator.pop(context);
            final alreadyDone = result['already_done'] as bool? ?? false;
            final progression = result['progression'] as int? ?? 0;
            if (alreadyDone) {
              MkSnack.info(context, 'Treino já registrado hoje!');
            } else {
              final msg = progression > 0
                  ? '+10 pts  +${progression * 5} pts por progressão!'
                  : 'Treino concluído! +10 pts';
              MkSnack.success(context, msg);
            }
          }
        },
      ),
    );
  }
}

// ── AI Workout Sheet ──────────────────────────────────────────────────────────

class _AiWorkoutSheet extends StatefulWidget {
  final Future<void> Function(String name, List<Map<String, dynamic>> exercises)
      onSave;

  const _AiWorkoutSheet({required this.onSave});

  @override
  State<_AiWorkoutSheet> createState() => _AiWorkoutSheetState();
}

class _AiWorkoutSheetState extends State<_AiWorkoutSheet> {
  final _customCtrl = TextEditingController();
  String? _selectedGroup;
  List<Map<String, dynamic>> _generated = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  static const _chips = [
    'Peito', 'Costas', 'Ombros', 'Bíceps',
    'Tríceps', 'Pernas', 'Glúteos', 'Core', 'Full Body',
  ];

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final group = _selectedGroup ??
        (_customCtrl.text.trim().isEmpty ? null : _customCtrl.text.trim());
    if (group == null) return;

    if (!GroqConfig.isConfigured) {
      setState(() => _error = 'Sessão expirada. Faça login novamente.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _generated = [];
    });

    try {
      final result = await GroqService.generateWorkout(group);
      if (mounted) setState(() => _generated = result);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() => _error = msg.isNotEmpty ? msg : 'Erro ao gerar treino. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_generated.isEmpty) return;
    final name = _selectedGroup ?? _customCtrl.text.trim();
    setState(() => _saving = true);
    final exercises = _generated
        .map((e) => {
              'name': e['name'] as String,
              'sets': (e['sets'] as num).toInt(),
              'reps': (e['reps'] as num).toInt(),
              'weight_kg': 0.0,
            })
        .toList();
    await widget.onSave(name, exercises);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Título
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Color(0xFF7C3AED), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TREINO COM IA',
                          style: AppTypography.headlineSm
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text('Groq · LLaMA 3.3',
                          style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text('AGRUPAMENTO MUSCULAR',
                  style: AppTypography.labelSm.copyWith(letterSpacing: 2)),
              const SizedBox(height: 12),

              // Chips de grupo muscular
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _chips.map((g) {
                  final selected = _selectedGroup == g;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedGroup = selected ? null : g;
                      _customCtrl.clear();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF7C3AED).withOpacity(0.2)
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF7C3AED)
                              : AppColors.surfaceContainerHigh,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(g,
                          style: AppTypography.labelSm.copyWith(
                            color: selected
                                ? const Color(0xFF7C3AED)
                                : AppColors.onSurface,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          )),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Campo personalizado
              TextField(
                controller: _customCtrl,
                style: AppTypography.bodyMd,
                onChanged: (_) => setState(() => _selectedGroup = null),
                decoration: InputDecoration(
                  hintText: 'Ou descreva: "Peito e Tríceps pesado"',
                  hintStyle: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  prefixIcon: const Icon(Icons.edit_outlined,
                      color: AppColors.onSurfaceVariant, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.surfaceContainerHigh),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.surfaceContainerHigh),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF7C3AED), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão gerar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _loading
                      ? null
                      : (_selectedGroup != null ||
                              _customCtrl.text.trim().isNotEmpty)
                          ? _generate
                          : null,
                  icon: _loading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Icon(Icons.bolt, size: 18),
                  label: Text(_loading ? 'GERANDO...' : 'GERAR TREINO',
                      style: AppTypography.labelMd.copyWith(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              MkErrorBanner(
                message: _error,
                onDismiss: () => setState(() => _error = null),
                padding: const EdgeInsets.only(top: 12),
              ),

              // Exercícios gerados
              if (_generated.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('EXERCÍCIOS GERADOS',
                    style: AppTypography.labelSm.copyWith(letterSpacing: 2)),
                const SizedBox(height: 10),
                ..._generated.map((e) => _AiExerciseTile(exercise: e)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'As cargas serão preenchidas na hora do treino.',
                          style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_saving ? 'SALVANDO...' : 'SALVAR TREINO',
                        style: AppTypography.labelMd.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AiExerciseTile extends StatelessWidget {
  final Map<String, dynamic> exercise;
  const _AiExerciseTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final tip = exercise['tip'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center,
                color: Color(0xFF7C3AED), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise['name'] as String,
                    style: AppTypography.bodyMd
                        .copyWith(fontWeight: FontWeight.w600)),
                if (tip.isNotEmpty)
                  Text(tip,
                      style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${exercise['sets']}×${exercise['reps']}',
            style: AppTypography.labelMd.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Template Card ─────────────────────────────────────────────────────────────

class _TemplateCard extends ConsumerWidget {
  final WorkoutTemplateModel template;
  final VoidCallback onDo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onDo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(templateExercisesProvider(template.id));
    final done = template.doneToday;

    return Container(
      decoration: BoxDecoration(
        color: done
            ? AppColors.primary.withOpacity(0.06)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.surfaceContainerHigh,
          width: done ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: done
                        ? AppColors.primary.withOpacity(0.15)
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    done ? Icons.check_circle : Icons.fitness_center,
                    color: done
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name.toUpperCase(),
                          style: AppTypography.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: done
                                ? AppColors.primary
                                : AppColors.onSurface,
                          )),
                      Text('${template.exerciseCount} exercício(s)',
                          style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      // usa o context do PRÓPRIO diálogo no pop — com o context
                      // externo o pop removia a página de Treino (tela preta)
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: AppColors.surfaceContainerLow,
                        title: const Text('Excluir treino?'),
                        content: Text(
                            'O treino "${template.name}" será removido.'),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogCtx, false),
                              child: const Text('CANCELAR')),
                          TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogCtx, true),
                              child: Text('EXCLUIR',
                                  style: TextStyle(
                                      color: AppColors.error))),
                        ],
                      ),
                    );
                    if (confirm == true) onDelete();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),

          exercises.when(
            loading: () => const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  Container(height: 1, color: AppColors.surfaceContainerHigh),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                    child: Column(
                      children: list.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(Icons.circle,
                                size: 5,
                                color: done
                                    ? AppColors.primary
                                    : AppColors.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(e.name,
                                  style: AppTypography.bodyMd.copyWith(
                                      fontWeight: FontWeight.w500)),
                            ),
                            Text(
                              '${e.sets}×${e.reps}  ${e.weightKg > 0 ? "${e.weightKg.toStringAsFixed(e.weightKg % 1 == 0 ? 0 : 1)}kg" : "—"}',
                              style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: done
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('FEITO HOJE',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: onDo,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('FAZER HOJE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.labelMd
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onManual;
  final VoidCallback onAi;
  const _EmptyState({required this.onManual, required this.onAi});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Nenhum treino criado',
                style: AppTypography.headlineSm
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Crie manualmente ou deixe a IA montar um treino pra você',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAi,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('GERAR COM IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onManual,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('CRIAR MANUALMENTE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onSurface,
                  side: const BorderSide(color: AppColors.surfaceContainerHigh),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Template Sheet (criar / editar) ──────────────────────────────────────────

class _TemplateSheet extends ConsumerStatefulWidget {
  final String? initialName;
  final String? templateId;
  final Future<void> Function(
      String name, List<Map<String, dynamic>> exercises) onSave;

  const _TemplateSheet({
    this.initialName,
    this.templateId,
    required this.onSave,
  });

  @override
  ConsumerState<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends ConsumerState<_TemplateSheet> {
  late final TextEditingController _nameCtrl;
  List<Map<String, dynamic>> _exercises = [];
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    if (widget.templateId != null) _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final list = await ref
          .read(workoutTemplateRepositoryProvider)
          .getExercises(widget.templateId!);
      if (mounted) {
        setState(() {
          // <String, dynamic> explícito: sem isso o Dart infere Map<String, Object>
          // e o .add() de novos exercícios lança TypeError no modo edição
          _exercises = list
              .map((e) => <String, dynamic>{
                    'name': e.name,
                    'sets': e.sets,
                    'reps': e.reps,
                    'weight_kg': e.weightKg,
                  })
              .toList();
          _loaded = true;
        });
      }
    } catch (e) {
      // Libera a UI mesmo se falhar — evita o painel preso/vazio bloqueando a tela
      if (mounted) {
        setState(() => _loaded = true);
        MkSnack.error(
            context, 'Não foi possível carregar os exercícios do treino.');
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addExercise() {
    setState(() => _exercises.add(
        <String, dynamic>{'name': '', 'sets': 3, 'reps': 10, 'weight_kg': 0.0}));
  }

  void _openLibrary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseLibrarySheet(
        onSelect: (name) {
          setState(() => _exercises.add(<String, dynamic>{
                'name': name,
                'sets': 3,
                'reps': 10,
                'weight_kg': 0.0,
              }));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.templateId != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(isEdit ? 'EDITAR TREINO' : 'NOVO TREINO',
                  style: AppTypography.headlineSm
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              TextField(
                controller: _nameCtrl,
                style: AppTypography.bodyMd,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nome do treino',
                  hintText: 'Ex: Peito e Tríceps',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.surfaceContainerHigh),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.surfaceContainerHigh),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Text('EXERCÍCIOS',
                      style: AppTypography.labelSm.copyWith(
                        letterSpacing: 2,
                        color: AppColors.onSurfaceVariant,
                      )),
                  const Spacer(),
                  // Biblioteca
                  TextButton.icon(
                    onPressed: _openLibrary,
                    icon: const Icon(Icons.library_books_outlined,
                        color: Color(0xFF7C3AED), size: 16),
                    label: Text('BIBLIOTECA',
                        style: AppTypography.labelSm
                            .copyWith(color: Color(0xFF7C3AED))),
                  ),
                  TextButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add,
                        color: AppColors.primary, size: 16),
                    label: Text('MANUAL',
                        style: AppTypography.labelSm
                            .copyWith(color: AppColors.primary)),
                  ),
                ],
              ),

              if (isEdit && !_loaded)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_exercises.isEmpty)
                GestureDetector(
                  onTap: _openLibrary,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.library_books_outlined,
                            color: AppColors.primary, size: 28),
                        const SizedBox(height: 8),
                        Text('Toque para escolher da biblioteca',
                            style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )
              else
                ..._exercises.asMap().entries.map((entry) {
                  final i = entry.key;
                  return _ExerciseInputRow(
                    key: ValueKey(i),
                    index: i,
                    data: _exercises[i],
                    onChange: (v) => setState(() => _exercises[i] = v),
                    onRemove: () =>
                        setState(() => _exercises.removeAt(i)),
                  );
                }),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_saving ||
                          _nameCtrl.text.trim().isEmpty ||
                          _exercises.isEmpty)
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          await widget.onSave(
                              _nameCtrl.text.trim(), _exercises);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor:
                        AppColors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary))
                      : Text('SALVAR TREINO',
                          style: AppTypography.labelMd.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Exercise Library Sheet ────────────────────────────────────────────────────

class _ExerciseLibrarySheet extends StatefulWidget {
  final void Function(String name) onSelect;
  const _ExerciseLibrarySheet({required this.onSelect});

  @override
  State<_ExerciseLibrarySheet> createState() => _ExerciseLibrarySheetState();
}

class _ExerciseLibrarySheetState extends State<_ExerciseLibrarySheet> {
  final _searchCtrl = TextEditingController();
  String? _selectedGroup;
  List<String> _searchResults = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _searchResults = ExerciseLibrary.search(q);
      _selectedGroup = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = ExerciseLibrary.allGroups;
    final showSearch = _searchCtrl.text.isNotEmpty;
    final exercises = showSearch
        ? _searchResults
        : (_selectedGroup != null
            ? ExerciseLibrary.byGroup[_selectedGroup!] ?? []
            : <String>[]);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BIBLIOTECA DE EXERCÍCIOS',
                    style: AppTypography.headlineSm
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                // Search
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  style: AppTypography.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'Buscar exercício...',
                    hintStyle: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.onSurfaceVariant, size: 20),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                // Group chips
                if (!showSearch)
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final g = groups[i];
                        final sel = _selectedGroup == g;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedGroup = sel ? null : g),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary.withOpacity(0.15)
                                  : AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.surfaceContainerHigh,
                              ),
                            ),
                            child: Text(g,
                                style: AppTypography.labelSm.copyWith(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.onSurface,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                )),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Text(
                      _selectedGroup == null && !showSearch
                          ? 'Selecione um grupo muscular'
                          : 'Nenhum exercício encontrado',
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                    itemCount: exercises.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AppColors.surfaceContainerHigh,
                    ),
                    itemBuilder: (_, i) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // Adiciona primeiro; o fechamento nunca pode impedir a ação
                        widget.onSelect(exercises[i]);
                        Navigator.of(context).maybePop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(exercises[i],
                                  style: AppTypography.bodyMd
                                      .copyWith(fontWeight: FontWeight.w500)),
                            ),
                            const Icon(Icons.add_circle_outline,
                                color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Exercise Input Row ────────────────────────────────────────────────────────

class _ExerciseInputRow extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final ValueChanged<Map<String, dynamic>> onChange;
  final VoidCallback onRemove;

  const _ExerciseInputRow({
    super.key,
    required this.index,
    required this.data,
    required this.onChange,
    required this.onRemove,
  });

  @override
  State<_ExerciseInputRow> createState() => _ExerciseInputRowState();
}

class _ExerciseInputRowState extends State<_ExerciseInputRow> {
  late final TextEditingController _name;
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _weight;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.data['name'] as String);
    _sets = TextEditingController(text: '${widget.data['sets']}');
    _reps = TextEditingController(text: '${widget.data['reps']}');
    _weight = TextEditingController(
        text: (widget.data['weight_kg'] as double) == 0
            ? ''
            : '${widget.data['weight_kg']}');
  }

  @override
  void dispose() {
    _name.dispose();
    _sets.dispose();
    _reps.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChange(<String, dynamic>{
      'name': _name.text,
      'sets': int.tryParse(_sets.text) ?? 3,
      'reps': int.tryParse(_reps.text) ?? 10,
      'weight_kg': double.tryParse(_weight.text) ?? 0.0,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Exercício ${widget.index + 1}',
                  style: AppTypography.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(Icons.close,
                    size: 18, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            style: AppTypography.bodyMd,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _emit(),
            decoration: _dec('Nome do exercício'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _sets,
                  style: AppTypography.bodyMd,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _emit(),
                  decoration: _dec('Séries'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _reps,
                  style: AppTypography.bodyMd,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _emit(),
                  decoration: _dec('Reps'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _weight,
                  style: AppTypography.bodyMd,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onChanged: (_) => _emit(),
                  decoration: _dec('Peso (kg)'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        labelStyle:
            AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );
}

// ── Do Workout Sheet (com cronômetro) ─────────────────────────────────────────

class _DoWorkoutSheet extends ConsumerStatefulWidget {
  final WorkoutTemplateModel template;
  final Future<void> Function(List<TemplateExerciseModel> exercises) onComplete;

  const _DoWorkoutSheet({required this.template, required this.onComplete});

  @override
  ConsumerState<_DoWorkoutSheet> createState() => _DoWorkoutSheetState();
}

class _DoWorkoutSheetState extends ConsumerState<_DoWorkoutSheet> {
  List<TemplateExerciseModel> _exercises = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ref
        .read(workoutTemplateRepositoryProvider)
        .getExercises(widget.template.id);
    if (mounted) setState(() => _exercises = list);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fitness_center,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.template.name.toUpperCase(),
                          style: AppTypography.headlineSm
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text('Atualize as cargas se necessário',
                          style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Cronômetro ───────────────────────────────────────────
              const _WorkoutTimer(),

              const SizedBox(height: 16),

              if (_exercises.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else
                ..._exercises.asMap().entries.map((entry) {
                  final i = entry.key;
                  return _DoExerciseRow(
                    key: ValueKey(_exercises[i].id),
                    exercise: _exercises[i],
                    onChange: (updated) =>
                        setState(() => _exercises[i] = updated),
                  );
                }),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_saving || _exercises.isEmpty)
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          await widget.onComplete(_exercises);
                        },
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary))
                      : const Icon(Icons.check_circle, size: 20),
                  label: Text(
                      _saving ? 'SALVANDO...' : 'CONCLUIR TREINO',
                      style: AppTypography.labelMd.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Workout Timer ─────────────────────────────────────────────────────────────

class _WorkoutTimer extends StatefulWidget {
  const _WorkoutTimer();

  @override
  State<_WorkoutTimer> createState() => _WorkoutTimerState();
}

class _WorkoutTimerState extends State<_WorkoutTimer> {
  Timer? _timer;
  int _seconds = 0;
  bool _running = false;

  static const _presets = [30, 60, 90, 120];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
      });
      setState(() => _running = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _running = false;
    });
  }

  void _setPreset(int s) {
    _timer?.cancel();
    setState(() {
      _seconds = s;
      _running = false;
    });
    _toggle();
  }

  String _format(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _running
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.surfaceContainerHigh,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined,
                  color: AppColors.onSurfaceVariant, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text('DESCANSO',
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSm.copyWith(
                      letterSpacing: 1.5,
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    )),
              ),
              const SizedBox(width: 6),
              // Presets
              ...(_presets.map((s) => GestureDetector(
                    onTap: () => _setPreset(s),
                    child: Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${s}s',
                          style: AppTypography.labelSm
                              .copyWith(fontSize: 10)),
                    ),
                  ))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _format(_seconds),
                style: AppTypography.headlineLg.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: _running ? AppColors.primary : AppColors.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: _toggle,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _running
                        ? AppColors.primary
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _running ? Icons.pause : Icons.play_arrow,
                    color: _running
                        ? AppColors.onPrimary
                        : AppColors.onSurface,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _reset,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.refresh,
                      color: AppColors.onSurfaceVariant, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Do Exercise Row ───────────────────────────────────────────────────────────

class _DoExerciseRow extends StatefulWidget {
  final TemplateExerciseModel exercise;
  final ValueChanged<TemplateExerciseModel> onChange;

  const _DoExerciseRow(
      {super.key, required this.exercise, required this.onChange});

  @override
  State<_DoExerciseRow> createState() => _DoExerciseRowState();
}

class _DoExerciseRowState extends State<_DoExerciseRow> {
  late final TextEditingController _weight;
  late final TextEditingController _sets;
  late final TextEditingController _reps;

  @override
  void initState() {
    super.initState();
    final w = widget.exercise.weightKg;
    _weight = TextEditingController(
        text: w == 0 ? '' : w % 1 == 0 ? '${w.toInt()}' : '$w');
    _sets = TextEditingController(text: '${widget.exercise.sets}');
    _reps = TextEditingController(text: '${widget.exercise.reps}');
  }

  @override
  void dispose() {
    _weight.dispose();
    _sets.dispose();
    _reps.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChange(widget.exercise.copyWith(
      weightKg: double.tryParse(_weight.text) ?? 0,
      sets: int.tryParse(_sets.text) ?? widget.exercise.sets,
      reps: int.tryParse(_reps.text) ?? widget.exercise.reps,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.exercise.name.toUpperCase(),
              style:
                  AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(_sets, 'Séries')),
              const SizedBox(width: 8),
              Expanded(child: _field(_reps, 'Reps')),
              const SizedBox(width: 8),
              Expanded(
                  flex: 2,
                  child: _field(_weight, 'Peso (kg)', decimal: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
          {bool decimal = false}) =>
      TextField(
        controller: ctrl,
        style: AppTypography.bodyMd,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        onChanged: (_) => _emit(),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: AppColors.surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          labelStyle:
              AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      );
}
