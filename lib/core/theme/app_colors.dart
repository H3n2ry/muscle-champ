import 'package:flutter/material.dart';

import 'paleta.dart';

class AppColors {
  AppColors._();

  /// Paleta em uso. Trocar isto **não** repinta nada sozinho — quem repinta é
  /// o `PaletaScope`, que reconstrói a árvore depois de trocar.
  ///
  /// É um campo estático e não um `InheritedWidget` porque estas cores são
  /// lidas de 33 arquivos, muitos deles sem `BuildContext` à mão. Ler pelo
  /// `Theme.of(context)` seria o caminho canônico do Flutter e custaria 431
  /// mudanças de chamada em vez de 163.
  static Paleta paleta = Paleta.limao;

  // Obsidian Kinetic - Base surfaces
  static const Color background        = Color(0xFF121413);
  static const Color surface           = Color(0xFF121413);
  static const Color surfaceContainerLowest = Color(0xFF0D0E0E);
  static const Color surfaceContainerLow   = Color(0xFF1B1C1C);
  static const Color surfaceContainer      = Color(0xFF1F2020);
  static const Color surfaceContainerHigh  = Color(0xFF292A2A);
  static const Color surfaceContainerHighest = Color(0xFF343535);
  static const Color surfaceBright     = Color(0xFF393939);

  // Primary — vem da paleta escolhida
  static Color get primary            => paleta.primary;
  static Color get primaryDim         => paleta.primaryDim;
  static Color get primaryText        => paleta.primaryText;
  static Color get onPrimary          => paleta.onPrimary;
  static Color get primaryContainer   => paleta.primary;
  static Color get onPrimaryContainer => paleta.onPrimaryContainer;

  // On surfaces
  static const Color onSurface        = Color(0xFFE4E2E1);

  /// Cinza esverdeado no limão, e enviesado para o acento nas outras paletas.
  static Color get onSurfaceVariant   => paleta.onSurfaceVariant;

  static const Color onBackground     = Color(0xFFE4E2E1);

  // Secondary
  static const Color secondary          = Color(0xFFC6C6C6);
  static const Color secondaryContainer = Color(0xFF454747);
  static const Color onSecondary        = Color(0xFF2F3131);

  // Borders — também enviesadas; ver o comentário em paleta.dart
  static Color get outline        => paleta.outline;
  static Color get outlineVariant => paleta.outlineVariant;

  // Error
  static const Color error          = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  // Semantic. `warning` e `error` NÃO seguem o acento de propósito: são cores
  // com significado, e um alerta que muda de cor junto com o tema deixa de
  // avisar. A chama da sequência é dourada em todas as paletas.
  static Color get success => paleta.primary;
  static const Color warning = Color(0xFFFFD700);

  // Glow effect (low opacity primary for inner glow)
  static Color get primaryGlow => primary.withOpacity(0.15);
  static Color get primaryGlowStrong => primary.withOpacity(0.30);
}
