import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/diet/presentation/pages/diet_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/ranking/presentation/pages/ranking_page.dart';
import '../../features/workout/presentation/pages/workout_page.dart';

/// Uma aba do `StatefulShellRoute`.
///
/// Carrega tudo que identifica a aba — rota, página, ícone e rótulo. O ícone e
/// o rótulo moram aqui, e não na barra, porque enquanto estavam lá eram uma
/// segunda lista: acrescentar uma aba compilava e ela aparecia no menu com o
/// ícone e o nome de outra.
class Aba {
  final String rota;
  final WidgetBuilder construir;
  final IconData icone;
  final String Function(L) rotulo;

  const Aba({
    required this.rota,
    required this.construir,
    required this.icone,
    required this.rotulo,
  });
}

/// As abas do app, na ordem dos ramos.
///
/// ⚠️ Esta lista existe para haver UMA ordem, não duas.
///
/// O `StatefulShellRoute` identifica a aba ativa por índice, enquanto a barra
/// de navegação raciocina em rotas — então alguém precisa converter entre as
/// duas coisas. Enquanto o router tinha os ramos escritos nele e a barra tinha
/// a própria cópia da ordem, reordenar um lado sem o outro levava a pessoa para
/// a aba errada: os dois lados continuam compilando, a barra continua acendendo
/// um slot, e nada acusa que é o slot errado.
///
/// Com a lista aqui, o router monta os ramos a partir dela e a barra faz
/// `indexOf` nela. Não há segunda ordem para sair de sincronia.
///
/// A primeira e a última são as que têm alvo próprio na barra (casa e perfil);
/// as do meio moram dentro do botão central.
/// ⚠️ Variantes SIMPLES dos ícones (`restaurant`, não `restaurant_rounded`).
/// A fonte de ícones é recortada a cada build, então glifo novo em produção
/// depende de deploy + cache — ver `tool/versionar_fonte_de_icones.dart`.
const List<Aba> kAbas = [
  Aba(
      rota: '/dashboard',
      construir: _dashboard,
      icone: Icons.home,
      rotulo: _rotuloInicio),
  Aba(
      rota: '/workout',
      construir: _workout,
      icone: Icons.fitness_center,
      rotulo: _rotuloTreino),
  Aba(
      rota: '/diet',
      construir: _diet,
      icone: Icons.restaurant,
      rotulo: _rotuloDieta),
  Aba(
      rota: '/ranking',
      construir: _ranking,
      icone: Icons.emoji_events,
      rotulo: _rotuloRanking),
  Aba(
      rota: '/profile',
      construir: _profile,
      icone: Icons.person,
      rotulo: _rotuloPerfil),
];

// Funções de topo em vez de lambdas para `kAbas` poder ser `const`.
Widget _dashboard(BuildContext _) => const DashboardPage();
Widget _workout(BuildContext _) => const WorkoutPage();
Widget _diet(BuildContext _) => const DietPage();
Widget _ranking(BuildContext _) => const RankingPage();
Widget _profile(BuildContext _) => const ProfilePage();

String _rotuloInicio(L l) => l.navInicio;
String _rotuloTreino(L l) => l.navTreino;
String _rotuloDieta(L l) => l.navDieta;
String _rotuloRanking(L l) => l.navRanking;
String _rotuloPerfil(L l) => l.navPerfil;

/// As abas que NÃO têm alvo próprio na barra — moram dentro do botão central.
List<Aba> get abasDoCentro => kAbas.sublist(1, kAbas.length - 1);

/// Slot da barra que representa um ramo: 0 = casa · 1 = centro · 2 = perfil.
///
/// A barra tem três alvos e o app tem cinco abas, então três delas dividem o
/// botão do meio. Fica aqui, e não dentro do widget, para ser testável sem
/// montar tela nenhuma.
int slotDoRamo(int ramo) {
  if (ramo == 0) return 0;
  if (ramo == kAbas.length - 1) return 2;
  return 1;
}
