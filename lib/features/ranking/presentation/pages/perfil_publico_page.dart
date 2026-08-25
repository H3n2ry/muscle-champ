/// Perfil de outro competidor, aberto ao tocar na foto no ranking.
///
/// Mostra o placar (nível, pontos, sequência, treinos, conquistas), o tipo de
/// objetivo e o plano de treino. NÃO mostra peso, altura nem idade — ver
/// `perfil_publico.dart` e a migração `20260825c_perfil_publico.sql`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/gamification/level_system.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/badge_gallery.dart';
import '../../data/models/perfil_publico.dart';
import '../providers/perfil_publico_provider.dart';

class PerfilPublicoPage extends ConsumerWidget {
  final String userId;
  const PerfilPublicoPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final perfil = ref.watch(perfilPublicoProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: perfil.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => _Erro(mensagem: l.atleta_naoCarregou),
        data: (p) => p == null
            ? _Erro(mensagem: l.atleta_naoCarregou)
            : _Conteudo(perfil: p),
      ),
    );
  }
}

class _Erro extends StatelessWidget {
  final String mensagem;
  const _Erro({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              color: AppColors.onSurface,
              onPressed: () => context.pop(),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(mensagem,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  final PerfilPublico perfil;
  const _Conteudo({required this.perfil});

  String _objetivo(L l) => switch (perfil.objetivo) {
        'lose_weight' => l.objetivo_perderPesoCap,
        'gain_weight' => l.objetivo_ganharMassaCap,
        _ => l.objetivo_manutencaoCap,
      };

  String _data(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final nivel = LevelSystem.nivelDe(perfil.totalPontos);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.background,
          pinned: true,
          expandedHeight: 280,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: AppColors.onSurface,
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.10),
                    AppColors.background,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    _Avatar(url: perfil.avatarUrl, nome: perfil.nome),
                    const SizedBox(height: 12),
                    Text(perfil.nome,
                        style: AppTypography.headlineMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(l.nivel_lvl(nivel),
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                              )),
                        ),
                        const SizedBox(width: 8),
                        Text('${l.perfil_desde} ${_data(perfil.membroDesde)}',
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Placar ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _Numero(
                      valor: '${perfil.totalPontos}',
                      rotulo: l.perfil_pontos,
                      destaque: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Numero(
                      valor: '${perfil.totalTreinos}',
                      rotulo: l.perfil_treinos,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Numero(
                      valor: '${perfil.streak}',
                      rotulo: l.perfil_sequencia,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Objetivo ──────────────────────────────────────
              // Só o tipo. Os pesos não saem do banco.
              _Rotulo(l.edit_objetivo),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceContainerHigh),
                ),
                child: Row(
                  children: [
                    Icon(
                      switch (perfil.objetivo) {
                        'lose_weight' => Icons.trending_down,
                        'gain_weight' => Icons.trending_up,
                        _ => Icons.balance,
                      },
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_objetivo(l),
                              style: AppTypography.bodyMd
                                  .copyWith(fontWeight: FontWeight.w600)),
                          if (perfil.metaSemanal > 0) ...[
                            const SizedBox(height: 2),
                            Text(l.atleta_metaSemanal(perfil.metaSemanal),
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Conquistas ────────────────────────────────────
              _Rotulo(l.perfil_conquistas),
              const SizedBox(height: 12),
              BadgeGallery(
                totalPoints: perfil.totalPontos,
                totalWorkouts: perfil.totalTreinos,
                streak: perfil.streak,
              ),

              const SizedBox(height: 24),

              // ── Plano de treino ───────────────────────────────
              _Rotulo(l.atleta_planoDeTreino),
              const SizedBox(height: 12),
              if (perfil.treinos.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceContainerHigh),
                  ),
                  child: Text(l.atleta_semTreinos,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                )
              else
                for (final t in perfil.treinos) ...[
                  _CardDeTreino(treino: t),
                  const SizedBox(height: 10),
                ],
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Peças ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? url;
  final String nome;
  const _Avatar({required this.url, required this.nome});

  @override
  Widget build(BuildContext context) {
    final inicial = nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.primary, width: 2),
        image: (url != null && url!.isNotEmpty)
            ? DecorationImage(image: NetworkImage(url!), fit: BoxFit.cover)
            : null,
      ),
      child: (url == null || url!.isEmpty)
          ? Center(
              child: Text(inicial,
                  style: AppTypography.display
                      .copyWith(fontSize: 34, color: AppColors.primary)),
            )
          : null,
    );
  }
}

class _Numero extends StatelessWidget {
  final String valor;
  final String rotulo;
  final bool destaque;
  const _Numero({
    required this.valor,
    required this.rotulo,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: destaque
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.surfaceContainerHigh,
        ),
      ),
      child: Column(
        children: [
          Text(valor,
              style: AppTypography.headlineMd.copyWith(
                color: destaque ? AppColors.primary : AppColors.onSurface,
              )),
          const SizedBox(height: 2),
          Text(rotulo,
              style: AppTypography.labelSm.copyWith(
                fontSize: 9,
                letterSpacing: 1.2,
                color: AppColors.onSurfaceVariant,
              )),
        ],
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  final String texto;
  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) => Text(
        texto,
        style: AppTypography.labelSm.copyWith(
          letterSpacing: 2,
          fontSize: 10,
          color: AppColors.onSurfaceVariant,
        ),
      );
}

class _CardDeTreino extends StatelessWidget {
  final TreinoPublico treino;
  const _CardDeTreino({required this.treino});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
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
              const Icon(Icons.fitness_center,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(treino.nome,
                    style: AppTypography.bodyMd
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              Text(
                treino.exercicios.length == 1
                    ? l.treino_exercicioCount(treino.exercicios.length)
                    : l.treino_exerciciosCount(treino.exercicios.length),
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (treino.exercicios.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final e in treino.exercicios)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.nome,
                          style: AppTypography.bodySm.copyWith(fontSize: 12)),
                    ),
                    Text(
                      '${e.series}x${e.reps}'
                      '${e.pesoKg != null && e.pesoKg! > 0 ? '  ·  ${e.pesoKg!.toStringAsFixed(0)} kg' : ''}',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
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
