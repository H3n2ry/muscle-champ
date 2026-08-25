/// Cota diária de IA do plano gratuito.
///
/// Os números vieram de decisão de produto (1 foto, 3 textos, 1 treino, 1
/// plano por dia). Ficam no teste porque mexer neles sem querer é fácil e o
/// efeito — usuário travado ou IA de graça à vontade — só aparece em produção.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/features/subscription/data/models/cota_ia.dart';

SaldoDeCota _saldo(RecursoIa r, int usados, {bool pro = false}) =>
    SaldoDeCota(recurso: r, usados: usados, ilimitado: pro);

void main() {
  group('limites do plano gratuito', () {
    test('são os combinados', () {
      expect(RecursoIa.fotoRefeicao.limiteGratis, 1);
      expect(RecursoIa.macrosTexto.limiteGratis, 3);
      expect(RecursoIa.gerarTreino.limiteGratis, 1);
      expect(RecursoIa.planoDieta.limiteGratis, 1);
    });

    test('a foto é o mais apertado — 88% do custo de IA está nela', () {
      for (final r in RecursoIa.values) {
        expect(RecursoIa.fotoRefeicao.limiteGratis,
            lessThanOrEqualTo(r.limiteGratis));
      }
    });

    test('nenhum recurso fica com limite zero', () {
      // Zero seria bloqueio, não cota — e a decisão foi deixar provar.
      for (final r in RecursoIa.values) {
        expect(r.limiteGratis, greaterThan(0), reason: r.name);
      }
    });
  });

  group('chave de persistência', () {
    // Estas quatro strings sao um CONTRATO com o banco: a funcao
    // consumir_cota_ia() so aceita (foto, texto, treino, dieta) e levanta
    // 'recurso invalido' em qualquer outra. Renomear aqui sem mexer na
    // migracao derruba TODA chamada de IA do app.
    test('casam com a lista aceita por consumir_cota_ia() no banco', () {
      expect(RecursoIa.values.map((r) => r.chave).toSet(),
          {'foto', 'texto', 'treino', 'dieta'});
    });

    test('é estável e não é o nome do enum', () {
      // Se a chave fosse `name`, renomear o enum zeraria a cota de todo mundo
      // em silêncio.
      expect(RecursoIa.fotoRefeicao.chave, 'foto');
      expect(RecursoIa.macrosTexto.chave, 'texto');
      expect(RecursoIa.gerarTreino.chave, 'treino');
      expect(RecursoIa.planoDieta.chave, 'dieta');
    });

    test('não há chave repetida', () {
      final chaves = RecursoIa.values.map((r) => r.chave).toList();
      expect(chaves.toSet(), hasLength(chaves.length));
    });
  });

  group('saldo no plano gratuito', () {
    test('sem uso, pode usar e mostra o limite cheio', () {
      final s = _saldo(RecursoIa.macrosTexto, 0);
      expect(s.podeUsar, isTrue);
      expect(s.restantes, 3);
    });

    test('no último uso ainda pode', () {
      final s = _saldo(RecursoIa.macrosTexto, 2);
      expect(s.podeUsar, isTrue);
      expect(s.restantes, 1);
    });

    test('atingido o limite, bloqueia e zera o restante', () {
      final s = _saldo(RecursoIa.macrosTexto, 3);
      expect(s.podeUsar, isFalse);
      expect(s.restantes, 0);
    });

    test('uma foto por dia: o segundo uso já bloqueia', () {
      expect(_saldo(RecursoIa.fotoRefeicao, 0).podeUsar, isTrue);
      expect(_saldo(RecursoIa.fotoRefeicao, 1).podeUsar, isFalse);
    });

    test('contador acima do limite não vira restante negativo', () {
      // Defensivo: se algo contar duas vezes, a tela mostra 0, não "-1".
      final s = _saldo(RecursoIa.gerarTreino, 7);
      expect(s.restantes, 0);
      expect(s.podeUsar, isFalse);
    });
  });

  group('assinante', () {
    test('nunca é bloqueado, por mais que use', () {
      for (final r in RecursoIa.values) {
        expect(_saldo(r, 999, pro: true).podeUsar, isTrue, reason: r.name);
      }
    });

    test('o selo some para quem é Pro', () {
      // `ilimitado` é o que o SeloDeCota usa para não desenhar contador.
      expect(_saldo(RecursoIa.fotoRefeicao, 5, pro: true).ilimitado, isTrue);
      expect(_saldo(RecursoIa.fotoRefeicao, 0).ilimitado, isFalse);
    });
  });

}

