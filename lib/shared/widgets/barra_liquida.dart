import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Destino do menu radial que abre a partir do botão central.
class DestinoRadial {
  final String rota;
  final IconData icone;
  final String rotulo;
  const DestinoRadial(
      {required this.rota, required this.icone, required this.rotulo});
}

/// Barra flutuante de vidro, com o item ativo saindo para fora.
///
/// Duas ideias combinadas:
///
/// • **liquid bar** — o alvo ativo sobe da barra num círculo sólido e o rótulo
///   aparece embaixo, dentro da barra. O círculo DESLIZA entre as posições em
///   vez de pular, que é o que dá a sensação de líquido.
/// • **liquid glass** — a barra é translúcida com blur forte, deixando a cor do
///   que está atrás vazar. Por isso o fundo tem opacidade baixa: opaco anula o
///   efeito e só cobra o custo do blur.
///
/// Três alvos em vez das cinco abas antigas — casa, centro e perfil. Treino,
/// Dieta e Ranking vivem dentro do botão central, que gira e os abre em arco.
///
/// ⚠️ `BackdropFilter` custa uma passada de blur por quadro, e no CanvasKit
/// (web) isso é sensível. A área borrada é pequena de propósito. Aumentar
/// `sigma` ou esticar a barra para a largura toda tem custo real.
class BarraLiquida extends StatefulWidget {
  /// 0 = casa · 1 = centro (ou uma das seções do radial) · 2 = perfil
  final int indiceAtivo;

  /// Ícone a mostrar no botão central. Quando se está numa das seções do
  /// radial, ele assume o ícone daquela seção — assim a barra continua dizendo
  /// onde a pessoa está, mesmo sem um alvo próprio para aquela tela.
  final IconData? iconeCentral;

  final ValueChanged<String> onNavegar;
  final List<DestinoRadial> destinos;
  final String rotuloCasa;
  final String rotuloPerfil;

  const BarraLiquida({
    super.key,
    required this.indiceAtivo,
    required this.onNavegar,
    required this.destinos,
    required this.rotuloCasa,
    required this.rotuloPerfil,
    this.iconeCentral,
  });

  @override
  State<BarraLiquida> createState() => _BarraLiquidaState();
}

class _BarraLiquidaState extends State<BarraLiquida>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 220),
  );

  static const double _alturaBarra = 64;
  static const double _diametroBolha = 52;
  static const double _margemLateral = 20;
  static const double _larguraMaxima = 440;

  bool get _aberto => _ctrl.value > 0.5;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _escolher(String rota) {
    if (_aberto) _ctrl.reverse();
    widget.onNavegar(rota);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Teto de largura: sem isto, num monitor de 1920px os tres slots ficam
        // com 620px cada e a bolha do ativo vai parar no canto da tela, longe
        // do polegar e longe de parecer uma barra.
        final larguraBarra = math.min(
          constraints.maxWidth - _margemLateral * 2,
          _larguraMaxima,
        );
        final larguraSlot = larguraBarra / 3;
        final sobra = (constraints.maxWidth - larguraBarra) / 2;

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.status == AnimationStatus.reverse
                ? Curves.easeIn.transform(_ctrl.value)
                : Curves.easeOutBack.transform(_ctrl.value).clamp(0.0, 1.15);

            // Stack de TELA INTEIA, nao so a altura da barra.
            //
            // `clipBehavior: Clip.none` deixa PINTAR fora dos limites, mas o
            // hit test continua recortado pela caixa do widget — entao os
            // botoes do arco apareciam e nao recebiam toque, e o veu nao
            // fechava ao tocar fora. Ocupando a tela toda, os dois funcionam.
            //
            // Nao bloqueia a pagina quando fechado: um Stack nao absorve
            // toques onde nao ha filho, e o veu so existe com o menu aberto.
            return Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                if (_ctrl.value > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: _ctrl.value < 0.05,
                      child: GestureDetector(
                        onTap: () => _ctrl.reverse(),
                        child: Container(
                          color: Colors.black.withOpacity(0.5 * _ctrl.value),
                        ),
                      ),
                    ),
                  ),
                ..._itensRadiais(t),
                _vidro(larguraBarra, larguraSlot, sobra),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _itensRadiais(double t) {
    // 140° / 90° / 40° a partir do eixo x, anti-horário: espalha sem encostar
    // nas bordas em telas estreitas.
    const angulos = [140.0, 90.0, 40.0];
    const raio = 92.0;

    return List.generate(widget.destinos.length, (i) {
      final d = widget.destinos[i];
      final rad = angulos[i % angulos.length] * math.pi / 180;

      return Positioned(
        bottom: _alturaBarra / 2 + math.sin(rad) * raio * t,
        child: Transform.translate(
          offset: Offset(math.cos(rad) * raio * t, 0),
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: t.clamp(0.0, 1.0),
              child: _BotaoRadial(
                icone: d.icone,
                rotulo: d.rotulo,
                onTap: () => _escolher(d.rota),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _vidro(double larguraBarra, double larguraSlot, double sobra) {
    // A bolha sobe metade para fora da barra, então o Stack precisa dessa
    // folga em cima — sem ela o círculo é cortado.
    final folgaTopo = _diametroBolha / 2 + 12;

    return SizedBox(
      height: _alturaBarra + folgaTopo,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: sobra,
            right: sobra,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_alturaBarra / 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
              borderRadius: BorderRadius.circular(_alturaBarra / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  height: _alturaBarra,
                  decoration: BoxDecoration(
                    // Vidro sobre fundo QUASE PRETO nao aparece sozinho: nao ha
                    // cor atras para atravessar, diferente da referencia (que
                    // tinha um fundo colorido vazando). Entao o material precisa
                    // trazer a propria luz — um degrade sutil de cima para
                    // baixo, mais borda clara, mais sombra externa para destacar
                    // do preto. Sem isso a barra some.
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.onSurface.withOpacity(0.16),
                        AppColors.surfaceContainerLow.withOpacity(0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(_alturaBarra / 2),
                    border: Border.all(
                      color: AppColors.onSurface.withOpacity(0.22),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _slot(0, widget.rotuloCasa)),
                      Expanded(child: _slot(1, null)),
                      Expanded(child: _slot(2, widget.rotuloPerfil)),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),

          // A bolha do ativo. `AnimatedPositioned` desliza entre os slots —
          // é o que faz parecer líquido em vez de trocar de lugar seco.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            left: sobra +
                larguraSlot * widget.indiceAtivo +
                (larguraSlot - _diametroBolha) / 2,
            bottom: _alturaBarra - _diametroBolha / 2 - 4,
            child: _Bolha(
              icone: _iconeDoSlot(widget.indiceAtivo),
              giro: widget.indiceAtivo == 1 && widget.iconeCentral == null
                  ? _ctrl.value
                  : 0,
              onTap: () {
                if (widget.indiceAtivo == 1) {
                  _aberto ? _ctrl.reverse() : _ctrl.forward();
                }
              },
            ),
          ),

          // Alvos invisíveis por cima, para tocar em qualquer slot.
          Positioned(
            left: sobra,
            right: sobra,
            bottom: 0,
            height: _alturaBarra,
            child: Row(
              children: [
                Expanded(
                  child: _AlvoInvisivel(onTap: () => _escolher('/dashboard')),
                ),
                Expanded(
                  child: _AlvoInvisivel(
                    onTap: () => _aberto ? _ctrl.reverse() : _ctrl.forward(),
                  ),
                ),
                Expanded(
                  child: _AlvoInvisivel(onTap: () => _escolher('/profile')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ⚠️ Variantes SIMPLES de proposito (`home`, nao `home_rounded`).
  ///
  /// As `_rounded` sumiram em producao: o Flutter recorta a fonte MaterialIcons
  /// para so os glifos usados, e glifo que nao esta no app inteiro depende do
  /// asset ser regerado. Estas tres ja aparecem em outras telas, entao estao
  /// garantidas na fonte. Trocar por uma variante nova exige `flutter clean`
  /// antes de concluir que "o icone nao aparece".
  IconData _iconeDoSlot(int i) {
    if (i == 0) return Icons.home;
    if (i == 2) return Icons.person;
    return widget.iconeCentral ?? Icons.add;
  }

  /// Conteúdo de um slot dentro da barra.
  ///
  /// Ativo  → só o rótulo, embaixo. O ícone dele está na bolha, acima.
  /// Inativo → o ícone, centralizado.
  ///
  /// A primeira versão só desenhava o rótulo do ativo, e os outros dois slots
  /// ficavam literalmente vazios — inclusive o "+", que sumiu da barra.
  Widget _slot(int i, String? texto) {
    final ativo = widget.indiceAtivo == i;

    if (!ativo) {
      return Center(
        // Branco puro no inativo e preto puro na bolha (ver _Bolha). Nao segue
        // a paleta de proposito: e uma barra de vidro sobre conteudo variavel,
        // e contraste maximo e o unico jeito de o icone nao sumir contra o que
        // estiver passando atras.
        child: Icon(
          _iconeDoSlot(i),
          size: 24,
          color: Colors.white,
        ),
      );
    }

    if (texto == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          texto,
          style: AppTypography.labelSm.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// O círculo do item ativo, que sobe para fora da barra.
class _Bolha extends StatelessWidget {
  final IconData icone;
  final double giro;
  final VoidCallback onTap;

  const _Bolha({required this.icone, required this.giro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _BarraLiquidaState._diametroBolha,
        height: _BarraLiquidaState._diametroBolha,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.40),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        // `Center` explícito: o Container tem tamanho fixo e passa restrição
        // apertada ao filho, o que pode esticar o Icon em vez de centralizá-lo.
        child: Center(
          child: Transform.rotate(
            // 45° transforma o "+" em "×", sem trocar de ícone.
            angle: giro * math.pi / 4,
            child: Icon(icone, size: 26, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _AlvoInvisivel extends StatelessWidget {
  final VoidCallback onTap;
  const _AlvoInvisivel({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.expand(),
      );
}

class _BotaoRadial extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final VoidCallback onTap;

  const _BotaoRadial(
      {required this.icone, required this.rotulo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.45)),
            ),
            child: Icon(icone, size: 24, color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            rotulo,
            style: AppTypography.labelSm
                .copyWith(fontSize: 10, color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}
