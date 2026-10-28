import 'package:flutter/material.dart';

/// Segura uma folha modal aberta enquanto houver o que perder, e transforma
/// toda tentativa de fechá-la numa chamada a [aoTentarSair]. Quem usa decide o
/// que perguntar e, se a resposta for sair, fecha com `Navigator.pop` — que não
/// passa pelo PopScope e por isso não é segurado de novo.
///
/// Uma folha modal fecha de três jeitos, e só dois passam pelo PopScope: tocar
/// fora e o botão voltar chamam `maybePop`. O arrasto chama `Navigator.pop`
/// direto (`onClosing` em `bottom_sheet.dart`) e o ignora. Daí o
/// GestureDetector: estando mais fundo que o da folha, ganha a disputa do gesto
/// e converte o arrasto para baixo na mesma chamada. Com [segurar] falso os
/// callbacks são nulos, ele nem entra na disputa, e a folha arrasta como sempre.
///
/// O arrasto não é visto quando cai num conteúdo que rola — aí quem ganha é o
/// Scrollable, mais fundo ainda. Mas nesse caso a folha também não fecharia.
class GuardaDeSaida extends StatefulWidget {
  final bool segurar;
  final VoidCallback aoTentarSair;
  final Widget child;

  const GuardaDeSaida({
    super.key,
    required this.segurar,
    required this.aoTentarSair,
    required this.child,
  });

  @override
  State<GuardaDeSaida> createState() => _GuardaDeSaidaState();
}

class _GuardaDeSaidaState extends State<GuardaDeSaida> {
  double _arrasto = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.segurar;
    return PopScope(
      canPop: !s,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.aoTentarSair();
      },
      child: GestureDetector(
        onVerticalDragStart: s ? (_) => _arrasto = 0 : null,
        onVerticalDragUpdate: s ? (d) => _arrasto += d.primaryDelta ?? 0 : null,
        onVerticalDragEnd: s
            ? (d) {
                // Peteleco: 700 é o limiar da própria folha. Distância: a folha
                // só fecha passando da metade da altura, aqui basta pouco —
                // perguntar à toa custa menos que não perguntar.
                if (_arrasto > 48 || (d.primaryVelocity ?? 0) > 700) {
                  widget.aoTentarSair();
                }
              }
            : null,
        child: widget.child,
      ),
    );
  }
}
