import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/mk_error_banner.dart';
import '../../../../shared/widgets/mk_otp_box.dart';
import '../../../../shared/widgets/mk_text_field.dart';
import '../../data/repositories/auth_repository.dart';

/// Segundo passo da recuperação: código + senha nova, num envio só.
///
/// Código e senha ficam na mesma tela de propósito. `verifyOTP` já autentica a
/// pessoa; se houvesse uma navegação entre validar o código e gravar a senha, o
/// redirect do GoRouter veria a sessão viva e jogaria ela no dashboard — com a
/// senha antiga ainda valendo e sem nenhum aviso de que a troca não aconteceu.
class ResetPasswordPage extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final List<TextEditingController> _codeCtrls =
      List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _codeNodes = List.generate(8, (_) => FocusNode());

  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSaving = false;
  String? _errorMessage;
  bool _codeHasError = false;

  /// Vira true assim que o código é aceito — e nunca volta.
  ///
  /// O código de recuperação é de uso único: depois do `verifyOTP` ele está
  /// queimado, mesmo que a gravação da senha falhe logo em seguida. Sem esta
  /// trava, o segundo envio revalidaria o mesmo código, tomaria 403 e a pessoa
  /// veria "código inválido" quando o problema real era a senha.
  bool _codigoValidado = false;

  @override
  void dispose() {
    for (final c in _codeCtrls) {
      c.dispose();
    }
    for (final f in _codeNodes) {
      f.dispose();
    }
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _code => _codeCtrls.map((c) => c.text).join();

  void _onBoxChanged(int index, String value) {
    if (_errorMessage != null || _codeHasError) {
      setState(() {
        _errorMessage = null;
        _codeHasError = false;
      });
    }

    // Colagem do código inteiro numa caixinha só
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
      for (int j = 0; j < 8 && j < digits.length; j++) {
        _codeCtrls[j].text = digits[j];
        _codeCtrls[j].selection =
            TextSelection.collapsed(offset: _codeCtrls[j].text.length);
      }
      // Diferente da confirmação de e-mail, completar o código aqui não envia
      // nada: ainda falta a senha. Só move o foco para o campo seguinte.
      if (digits.length >= 8) {
        _codeNodes[7].unfocus();
      } else {
        _codeNodes[digits.length.clamp(0, 7)].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 7) {
        _codeNodes[index + 1].requestFocus();
      } else {
        _codeNodes[index].unfocus();
      }
    } else if (index > 0) {
      _codeNodes[index - 1].requestFocus();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_codigoValidado && _code.length < 8) {
      setState(() {
        _errorMessage = L.of(context).recSenha_digite8;
        _codeHasError = true;
      });
      return;
    }

    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMessage = L.of(context).recSenha_naoConfere);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _codeHasError = false;
    });

    try {
      final repo = ref.read(authRepositoryProvider);

      // Só valida o código na primeira vez. Numa retentativa por senha
      // recusada, o código já foi consumido e revalidá-lo daria 403 — a sessão
      // aberta pelo verify anterior é o que permite gravar a senha agora.
      if (!_codigoValidado) {
        await repo.verifyRecoveryCode(email: widget.email, token: _code);
        if (!mounted) return;
        setState(() => _codigoValidado = true);
      }

      await repo.updatePassword(_passwordCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L.of(context).recSenha_sucesso),
          backgroundColor: AppColors.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // O verify deixou a sessão autenticada, então já entra direto.
      context.go('/dashboard');
    } on SamePasswordException {
      if (!mounted) return;
      // Erro mais comum do fluxo: quem esqueceu a senha tenta primeiro a que
      // achava que era. O código continua validado — é só escolher outra e
      // enviar de novo, sem pedir código novo.
      setState(() {
        _errorMessage = L.of(context).recSenha_senhaIgual;
        _passwordCtrl.clear();
        _confirmCtrl.clear();
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      // Antes de validar o código, qualquer AuthException é código errado.
      // Depois, o código já foi consumido: mandar digitar outro seria mentira.
      setState(() {
        _errorMessage = _codigoValidado
            ? L.of(context).recSenha_erroSalvar
            : L.of(context).recSenha_codigoInvalido;
        _codeHasError = !_codigoValidado;
        if (!_codigoValidado) {
          for (final c in _codeCtrls) {
            c.clear();
          }
          _codeNodes[0].requestFocus();
        }
      });
      debugPrint('resetPassword falhou: ${e.message}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = L.of(context).comum_algoDeuErrado);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.go('/forgot-password'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                Text(
                  L.of(context).recSenha_novaTitulo1,
                  style: AppTypography.headlineLg.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  L.of(context).recSenha_novaTitulo2,
                  style: AppTypography.headlineLg.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  L.of(context).recSenha_digiteCodigo,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Text(
                    widget.email,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Validado o código, as caixinhas ficam inertes e apagadas: ele
                // já foi consumido e reeditar não teria efeito nenhum. Sem esse
                // sinal, um erro na senha faz a pessoa mexer no código achando
                // que o problema está ali.
                IgnorePointer(
                  ignoring: _codigoValidado,
                  child: Opacity(
                    opacity: _codigoValidado ? 0.45 : 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        8,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: MkOtpBox(
                            controller: _codeCtrls[i],
                            focusNode: _codeNodes[i],
                            hasError: _codeHasError,
                            onChanged: (v) => _onBoxChanged(i, v),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (_codigoValidado)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          L.of(context).recSenha_codigoOk,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                Text(
                  L.of(context).recSenha_novaSenha,
                  style: AppTypography.labelSm.copyWith(
                    letterSpacing: 2,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                MkTextField(
                  controller: _passwordCtrl,
                  label: '••••••••',
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6
                      ? L.of(context).login_minimo6
                      : null,
                ),

                const SizedBox(height: 20),

                Text(
                  L.of(context).recSenha_confirmarSenha,
                  style: AppTypography.labelSm.copyWith(
                    letterSpacing: 2,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                MkTextField(
                  controller: _confirmCtrl,
                  label: '••••••••',
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6
                      ? L.of(context).login_minimo6
                      : null,
                ),

                MkErrorBanner(
                  message: _errorMessage,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(
                            L.of(context).recSenha_salvar,
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
