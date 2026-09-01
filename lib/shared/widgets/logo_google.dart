import 'package:flutter/material.dart';

/// O "G" do Google, a partir dos caminhos oficiais do SVG da marca.
///
/// ⚠️ As cores e a geometria são da marca e **não seguem a paleta do app** —
/// diferente de todo o resto da interface, que muda com o tema escolhido pelo
/// usuário. É exigência: as diretrizes do Google proíbem recolorir ou redesenhar
/// o logo. Se alguém "corrigir" isto para usar `AppColors`, quebra a
/// conformidade e pode barrar a publicação.
///
/// A primeira versão desenhava o G com quatro arcos e uma barra. Parecia
/// razoável no código e saiu errado na tela: as proporções do G real não são
/// arcos de circunferência uniformes, e nenhum ajuste de ângulo chegava perto.
/// Por isso agora vêm os `path` oficiais, interpretados por
/// [_caminhoDeSvg] — assim o desenho é o da marca, não uma imitação.
///
/// Não virou asset porque PNG precisaria de várias resoluções para não borrar,
/// e SVG traria o `flutter_svg` como dependência por causa de um ícone só.
class LogoGoogle extends StatelessWidget {
  final double size;
  const LogoGoogle({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _GPainter()),
      );
}

class _GPainter extends CustomPainter {
  /// Caminhos oficiais, viewBox 24×24. Copiados verbatim — reescrever à mão é
  /// como a primeira tentativa errou.
  static const _partes = <int, String>{
    0xFF4285F4: 'M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 '
        '2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z',
    0xFF34A853: 'M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 '
        '1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z',
    0xFFFBBC05: 'M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 '
        '8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z',
    0xFFEA4335: 'M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 '
        '1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z',
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    _partes.forEach((cor, d) {
      canvas.drawPath(_caminhoDeSvg(d), Paint()..color = Color(cor));
    });
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Interpreta o `d` de um `<path>` de SVG.
///
/// Cobre só o que os caminhos do logo usam: M/m, L/l, H/h, V/v, C/c, S/s, Z/z.
/// Existe para os caminhos oficiais poderem ser colados sem transcrição — que é
/// exatamente onde a versão anterior deste arquivo se perdeu.
Path _caminhoDeSvg(String d) {
  final path = Path();
  final tokens = RegExp(r'[MmLlHhVvCcSsZz]|-?\d*\.?\d+')
      .allMatches(d)
      .map((m) => m[0]!)
      .toList();

  double x = 0, y = 0; // ponto atual
  double cx = 0, cy = 0; // 2º controle da última cúbica, para o S refletir
  String comando = '';
  int i = 0;
  double n() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    final t = tokens[i];
    if (RegExp(r'[A-Za-z]').hasMatch(t)) {
      comando = t;
      i++;
    }
    // Comando repetido sem repetir a letra (ex.: "c ... ... ...") é válido em
    // SVG e acontece nestes caminhos.
    final rel = comando.toLowerCase() == comando;

    switch (comando.toLowerCase()) {
      case 'm':
        final dx = n(), dy = n();
        x = rel ? x + dx : dx;
        y = rel ? y + dy : dy;
        path.moveTo(x, y);
        // Pares seguintes de um M viram lineTo, conforme a especificação.
        comando = rel ? 'l' : 'L';
        break;
      case 'l':
        final dx = n(), dy = n();
        x = rel ? x + dx : dx;
        y = rel ? y + dy : dy;
        path.lineTo(x, y);
        break;
      case 'h':
        final dx = n();
        x = rel ? x + dx : dx;
        path.lineTo(x, y);
        break;
      case 'v':
        final dy = n();
        y = rel ? y + dy : dy;
        path.lineTo(x, y);
        break;
      case 'c':
        final x1 = (rel ? x : 0) + n(), y1 = (rel ? y : 0) + n();
        final x2 = (rel ? x : 0) + n(), y2 = (rel ? y : 0) + n();
        final xe = (rel ? x : 0) + n(), ye = (rel ? y : 0) + n();
        path.cubicTo(x1, y1, x2, y2, xe, ye);
        cx = x2;
        cy = y2;
        x = xe;
        y = ye;
        break;
      case 's':
        // O 1º controle é o reflexo do 2º da cúbica anterior.
        final x1 = 2 * x - cx, y1 = 2 * y - cy;
        final x2 = (rel ? x : 0) + n(), y2 = (rel ? y : 0) + n();
        final xe = (rel ? x : 0) + n(), ye = (rel ? y : 0) + n();
        path.cubicTo(x1, y1, x2, y2, xe, ye);
        cx = x2;
        cy = y2;
        x = xe;
        y = ye;
        break;
      case 'z':
        path.close();
        break;
    }
  }
  return path;
}
