import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/mk_date_field.dart';
import '../../../../shared/widgets/mk_error_banner.dart';
import '../../../../shared/widgets/mk_text_field.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Register page — 3-step flow
//  Step 0: Conta      (nome, email, senha)
//  Step 1: Corpo      (altura, peso atual, peso alvo + IMC ao vivo)
//  Step 2: Missão     (objetivo + resumo)
// ─────────────────────────────────────────────────────────────────────────────

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _pageCtrl = PageController();
  int _step = 0;
  String? _errorMessage;

  // ── Step 0 ────────────────────────────────────────────────────────────────
  final _step0Key    = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  String _passValue  = '';

  // ── Step 1 ────────────────────────────────────────────────────────────────
  final _step1Key    = GlobalKey<FormState>();
  final _heightCtrl  = TextEditingController();
  final _currWtCtrl  = TextEditingController();
  final _targWtCtrl  = TextEditingController();
  DateTime? _birthDate;
  bool _birthDateError = false;

  // ── Step 2 ────────────────────────────────────────────────────────────────
  int _weeklyGoal = 3;

  // Infere automaticamente o objetivo a partir dos pesos
  String get _goalType {
    final curr = double.tryParse(_currWtCtrl.text.replaceAll(',', '.')) ?? 0;
    final targ = double.tryParse(_targWtCtrl.text.replaceAll(',', '.')) ?? 0;
    if (curr <= 0 || targ <= 0) return 'maintain';
    if (targ < curr - 1) return 'lose_weight';
    if (targ > curr + 1) return 'gain_weight';
    return 'maintain';
  }

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() => setState(() => _passValue = _passCtrl.text));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _heightCtrl.dispose();
    _currWtCtrl.dispose();
    _targWtCtrl.dispose();
    super.dispose();
  }

  // ── IMC ao vivo ───────────────────────────────────────────────────────────
  double? get _bmi {
    final h = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
    final w = double.tryParse(_currWtCtrl.text.replaceAll(',', '.'));
    if (h == null || w == null || h <= 0 || w <= 0) return null;
    final hm = h / 100.0;
    return w / (hm * hm);
  }

  double? get _targetBmi {
    final h = double.tryParse(_heightCtrl.text.replaceAll(',', '.'));
    final t = double.tryParse(_targWtCtrl.text.replaceAll(',', '.'));
    if (h == null || t == null || h <= 0 || t <= 0) return null;
    final hm = h / 100.0;
    return t / (hm * hm);
  }

  String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Abaixo do peso';
    if (bmi < 25.0) return 'Peso normal';
    if (bmi < 30.0) return 'Sobrepeso';
    if (bmi < 35.0) return 'Obesidade grau I';
    return 'Obesidade grau II+';
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF5B8DF6);
    if (bmi < 25.0) return AppColors.primary;
    if (bmi < 30.0) return AppColors.warning;
    return const Color(0xFFFF6B6B);
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _goNext() {
    if (_step == 0 && !_step0Key.currentState!.validate()) return;
    if (_step == 1) {
      final formOk = _step1Key.currentState!.validate();
      if (_birthDate == null) setState(() => _birthDateError = true);
      if (!formOk || _birthDate == null) return;
    }
    if (_step < 2) {
      setState(() => _step++);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _goBack() {
    if (_step == 0) {
      context.go('/login');
    } else {
      setState(() => _step--);
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    final height  = double.tryParse(_heightCtrl.text.replaceAll(',', '.')) ?? 0;
    final currWt  = double.tryParse(_currWtCtrl.text.replaceAll(',', '.')) ?? 0;
    final targWt  = double.tryParse(_targWtCtrl.text.replaceAll(',', '.')) ?? 0;

    await ref.read(authControllerProvider.notifier).register(
      name:              _nameCtrl.text.trim(),
      email:             _emailCtrl.text.trim(),
      password:          _passCtrl.text,
      goalType:          _goalType,
      heightCm:          height,
      currentWeight:     currWt,
      targetWeight:      targWt,
      weeklyWorkoutGoal: _weeklyGoal,
      birthDate:         _birthDate,
    );

    if (mounted) {
      final state = ref.read(authControllerProvider);
      if (state.hasError) {
        final err = state.error;
        if (err is EmailConfirmationPendingException) {
          context.go('/confirm-email', extra: err.email);
        } else {
          setState(() => _errorMessage = _friendlyError(err!));
        }
      } else {
        context.go('/dashboard');
      }
    }
  }

  String _friendlyError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('já está cadastrado') || msg.contains('already registered')) {
      return 'Este email já está cadastrado. Faça login.';
    }
    if (msg.contains('weak_password') || msg.contains('senha')) {
      return 'Senha fraca. Use letras, números e símbolos.';
    }
    if (msg.contains('network') || msg.contains('socketexception')) {
      return 'Sem conexão com a internet.';
    }
    return 'Algo deu errado. Tente novamente.';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: back + step indicator ──────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.surfaceContainerHigh),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.onSurface, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Step progress
                  Expanded(
                    child: _StepIndicator(current: _step, total: 3),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_step + 1}/3',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Page content ─────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step0Account(
                    formKey:   _step0Key,
                    nameCtrl:  _nameCtrl,
                    emailCtrl: _emailCtrl,
                    passCtrl:  _passCtrl,
                    passValue: _passValue,
                  ),
                  _Step1Body(
                    formKey:    _step1Key,
                    heightCtrl: _heightCtrl,
                    currWtCtrl: _currWtCtrl,
                    targWtCtrl: _targWtCtrl,
                    birthDate:  _birthDate,
                    birthDateError: _birthDateError
                        ? 'Informe sua data de nascimento'
                        : null,
                    onBirthDate: (d) => setState(() {
                      _birthDate = d;
                      _birthDateError = false;
                    }),
                    bmi:        _bmi,
                    targetBmi:  _targetBmi,
                    bmiLabel:   _bmi != null ? _bmiLabel(_bmi!) : null,
                    bmiColor:   _bmi != null ? _bmiColor(_bmi!) : null,
                    onChanged:  () => setState(() {}),
                  ),
                  _Step2Frequency(
                    selected:      _weeklyGoal,
                    onSelect:      (v) => setState(() => _weeklyGoal = v),
                    goalType:      _goalType,
                    currentWeight: double.tryParse(_currWtCtrl.text) ?? 0,
                    targetWeight:  double.tryParse(_targWtCtrl.text) ?? 0,
                  ),
                ],
              ),
            ),

            // ── Erro global (ex: email já cadastrado) ────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: MkErrorBanner(
                message: _errorMessage,
                onDismiss: () => setState(() => _errorMessage = null),
                padding: EdgeInsets.zero,
              ),
            ),

            // ── Bottom button ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _goNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor:
                        AppColors.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.onPrimary))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _step < 2 ? 'PRÓXIMO' : 'CRIAR CONTA',
                              style: AppTypography.labelMd.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _step < 2
                                  ? Icons.arrow_forward
                                  : Icons.check,
                              color: AppColors.onPrimary,
                              size: 18,
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

// ─────────────────────────────────────────────────────────────────────────────
// STEP INDICATOR
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  static const _labels = ['CONTA', 'CORPO', 'MISSÃO'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          _labels[current],
          style: AppTypography.labelSm.copyWith(
            color: AppColors.primary,
            letterSpacing: 2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 6),
        // Progress bar
        Row(
          children: List.generate(total, (i) {
            final active  = i == current;
            final done    = i < current;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: done
                      ? AppColors.primary
                      : active
                          ? AppColors.primary.withOpacity(0.5)
                          : AppColors.surfaceContainerHigh,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 0 — CONTA
// ─────────────────────────────────────────────────────────────────────────────

class _Step0Account extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final String passValue;

  const _Step0Account({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.passValue,
  });

  @override
  ConsumerState<_Step0Account> createState() => _Step0AccountState();
}

class _Step0AccountState extends ConsumerState<_Step0Account> {
  final _emailFocusNode = FocusNode();
  String? _emailError;
  bool _isCheckingEmail = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onEmailFocusChange() async {
    if (_emailFocusNode.hasFocus) {
      // Usuário voltou a editar → limpa o erro anterior
      if (_emailError != null) setState(() => _emailError = null);
      return;
    }

    final email = widget.emailCtrl.text.trim();
    if (!email.contains('@')) return; // formato inválido, o validator cuida

    setState(() => _isCheckingEmail = true);
    try {
      final exists = await ref
          .read(authRepositoryProvider)
          .checkEmailExists(email);
      if (!mounted) return;
      setState(() {
        _emailError = exists
            ? 'Este e-mail já está cadastrado. Faça login.'
            : null;
      });
    } catch (_) {
      // Erro de rede: não bloqueia — o servidor validará no cadastro
      if (mounted) setState(() => _emailError = null);
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
    }
  }

  // ── Regras da senha ──────────────────────────────────────────────────────
  static bool _hasMin8(String v)   => v.length >= 8;
  static bool _hasUpper(String v)  => v.contains(RegExp(r'[A-Z]'));
  static bool _hasNumber(String v) => v.contains(RegExp(r'[0-9]'));
  static bool _hasSymbol(String v) =>
      v.contains(RegExp(r'[!@#\$%^&*()\-_=+\[\]{};:,.<>?/|\\]'));

  String? _validatePass(String? v) {
    final s = v ?? '';
    if (!_hasMin8(s))   return 'Mínimo 8 caracteres';
    if (!_hasUpper(s))  return 'Precisa de letra maiúscula (A-Z)';
    if (!_hasNumber(s)) return 'Precisa de número (0-9)';
    if (!_hasSymbol(s)) return r'Precisa de símbolo (!@#$%...)';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final passValue = widget.passValue;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text('QUEM',
                style: AppTypography.headlineLg.copyWith(
                  fontSize: 32, fontWeight: FontWeight.w700)),
            Text('É VOCÊ?',
                style: AppTypography.headlineLg.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                )),
            const SizedBox(height: 6),
            Text('Crie sua identidade de competidor',
                style: AppTypography.bodySm),

            const SizedBox(height: 36),

            _FieldLabel('NOME DE GUERREIRO'),
            const SizedBox(height: 8),
            MkTextField(
              controller: widget.nameCtrl,
              label: 'Como te chamam?',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
            ),

            const SizedBox(height: 20),

            // ── Label EMAIL + spinner ────────────────────────────────
            Row(
              children: [
                _FieldLabel('EMAIL'),
                if (_isCheckingEmail) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            MkTextField(
              controller: widget.emailCtrl,
              label: 'seu@email.com',
              keyboardType: TextInputType.emailAddress,
              focusNode: _emailFocusNode,
              errorText: _emailError,
              validator: (v) {
                if (v == null || !v.contains('@')) return 'Email inválido';
                if (_emailError != null) return _emailError;
                return null;
              },
            ),

            const SizedBox(height: 20),

            _FieldLabel('SENHA'),
            const SizedBox(height: 8),
            MkTextField(
              controller: widget.passCtrl,
              label: '••••••••',
              obscureText: true,
              validator: _validatePass,
            ),

            // ── Indicador de requisitos ──────────────────────────────
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REQUISITOS DA SENHA',
                      style: AppTypography.labelSm.copyWith(
                        letterSpacing: 1.5,
                        fontSize: 9,
                        color: AppColors.onSurfaceVariant,
                      )),
                  const SizedBox(height: 10),
                  _Req('Mínimo 8 caracteres',   _hasMin8(passValue)),
                  _Req('Letra maiúscula (A-Z)', _hasUpper(passValue)),
                  _Req('Número (0-9)',           _hasNumber(passValue)),
                  _Req('Símbolo (!@#\$%...)',    _hasSymbol(passValue)),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Already have account
            Center(
              child: TextButton(
                onPressed: () => GoRouter.of(context).go('/login'),
                child: Text('Já tenho conta →',
                    style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Linha de requisito com ícone ──────────────────────────────────────────────
class _Req extends StatelessWidget {
  final String label;
  final bool met;
  const _Req(this.label, this.met);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              met ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(met),
              size: 16,
              color: met ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              fontSize: 12,
              color: met ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — CORPO
// ─────────────────────────────────────────────────────────────────────────────

class _Step1Body extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController heightCtrl;
  final TextEditingController currWtCtrl;
  final TextEditingController targWtCtrl;
  final DateTime? birthDate;
  final String? birthDateError;
  final ValueChanged<DateTime> onBirthDate;
  final double? bmi;
  final double? targetBmi;
  final String? bmiLabel;
  final Color? bmiColor;
  final VoidCallback onChanged;

  const _Step1Body({
    required this.formKey,
    required this.heightCtrl,
    required this.currWtCtrl,
    required this.targWtCtrl,
    required this.birthDate,
    required this.birthDateError,
    required this.onBirthDate,
    required this.bmi,
    required this.targetBmi,
    required this.bmiLabel,
    required this.bmiColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text('SUAS',
                style: AppTypography.headlineLg.copyWith(
                  fontSize: 32, fontWeight: FontWeight.w700)),
            Text('MEDIDAS',
                style: AppTypography.headlineLg.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                )),
            const SizedBox(height: 6),
            Text('Usadas para IMC, meta calórica e hidratação',
                style: AppTypography.bodySm),

            const SizedBox(height: 32),

            // Altura + Peso atual — side by side
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('ALTURA'),
                      const SizedBox(height: 8),
                      _UnitField(
                        controller: heightCtrl,
                        hint: '175',
                        unit: 'cm',
                        onChanged: onChanged,
                        validator: (v) {
                          final n = double.tryParse(
                              (v ?? '').replaceAll(',', '.'));
                          if (n == null || n < 100 || n > 250) {
                            return 'Ex: 175';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('PESO ATUAL'),
                      const SizedBox(height: 8),
                      _UnitField(
                        controller: currWtCtrl,
                        hint: '80',
                        unit: 'kg',
                        onChanged: onChanged,
                        validator: (v) {
                          final n = double.tryParse(
                              (v ?? '').replaceAll(',', '.'));
                          if (n == null || n < 20 || n > 500) {
                            return 'Ex: 80';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _FieldLabel('PESO ALVO'),
            const SizedBox(height: 8),
            _UnitField(
              controller: targWtCtrl,
              hint: '72',
              unit: 'kg',
              onChanged: onChanged,
              validator: (v) {
                final n = double.tryParse(
                    (v ?? '').replaceAll(',', '.'));
                if (n == null || n < 20 || n > 500) {
                  return 'Ex: 72';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            _FieldLabel('DATA DE NASCIMENTO'),
            const SizedBox(height: 8),
            MkDateField(
              value: birthDate,
              onChanged: onBirthDate,
              errorText: birthDateError,
            ),

            const SizedBox(height: 24),

            // IMC ao vivo
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: bmi != null
                  ? _BmiLiveCard(
                      key: const ValueKey('bmi_card'),
                      bmi:       bmi!,
                      targetBmi: targetBmi,
                      label:     bmiLabel!,
                      color:     bmiColor!,
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — FREQUÊNCIA SEMANAL
// ─────────────────────────────────────────────────────────────────────────────

class _Step2Frequency extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final String goalType;
  final double currentWeight;
  final double targetWeight;

  const _Step2Frequency({
    required this.selected,
    required this.onSelect,
    required this.goalType,
    required this.currentWeight,
    required this.targetWeight,
  });

  static const _options = [2, 3, 4, 5, 6];

  String get _goalLabel {
    switch (goalType) {
      case 'lose_weight': return 'Perder Peso';
      case 'gain_weight': return 'Ganhar Massa';
      default:            return 'Manutenção';
    }
  }

  IconData get _goalIcon {
    switch (goalType) {
      case 'lose_weight': return Icons.trending_down;
      case 'gain_weight': return Icons.trending_up;
      default:            return Icons.balance;
    }
  }

  String _daysLabel(int days) {
    switch (days) {
      case 2: return 'Iniciante';
      case 3: return 'Regular';
      case 4: return 'Dedicado';
      case 5: return 'Avançado';
      case 6: return 'Elite';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SEU',
              style: AppTypography.headlineLg.copyWith(
                fontSize: 32, fontWeight: FontWeight.w700)),
          Text('COMPROMISSO',
              style: AppTypography.headlineLg.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              )),
          const SizedBox(height: 6),
          Text('Quantos dias por semana você vai treinar?',
              style: AppTypography.bodySm),

          const SizedBox(height: 32),

          // Frequência — grid de opções
          Row(
            children: _options.map((days) {
              final isSelected = days == selected;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: days != _options.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => onSelect(days),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceContainerHigh,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$days',
                            style: AppTypography.headlineMd.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            'dias',
                            style: AppTypography.labelSm.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Label do nível selecionado
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _daysLabel(selected),
                key: ValueKey(selected),
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Card de objetivo inferido automaticamente
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_goalIcon,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OBJETIVO DETECTADO',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 9,
                            letterSpacing: 2,
                          )),
                      const SizedBox(height: 2),
                      Text(_goalLabel,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.primary,
                          )),
                      if (currentWeight > 0 && targetWeight > 0)
                        Text(
                          '${currentWeight.toStringAsFixed(1)} kg → ${targetWeight.toStringAsFixed(1)} kg',
                          style: AppTypography.bodySm.copyWith(
                              fontSize: 11),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome,
                    color: AppColors.primary, size: 18),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BMI LIVE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BmiLiveCard extends StatelessWidget {
  final double bmi;
  final double? targetBmi;
  final String label;
  final Color color;
  const _BmiLiveCard({
    required this.bmi,
    required this.targetBmi,
    required this.label,
    required this.color,
    super.key,
  });

  double get _progress => ((bmi - 15) / 25).clamp(0.0, 1.0);
  double? get _tProgress =>
      targetBmi != null ? ((targetBmi! - 15) / 25).clamp(0.0, 1.0) : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.monitor_weight_outlined,
                    color: color, size: 17),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IMC CALCULADO',
                      style: AppTypography.labelSm
                          .copyWith(letterSpacing: 2, fontSize: 9)),
                  Row(
                    children: [
                      Text(bmi.toStringAsFixed(1),
                          style: AppTypography.headlineSm.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          )),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label,
                            style: AppTypography.labelSm.copyWith(
                              color: color, fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (ctx, box) {
            final w = box.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF5B8DF6),
                        Color(0xFF7EFC00),
                        Color(0xFFFFD700),
                        Color(0xFFFF6B6B),
                      ],
                    ),
                  ),
                ),
                // Current position
                Positioned(
                  left: (w * _progress) - 8,
                  top: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.45),
                            blurRadius: 6),
                      ],
                    ),
                  ),
                ),
                // Target position
                if (_tProgress != null &&
                    (_tProgress! - _progress).abs() > 0.03)
                  Positioned(
                    left: (w * _tProgress!) - 6,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 7),
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

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTypography.labelSm.copyWith(letterSpacing: 2));
}

class _UnitField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String unit;
  final VoidCallback? onChanged;
  final String? Function(String?)? validator;
  const _UnitField({
    required this.controller,
    required this.hint,
    required this.unit,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: AppTypography.bodyMd,
            onChanged: (_) => onChanged?.call(),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.error),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 46,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(unit,
                style: AppTypography.labelMd.copyWith(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant)),
          ),
        ),
      ],
    );
  }
}
