import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/core/gamification/level_system.dart';

void main() {
  group('LevelSystem — requisitos', () {
    test('nível 1 é grátis; 2 custa 100 e depois multiplica por 1,5', () {
      expect(LevelSystem.requisito(1), 0);
      expect(LevelSystem.requisito(2), 100);
      expect(LevelSystem.requisito(3), 150);
      expect(LevelSystem.requisito(4), 225);
      expect(LevelSystem.requisito(5), 338); // 337,5 arredondado
      expect(LevelSystem.requisito(6), 506); // 506,25
    });

    test('requisito nunca diminui', () {
      for (var n = 1; n < 30; n++) {
        expect(LevelSystem.requisito(n + 1),
            greaterThan(LevelSystem.requisito(n)),
            reason: 'nível ${n + 1} deveria custar mais que o $n');
      }
    });

    test('níveis inválidos não quebram', () {
      expect(LevelSystem.requisito(0), 0);
      expect(LevelSystem.requisito(-5), 0);
    });
  });

  group('LevelSystem — nível a partir dos pontos', () {
    test('usuário novo entra no nível 1', () {
      expect(LevelSystem.nivelDe(0), 1);
    });

    test('sobe exatamente no requisito, não antes', () {
      expect(LevelSystem.nivelDe(99), 1);
      expect(LevelSystem.nivelDe(100), 2);
      expect(LevelSystem.nivelDe(149), 2);
      expect(LevelSystem.nivelDe(150), 3);
      expect(LevelSystem.nivelDe(224), 3);
      expect(LevelSystem.nivelDe(225), 4);
    });

    test('o caso real do app: 130 pontos é nível 2', () {
      // Dashboard mostrava 1 (fixo) e perfil mostrava 2. Agora só existe um.
      expect(LevelSystem.nivelDe(130), 2);
    });

    test('pontos negativos não quebram', () {
      expect(LevelSystem.nivelDe(-10), 1);
    });

    test('valor absurdo não trava nem passa do teto', () {
      final n = LevelSystem.nivelDe(999999999);
      expect(n, greaterThan(10));
      expect(n, lessThanOrEqualTo(LevelSystem.nivelMaximo));
    });
  });

  group('LevelSystem — quanto falta', () {
    test('conta a partir dos pontos atuais', () {
      expect(LevelSystem.pontosParaProximo(0), 100);
      expect(LevelSystem.pontosParaProximo(130), 20);  // 150 - 130
      expect(LevelSystem.pontosParaProximo(150), 75);  // 225 - 150
    });

    test('no requisito exato, falta o do próximo nível inteiro', () {
      expect(LevelSystem.pontosParaProximo(100), 50); // 150 - 100
    });

    test('nunca é negativo', () {
      for (final p in [0, 1, 99, 100, 101, 224, 225, 5000]) {
        expect(LevelSystem.pontosParaProximo(p), greaterThanOrEqualTo(0),
            reason: 'com $p pontos');
      }
    });
  });

  group('LevelSystem — progresso na barra', () {
    test('zera ao entrar no nível e enche ao alcançar o próximo', () {
      expect(LevelSystem.progressoNoNivel(100), 0.0);
      expect(LevelSystem.progressoNoNivel(125), closeTo(0.5, 0.001));
      expect(LevelSystem.progressoNoNivel(149), closeTo(0.98, 0.01));
    });

    test('usa a faixa do nível, não os pontos totais', () {
      // 130 pontos: 30 andados numa faixa de 50 (100→150), não 130/150.
      expect(LevelSystem.progressoNoNivel(130), closeTo(0.6, 0.001));
    });

    test('fica sempre entre 0 e 1', () {
      for (final p in [-50, 0, 99, 100, 337, 338, 1000000]) {
        final v = LevelSystem.progressoNoNivel(p);
        expect(v, inInclusiveRange(0.0, 1.0), reason: 'com $p pontos');
      }
    });
  });

  group('LevelSystem — coerência entre as funções', () {
    test('quem está no nível N tem pelo menos o requisito de N', () {
      for (var p = 0; p <= 2000; p += 7) {
        final n = LevelSystem.nivelDe(p);
        expect(p, greaterThanOrEqualTo(LevelSystem.requisito(n)),
            reason: '$p pontos caiu no nível $n');
        if (n < LevelSystem.nivelMaximo) {
          expect(p, lessThan(LevelSystem.requisito(n + 1)),
              reason: '$p pontos deveria ter subido de nível');
        }
      }
    });

    test('pontos + quanto falta chega exatamente no próximo requisito', () {
      for (var p = 0; p <= 1000; p += 13) {
        final n = LevelSystem.nivelDe(p);
        expect(p + LevelSystem.pontosParaProximo(p),
            LevelSystem.requisito(n + 1),
            reason: 'com $p pontos, no nível $n');
      }
    });
  });
}
