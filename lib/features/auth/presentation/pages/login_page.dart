import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../../../shared/widgets/mk_error_banner.dart';
import '../../../../shared/widgets/mk_text_field.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_clearError);
    _passwordCtrl.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _friendlyError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('invalid_credentials') || msg.contains('invalid login credentials')) {
      return L.of(context).login_credenciaisInvalidas;
    }
    if (msg.contains('email_not_confirmed') || msg.contains('not confirmed')) {
      return L.of(context).login_confirmeEmail;
    }
    if (msg.contains('user_not_found') || msg.contains('no user')) {
      return L.of(context).login_contaNaoEncontrada;
    }
    if (msg.contains('too_many_requests') || msg.contains('rate limit')) {
      return L.of(context).login_muitasTentativas;
    }
    if (msg.contains('network') || msg.contains('socketexception') || msg.contains('connection')) {
      return L.of(context).login_semInternet;
    }
    return L.of(context).comum_algoDeuErrado;
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (mounted) {
      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        setState(() => _errorMessage = _friendlyError(error));
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),

                    // ── Logo ───────────────────────────────────────
                    Row(
                      children: [
                        // Logo image (coloque logo.png em assets/images/)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.emoji_events,
                                  color: AppColors.onPrimary, size: 38),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('MUSCLE',
                                style: AppTypography.display.copyWith(
                                  fontSize: 34,
                                  height: 1,
                                )),
                            Text('CHAMP',
                                style: AppTypography.display.copyWith(
                                  fontSize: 34,
                                  color: AppColors.primary,
                                  height: 1,
                                )),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Text(
                      L.of(context).login_slogan,
                      style: AppTypography.bodyLg.copyWith(
                          color: AppColors.onSurfaceVariant),
                    ),

                    const SizedBox(height: 56),

                    // ── Form ───────────────────────────────────────
                    Text(L.of(context).login_email,
                        style: AppTypography.labelSm.copyWith(
                          letterSpacing: 2,
                          color: AppColors.onSurfaceVariant,
                        )),
                    const SizedBox(height: 8),
                    MkTextField(
                      controller: _emailCtrl,
                      label: L.of(context).login_emailHint,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@')
                          ? L.of(context).comum_emailInvalido
                          : null,
                    ),

                    const SizedBox(height: 24),

                    Text(L.of(context).login_senha,
                        style: AppTypography.labelSm.copyWith(
                          letterSpacing: 2,
                          color: AppColors.onSurfaceVariant,
                        )),
                    const SizedBox(height: 8),
                    MkTextField(
                      controller: _passwordCtrl,
                      label: '••••••••',
                      obscureText: true,
                      validator: (v) =>
                          v == null || v.length < 6
                              ? L.of(context).login_minimo6
                              : null,
                    ),

                    // ── Esqueci minha senha ───────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          L.of(context).recSenha_linkLogin,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    // ── Erro inline ───────────────────────────────
                    MkErrorBanner(
                      message: _errorMessage,
                      onDismiss: () => setState(() => _errorMessage = null),
                    ),

                    const SizedBox(height: 12),

                    // ── Login button ───────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          disabledBackgroundColor:
                              AppColors.surfaceContainerHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : Text(L.of(context).login_entrar,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.onPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                )),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Register link ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => context.go('/register'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                          side: const BorderSide(
                              color: AppColors.surfaceContainerHigh),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(L.of(context).login_criarConta,
                            style: AppTypography.labelMd.copyWith(
                              fontSize: 15,
                              letterSpacing: 2,
                            )),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Feature pills ──────────────────────────────
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FeaturePill(
                              icon: Icons.fitness_center,
                              label: L.of(context).login_pillTreinos),
                          _FeaturePill(
                              icon: Icons.restaurant,
                              label: L.of(context).login_pillDieta),
                          _FeaturePill(
                              icon: Icons.emoji_events,
                              label: L.of(context).login_pillRanking),
                          _FeaturePill(
                              icon: Icons.bolt,
                              label: L.of(context).login_pillPontos),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Idioma no login: é a PRIMEIRA tela do app. Quem não lê
                    // português precisa poder trocar antes de qualquer outra
                    // coisa — deixar só no cadastro e no perfil obriga a
                    // navegar em um idioma que a pessoa não entende.
                    const LanguageSelector(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
              )),
        ],
      ),
    );
  }
}
