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
import '../../../../shared/widgets/mk_snack.dart';
import '../../../workout/presentation/providers/workout_template_provider.dart';
import '../../data/models/perfil_publico.dart';
import '../../data/repositories/ranking_repository.dart';
import '../providers/perfil_publico_provider.dart';
import '../providers/ranking_provider.dart';

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
                    _Avatar(
                      url: perfil.avatarUrl,
                      nome: perfil.nome,
                      userId: perfil.id,
                      amizade: perfil.amizade,
                    ),
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
                  _CardDeTreino(treino: t, dono: perfil.nome),
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

class _Avatar extends ConsumerStatefulWidget {
  final String? url;
  final String nome;
  final String userId;
  final String amizade;

  const _Avatar({
    required this.url,
    required this.nome,
    required this.userId,
    required this.amizade,
  });

  @override
  ConsumerState<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends ConsumerState<_Avatar> {
  bool _ocupado = false;

  /// Vínculo como esta tela enxerga AGORA.
  ///
  /// Espelha `widget.amizade` e é atualizado no toque, para o selo trocar na
  /// hora. Recarregar o perfil pelo servidor também funcionaria, mas piscaria
  /// a tela inteira em loading por causa de um toque num cantinho.
  late String _estado = widget.amizade;

  Future<void> _pedirAmizade() async {
    final l = L.of(context);
    setState(() => _ocupado = true);
    try {
      await ref
          .read(rankingRepositoryProvider)
          .sendFriendRequest(widget.userId);
      // O ranking de amigos precisa reler; sem isto a mudança só apareceria
      // lá na próxima abertura do app.
      ref.invalidate(friendsRankingProvider);
      if (mounted) {
        setState(() => _estado = 'pendente');
        MkSnack.success(context, l.atleta_pedidoEnviado);
      }
    } catch (_) {
      if (mounted) MkSnack.error(context, l.atleta_falhaPedido);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _desfazerAmizade() async {
    final l = L.of(context);

    // Confirma antes: o selo é pequeno e fica colado na foto — um toque
    // errado apagaria a amizade sem aviso. Mesmo diálogo do ranking.
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLow,
        title: Text(l.rank_removerAmigo, style: AppTypography.headlineSm),
        content: Text(l.rank_seraRemovido(widget.nome),
            style: AppTypography.bodySm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.comum_cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.atleta_removerAmigo,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;

    setState(() => _ocupado = true);
    try {
      await ref.read(rankingRepositoryProvider).removeFriend(widget.userId);
      ref.invalidate(friendsRankingProvider);
      if (mounted) {
        setState(() => _estado = 'nenhum');
        MkSnack.success(context, l.atleta_amizadeDesfeita);
      }
    } catch (_) {
      if (mounted) MkSnack.error(context, l.atleta_falhaRemover);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.nome;
    final url = widget.url;
    final inicial = nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();

    final foto = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceContainerLow,
        border: Border.all(color: AppColors.primary, width: 2),
        image: (url != null && url.isNotEmpty)
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: (url == null || url.isEmpty)
          ? Center(
              child: Text(inicial,
                  style: AppTypography.display
                      .copyWith(fontSize: 34, color: AppColors.primary)),
            )
          : null,
    );

    final adicionar = _estado == 'nenhum';
    final remover = _estado == 'amigos';
    // pendente e proprio nao ganham selo: no primeiro o pedido ja foi feito,
    // no segundo a pessoa e voce mesmo.
    if (!adicionar && !remover) return foto;

    // `clipBehavior: none` porque o selo encosta na borda do círculo e seria
    // cortado pelo Stack padrão.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        foto,
        Positioned(
          right: -2,
          bottom: -2,
          child: GestureDetector(
            onTap: _ocupado
                ? null
                : (adicionar ? _pedirAmizade : _desfazerAmizade),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: adicionar ? AppColors.primary : AppColors.error,
                // A borda na cor do fundo separa o selo da foto; sem ela, um
                // avatar claro faz o círculo desaparecer na borda.
                border: Border.all(color: AppColors.background, width: 2.5),
              ),
              child: _ocupado
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : Icon(adicionar ? Icons.add : Icons.remove,
                      size: 18,
                      color: adicionar
                          ? AppColors.onPrimary
                          : AppColors.onSurface),
            ),
          ),
        ),
      ],
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

class _CardDeTreino extends ConsumerStatefulWidget {
  final TreinoPublico treino;
  final String dono;
  const _CardDeTreino({required this.treino, required this.dono});

  @override
  ConsumerState<_CardDeTreino> createState() => _CardDeTreinoState();
}

class _CardDeTreinoState extends ConsumerState<_CardDeTreino> {
  bool _copiando = false;

  Future<void> _copiar() async {
    final l = L.of(context);
    setState(() => _copiando = true);
    try {
      await ref.read(copiarTreinoProvider)(
        widget.treino.id,
        l.atleta_nomeDaCopia(widget.treino.nome, widget.dono),
      );
      // A aba Treino precisa reler, senao o treino copiado so aparece na
      // proxima abertura do app.
      ref.invalidate(workoutTemplatesProvider);
      if (mounted) MkSnack.success(context, l.atleta_treinoCopiado);
    } catch (e) {
      if (mounted) MkSnack.error(context, l.atleta_falhaCopiar);
    } finally {
      if (mounted) setState(() => _copiando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final treino = widget.treino;
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
              const SizedBox(width: 8),
              _BotaoCopiar(copiando: _copiando, aoTocar: _copiar),
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

/// Botão de copiar treino.
///
/// Fica no cabeçalho de cada treino, não num botão único do perfil: copiar é
/// por treino, e quem visita normalmente quer um dos cinco, não todos.
class _BotaoCopiar extends StatelessWidget {
  final bool copiando;
  final VoidCallback aoTocar;
  const _BotaoCopiar({required this.copiando, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return GestureDetector(
      onTap: copiando ? null : aoTocar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (copiando)
              const SizedBox(
                width: 11,
                height: 11,
                child: CircularProgressIndicator(
                    strokeWidth: 1.8, color: AppColors.primary),
              )
            else
              const Icon(Icons.copy_all_outlined,
                  size: 12, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(copiando ? l.atleta_copiando : l.atleta_copiar,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.primary,
                  fontSize: 9,
                )),
          ],
        ),
      ),
    );
  }
}
