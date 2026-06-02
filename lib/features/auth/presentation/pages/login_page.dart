import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/mk_text_field.dart';
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
    if (mounted) {
      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppColors.errorContainer,
          ),
        );
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
                              child: const Icon(Icons.emoji_events,
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
                      'Compete. Evolua. Domine.',
                      style: AppTypography.bodyLg.copyWith(
                          color: AppColors.onSurfaceVariant),
                    ),

                    const SizedBox(height: 56),

                    // ── Form ───────────────────────────────────────
                    Text('EMAIL',
                        style: AppTypography.labelSm.copyWith(
                          letterSpacing: 2,
                          color: AppColors.onSurfaceVariant,
                        )),
                    const SizedBox(height: 8),
                    MkTextField(
                      controller: _emailCtrl,
                      label: 'seu@email.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Email inválido'
                          : null,
                    ),

                    const SizedBox(height: 24),

                    Text('SENHA',
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
                              ? 'Mínimo 6 caracteres'
                              : null,
                    ),

                    const SizedBox(height: 40),

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
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : Text('ENTRAR',
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
                        child: Text('CRIAR CONTA',
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
                        children: const [
                          _FeaturePill(
                              icon: Icons.fitness_center,
                              label: 'Treinos'),
                          _FeaturePill(
                              icon: Icons.restaurant,
                              label: 'Dieta'),
                          _FeaturePill(
                              icon: Icons.emoji_events,
                              label: 'Ranking'),
                          _FeaturePill(
                              icon: Icons.bolt, label: 'Pontos'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
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
