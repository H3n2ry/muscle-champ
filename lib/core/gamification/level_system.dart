/// Sistema de níveis — fonte única da verdade.
///
/// Existia duplicado e divergente: o dashboard tinha "LVL 1" escrito na mão e o
/// perfil calculava `(pontos ~/ 100) + 1`. O mesmo usuário aparecia em níveis
/// diferentes dependendo da tela.
///
/// Regra: começa no nível 1 com 0 pontos. O nível 2 exige 100 pontos, e cada
/// nível seguinte exige 1,5× o anterior — 150, 225, 338, 506…
///
/// Os requisitos são **acumulados**, não incrementos: alcançar o nível 3 é
/// chegar a 150 pontos no total, não somar mais 150 depois do nível 2.
class LevelSystem {
  LevelSystem._();

  /// Pontos para alcançar o nível 2. Base da progressão.
  static const int _base = 100;

  /// Fator entre níveis consecutivos.
  static const double _fator = 1.5;

  /// Teto de segurança. 1,5^n cresce rápido — no nível 40 já passa de
  /// 1 bilhão de pontos. Serve só para os laços não correrem sem fim.
  static const int nivelMaximo = 99;

  /// Pontos acumulados necessários para alcançar [nivel].
  ///
  /// Nível 1 = 0 (todo usuário entra nele), nível 2 = 100, e daí por diante
  /// multiplicando por 1,5. Arredondado, porque ponto é inteiro.
  static int requisito(int nivel) {
    if (nivel <= 1) return 0;
    var req = _base.toDouble();
    for (var n = 3; n <= nivel; n++) {
      req *= _fator;
    }
    return req.round();
  }

  /// Nível correspondente a [pontos].
  static int nivelDe(int pontos) {
    if (pontos < _base) return 1;
    var nivel = 1;
    while (nivel < nivelMaximo && pontos >= requisito(nivel + 1)) {
      nivel++;
    }
    return nivel;
  }

  /// Pontos que faltam para o próximo nível. Zero no nível máximo.
  static int pontosParaProximo(int pontos) {
    final nivel = nivelDe(pontos);
    if (nivel >= nivelMaximo) return 0;
    final falta = requisito(nivel + 1) - pontos;
    return falta > 0 ? falta : 0;
  }

  /// Progresso dentro do nível atual, de 0 a 1.
  ///
  /// Usa a faixa entre o requisito do nível atual e o do próximo — não os
  /// pontos totais. Sem isso a barra ficaria quase cheia o tempo todo nos
  /// níveis altos.
  static double progressoNoNivel(int pontos) {
    final nivel = nivelDe(pontos);
    if (nivel >= nivelMaximo) return 1;

    final inicio = requisito(nivel);
    final fim = requisito(nivel + 1);
    final faixa = fim - inicio;
    if (faixa <= 0) return 1;

    final andado = (pontos - inicio) / faixa;
    return andado.clamp(0.0, 1.0);
  }
}
