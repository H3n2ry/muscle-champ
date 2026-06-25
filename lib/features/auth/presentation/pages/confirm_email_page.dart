import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/repositories/auth_repository.dart';

class ConfirmEmailPage extends ConsumerStatefulWidget {
  final String email;
  const ConfirmEmailPage({super.key, required this.email});

  @override
  ConsumerState<ConfirmEmailPage> createState() => _ConfirmEmailPageState();
}

class _ConfirmEmailPageState extends ConsumerState<ConfirmEmailPage> {
  final List<TextEditingController> _controllers =
      List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(8, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  String? _errorMsg;

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  // ── Verificar código ──────────────────────────────────────────────────────

  Future<void> _verify() async {
    final code = _code;
    if (code.length < 8) {
      setState(() => _errorMsg = 'Digite todos os 8 dígitos');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMsg = null;
    });

    try {
      await ref.read(authRepositoryProvider).verifyOtp(
            email: widget.email,
            token: code,
          );
      if (mounted) context.go('/dashboard');
    } on AuthException catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Código inválido ou expirado. Verifique e tente novamente.';
      });
      // Limpar caixinhas e focar na primeira
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Algo deu errado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // ── Reenviar código ──────────────────────────────────────────────────────

  Future<void> _resend() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).resendConfirmation(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código reenviado para ${widget.email}'),
          backgroundColor: AppColors.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startCountdown(60);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao reenviar o código. Tente novamente.'),
          backgroundColor: AppColors.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startCountdown(int seconds) {
    setState(() => _resendCountdown = seconds);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _resendCountdown = 0;
          timer.cancel();
        }
      });
    });
  }

  // ── Lógica das caixinhas ──────────────────────────────────────────────────

  void _onBoxChanged(int index, String value) {
    setState(() => _errorMsg = null);

    // Suporte a colar o código completo (8 dígitos de uma vez)
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
      for (int j = 0; j < 8 && j < digits.length; j++) {
        _controllers[j].text = digits[j];
        _controllers[j].selection = TextSelection.collapsed(
          offset: _controllers[j].text.length,
        );
      }
      if (digits.length >= 8) {
        _focusNodes[7].unfocus();
        _verify();
      } else {
        final next = digits.length.clamp(0, 7);
        _focusNodes[next].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 7) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Última caixinha preenchida → verificar automaticamente
        _focusNodes[index].unfocus();
        _verify();
      }
    } else {
      // Deletou → voltar para caixinha anterior
      if (index > 0) _focusNodes[index - 1].requestFocus();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 56),

              // Ícone
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.primary,
                  size: 48,
                ),
              ),

              const SizedBox(height: 32),

              // Título
              Text(
                'VERIFIQUE',
                style: AppTypography.headlineLg.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'SEU EMAIL',
                style: AppTypography.headlineLg.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 20),

              // Descrição
              Text(
                'Enviamos um código de 8 dígitos para:',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Text(
                  widget.email,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Caixinhas OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  8,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _OtpBox(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      hasError: _errorMsg != null,
                      onChanged: (v) => _onBoxChanged(i, v),
                    ),
                  ),
                ),
              ),

              // Mensagem de erro
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _errorMsg != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _errorMsg!,
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 36),

              // Botão CONFIRMAR
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.onPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'CONFIRMAR',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Reenviar código
              TextButton(
                onPressed:
                    (_resendCountdown > 0 || _isResending) ? null : _resend,
                child: _isResending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.onSurfaceVariant,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _resendCountdown > 0
                            ? 'Reenviar código em ${_resendCountdown}s'
                            : 'Não recebeu o código? Reenviar',
                        style: AppTypography.bodyMd.copyWith(
                          color: _resendCountdown > 0
                              ? AppColors.onSurfaceVariant.withOpacity(0.5)
                              : AppColors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
              ),

              const SizedBox(height: 8),

              // Usar outro e-mail
              TextButton(
                onPressed: () => context.go('/register'),
                child: Text(
                  'Usar outro e-mail',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget de caixinha individual ─────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 52,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.text,
        maxLength: 8, // Permite 8 para capturar cola, tratado no onChanged
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]'))],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.surfaceContainerLow,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError
                  ? AppColors.error
                  : AppColors.outlineVariant,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasError ? AppColors.error : AppColors.primary,
              width: 2,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.outlineVariant),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
