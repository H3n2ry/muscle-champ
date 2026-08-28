import 'package:flutter/material.dart';
import '../../../../core/gamification/level_system.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/dashboard_model.dart';

/// Cartão de identidade do atleta, no topo da home.
///
/// Junta num lugar só o que estava espalhado: pontuação (home), nível e XP
/// (perfil), sequência (perfil) e objetivo (editar perfil). Nada aqui é dado
/// novo — é a mesma carga do dashboard, reaproveitada.
///
/// A foto é a MESMA do perfil. O recorte sem fundo do app de referência exige
/// segmentação de imagem, que não temos; no lugar dela a foto desbota para a
/// esquerda com um degradê, para encostar no texto sem cortar em retângulo.
class CartaoDoAtleta extends StatelessWidget {
  final DashboardModel dados;

  /// Como carregar a foto. Trocável só nos testes: dentro do `flutter_test`
  /// toda `Image.network` devolve um 1x1 transparente, o que apagaria a foto
  /// justamente no golden que existe para conferir o degradê dela.
  final ImageProvider Function(String url) imagemDe;

  const CartaoDoAtleta({
    super.key,
    required this.dados,
    this.imagemDe = NetworkImage.new,
  });

  String _objetivo(L l) => switch (dados.objetivo) {
        'lose_weight' => l.objetivo_perderPeso,
        'gain_weight' => l.objetivo_ganharMassa,
        _ => l.objetivo_manutencao,
      };

  /// Frase do dia. Gira pelo dia do ano — a mesma o dia inteiro, para não
  /// trocar de texto a cada rebuild da tela.
  ///
  /// Fixa e traduzida de propósito: gerar pela IA gastaria a cota diária do
  /// usuário numa frase decorativa.
  String _frase(L l, DateTime agora) {
    final nome = dados.nome.trim().split(' ').first;
    final dia = agora.difference(DateTime(agora.year)).inDays;
    return switch (dia % 4) {
      0 => l.cartao_frase1(nome),
      1 => l.cartao_frase2(nome),
      2 => l.cartao_frase3(nome),
      _ => l.cartao_frase4(nome),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final nivel = LevelSystem.nivelDe(dados.totalPoints);
    final progresso = LevelSystem.progressoNoNivel(dados.totalPoints);
    final falta = LevelSystem.pontosParaProximo(dados.totalPoints);

    return LayoutBuilder(
      builder: (context, c) {
        // A foto acompanha a largura disponível: fixa em 160 ela engoliria
        // metade de um aparelho de 320px.
        final larguraFoto = (c.maxWidth * 0.38).clamp(0.0, 170.0);
        final temFoto = (dados.avatarUrl ?? '').isNotEmpty;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.25), width: 1),
            ),
            child: Stack(
              children: [
                // A foto vem primeiro para o texto ficar por cima dela na
                // faixa desbotada.
                if (temFoto)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: larguraFoto,
                    child: _FotoDesbotada(imagem: imagemDe(dados.avatarUrl!)),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    18,
                    // Invade a foto só até onde ela já está quase transparente,
                    // senão sobraria uma coluna vazia enorme à direita.
                    temFoto ? larguraFoto * 0.55 + 14 : 18,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Sem isto o cartão estica até a altura que sobrar. Na home
                    // ele rola em altura infinita e nem aparece; numa caixa de
                    // altura limitada vira um retângulo com um vão embaixo.
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Pontuacao(pontos: dados.totalPoints, l: l),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dados.nome.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.headlineSm.copyWith(
                                    color: AppColors.onSurface,
                                    fontSize: 22,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _objetivo(l),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.primary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _SeloDeNivel(nivel: nivel, l: l),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _BarraDeXp(
                        progresso: progresso,
                        pontos: dados.totalPoints,
                        falta: falta,
                        proximo: nivel + 1,
                        l: l,
                      ),
                      if (dados.streak > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '🔥 ${l.cartao_diasSeguidos(dados.streak)}',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        _frase(l, DateTime.now()),
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Foto do perfil encostando no texto sem borda dura.
///
/// Dois degradês: um horizontal, que some para a esquerda, e um vertical
/// leve no topo. O `dstIn` usa só o alfa do degradê como máscara da imagem.
class _FotoDesbotada extends StatelessWidget {
  final ImageProvider imagem;

  const _FotoDesbotada({required this.imagem});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00000000), Color(0xFF000000)],
        stops: [0.0, 0.22],
      ).createShader(r),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0x00000000), Color(0x66000000), Color(0xFF000000)],
          stops: [0.0, 0.35, 0.62],
        ).createShader(r),
        child: Image(
          image: imagem,
          fit: BoxFit.cover,
          // O rosto fica no terço de cima da foto; centralizar cortaria a
          // cabeça num recorte alto e estreito como este.
          alignment: Alignment.topCenter,
          // Sem fundo cinza enquanto carrega nem ícone de erro: o cartão tem
          // que funcionar inteiro sem a foto.
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          frameBuilder: (_, filho, quadro, sincrono) =>
              quadro == null && !sincrono ? const SizedBox.shrink() : filho,
        ),
      ),
    );
  }
}

class _Pontuacao extends StatelessWidget {
  /// Largura da coluna. Fixa para o número e o rótulo abaixo dele ocuparem a
  /// mesma faixa — e para o resto do cartão não encolher quando a pontuação
  /// ganha um dígito.
  static const double _largura = 84;

  final int pontos;
  final L l;

  const _Pontuacao({required this.pontos, required this.l});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Encolhe em vez de estourar. Pontuação não tem teto: com 44px fixos,
        // seis dígitos empurram a coluna do nome para fora do cartão.
        SizedBox(
          width: _largura,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$pontos',
              maxLines: 1,
              style: AppTypography.headlineSm.copyWith(
                color: AppColors.onSurface,
                fontSize: 44,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: _largura,
          child: Text(
            l.cartao_pontuacaoGeral,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.4,
              fontSize: 10,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _SeloDeNivel extends StatelessWidget {
  final int nivel;
  final L l;

  const _SeloDeNivel({required this.nivel, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.45), width: 1),
      ),
      child: Text(
        '🌱  ${l.perfil_nivelN2(nivel).toUpperCase()}',
        style: AppTypography.labelSm.copyWith(
          color: AppColors.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _BarraDeXp extends StatelessWidget {
  final double progresso;
  final int pontos;
  final int falta;
  final int proximo;
  final L l;

  const _BarraDeXp({
    required this.progresso,
    required this.pontos,
    required this.falta,
    required this.proximo,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progresso,
            minHeight: 5,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.cartao_xp(pontos),
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
            ),
            // No nível máximo não há "faltam N" — a barra fica cheia.
            if (falta > 0)
              Flexible(
                child: Text(
                  l.cartao_paraNivel(falta, proximo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
