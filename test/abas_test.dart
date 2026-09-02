import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/core/router/abas.dart';
import 'package:muscle_camp/shared/widgets/barra_liquida.dart';

/// O app tem cinco abas e a barra tem três alvos — três delas dividem o botão
/// central. Essa conversão de índice para slot é a costura entre o
/// `StatefulShellRoute` (que pensa em números) e a barra (que pensa em rotas),
/// e é onde uma aba nova entra errada sem ninguém perceber: os dois lados
/// continuam compilando e a barra continua acendendo um slot, só que o errado.
void main() {
  group('kAbas', () {
    test('casa é a primeira e perfil é a última', () {
      // A barra dá alvo próprio só às pontas. Reordenar kAbas sem lembrar
      // disso troca o que fica visível e o que fica escondido no "+".
      expect(kAbas.first.rota, '/dashboard');
      expect(kAbas.last.rota, '/profile');
    });

    test('não há rota repetida', () {
      final rotas = kAbas.map((a) => a.rota).toList();
      expect(rotas.toSet().length, rotas.length);
    });

    test('toda rota começa com barra', () {
      for (final aba in kAbas) {
        expect(aba.rota, startsWith('/'), reason: 'rota inválida: ${aba.rota}');
      }
    });

    test('o miolo é o que vai para o menu radial', () {
      expect(abasDoCentro.map((a) => a.rota),
          orderedEquals(['/workout', '/diet', '/ranking']));
      expect(abasDoCentro.length, kAbas.length - 2);
    });
  });

  group('slotDoRamo', () {
    test('as pontas viram os slots das pontas', () {
      expect(slotDoRamo(0), 0);
      expect(slotDoRamo(kAbas.length - 1), 2);
    });

    test('todo o miolo cai no botão central', () {
      for (var ramo = 1; ramo < kAbas.length - 1; ramo++) {
        expect(slotDoRamo(ramo), 1,
            reason: '${kAbas[ramo].rota} deveria morar no botão central');
      }
    });

    test('nenhum ramo aponta para um slot que a barra não tem', () {
      for (var ramo = 0; ramo < kAbas.length; ramo++) {
        expect(slotDoRamo(ramo), inInclusiveRange(0, BarraLiquida.slots - 1));
      }
    });

    test('todo slot da barra é alcançável por algum ramo', () {
      // Sem isto, um slot poderia existir na barra sem nada que o acenda.
      final alcancados = {
        for (var ramo = 0; ramo < kAbas.length; ramo++) slotDoRamo(ramo)
      };
      expect(alcancados.length, BarraLiquida.slots);
    });
  });
}
