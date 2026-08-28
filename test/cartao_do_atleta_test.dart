import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:muscle_camp/core/theme/app_colors.dart';
import 'package:muscle_camp/features/dashboard/data/models/dashboard_model.dart';
import 'package:muscle_camp/features/dashboard/presentation/widgets/cartao_do_atleta.dart';
import 'package:muscle_camp/l10n/app_localizations.dart';

/// Retrato do cartão do atleta, para conferir o layout com o olho.
///
/// Não roda no `flutter test` normal — é ferramenta, não teste de regressão,
/// igual ao `nutricao_gravar_test.dart`. Para gerar os PNGs em test/goldens:
///
/// ```
/// $env:GOLDEN_CARTAO=1; flutter test --update-goldens test/cartao_do_atleta_test.dart
/// ```
///
/// Responde: a foto encosta no texto sem virar retângulo colado no canto? o
/// nome comprido estoura? sem foto sobra buraco à direita? Nada disso cabe num
/// `expect`.
///
/// NÃO responde tipografia. O `AppTypography` monta os estilos com
/// `google_fonts`, que busca Space Grotesk e Inter pela rede — e teste não tem
/// rede. Cada letra sai como uma caixinha preta. Tentei registrar Roboto no
/// lugar e não compensa: o nome da família só é decidido depois do download, e
/// só de LER um estilo para descobri-lo o `google_fonts` já dispara a busca e
/// derruba o `setUpAll`. As caixinhas até ajudam a ver a caixa de cada texto.
void main() {
  if (Platform.environment['GOLDEN_CARTAO'] != '1') {
    test('goldens do cartão', () {}, skip: 'defina GOLDEN_CARTAO=1 para gerar');
    return;
  }

  testWidgets('cartão com foto', (t) async {
    await _renderizar(t, _modelo(), 'cartao_do_atleta.png');
  });

  testWidgets('cartão sem foto não deixa buraco à direita', (t) async {
    await _renderizar(t, _modelo(comFoto: false), 'cartao_sem_foto.png');
  });

  testWidgets('nome comprido e pontuação alta não estouram', (t) async {
    await _renderizar(
      t,
      _modelo(
        nome: 'Henrique Aparecido da Silva Nascimento',
        pontos: 128450,
        streak: 1,
      ),
      'cartao_extremos.png',
    );
  });
}

DashboardModel _modelo({
  String nome = 'Henry',
  int pontos = 60,
  int streak = 12,
  bool comFoto = true,
}) =>
    DashboardModel(
      totalPoints: pontos,
      globalRank: 1,
      friendsRank: 1,
      workoutDoneToday: true,
      dietGoalMetToday: false,
      currentWeight: 80,
      targetWeight: 75,
      weeklyWorkouts: 3,
      weeklyWorkoutGoal: 5,
      pointHistory: const [],
      nome: nome,
      avatarUrl: comFoto ? 'https://exemplo/foto.jpg' : null,
      objetivo: 'gain_weight',
      streak: streak,
    );

Future<void> _renderizar(
    WidgetTester t, DashboardModel dados, String arquivo) async {
  // Largura de celular estreito: é onde a foto mais briga com o texto.
  await t.binding.setSurfaceSize(const Size(390, 420));
  addTearDown(() => t.binding.setSurfaceSize(null));

  final provider = MemoryImage(_fotoFalsa());

  await t.pumpWidget(MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: L.localizationsDelegates,
    supportedLocales: L.supportedLocales,
    home: Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CartaoDoAtleta(dados: dados, imagemDe: (_) => provider),
        ),
      ),
    ),
  ));

  // Decodificar PNG é assíncrono de verdade; sem `runAsync` o golden sai antes
  // da foto entrar e o degradê não aparece.
  await t.runAsync(() async {
    await precacheImage(provider, t.element(find.byType(CartaoDoAtleta)));
  });
  await t.pumpAndSettle();

  await expectLater(
    find.byType(CartaoDoAtleta),
    matchesGoldenFile('goldens/$arquivo'),
  );
}

/// Retrato sintético: fundo listrado — para dar de ver o degradê comendo o
/// fundo — com uma silhueta clara por cima.
Uint8List _fotoFalsa() {
  final im = img.Image(width: 300, height: 400);
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      final listra = ((x + y) ~/ 18) % 2 == 0;
      im.setPixelRgb(
          x, y, listra ? 30 : 64, listra ? 70 : 110, listra ? 120 : 170);
    }
  }
  img.fillCircle(im,
      x: 150, y: 130, radius: 62, color: img.ColorRgb8(226, 198, 172));
  img.fillRect(im,
      x1: 82, y1: 196, x2: 218, y2: 400, color: img.ColorRgb8(212, 180, 152));
  return img.encodePng(im);
}
