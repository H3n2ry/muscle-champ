import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/mk_date_field.dart';
import '../../../../shared/widgets/mk_snack.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final ProfileModel profile;
  const EditProfilePage({super.key, required this.profile});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _currentWeightCtrl;
  late final TextEditingController _targetWeightCtrl;
  late String _goalType;
  DateTime? _birthDate;

  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _heightCtrl = TextEditingController(
        text: p.heightCm > 0 ? p.heightCm.toStringAsFixed(0) : '');
    _currentWeightCtrl = TextEditingController(
        text: p.currentWeight > 0 ? p.currentWeight.toStringAsFixed(1) : '');
    _targetWeightCtrl = TextEditingController(
        text: p.targetWeight > 0 ? p.targetWeight.toStringAsFixed(1) : '');
    _goalType = p.goalType;
    _birthDate = p.birthDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _currentWeightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  double? get _liveBmi {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_currentWeightCtrl.text);
    if (h == null || w == null || h <= 0 || w <= 0) return null;
    final hm = h / 100.0;
    return w / (hm * hm);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo    = ref.read(profileRepositoryProvider);
      final p       = widget.profile;
      final futures = <Future>[];

      final newName = _nameCtrl.text.trim();
      if (newName != p.name && newName.isNotEmpty) {
        futures.add(repo.updateName(newName));
      }

      final newHeight = double.tryParse(_heightCtrl.text) ?? 0;
      if (newHeight != p.heightCm) {
        futures.add(repo.updateHeight(newHeight));
      }

      final newCurrent = double.tryParse(_currentWeightCtrl.text) ?? 0;
      if (newCurrent != p.currentWeight && newCurrent > 0) {
        futures.add(repo.updateWeight(newCurrent));
      }

      final newTarget = double.tryParse(_targetWeightCtrl.text) ?? 0;
      if (_goalType != p.goalType || newTarget != p.targetWeight) {
        futures.add(repo.updateGoal(_goalType, newTarget));
      }

      if (_birthDate != p.birthDate) {
        futures.add(repo.updateBirthDate(_birthDate));
      }

      await Future.wait(futures);

      // Recarrega o perfil
      ref.invalidate(profileProvider);

      if (mounted) {
        context.pop();
        MkSnack.success(context, L.of(context).edit_perfilAtualizado);
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        MkSnack.error(context,
            msg.length > 100 ? L.of(context).edit_erroSalvar : msg);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _liveBmi;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(0.08),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 24, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        color: AppColors.onSurface,
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(L.of(context).edit_editar,
                              style: AppTypography.headlineLg.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              )),
                          Text(L.of(context).edit_perfil,
                              style: AppTypography.headlineLg.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Form ──────────────────────────────────────────
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Dados Pessoais ──────────────────────
                          _SectionHeader(
                              icon: Icons.person_outline,
                              title: L.of(context).edit_dadosPessoais),
                          const SizedBox(height: 14),
                          _EditField(
                            label: L.of(context).edit_nome,
                            controller: _nameCtrl,
                            hint: L.of(context).edit_seuNomeCompleto,
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? L.of(context).comum_obrigatorio
                                    : null,
                          ),

                          const SizedBox(height: 16),

                          Text(L.of(context).edit_dataNascimento,
                              style: AppTypography.labelSm.copyWith(
                                  letterSpacing: 1.5,
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 10)),
                          const SizedBox(height: 8),
                          MkDateField(
                            value: _birthDate,
                            onChanged: (d) =>
                                setState(() => _birthDate = d),
                          ),

                          const SizedBox(height: 28),

                          // ── Medidas Corporais ───────────────────
                          _SectionHeader(
                              icon: Icons.monitor_weight_outlined,
                              title: L.of(context).edit_medidasCorporais),
                          const SizedBox(height: 14),

                          Row(
                            children: [
                              Expanded(
                                child: _EditField(
                                  label: L.of(context).edit_altura,
                                  controller: _heightCtrl,
                                  hint: '175',
                                  suffix: 'cm',
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _EditField(
                                  label: L.of(context).edit_pesoAtual,
                                  controller: _currentWeightCtrl,
                                  hint: '80.0',
                                  suffix: 'kg',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          _EditField(
                            label: L.of(context).edit_pesoAlvo,
                            controller: _targetWeightCtrl,
                            hint: '75.0',
                            suffix: 'kg',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                          ),

                          // Live BMI preview
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: bmi != null
                                ? Padding(
                                    key: const ValueKey('bmi'),
                                    padding:
                                        const EdgeInsets.only(top: 16),
                                    child: _LiveBmiBar(bmi: bmi),
                                  )
                                : const SizedBox(key: ValueKey('no-bmi')),
                          ),

                          const SizedBox(height: 28),

                          // ── Objetivo ────────────────────────────
                          _SectionHeader(
                              icon: Icons.flag_outlined,
                              title: L.of(context).edit_objetivo),
                          const SizedBox(height: 14),

                          ..._goalOptions.map((opt) {
                            final selected = _goalType == opt.key;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _GoalCard(
                                option: opt,
                                selected: selected,
                                onTap: () =>
                                    setState(() => _goalType = opt.key),
                              ),
                            );
                          }),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Save button ───────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      16 + MediaQuery.of(context).padding.bottom),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        disabledBackgroundColor:
                            AppColors.surfaceContainerHigh,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.onPrimary))
                          : Text(L.of(context).edit_salvarAlteracoes,
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Goal options ──────────────────────────────────────────────────────────────

// A lista continua const (o `key` e o ícone não mudam de idioma); o texto sai
// do L no momento de desenhar, senão a troca de idioma não chegaria aqui.
class _GoalOption {
  final String key;
  final IconData icon;
  const _GoalOption(this.key, this.icon);

  String label(L l) => switch (key) {
        'lose_weight' => l.objetivo_perdaPeso,
        'gain_weight' => l.objetivo_ganhoMassa,
        _ => l.objetivo_manutencaoUp,
      };

  String description(L l) => switch (key) {
        'lose_weight' => l.objetivo_perdaPesoDesc,
        'gain_weight' => l.objetivo_ganhoMassaDesc,
        _ => l.objetivo_manutencaoDesc,
      };
}

const _goalOptions = [
  _GoalOption('lose_weight', Icons.trending_down),
  _GoalOption('maintain', Icons.balance),
  _GoalOption('gain_weight', Icons.trending_up),
];

class _GoalCard extends StatelessWidget {
  final _GoalOption option;
  final bool selected;
  final VoidCallback onTap;
  const _GoalCard(
      {required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.surfaceContainerHigh,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(option.icon,
                  color: selected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.label(L.of(context)),
                      style: AppTypography.labelMd.copyWith(
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 2),
                  Text(option.description(L.of(context)),
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check,
                    color: AppColors.onPrimary, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: AppTypography.labelSm
                .copyWith(letterSpacing: 2, color: AppColors.primary)),
      ],
    );
  }
}

// ── Edit field ────────────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _EditField({
    required this.label,
    required this.controller,
    required this.hint,
    this.suffix,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSm.copyWith(
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant,
                fontSize: 10)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
            suffixText: suffix,
            suffixStyle: AppTypography.labelMd
                .copyWith(color: AppColors.onSurfaceVariant),
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
              borderSide:
                  BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ── Live BMI bar ──────────────────────────────────────────────────────────────

class _LiveBmiBar extends StatelessWidget {
  final double bmi;
  const _LiveBmiBar({required this.bmi});

  String _label(L l) {
    if (bmi < 18.5) return l.imc_abaixoPeso;
    if (bmi < 25.0) return l.imc_normalOk;
    if (bmi < 30.0) return l.imc_sobrepeso;
    if (bmi < 35.0) return l.imc_obesidade1;
    return l.imc_obesidade2;
  }

  Color get _color {
    if (bmi < 18.5) return const Color(0xFF5B8DF6);
    if (bmi < 25.0) return AppColors.primary;
    if (bmi < 30.0) return AppColors.warning;
    return const Color(0xFFFF6B6B);
  }

  double get _progress => ((bmi - 15) / 25).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.monitor_weight_outlined,
                    size: 14, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(L.of(context).edit_imc,
                    style: AppTypography.labelSm.copyWith(letterSpacing: 2)),
              ]),
              Text(
                '${bmi.toStringAsFixed(1)}  ·  ${_label(L.of(context))}',
                style: AppTypography.labelMd.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (_, box) {
            final w = box.maxWidth;
            return Stack(clipBehavior: Clip.none, children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(colors: [
                    Color(0xFF5B8DF6),
                    Color(0xFF7EFC00),
                    Color(0xFFFFD700),
                    Color(0xFFFF6B6B),
                  ]),
                ),
              ),
              Positioned(
                left: (w * _progress - 7).clamp(0.0, w - 14),
                top: -3,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _color, width: 2.5),
                    boxShadow: [
                      BoxShadow(color: _color.withOpacity(0.5), blurRadius: 6)
                    ],
                  ),
                ),
              ),
            ]);
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['15', '18.5', '25', '30', '40+']
                .map((l) => Text(l,
                    style: AppTypography.labelSm.copyWith(fontSize: 9)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
