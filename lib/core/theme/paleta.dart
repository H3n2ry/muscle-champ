import 'package:flutter/material.dart';

/// Conjunto de cores que muda quando o usuário troca o acento do app.
///
/// Cor de app não é um valor, é um conjunto. Trocar só o acento deixa resíduo
/// da cor antiga: os cinzas do tema são **enviesados** — `onSurfaceVariant` é
/// `#BDCBAE`, um cinza esverdeado escolhido para conviver com o limão, e as
/// bordas (`outline`, `outlineVariant`) também puxam verde. Com o acento roxo
/// e os cinzas intocados, metade da tela continua verde sem ninguém saber por
/// quê. Por isso cada paleta carrega o conjunto inteiro.
///
/// A lista é **fechada** de propósito. Com seletor livre o usuário escolhe um
/// azul-marinho sobre o fundo `#121413` e fica com botão ilegível — e aí o
/// problema vira suporte. Cada `onPrimary` aqui foi conferido contra o acento
/// no contraste mínimo da WCAG AA (4,5:1) para texto normal.
class Paleta {
  /// Chave persistida no banco. **Não renomeie**: é o valor gravado em
  /// `profiles.tema` de quem já escolheu, e um id desconhecido cai no limão.
  final String id;

  final Color primary;
  final Color primaryDim;

  /// Quase-branco com um toque do acento, para títulos sobre o acento.
  final Color primaryText;

  /// Tinta que fica LEGÍVEL em cima do acento. Escura nos acentos claros,
  /// branca nos escuros — não é sempre a mesma.
  final Color onPrimary;

  final Color onPrimaryContainer;

  /// Cinza de texto secundário, enviesado para a família do acento.
  final Color onSurfaceVariant;

  final Color outline;
  final Color outlineVariant;

  const Paleta({
    required this.id,
    required this.primary,
    required this.primaryDim,
    required this.primaryText,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
  });

  // ── As sete ────────────────────────────────────────────────────────────

  static const limao = Paleta(
    id: 'limao',
    primary: Color(0xFF7EFC00),
    primaryDim: Color(0xFF6FE000),
    primaryText: Color(0xFFF7FFEA),
    onPrimary: Color(0xFF173800),
    onPrimaryContainer: Color(0xFF357000),
    onSurfaceVariant: Color(0xFFBDCBAE),
    outline: Color(0xFF88957B),
    outlineVariant: Color(0xFF3F4A34),
  );

  /// O `#7C3AED` já era o acento de IA do app. Reaproveitado aqui porque um
  /// roxo mais claro perde contraste com o branco em vez de ganhar.
  static const roxo = Paleta(
    id: 'roxo',
    primary: Color(0xFF7C3AED),
    primaryDim: Color(0xFF6D31D4),
    primaryText: Color(0xFFF3EEFF),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFFF1E9FF),
    onSurfaceVariant: Color(0xFFC4BDD1),
    outline: Color(0xFF8B85A0),
    outlineVariant: Color(0xFF423A52),
  );

  static const ciano = Paleta(
    id: 'ciano',
    primary: Color(0xFF00E5FF),
    primaryDim: Color(0xFF00C9E0),
    primaryText: Color(0xFFE8FDFF),
    onPrimary: Color(0xFF00343D),
    onPrimaryContainer: Color(0xFF00505C),
    onSurfaceVariant: Color(0xFFAEC6CB),
    outline: Color(0xFF7B9298),
    outlineVariant: Color(0xFF2F4449),
  );

  static const ambar = Paleta(
    id: 'ambar',
    primary: Color(0xFFFFA000),
    primaryDim: Color(0xFFE08C00),
    primaryText: Color(0xFFFFF6E6),
    onPrimary: Color(0xFF3A2100),
    onPrimaryContainer: Color(0xFF5C3600),
    onSurfaceVariant: Color(0xFFCBC2AE),
    outline: Color(0xFF97907B),
    outlineVariant: Color(0xFF4A4234),
  );

  static const coral = Paleta(
    id: 'coral',
    primary: Color(0xFFFF5252),
    primaryDim: Color(0xFFE04747),
    primaryText: Color(0xFFFFEDED),
    onPrimary: Color(0xFF4A0A0A),
    onPrimaryContainer: Color(0xFF6E1414),
    onSurfaceVariant: Color(0xFFCBB6B6),
    outline: Color(0xFF988080),
    outlineVariant: Color(0xFF4A3434),
  );

  static const azul = Paleta(
    id: 'azul',
    primary: Color(0xFF2563EB),
    primaryDim: Color(0xFF1F55CE),
    primaryText: Color(0xFFECF1FF),
    onPrimary: Color(0xFFFFFFFF),
    onPrimaryContainer: Color(0xFFE3EBFF),
    onSurfaceVariant: Color(0xFFB6BECB),
    outline: Color(0xFF7F8798),
    outlineVariant: Color(0xFF343B4A),
  );

  static const rosa = Paleta(
    id: 'rosa',
    primary: Color(0xFFFF9EC9),
    primaryDim: Color(0xFFE88AB3),
    primaryText: Color(0xFFFFF0F7),
    onPrimary: Color(0xFF4A0C2A),
    onPrimaryContainer: Color(0xFF6E1642),
    onSurfaceVariant: Color(0xFFCBB6C2),
    outline: Color(0xFF988090),
    outlineVariant: Color(0xFF4A3441),
  );

  static const List<Paleta> todas = [
    limao,
    roxo,
    ciano,
    ambar,
    coral,
    azul,
    rosa,
  ];

  /// Paleta de [id], ou o limão quando o id é nulo ou desconhecido.
  ///
  /// Cair no padrão em vez de estourar importa: um app mais novo pode ter
  /// gravado uma paleta que esta versão ainda não conhece, e um usuário com
  /// duas versões instaladas não deve ver a tela quebrar por causa disso.
  static Paleta doId(String? id) => todas.firstWhere(
        (p) => p.id == id,
        orElse: () => limao,
      );
}
