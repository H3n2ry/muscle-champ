import 'dart:math' as math;
import 'package:flutter/material.dart';

/// O "G" do Google, desenhado em vez de importado.
///
/// Vale a pena não ser um asset: PNG precisaria de várias resoluções para não
/// borrar, e SVG traria o `flutter_svg` como dependência só por causa deste
/// ícone. Desenhado, escala em qualquer tamanho sem nada disso.
///
/// ⚠️ As cores são as oficiais do Google e **não seguem a paleta do app** —
/// diferente de todo o resto da interface, que muda com o tema escolhido pelo
/// usuário. Isso é exigência de marca: as diretrizes do Google proíbem
/// recolorir o logo. Se alguém "corrigir" isto para usar `AppColors`, quebra a
/// conformidade e pode barrar a publicação.
class LogoGoogle extends StatelessWidget {
  final double size;
  const LogoGoogle({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _GPainter()));
}

class _GPainter extends CustomPainter {
  // Cores oficiais da marca.
  static const _azul = Color(0xFF4285F4);
  static const _verde = Color(0xFF34A853);
  static const _amarelo = Color(0xFFFBBC05);
  static const _vermelho = Color(0xFFEA4335);

  double _rad(double graus) => graus * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    // O traço é ~22% do diâmetro; abaixo disso o G fica fino demais em 18px,
    // que é o tamanho usado no botão.
    final traco = size.width * 0.22;
    final raio = (size.width - traco) / 2;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: raio,
    );

    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = traco
      ..strokeCap = StrokeCap.butt;

    // Ângulos em graus, 0 = 3h, sentido horário.
    //
    // O vão de 0° a 50° é o que faz o desenho ler como "G" e não como círculo
    // colorido: é o entalhe à direita, LOGO ABAIXO da barra. Fechar esse trecho
    // (foi o primeiro erro aqui) esconde a barra dentro do arco.
    canvas.drawArc(rect, _rad(50), _rad(90), false, p..color = _verde);
    canvas.drawArc(rect, _rad(140), _rad(75), false, p..color = _amarelo);
    canvas.drawArc(rect, _rad(215), _rad(85), false, p..color = _vermelho);
    canvas.drawArc(rect, _rad(300), _rad(60), false, p..color = _azul);

    // A barra: continua de onde o arco azul termina (0° = 3h) para dentro do
    // círculo, na altura do meio.
    canvas.drawRect(
      Rect.fromLTRB(
        size.width * 0.46,
        size.height / 2 - traco / 2,
        size.width,
        size.height / 2 + traco / 2,
      ),
      Paint()..color = _azul,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
