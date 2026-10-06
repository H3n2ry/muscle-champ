import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/features/workout/presentation/widgets/guarda_de_saida.dart';

/// A folha de treino só grava carga e repetições no CONCLUIR TREINO. Fechá-la
/// antes perdia tudo em silêncio, e a guarda existe para perguntar antes.
///
/// O que estes testes prendem é o caminho que o PopScope sozinho NÃO cobre: o
/// arrasto para baixo, que na folha modal chama `Navigator.pop` direto. Rodam
/// contra o `showModalBottomSheet` de verdade, porque é o comportamento dele que
/// está sendo contornado — se uma versão do Flutter mudar isso, a quebra
/// aparece aqui.
void main() {
  testWidgets('sem nada a perder, arrastar para baixo fecha a folha', (t) async {
    // Controle: prova que o arrasto do teste fecha a folha de fato. Sem ele, o
    // teste seguinte passaria mesmo se o arrasto não fizesse nada.
    final banca = await _abrir(t, segurar: false);

    await t.drag(find.text('folha'), const Offset(0, 300));
    await t.pumpAndSettle();

    expect(find.text('folha'), findsNothing);
    expect(banca.tentativas, 0);
  });

  group('com algo a perder', () {
    testWidgets('arrastar para baixo pergunta em vez de fechar', (t) async {
      final banca = await _abrir(t, segurar: true);

      await t.drag(find.text('folha'), const Offset(0, 300));
      await t.pumpAndSettle();

      expect(find.text('folha'), findsOneWidget);
      expect(banca.tentativas, 1);
    });

    testWidgets('um arrasto curto e lento não pergunta', (t) async {
      final banca = await _abrir(t, segurar: true);

      await t.timedDrag(find.text('folha'), const Offset(0, 30),
          const Duration(seconds: 1));
      await t.pumpAndSettle();

      expect(find.text('folha'), findsOneWidget);
      expect(banca.tentativas, 0);
    });

    testWidgets('tocar fora pergunta em vez de fechar', (t) async {
      final banca = await _abrir(t, segurar: true);

      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();

      expect(find.text('folha'), findsOneWidget);
      expect(banca.tentativas, 1);
    });

    testWidgets('o voltar do sistema pergunta em vez de fechar', (t) async {
      final banca = await _abrir(t, segurar: true);

      await t.binding.handlePopRoute();
      await t.pumpAndSettle();

      expect(find.text('folha'), findsOneWidget);
      expect(banca.tentativas, 1);
    });

    testWidgets('quem respondeu "sair" consegue fechar', (t) async {
      // A resposta fecha com Navigator.pop, que o PopScope não segura. Se
      // segurasse, "SAIR SEM SALVAR" não faria nada e a pessoa ficaria presa.
      final banca = await _abrir(t,
          segurar: true, aoTentarSair: (ctx) => Navigator.of(ctx).pop());

      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();

      expect(find.text('folha'), findsNothing);
      expect(banca.tentativas, 1);
    });
  });
}

class _Banca {
  int tentativas = 0;
}

Future<_Banca> _abrir(
  WidgetTester t, {
  required bool segurar,
  void Function(BuildContext folha)? aoTentarSair,
}) async {
  final banca = _Banca();
  await t.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (folha) => GuardaDeSaida(
                segurar: segurar,
                aoTentarSair: () {
                  banca.tentativas++;
                  aoTentarSair?.call(folha);
                },
                // Conteúdo que não rola: com Scrollable, é ele quem ganharia o
                // arrasto, e a folha não fecharia de nenhum jeito.
                child: const SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Center(child: Text('folha')),
                ),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  ));
  await t.tap(find.text('abrir'));
  await t.pumpAndSettle();
  expect(find.text('folha'), findsOneWidget);
  return banca;
}
