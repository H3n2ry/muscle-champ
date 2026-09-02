import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/completude_do_perfil.dart';
import '../../../../core/legal/legal_documents.dart';
import '../../../../core/legal/legal_texts.dart';
import '../../../../shared/widgets/legal_document_sheet.dart';
import '../../../../core/legal/privacy_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/mk_date_field.dart';
import '../../../../shared/widgets/mk_error_banner.dart';
import '../../../../shared/widgets/mk_text_field.dart';

/// Completa o que o login social não coleta.
///
/// O cadastro por e-mail tem três passos; o OAuth substitui só o primeiro
/// (nome, e-mail, senha). Data de nascimento, corpo e consentimentos continuam
/// obrigatórios e caem aqui.
///
/// Não é tela de "melhorar o perfil": sem ela a conta fica sem verificação de
/// idade e sem base legal para tratar dado de saúde. Ver
/// [CompletudeDoPerfil] para o que exatamente falta e por quê.
class CompletarPerfilPage extends ConsumerStatefulWidget {
  const CompletarPerfilPage({super.key});

  @override
  ConsumerState<CompletarPerfilPage> createState() =>
      _CompletarPerfilPageState();
}

class _CompletarPerfilPageState extends ConsumerState<CompletarPerfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _heightCtrl = TextEditingController();
  final _currWtCtrl = TextEditingController();
  final _targWtCtrl = TextEditingController();

  DateTime? _birthDate;
  bool _birthDateError = false;
  int _weeklyGoal = 3;
  bool _salvando = false;
  String? _erro;

  /// Todos começam desmarcados — consentimento pré-marcado não é consentimento
  /// válido (GDPR Art. 4(11) / LGPD Art. 5 XII).
  final Map<String, bool> _consents = {
    for (final c in LegalTexts.signupConsents) c.type: false,
  };

  bool get _obrigatoriosOk => LegalTexts.signupConsents
      .where((c) => c.required)
      .every((c) => _consents[c.type] == true);

  @override
  void dispose() {
    _heightCtrl.dispose();
    _currWtCtrl.dispose();
    _targWtCtrl.dispose();
    super.dispose();
  }

  /// Mesma inferência do cadastro: o objetivo sai da diferença entre os pesos,
  /// em vez de perguntar de novo.
  String get _goalType {
    final curr = double.tryParse(_currWtCtrl.text.replaceAll(',', '.')) ?? 0;
    final targ = double.tryParse(_targWtCtrl.text.replaceAll(',', '.')) ?? 0;
    if (curr <= 0 || targ <= 0) return 'maintain';
    if (targ < curr - 1) return 'lose_weight';
    if (targ > curr + 1) return 'gain_weight';
    return 'maintain';
  }

  /// Alterna um consentimento, abrindo o documento quando existe.
  ///
  /// Mesmo comportamento do cadastro por e-mail: Termos e Privacidade só podem
  /// ser marcados depois de abrir e rolar até o fim. Sem isso o consentimento
  /// não é informado — e consentimento não informado não vale (GDPR Art.
  /// 4(11) / LGPD Art. 5 XII). A primeira versão desta tela mostrava só o
  /// rótulo, sem nenhuma forma de ler o que estava sendo aceito.
  ///
  /// Desmarcar nunca abre documento: só faz sentido exigir leitura para aceitar.
  Future<void> _alternar(ConsentItem item) async {
    final marcado = _consents[item.type] ?? false;
    final doc = LegalDocuments.forConsent(item.type);

    if (doc == null || marcado) {
      setState(() => _consents[item.type] = !marcado);
      return;
    }

    final aceitou = await LegalDocumentSheet.show(context, doc);
    if (aceitou == true && mounted) {
      setState(() => _consents[item.type] = true);
    }
  }

  Future<void> _salvar() async {
    setState(() => _erro = null);

    final formOk = _formKey.currentState!.validate();
    if (_birthDate == null) setState(() => _birthDateError = true);
    if (!formOk || _birthDate == null) return;

    // A barreira de idade. É o motivo principal desta tela existir: o fluxo
    // OAuth não passa por `register_page._goNext()` nem por
    // `AuthRepository.register()`, que são onde ela é aplicada no cadastro
    // por e-mail.
    if (!LegalTexts.isOldEnough(_birthDate!)) {
      setState(() => _erro = LegalTexts.underageMessage);
      return;
    }

    if (!_obrigatoriosOk) {
      setState(() => _erro = L.of(context).comum_algoDeuErrado);
      return;
    }

    setState(() => _salvando = true);
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser!.id;

      // O trigger `handle_new_user` já criou a linha de goals com valores
      // inventados (170cm, 70kg). Aqui ela é sobrescrita com o que a pessoa
      // realmente informou. O trigger `trg_goals_recalc` recalcula a meta de
      // água e as calorias a partir do peso e da data de nascimento.
      await client.from('goals').update({
        'birth_date': _birthDate!.toIso8601String().substring(0, 10),
        'height_cm': double.parse(_heightCtrl.text.replaceAll(',', '.')),
        'current_weight': double.parse(_currWtCtrl.text.replaceAll(',', '.')),
        'target_weight': double.parse(_targWtCtrl.text.replaceAll(',', '.')),
        'weekly_workout_goal': _weeklyGoal,
        'goal_type': _goalType,
      }).eq('user_id', uid);

      // Um `grant_consent` por finalidade aceita. A RPC grava linha nova com a
      // versão atual dos documentos — é assim que o registro append-only
      // mantém a trilha de responsabilização (LGPD 6 X / GDPR 5(2)).
      final repo = ref.read(privacyRepositoryProvider);
      for (final item in LegalTexts.signupConsents) {
        if (_consents[item.type] == true) {
          await repo.grantConsent(item.type);
        }
      }

      // Marca o espelho ANTES de navegar. `ref.invalidate` sozinho não serve
      // aqui por dois motivos, e os dois travavam a tela:
      //
      //   1. Ele agenda a re-consulta, não espera por ela. O `context.go`
      //      abaixo rodaria com o espelho ainda em `true`, e o redirect
      //      devolveria a pessoa para cá — preso num anel.
      //   2. O provider é autoDispose e nada o observa nesta tela, então o
      //      invalidate nem refaz a consulta.
      //
      // Acabamos de gravar tudo que faltava, então o valor é conhecido: não há
      // por que perguntar ao banco antes de sair.
      PerfilIncompleto.valor = false;
      ref.invalidate(completudeDoPerfilProvider);
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = L.of(context).comum_algoDeuErrado);
      debugPrint('completarPerfil falhou: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUASE',
                  style: AppTypography.headlineLg
                      .copyWith(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                Text(
                  'LÁ',
                  style: AppTypography.headlineLg.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Faltam alguns dados para o app calcular suas metas e para '
                  'registrarmos sua autorização.',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),

                const SizedBox(height: 30),
                _rotulo(context, 'DATA DE NASCIMENTO'),
                MkDateField(
                  value: _birthDate,
                  errorText: _birthDateError ? 'Informe sua data de nascimento' : null,
                  lastDate: DateTime.now(),
                  onChanged: (d) => setState(() {
                    _birthDate = d;
                    _birthDateError = false;
                  }),
                ),

                const SizedBox(height: 20),
                _rotulo(context, 'ALTURA (CM)'),
                MkTextField(
                  controller: _heightCtrl,
                  label: '175',
                  keyboardType: TextInputType.number,
                  validator: (v) => _numeroEntre(v, 50, 250),
                ),

                const SizedBox(height: 20),
                _rotulo(context, 'PESO ATUAL (KG)'),
                MkTextField(
                  controller: _currWtCtrl,
                  label: '70',
                  keyboardType: TextInputType.number,
                  validator: (v) => _numeroEntre(v, 20, 500),
                ),

                const SizedBox(height: 20),
                _rotulo(context, 'PESO ALVO (KG)'),
                MkTextField(
                  controller: _targWtCtrl,
                  label: '68',
                  keyboardType: TextInputType.number,
                  validator: (v) => _numeroEntre(v, 20, 500),
                ),

                const SizedBox(height: 20),
                _rotulo(context, 'TREINOS POR SEMANA'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final n in const [2, 3, 4, 5, 6])
                      ChoiceChip(
                        label: Text('$n'),
                        selected: _weeklyGoal == n,
                        onSelected: (_) => setState(() => _weeklyGoal = n),
                      ),
                  ],
                ),

                const SizedBox(height: 30),
                _rotulo(context, 'PRIVACIDADE'),
                const SizedBox(height: 6),
                for (final item in LegalTexts.signupConsents)
                  CheckboxListTile(
                    value: _consents[item.type],
                    onChanged: (_) => _alternar(item),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.required ? '${item.label} *' : item.label,
                            style: AppTypography.bodyMd.copyWith(
                              // Sublinhado só no que abre documento, para o
                              // toque parecer o que é: um link.
                              decoration:
                                  LegalDocuments.forConsent(item.type) != null
                                      ? TextDecoration.underline
                                      : null,
                            ),
                          ),
                        ),
                        if (LegalDocuments.forConsent(item.type) != null) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.article_outlined,
                              size: 14, color: AppColors.onSurfaceVariant),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      item.detail,
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),

                MkErrorBanner(
                  message: _erro,
                  onDismiss: () => setState(() => _erro = null),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_salvando || !_obrigatoriosOk) ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _salvando
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(
                            'COMEÇAR',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rotulo(BuildContext context, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          texto,
          style: AppTypography.labelSm.copyWith(
            letterSpacing: 2,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      );

  String? _numeroEntre(String? v, double min, double max) {
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    if (n == null || n < min || n > max) return 'Entre $min e $max';
    return null;
  }
}
