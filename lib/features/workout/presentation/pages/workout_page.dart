import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/legal/legal_texts.dart';
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
import '../../../../l10n/app_localizations.dart';
import '../../../subscription/data/models/cota_ia.dart';
import '../../../subscription/presentation/providers/cota_ia_provider.dart';
import '../../../subscription/presentation/widgets/limite_atingido_sheet.dart';

// O grupo muscular é chave da ExerciseLibrary e vai no prompt da IA, então o
// valor guardado continua em português; só o rótulo na tela é traduzido.
String _grupoLabel(String g, L l) => switch (g) {
      'Peito' => l.grupo_peito,
      'Costas' => l.grupo_costas,
      'Ombros' => l.grupo_ombros,
      'Bíceps' => l.grupo_biceps,
      'Tríceps' => l.grupo_triceps,
      'Pernas' => l.grupo_pernas,
      'Glúteos' => l.grupo_gluteos,
      'Core' => l.grupo_core,
      'Full Body' => l.grupo_fullBody,
      _ => g,
    };


class WorkoutPage extends ConsumerStatefulWidget {
  const WorkoutPage({super.key});

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  /// Modo de reordenação. Fora dele a lista é comum — arrastar sem querer num
  /// card cheio de botões seria fácil demais.
  bool _reordenando = false;

  /// Ordem local enquanto arrasta. O provider só é invalidado ao sair do modo,
  /// senão cada arrasto recarregaria a lista e ela pularia sob o dedo.
  List<WorkoutTemplateModel>? _ordemLocal;

  Future<void> _aoReordenar(int de, int para) async {
    final lista = List<WorkoutTemplateModel>.from(_ordemLocal!);
    // O ReorderableListView entrega o índice de destino já contando o item
    // removido quando se arrasta para baixo.
    if (para > de) para -= 1;
    lista.insert(para, lista.removeAt(de));
    setState(() => _ordemLocal = lista);

    try {
      await ref
          .read(workoutTemplateRepositoryProvider)
          .reorderTemplates(lista.map((t) => t.id).toList());
    } catch (_) {
      if (mounted) {
        MkSnack.error(context, L.of(context).treino_naoFoiPossivelSalvarOrdem);
        // Volta ao que o servidor tem, para a tela não mentir.
        setState(() => _ordemLocal = null);
        ref.invalidate(workoutTemplatesProvider);
      }
    }
  }

  /// Recarrega a listagem E os exercícios exibidos em cada card.
  ///
  /// São dois providers distintos: o card observa `templateExercisesProvider`,
  /// que NÃO é invalidado junto com `workoutTemplatesProvider`. Invalidar só o
  /// segundo fazia o card seguir mostrando a lista anterior — foi por isso que
  /// reordenar exercícios parecia "não salvar", com o banco já correto.
  ///
  /// Vale também para concluir treino, que atualiza as cargas em
  /// `template_exercises`: sem isto o card mostraria os pesos antigos.
  void _recarregarTreinos() {
    ref.invalidate(workoutTemplatesProvider);
    ref.invalidate(templateExercisesProvider);
  }

  void _alternarReordenacao(List<WorkoutTemplateModel> atual) {
    setState(() {
      _reordenando = !_reordenando;
      _ordemLocal = _reordenando ? List.of(atual) : null;
    });
    if (!_reordenando) ref.invalidate(workoutTemplatesProvider);
  }

  @override
  Widget build(BuildContext context) {
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
                      Text(L.of(context).treino_missoes,
                          style: AppTypography.labelSm.copyWith(
                            letterSpacing: 2,
                            color: AppColors.onSurfaceVariant,
                          )),
                      Text(L.of(context).treino_treinoUp,
                          style: AppTypography.headlineLg.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                  const Spacer(),
                  // Botão reordenar — só faz sentido com 2+ treinos
                  if ((templates.valueOrNull?.length ?? 0) > 1)
                    GestureDetector(
                      onTap: () =>
                          _alternarReordenacao(templates.valueOrNull ?? []),
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: _reordenando
                              ? AppColors.primary
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _reordenando
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh,
                          ),
                        ),
                        child: Icon(
                          _reordenando ? Icons.check : Icons.swap_vert,
                          color: _reordenando
                              ? AppColors.onPrimary
                              : AppColors.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
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
              child: Text(L.of(context).treino_meusTreinos,
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
                  // ── Modo reordenação ───────────────────────────────
                  if (_reordenando) {
                    final ordem = _ordemLocal ?? list;
                    return Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(24, 0, 24, 12),
                          child: Row(
                            children: [
                              const Icon(Icons.drag_indicator,
                                  size: 15,
                                  color: AppColors.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  L.of(context).treino_arrasteEConclua,
                                  style: AppTypography.bodySm
                                      .copyWith(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ReorderableListView.builder(
                            padding: EdgeInsets.fromLTRB(
                                24, 0, 24,
                                80 + MediaQuery.of(context).padding.bottom),
                            itemCount: ordem.length,
                            onReorder: _aoReordenar,
                            proxyDecorator: (child, _, __) => Material(
                              color: Colors.transparent,
                              child: child,
                            ),
                            itemBuilder: (_, i) => Padding(
                              key: ValueKey(ordem[i].id),
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReorderTile(
                                template: ordem[i],
                                posicao: i,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
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
                                  L.of(context).treino_naoFoiPossivelExcluirTreino);
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
          _recarregarTreinos();
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
          _recarregarTreinos();
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
          _recarregarTreinos();
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
          _recarregarTreinos();
          if (context.mounted) {
            Navigator.pop(context);
            final alreadyDone = result['already_done'] as bool? ?? false;
            final progression = result['progression'] as int? ?? 0;
            if (alreadyDone) {
              MkSnack.info(context, L.of(context).treino_jaRegistradoHoje);
            } else {
              final msg = progression > 0
                  ? L.of(context).treino_ptsComProgressao(progression * 5)
                  : L.of(context).treino_concluidoPts;
              MkSnack.success(context, msg);
            }
          }
        },
      ),
    );
  }
}

// ── AI Workout Sheet ──────────────────────────────────────────────────────────

class _AiWorkoutSheet extends ConsumerStatefulWidget {
  final Future<void> Function(String name, List<Map<String, dynamic>> exercises)
      onSave;

  const _AiWorkoutSheet({required this.onSave});

  @override
  ConsumerState<_AiWorkoutSheet> createState() => _AiWorkoutSheetState();
}

class _AiWorkoutSheetState extends ConsumerState<_AiWorkoutSheet> {
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
      setState(() => _error = L.of(context).treino_sessaoExpirada);
      return;
    }

    if (!await ref
        .read(cotaIaControllerProvider)
        .podeUsar(RecursoIa.gerarTreino)) {
      if (mounted) {
        await LimiteAtingidoSheet.mostrar(context, RecursoIa.gerarTreino);
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _generated = [];
    });

    try {
      final result = await GroqService.generateWorkout(group);
      await ref
          .read(cotaIaControllerProvider)
          .registrarUso(RecursoIa.gerarTreino);
      if (mounted) setState(() => _generated = result);
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() => _error = msg.isNotEmpty ? msg : L.of(context).treino_erroGerar);
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
                      Text(L.of(context).treino_treinoComIa,
                          style: AppTypography.headlineSm
                              .copyWith(fontWeight: FontWeight.w700)),
                      // Nao nomear o modelo aqui: quem escolhe e o proxy,
                      // e o texto anterior ('LLaMA 3.3') ficou mentindo por
                      // duas trocas de modelo seguidas.
                      Text(L.of(context).dieta_iaAtivaGroq,
                          style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  const _SeloDeCotaTreino(),
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
                      child: Text(_grupoLabel(g, L.of(context)),
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
                  hintText: L.of(context).treino_ouDescreva,
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
                Text(L.of(context).treino_exerciciosGerados,
                    style: AppTypography.labelSm.copyWith(letterSpacing: 2)),
                const SizedBox(height: 10),
                ..._generated.map((e) => _AiExerciseTile(exercise: e)),
                const SizedBox(height: 16),
                // Disclaimer obrigatório — política de apps de saúde do Google Play
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.warning.withOpacity(0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.health_and_safety_outlined,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          LegalTexts.workoutDisclaimer,
                          style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                          L.of(context).treino_cargasNaHora,
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

/// Card enxuto usado só no modo de reordenação.
///
/// Sem os botões de fazer/editar/excluir de propósito: durante o arrasto eles
/// viram alvo acidental, e a tarefa aqui é uma só — definir a ordem.
class _ReorderTile extends StatelessWidget {
  final WorkoutTemplateModel template;
  final int posicao;

  const _ReorderTile({required this.template, required this.posicao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${posicao + 1}',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.name,
                    style: AppTypography.bodyMd
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  template.exerciseCount == 1
                      ? L.of(context).treino_exercicioCount(template.exerciseCount)
                      : L.of(context).treino_exerciciosCount(template.exerciseCount),
                  style: AppTypography.bodySm.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          if (template.doneToday)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.check_circle,
                  size: 16, color: AppColors.primary),
            ),
          const Icon(Icons.drag_handle,
              color: AppColors.onSurfaceVariant, size: 22),
        ],
      ),
    );
  }
}

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
                      Text(L.of(context).treino_exerciciosParen(template.exerciseCount),
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
                        title: Text(L.of(context).treino_excluirTreino),
                        content: Text(
                            L.of(context).treino_seraRemovido(template.name)),
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
                          Text(L.of(context).treino_feitoHoje,
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
                      label: Text(L.of(context).treino_fazerHoje),
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
            Text(L.of(context).treino_nenhumCriado,
                style: AppTypography.headlineSm
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(L.of(context).treino_crieOuIa,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAi,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(L.of(context).treino_gerarComIa),
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
                    '_uid': _novoUid(),
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
            context, L.of(context).treino_naoFoiPossivelCarregarExercicios);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Identidade estável de cada exercício na lista da tela.
  ///
  /// Necessária porque `_emit()` devolve um Map NOVO a cada tecla digitada.
  /// Chavear o widget pelo próprio Map fazia a chave mudar a cada letra, e o
  /// Flutter destruía e recriava a linha — o campo perdia o foco no meio da
  /// digitação. Só existe na tela: `updateExercises` monta o insert campo a
  /// campo e ignora esta chave.
  int _uidSeq = 0;
  String _novoUid() => 'ex${_uidSeq++}';

  void _addExercise() {
    setState(() => _exercises.add(<String, dynamic>{
          '_uid': _novoUid(),
          'name': '',
          'sets': 3,
          'reps': 10,
          'weight_kg': 0.0,
        }));
  }

  /// Move um exercício uma posição para cima ou para baixo.
  ///
  /// Setas em vez de arrastar: a lista vive dentro de um SingleChildScrollView
  /// e o ReorderableListView aninhado brigava com a rolagem do painel — o
  /// arrasto não firmava e a nova ordem se perdia. Com campos de texto na
  /// linha, seta também é mais preciso que arrasto.
  void _moverExercicio(int de, int para) {
    if (para < 0 || para >= _exercises.length) return;
    setState(() {
      final item = _exercises.removeAt(de);
      _exercises.insert(para, item);
    });
  }

  void _openLibrary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseLibrarySheet(
        onSelect: (name) {
          setState(() => _exercises.add(<String, dynamic>{
                '_uid': _novoUid(),
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
                // Mesmo motivo do campo da dieta: SALVAR TREINO lê
                // _nameCtrl.text e ficava travado até o campo perder o foco.
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: L.of(context).treino_nomeDoTreino,
                  hintText: L.of(context).treino_exNome,
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
                  Text(L.of(context).treino_exercicios,
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
                    label: Text(L.of(context).treino_biblioteca,
                        style: AppTypography.labelSm
                            .copyWith(color: Color(0xFF7C3AED))),
                  ),
                  TextButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add,
                        color: AppColors.primary, size: 16),
                    label: Text(L.of(context).treino_manual,
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
                        Text(L.of(context).treino_toqueBiblioteca,
                            style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )
              else
                // A ordem final é a da lista — updateExercises grava
                // order_index pela posição, então não há nada a persistir aqui.
                ..._exercises.asMap().entries.map((entry) {
                  final i = entry.key;
                  return _ExerciseInputRow(
                    // Chave pelo uid, não pelo Map nem pelo índice: o Map muda
                    // a cada tecla (perderia o foco) e o índice muda ao mover
                    // (a linha mostraria os dados da outra).
                    key: ValueKey(_exercises[i]['_uid']),
                    index: i,
                    data: _exercises[i],
                    podeSubir: i > 0,
                    podeDescer: i < _exercises.length - 1,
                    onSubir: () => _moverExercicio(i, i - 1),
                    onDescer: () => _moverExercicio(i, i + 1),
                    onChange: (v) => setState(() {
                      // Preserva o uid: _emit() devolve um Map novo sem ele.
                      _exercises[i] = <String, dynamic>{
                        ...v,
                        '_uid': _exercises[i]['_uid'],
                      };
                    }),
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
                      : Text(L.of(context).treino_salvarTreino,
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
                Text(L.of(context).treino_bibliotecaExercicios,
                    style: AppTypography.headlineSm
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                // Search
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearch,
                  style: AppTypography.bodyMd,
                  decoration: InputDecoration(
                    hintText: L.of(context).treino_buscarExercicioHint,
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
                            child: Text(_grupoLabel(g, L.of(context)),
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
                          : L.of(context).treino_nenhumExercicioEncontrado,
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
  final bool podeSubir;
  final bool podeDescer;
  final VoidCallback onSubir;
  final VoidCallback onDescer;

  const _ExerciseInputRow({
    super.key,
    required this.index,
    required this.data,
    required this.onChange,
    required this.onRemove,
    required this.podeSubir,
    required this.podeDescer,
    required this.onSubir,
    required this.onDescer,
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
              Text(L.of(context).treino_exercicioNumero(widget.index + 1),
                  style: AppTypography.labelSm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              // Setas de ordenação. Desabilitadas nas pontas em vez de
              // sumirem, para os ícones não dançarem de posição.
              GestureDetector(
                onTap: widget.podeSubir ? widget.onSubir : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.keyboard_arrow_up,
                      size: 20,
                      color: widget.podeSubir
                          ? AppColors.onSurface
                          : AppColors.surfaceContainerHigh),
                ),
              ),
              GestureDetector(
                onTap: widget.podeDescer ? widget.onDescer : null,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(Icons.keyboard_arrow_down,
                      size: 20,
                      color: widget.podeDescer
                          ? AppColors.onSurface
                          : AppColors.surfaceContainerHigh),
                ),
              ),
              const SizedBox(width: 6),
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
            decoration: _dec(L.of(context).treino_nomeDoExercicio),
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
                  decoration: _dec(L.of(context).treino_seriesLabel),
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

  /// Ids dos exercícios já concluídos nesta sessão.
  Set<String> _feitos = {};

  /// Chave do progresso: por usuário, template e dia.
  ///
  /// Persistir em SharedPreferences (e não só em memória) porque durante o
  /// treino o app sai de foco o tempo todo — tela bloqueia, chega mensagem,
  /// troca de música. Perder os checks nessas horas seria pior que não ter.
  /// A data no meio da chave faz o progresso de ontem não reaparecer hoje.
  String get _chaveProgresso {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
    final hoje = DateTime.now().toIso8601String().substring(0, 10);
    return 'workout_progress_${widget.template.id}_${hoje}_$uid';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ref
        .read(workoutTemplateRepositoryProvider)
        .getExercises(widget.template.id);

    Set<String> feitos = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      feitos = (prefs.getStringList(_chaveProgresso) ?? []).toSet();
    } catch (_) {
      // Progresso é conveniência; não pode impedir o treino de abrir.
    }

    if (mounted) {
      setState(() {
        _exercises = list;
        // Descarta ids que não existem mais (exercício removido do template).
        _feitos = feitos.where((id) => list.any((e) => e.id == id)).toSet();
      });
    }
  }

  Future<void> _alternarFeito(String id) async {
    setState(() {
      _feitos.contains(id) ? _feitos.remove(id) : _feitos.add(id);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_chaveProgresso, _feitos.toList());
    } catch (_) {/* silencioso: o check na tela já valeu */}
  }

  Future<void> _limparProgresso() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chaveProgresso);
    } catch (_) {}
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
                      Text(L.of(context).treino_atualizeCargas,
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
              else ...[
                // Progresso da sessão
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _exercises.isEmpty
                                ? 0
                                : _feitos.length / _exercises.length,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceContainerHigh,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${_feitos.length}/${_exercises.length}',
                          style: AppTypography.labelSm.copyWith(
                            color: _feitos.length == _exercises.length
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
                ..._exercises.asMap().entries.map((entry) {
                  final i = entry.key;
                  return _DoExerciseRow(
                    key: ValueKey(_exercises[i].id),
                    exercise: _exercises[i],
                    feito: _feitos.contains(_exercises[i].id),
                    onToggleFeito: () => _alternarFeito(_exercises[i].id),
                    onChange: (updated) =>
                        setState(() => _exercises[i] = updated),
                  );
                }),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  // Continua liberado mesmo com exercícios em aberto: pular um
                  // por dor, equipamento ocupado ou falta de tempo é rotina, e
                  // travar a conclusão puniria o usuário por treinar.
                  onPressed: (_saving || _exercises.isEmpty)
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          await _limparProgresso();
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
  final bool feito;
  final VoidCallback onToggleFeito;

  const _DoExerciseRow({
    super.key,
    required this.exercise,
    required this.onChange,
    required this.feito,
    required this.onToggleFeito,
  });

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
        color: widget.feito
            ? AppColors.primary.withOpacity(0.06)
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.feito
              ? AppColors.primary.withOpacity(0.45)
              : AppColors.surfaceContainerHigh,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Alvo de toque generoso: é usado com a mão suada, no meio da
              // série, muitas vezes sem olhar direito.
              GestureDetector(
                onTap: widget.onToggleFeito,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10, top: 2, bottom: 2),
                  child: Icon(
                    widget.feito
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 22,
                    color: widget.feito
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.exercise.name.toUpperCase(),
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.feito
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                    decoration: widget.feito
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(_sets, L.of(context).treino_seriesLabel)),
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

/// Selo de cota do gerador de treino.
class _SeloDeCotaTreino extends ConsumerWidget {
  const _SeloDeCotaTreino();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(saldoDeCotaProvider(RecursoIa.gerarTreino)).maybeWhen(
          data: (s) => SeloDeCota(saldo: s),
          orElse: () => const SizedBox.shrink(),
        );
  }
}
