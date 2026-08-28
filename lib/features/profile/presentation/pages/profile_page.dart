import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/gamification/level_system.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/seletor_de_cor.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/badge_gallery.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscription/data/repositories/assinatura_repository.dart';
import '../../../subscription/data/repositories/cota_ia_repository.dart';
import '../../../subscription/presentation/providers/assinatura_provider.dart';
import '../../../subscription/presentation/providers/cota_ia_provider.dart';
import '../../../../shared/widgets/mk_snack.dart';
import '../../data/repositories/profile_repository.dart';
import '../providers/profile_provider.dart';
import '../widgets/excluir_conta.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: profile.when(
          loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(L.of(context).perfil_erroCarregar,
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.error)),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          )),
          data: (p) => _ProfileBody(
            profile: p,
            onLogout: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ),
      ),
    );
  }
}

// ── Profile body (stateful para upload de avatar) ─────────────────────────────

class _ProfileBody extends ConsumerStatefulWidget {
  final dynamic profile;
  final VoidCallback onLogout;
  const _ProfileBody({required this.profile, required this.onLogout});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  bool _isUploadingAvatar = false;

  String get _goalLabel {
    switch (widget.profile.goalType as String) {
      case 'lose_weight':
        return L.of(context).objetivo_perdaPeso;
      case 'gain_weight':
        return L.of(context).objetivo_ganhoMassa;
      default:
        return L.of(context).objetivo_manutencaoUp;
    }
  }

  // _calcLevel local removido: era `(pontos ~/ 100) + 1`, linear, e divergia do
  // dashboard. O cálculo agora é único, em LevelSystem.

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final safeExt = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';

      await ref.read(profileRepositoryProvider).uploadAvatar(bytes, safeExt);
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${L.of(context).perfil_erroFoto}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return CustomScrollView(
      slivers: [
        // ── SliverAppBar ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 230,
          backgroundColor: AppColors.background,
          pinned: true,
          actions: [
            // Editar perfil
            IconButton(
              tooltip: 'Editar perfil',
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: AppColors.onSurface, size: 16),
              ),
              onPressed: () => context.push('/edit-profile', extra: p),
            ),
            const SizedBox(width: 4),
            // Privacidade e dados (LGPD Art. 18 / GDPR Art. 15-22)
            IconButton(
              tooltip: L.of(context).perfil_privacidadeDados,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: const Icon(Icons.shield_outlined,
                    color: AppColors.onSurface, size: 16),
              ),
              onPressed: () => context.push('/privacy'),
            ),
            const SizedBox(width: 4),
            // Sair
            IconButton(
              tooltip: L.of(context).perfil_sair,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: const Icon(Icons.logout,
                    color: AppColors.error, size: 16),
              ),
              onPressed: widget.onLogout,
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.08),
                    AppColors.background,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 52),

                    // ── Avatar clicável ────────────────────────
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Avatar circle
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primary, width: 3),
                              color: AppColors.surfaceContainer,
                            ),
                            child: _isUploadingAvatar
                                ? Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: AppColors.primary))
                                : ClipOval(
                                    child: (p.avatarUrl as String?) != null
                                        ? Image.network(
                                            p.avatarUrl as String,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Icon(Icons.person,
                                                    color: AppColors.primary,
                                                    size: 42),
                                          )
                                        : Icon(Icons.person,
                                            color: AppColors.primary,
                                            size: 42),
                                  ),
                          ),

                          // Camera icon overlay
                          if (!_isUploadingAvatar)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.background, width: 2),
                                ),
                                child: Icon(Icons.camera_alt,
                                    color: AppColors.onPrimary, size: 14),
                              ),
                            ),

                          // Level badge
                          Positioned(
                            bottom: -6,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'LVL ${LevelSystem.nivelDe(p.totalPoints as int)}',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      (p.name as String).toUpperCase(),
                      style: AppTypography.headlineMd
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TagChip(label: _goalLabel, accent: true),
                        const SizedBox(width: 8),
                        _TagChip(
                            label:
                                'DESDE ${(p.memberSince as DateTime).year}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              24, 8, 24, 80 + MediaQuery.of(context).padding.bottom),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Stats row ────────────────────────────────────
              Row(
                children: [
                  _StatBox(
                      label: L.of(context).perfil_pontos,
                      value: '${p.totalPoints}',
                      accent: true),
                  const SizedBox(width: 10),
                  _StatBox(label: L.of(context).perfil_treinos, value: '${p.totalWorkouts}'),
                  const SizedBox(width: 10),
                  _StatBox(
                      label: L.of(context).perfil_sequencia, value: '${p.streak}d'),
                ],
              ),

              const SizedBox(height: 12),
              _LevelProgressCard(points: p.totalPoints as int),

              const SizedBox(height: 24),

              // ── IMC ──────────────────────────────────────────
              if ((p.heightCm as double? ?? 0) > 0) ...[
                _SectionLabel(label: L.of(context).perfil_imc),
                const SizedBox(height: 12),
                _ProfileBmiCard(
                  heightCm:      p.heightCm as double,
                  currentWeight: p.currentWeight as double,
                  targetWeight:  p.targetWeight as double,
                ),
                const SizedBox(height: 24),
              ],

              // ── Sequência ─────────────────────────────────────
              _SectionLabel(label: L.of(context).perfil_sequenciaAtiva),
              const SizedBox(height: 12),
              _StreakCard(streak: p.streak as int),

              const SizedBox(height: 24),

              // ── Meta ──────────────────────────────────────────
              _SectionLabel(label: L.of(context).perfil_metaComposicao),
              const SizedBox(height: 12),
              _GoalProgressCard(
                goalType:      p.goalType as String,
                currentWeight: p.currentWeight as double,
                targetWeight:  p.targetWeight as double,
              ),

              const SizedBox(height: 24),

              // ── Assinatura ────────────────────────────────────
              _SectionLabel(label: L.of(context).perfil_assinatura),
              const SizedBox(height: 12),
              const _AssinaturaCard(),

              const SizedBox(height: 24),

              // ── Bioimpedância ─────────────────────────────────
              _SectionLabel(label: L.of(context).perfil_bioimpedanciaCorporal),
              const SizedBox(height: 12),
              _BioimpedanceCard(profile: p),

              const SizedBox(height: 24),

              // ── Pontuação ─────────────────────────────────────
              _SectionLabel(label: L.of(context).perfil_sistemaPontuacao),
              const SizedBox(height: 12),
              const _PointsGuideCard(),

              const SizedBox(height: 24),

              // ── Evolução ──────────────────────────────────────
              _SectionLabel(label: L.of(context).perfil_evolucaoPontos),
              const SizedBox(height: 12),
              _EvolutionChart(totalPoints: p.totalPoints as int),

              const SizedBox(height: 24),

              // ── Conquistas ────────────────────────────────────
              _SectionLabel(label: L.of(context).perfil_conquistas),
              const SizedBox(height: 12),
              BadgeGallery(
                totalPoints:   p.totalPoints as int,
                totalWorkouts: p.totalWorkouts as int,
                streak:        p.streak as int,
              ),

              const SizedBox(height: 28),

              // ── Idioma ────────────────────────────────────────
              // No fim da página, como no login: é ajuste de preferência, não
              // algo que se consulta a toda hora.
              _SectionLabel(label: L.of(context).idioma_titulo),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: const LanguageListTile(),
              ),

              const SizedBox(height: 28),

              // ── Cor do app ────────────────────────────────────
              // Junto do idioma: as duas são preferência de aparência e não
              // dado de treino.
              _SectionLabel(label: L.of(context).cor_titulo),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: const SeletorDeCor(),
              ),

              const SizedBox(height: 28),

              // ── Zona de perigo ────────────────────────────────
              // No fim da rolagem: precisa ser encontravel (o Google Play
              // exige exclusao acessivel no app) sem ficar ao alcance de um
              // toque distraido.
              _SectionLabel(label: L.of(context).perfil_zonaPerigo),
              const SizedBox(height: 12),
              const BlocoExcluirConta(),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Bioimpedance card ─────────────────────────────────────────────────────────

class _BioimpedanceCard extends ConsumerWidget {
  final dynamic profile;
  const _BioimpedanceCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasData = profile.hasBioimpedance as bool;

    if (!hasData) {
      // Estado vazio — botão para adicionar
      return GestureDetector(
        onTap: () => _showBioSheet(context, ref, profile),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.surfaceContainerHigh,
                style: BorderStyle.solid),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.electrical_services,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADICIONAR DADOS',
                        style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(L.of(context).perfil_registreComposicao,
                        style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline,
                  color: AppColors.primary, size: 22),
            ],
          ),
        ),
      );
    }

    // Com dados
    return GestureDetector(
      onTap: () => _showBioSheet(context, ref, profile),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.07),
              AppColors.surfaceContainerLow,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.electrical_services,
                      color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Text(L.of(context).perfil_composicaoCorporal,
                    style: AppTypography.labelSm
                        .copyWith(letterSpacing: 1.5, color: AppColors.primary)),
                const Spacer(),
                if (profile.bioUpdatedAt != null)
                  Text(
                    '${(profile.bioUpdatedAt as DateTime).day.toString().padLeft(2, '0')}/'
                    '${(profile.bioUpdatedAt as DateTime).month.toString().padLeft(2, '0')}',
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant, fontSize: 9),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined,
                    color: AppColors.onSurfaceVariant, size: 14),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (profile.bodyFatPct != null)
                  _BioStat(
                      label: 'GORDURA',
                      value: '${(profile.bodyFatPct as double).toStringAsFixed(1)}%',
                      icon: Icons.water_drop_outlined,
                      color: const Color(0xFFFF6B6B)),
                if (profile.muscleMassKg != null)
                  _BioStat(
                      label: L.of(context).perfil_musculo,
                      value: '${(profile.muscleMassKg as double).toStringAsFixed(1)} kg',
                      icon: Icons.fitness_center,
                      color: AppColors.primary),
                if (profile.visceralFat != null)
                  _BioStat(
                      label: 'VISCERAL',
                      value: L.of(context).perfil_nivelN2(profile.visceralFat),
                      icon: Icons.monitor_heart_outlined,
                      color: const Color(0xFFFFD700)),
                if (profile.hydrationPct != null)
                  _BioStat(
                      label: L.of(context).perfil_hidratacao,
                      value: '${(profile.hydrationPct as double).toStringAsFixed(1)}%',
                      icon: Icons.opacity,
                      color: const Color(0xFF5B8DF6)),
                if (profile.boneMassKg != null)
                  _BioStat(
                      label: L.of(context).perfil_ossea,
                      value: '${(profile.boneMassKg as double).toStringAsFixed(1)} kg',
                      icon: Icons.accessibility_new,
                      color: AppColors.warning),
                if (profile.bmrKcal != null)
                  _BioStat(
                      label: 'METAB. BASAL',
                      value: '${profile.bmrKcal} kcal',
                      icon: Icons.local_fire_department,
                      color: AppColors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBioSheet(BuildContext context, WidgetRef ref, dynamic profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BioimpedanceSheet(
        profile: profile,
        onSaved: () => ref.invalidate(profileProvider),
      ),
    );
  }
}

class _BioStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _BioStat(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTypography.labelSm
                      .copyWith(fontSize: 9, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.onSurface)),
        ],
      ),
    );
  }
}

// ── Bioimpedance input sheet ──────────────────────────────────────────────────

class _BioimpedanceSheet extends ConsumerStatefulWidget {
  final dynamic profile;
  final VoidCallback onSaved;
  const _BioimpedanceSheet({required this.profile, required this.onSaved});

  @override
  ConsumerState<_BioimpedanceSheet> createState() =>
      _BioimpedanceSheetState();
}

class _BioimpedanceSheetState extends ConsumerState<_BioimpedanceSheet> {
  late final TextEditingController _fatCtrl;
  late final TextEditingController _muscleCtrl;
  late final TextEditingController _visceralCtrl;
  late final TextEditingController _hydroCtrl;
  late final TextEditingController _boneCtrl;
  late final TextEditingController _bmrCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _fatCtrl      = TextEditingController(
        text: p.bodyFatPct != null ? (p.bodyFatPct as double).toStringAsFixed(1) : '');
    _muscleCtrl   = TextEditingController(
        text: p.muscleMassKg != null ? (p.muscleMassKg as double).toStringAsFixed(1) : '');
    _visceralCtrl = TextEditingController(
        text: p.visceralFat != null ? '${p.visceralFat}' : '');
    _hydroCtrl    = TextEditingController(
        text: p.hydrationPct != null ? (p.hydrationPct as double).toStringAsFixed(1) : '');
    _boneCtrl     = TextEditingController(
        text: p.boneMassKg != null ? (p.boneMassKg as double).toStringAsFixed(1) : '');
    _bmrCtrl      = TextEditingController(
        text: p.bmrKcal != null ? '${p.bmrKcal}' : '');
  }

  @override
  void dispose() {
    _fatCtrl.dispose();
    _muscleCtrl.dispose();
    _visceralCtrl.dispose();
    _hydroCtrl.dispose();
    _boneCtrl.dispose();
    _bmrCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).saveBioimpedance(
            bodyFatPct:   double.tryParse(_fatCtrl.text),
            muscleMassKg: double.tryParse(_muscleCtrl.text),
            visceralFat:  int.tryParse(_visceralCtrl.text),
            hydrationPct: double.tryParse(_hydroCtrl.text),
            boneMassKg:   double.tryParse(_boneCtrl.text),
            bmrKcal:      int.tryParse(_bmrCtrl.text),
          );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${L.of(context).comum_erro}: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.electrical_services,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(L.of(context).perfil_bioimpedanciaUp,
                          style: AppTypography.headlineSm
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text('dados opcionais',
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                'L.of(context).perfil_preenchaValores',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),

              const SizedBox(height: 20),

              // Grid de campos
              Row(
                children: [
                  Expanded(
                    child: _BioField(
                      ctrl: _fatCtrl,
                      label: 'GORDURA CORPORAL',
                      hint: '25.0',
                      suffix: '%',
                      icon: Icons.water_drop_outlined,
                      color: const Color(0xFFFF6B6B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BioField(
                      ctrl: _muscleCtrl,
                      label: 'MASSA MUSCULAR',
                      hint: '35.0',
                      suffix: 'kg',
                      icon: Icons.fitness_center,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BioField(
                      ctrl: _visceralCtrl,
                      label: 'GORDURA VISCERAL',
                      hint: '1–20',
                      suffix: L.of(context).perfil_nivelMinusculo,
                      icon: Icons.monitor_heart_outlined,
                      color: const Color(0xFFFFD700),
                      isInt: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BioField(
                      ctrl: _hydroCtrl,
                      label: L.of(context).perfil_hidratacao,
                      hint: '60.0',
                      suffix: '%',
                      icon: Icons.opacity,
                      color: const Color(0xFF5B8DF6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BioField(
                      ctrl: _boneCtrl,
                      label: L.of(context).perfil_massaOssea,
                      hint: '3.0',
                      suffix: 'kg',
                      icon: Icons.accessibility_new,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BioField(
                      ctrl: _bmrCtrl,
                      label: 'METAB. BASAL',
                      hint: '1800',
                      suffix: 'kcal',
                      icon: Icons.local_fire_department,
                      color: AppColors.warning,
                      isInt: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.onPrimary))
                      : Text(L.of(context).perfil_salvarBioimpedancia,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BioField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final String suffix;
  final IconData icon;
  final Color color;
  final bool isInt;

  const _BioField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.icon,
    required this.color,
    this.isInt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: AppTypography.labelSm
                    .copyWith(fontSize: 9, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: isInt
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
            suffixText: suffix,
            suffixStyle: AppTypography.labelSm
                .copyWith(color: AppColors.onSurfaceVariant, fontSize: 10),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.surfaceContainerHigh),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ── Points guide card ─────────────────────────────────────────────────────────

class _PointsGuideCard extends StatelessWidget {
  const _PointsGuideCard();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.fitness_center,    '+10 pts', L.of(context).perfil_pontosTreino),
      (Icons.restaurant,        '+10 pts', L.of(context).perfil_pontosDieta),
      (Icons.trending_up,       '+5 pts',  L.of(context).perfil_pontosProgressao),
      (Icons.monitor_weight,    '+20 pts', L.of(context).perfil_pontosEvolucao),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        children: items.map((item) {
          final (icon, pts, desc) = item;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(desc, style: AppTypography.bodyMd),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(pts,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      )),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Profile BMI card ──────────────────────────────────────────────────────────

class _ProfileBmiCard extends StatelessWidget {
  final double heightCm;
  final double currentWeight;
  final double targetWeight;
  const _ProfileBmiCard({
    required this.heightCm,
    required this.currentWeight,
    required this.targetWeight,
  });

  double get _bmi {
    final hm = heightCm / 100.0;
    return currentWeight / (hm * hm);
  }

  double get _targetBmi {
    if (targetWeight <= 0) return _bmi;
    final hm = heightCm / 100.0;
    return targetWeight / (hm * hm);
  }

  String _label(double bmi, L l) {
    if (bmi < 18.5) return l.imc_abaixoPeso;
    if (bmi < 25.0) return l.imc_normalOk;
    if (bmi < 30.0) return l.imc_sobrepeso;
    if (bmi < 35.0) return l.imc_obesidade1;
    return l.imc_obesidade2;
  }

  Color _color(double bmi) {
    if (bmi < 18.5) return const Color(0xFF5B8DF6);
    if (bmi < 25.0) return AppColors.primary;
    if (bmi < 30.0) return AppColors.warning;
    return const Color(0xFFFF6B6B);
  }

  double _progress(double bmi) => ((bmi - 15) / 25).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final bmi   = _bmi;
    final tBmi  = _targetBmi;
    final color = _color(bmi);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(L.of(context).perfil_imcAtual,
                        style: AppTypography.labelSm
                            .copyWith(letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(bmi.toStringAsFixed(1),
                            style: AppTypography.headlineLg.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            )),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('  ${_label(bmi, L.of(context))}',
                              style: AppTypography.bodySm),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MiniInfo(
                      label: L.of(context).perfil_altura,
                      value: '${heightCm.toInt()} cm'),
                  const SizedBox(height: 4),
                  _MiniInfo(
                      label: L.of(context).perfil_peso,
                      value: '${currentWeight.toStringAsFixed(1)} kg'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (ctx, box) {
            final w = box.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(colors: [
                      Color(0xFF5B8DF6),
                      Color(0xFF7EFC00),
                      Color(0xFFFFD700),
                      Color(0xFFFF6B6B),
                    ]),
                  ),
                ),
                Positioned(
                  left: (w * _progress(bmi) - 7).clamp(0.0, w - 14),
                  top: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.5), blurRadius: 6)
                      ],
                    ),
                  ),
                ),
                if ((tBmi - bmi).abs() > 0.5)
                  Positioned(
                    left: (w * _progress(tBmi) - 5).clamp(0.0, w - 10),
                    top: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['15', '18.5', '25', '30', '40+']
                .map((l) =>
                    Text(l, style: AppTypography.labelSm.copyWith(fontSize: 9)))
                .toList(),
          ),
          if (targetWeight > 0 && (tBmi - bmi).abs() > 0.5) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_outlined,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${L.of(context).perfil_metaImc} ${tBmi.toStringAsFixed(1)} '
                      '(${_label(tBmi, L.of(context))})  '
                      '${L.of(context).perfil_comKg(targetWeight.toStringAsFixed(1))}',
                      style: AppTypography.bodySm.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String value;
  const _MiniInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppTypography.labelSm.copyWith(fontSize: 9)),
        Text(value,
            style:
                AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Tag chip ──────────────────────────────────────────────────────────────────

class _TagChip extends StatelessWidget {
  final String label;
  final bool accent;
  const _TagChip({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.outlineVariant,
        ),
      ),
      child: Text(label,
          style: AppTypography.labelSm.copyWith(
            fontSize: 10,
            color: accent
                ? AppColors.primary
                : AppColors.onSurfaceVariant,
          )),
    );
  }
}

// ── Stat box ──────────────────────────────────────────────────────────────────

/// Progresso rumo ao próximo nível.
///
/// A barra usa a faixa DO NÍVEL (do requisito atual até o próximo), não os
/// pontos totais — senão ela ficaria quase cheia o tempo todo conforme os
/// requisitos crescem.
class _LevelProgressCard extends StatelessWidget {
  final int points;
  const _LevelProgressCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final nivel    = LevelSystem.nivelDe(points);
    final falta    = LevelSystem.pontosParaProximo(points);
    final progresso = LevelSystem.progressoNoNivel(points);
    final alvo     = LevelSystem.requisito(nivel + 1);
    final noTeto   = nivel >= LevelSystem.nivelMaximo;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(L.of(context).nivel_nivelN(nivel),
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.primary)),
              const Spacer(),
              if (!noTeto)
                Text(L.of(context).nivel_nivelN(nivel + 1),
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progresso,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor:
                  AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          if (noTeto)
            Text(L.of(context).perfil_nivelMaximoAlcancado,
                style: AppTypography.bodySm.copyWith(fontSize: 12))
          else
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.bodySm.copyWith(fontSize: 12),
                      children: [
                        TextSpan(
                          text: '$falta ',
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: falta == 1
                              ? L.of(context).nivel_pontoParaNivelResto(nivel + 1)
                              : L.of(context).nivel_pontosParaNivelResto(nivel + 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Text('$points / $alvo',
                    style: AppTypography.bodySm.copyWith(fontSize: 11)),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;
  const _StatBox(
      {required this.label, required this.value, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: accent
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.surfaceContainerHigh,
          ),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTypography.headlineSm.copyWith(
                  color: accent
                      ? AppColors.primary
                      : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 4),
            Text(label,
                style: AppTypography.labelSm.copyWith(fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTypography.labelSm.copyWith(letterSpacing: 2));
  }
}

// ── Streak card ───────────────────────────────────────────────────────────────

/// Card de sequência: 7 caixas terminando HOJE na direita.
///
/// A versão anterior tinha dois bugs. Os rótulos eram um array fixo começando
/// na segunda, então a faixa nunca batia com o dia real; e o preenchimento
/// acendia as N primeiras caixas da esquerda, sem relação com o dia que cada
/// uma representava. Agora cada caixa é um dia concreto vindo do servidor.
class _StreakCard extends ConsumerWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semana = ref.watch(weekActivityProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Text(L.of(context).perfil_diasConsecutivos(streak),
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          semana.when(
            loading: () => const SizedBox(
              height: 52,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => SizedBox(
              height: 52,
              child: Center(
                child: Text(L.of(context).perfil_semanaNaoCarregou,
                    style: AppTypography.bodySm.copyWith(fontSize: 11)),
              ),
            ),
            data: (dias) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < dias.length; i++)
                  Builder(builder: (_) {
                    final d = dias[i];
                    final hoje = i == dias.length - 1;
                    return Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: d.treinou
                                ? AppColors.warning.withOpacity(0.2)
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: d.treinou
                                  ? AppColors.warning
                                  : hoje
                                      // Hoje sem treino: contorno destacado,
                                      // para o usuário achar o dia atual.
                                      ? AppColors.primary.withOpacity(0.7)
                                      : AppColors.outlineVariant,
                              width: hoje ? 1.5 : 1,
                            ),
                          ),
                          child: d.treinou
                              ? const Icon(Icons.local_fire_department,
                                  color: AppColors.warning, size: 16)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.inicial,
                          style: AppTypography.labelSm.copyWith(
                            fontSize: 9,
                            color: hoje
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            fontWeight:
                                hoje ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Goal progress card ────────────────────────────────────────────────────────

class _GoalProgressCard extends StatelessWidget {
  final String goalType;
  final double currentWeight;
  final double targetWeight;
  const _GoalProgressCard({
    required this.goalType,
    required this.currentWeight,
    required this.targetWeight,
  });

  String _goalLabel(L l) {
    switch (goalType) {
      case 'lose_weight':
        return l.objetivo_perderPesoCap;
      case 'gain_weight':
        return l.objetivo_ganharMassaCap;
      default:
        return l.objetivo_manutencaoCap;
    }
  }

  double get _progress {
    if (targetWeight == 0 || currentWeight == 0) return 0;
    if (goalType == 'lose_weight') {
      if (currentWeight <= targetWeight) return 1.0;
      return 1.0 - ((currentWeight - targetWeight) / currentWeight);
    } else if (goalType == 'gain_weight') {
      if (currentWeight >= targetWeight) return 1.0;
      return currentWeight / targetWeight;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_goalLabel(L.of(context)), style: AppTypography.bodyMd),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('ATIVO',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.primary,
                      fontSize: 10,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ATUAL', style: AppTypography.labelSm),
                    Text(
                      '${currentWeight.toStringAsFixed(1)} kg',
                      style: AppTypography.headlineSm,
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward,
                    color: AppColors.onSurfaceVariant, size: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('META', style: AppTypography.labelSm),
                    Text(
                      '${targetWeight.toStringAsFixed(1)} kg',
                      style: AppTypography.headlineSm
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor:
                  AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            L.of(context).perfil_percentualObjetivo((_progress * 100).toStringAsFixed(0)),
            style: AppTypography.bodySm,
          ),
        ],
      ),
    );
  }
}

// ── Evolution chart ───────────────────────────────────────────────────────────

/// Curva acumulada de pontos das últimas 6 semanas.
///
/// Já foi um desenho decorativo — dividia o total em seis fatias iguais, então
/// a escada saía idêntica para qualquer usuário em qualquer momento. Agora as
/// barras vêm da tabela `points` e a última fecha exatamente no total do perfil.
class _EvolutionChart extends ConsumerWidget {
  final int totalPoints;
  const _EvolutionChart({required this.totalPoints});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semanas = ref.watch(pointsEvolutionProvider(totalPoints));

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: semanas.when(
        loading: () => Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        ),
        error: (_, __) => Center(
          child: Text(L.of(context).perfil_evolucaoNaoCarregou,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ),
        data: (ws) => ws.last.acumulado == 0
            ? Center(
                child: Text(L.of(context).perfil_semDados,
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant)),
              )
            : _grafico(context, ws),
      ),
    );
  }

  Widget _grafico(BuildContext context, List<WeeklyPoints> ws) {
    final l = L.of(context);
    final topo = ws.last.acumulado;

    return BarChart(
      BarChartData(
        maxY: (topo * 1.15).ceilToDouble(),
        barGroups: ws.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.acumulado.toDouble(),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.4),
                    AppColors.primary,
                  ],
                ),
                width: 18,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceContainerHigh,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, _, __, ___) {
              final w = ws[group.x];
              return BarTooltipItem(
                l.perfil_tooltipSemana(w.acumulado, w.ganhos),
                AppTypography.bodySm.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= ws.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${l.perfil_semanaAbrev}${i + 1}',
                      style: AppTypography.labelSm.copyWith(fontSize: 9)),
                );
              },
              reservedSize: 22,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.surfaceContainerHigh,
            strokeWidth: 1,
          ),
        ),
      ),
    );
  }
}

// ── Badge gallery ─────────────────────────────────────────────────────────────

// ── Assinatura ───────────────────────────────────────────────────────────────

/// Estado da assinatura no perfil.
///
/// ⚠️ DEMONSTRAÇÃO: lê de SharedPreferences, não de entitlement no servidor.
/// Nenhuma função do app está bloqueada por isto — decidir o que é grátis e o
/// que é Pro ainda está em aberto.
class _AssinaturaCard extends ConsumerWidget {
  const _AssinaturaCard();

  String _data(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final assinatura = ref.watch(assinaturaProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: assinatura.when(
        loading: () => SizedBox(
          height: 44,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        ),
        error: (_, __) => Text(l.comum_algoDeuErrado,
            style: AppTypography.bodySm
                .copyWith(color: AppColors.onSurfaceVariant)),
        data: (a) => a == null || !a.ativa
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _semAssinatura(context, l),
                  // Só para conta de desenvolvimento: a RPC recusa o resto,
                  // e botão que sempre falha é pior que botão nenhum.
                  if (ref.watch(contaDeTesteProvider).valueOrNull ?? false)
                    _zerarCota(context, ref, l),
                ],
              )
            : _comAssinatura(context, ref, l, a),
      ),
    );
  }

  /// Atalho de desenvolvimento: zera o contador do dia para dar para testar
  /// o limite sem esperar a meia-noite. Sai junto com o modo demonstração.
  Widget _zerarCota(BuildContext context, WidgetRef ref, L l) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () async {
            await ref.read(cotaIaRepositoryProvider).zerar();
            ref.invalidate(saldosDeCotaProvider);
            if (context.mounted) MkSnack.success(context, l.cota_zerada);
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(l.cota_zerarDemo,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.warning,
                fontSize: 11,
              )),
        ),
      );

  Widget _semAssinatura(BuildContext context, L l) => Row(
        children: [
          Icon(Icons.workspace_premium_outlined,
              size: 22, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(l.perfil_planoGratuito,
                style: AppTypography.bodyMd
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => context.push('/assinatura'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: Text(l.perfil_verPlanos,
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.primary, fontSize: 12)),
          ),
        ],
      );

  Widget _comAssinatura(
      BuildContext context, WidgetRef ref, L l, Assinatura a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.workspace_premium,
                size: 22, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l.perfil_proAtivo,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          a.emTrial
              ? l.perfil_trialRestante(a.diasRestantes)
              : l.perfil_renovaEm(_data(a.expiraEm)),
          style: AppTypography.bodySm
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceContainerLow,
                  content: Text(l.perfil_cancelarConfirma,
                      style: AppTypography.bodySm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l.comum_cancelar),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.perfil_cancelarAssinatura,
                          style: const TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              await ref.read(assinaturaControllerProvider).cancelar();
              if (context.mounted) {
                MkSnack.success(context, l.perfil_assinaturaCancelada);
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l.perfil_cancelarAssinatura,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  decoration: TextDecoration.underline,
                  fontSize: 12,
                )),
          ),
        ),
      ],
    );
  }
}
