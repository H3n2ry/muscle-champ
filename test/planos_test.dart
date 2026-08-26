/// Coerência da tabela de preços.
///
/// `VALORES.md` §1 chama isto de "verificação que precisa continuar valendo a
/// cada mudança de preço". Mexer em preço é decisão de mão única — assinatura
/// no Play é difícil de subir depois que existe base ativa — então a
/// verificação vira teste em vez de checklist que alguém esquece de rodar.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/features/subscription/data/models/plano.dart';

void main() {
  group('escada de compromisso', () {
    // A regra: quanto maior o compromisso, mais barato o mês. Se inverter,
    // quem fizer a conta abandona o plano longo — foi o que aconteceu na
    // versão anterior da tabela, com 4 trimestrais saindo mais baratos que
    // a renovação anual.
    test('4 trimestrais custam mais que uma renovação anual', () {
      expect(Planos.trimestral.entrada * 4,
          greaterThan(Planos.anual.renovacao));
    });

    test('12 mensais custam mais que 4 trimestrais', () {
      expect(Planos.mensal.entrada * 12,
          greaterThan(Planos.trimestral.entrada * 4));
    });

    test('mais compromisso, menor o preço por mês', () {
      expect(Planos.anual.porMes, lessThan(Planos.trimestral.porMes));
      expect(Planos.trimestral.porMes, lessThan(Planos.mensal.porMes));
    });

    test('o preço de lançamento não quebra a escada', () {
      expect(Planos.lancamento.porMes, lessThan(Planos.anual.porMes));
      expect(Planos.trimestral.entrada * 4,
          greaterThan(Planos.lancamento.renovacao));
    });
  });

  group('economia anunciada', () {
    test('o anual economiza contra pagar 12 mensais', () {
      // 12 × 19,90 = 238,80 contra 119,90 → 118,90 de economia.
      expect(Planos.anual.economiaAnualContra(Planos.mensal), 11890);
    });

    test('o mensal não economiza contra ele mesmo', () {
      expect(Planos.mensal.economiaAnualContra(Planos.mensal), 0);
    });

    test('a economia do trimestral é positiva mas menor que a do anual', () {
      final tri = Planos.trimestral.economiaAnualContra(Planos.mensal);
      final ano = Planos.anual.economiaAnualContra(Planos.mensal);
      expect(tri, greaterThan(0));
      expect(tri, lessThan(ano));
    });
  });

  group('aviso de renovação', () {
    // Só o anual tem degrau de preço. Onde há degrau a tela é obrigada a
    // dizer os dois valores — "primeiro ano por A, renova por B" — porque
    // riscar o preço cheio que nunca é cobrado na entrada é preço de
    // referência artificial, e o CDC trata como propaganda enganosa.
    test('o anual precisa avisar, os demais não', () {
      expect(Planos.anual.precisaAvisarRenovacao, isTrue);
      expect(Planos.mensal.precisaAvisarRenovacao, isFalse);
      expect(Planos.trimestral.precisaAvisarRenovacao, isFalse);
    });

    test('a renovação nunca é menor que a entrada', () {
      for (final p in [...Planos.todos, Planos.lancamento]) {
        expect(p.renovacao, greaterThanOrEqualTo(p.entrada),
            reason: 'plano ${p.id} ficaria mais barato ao renovar');
      }
    });
  });

  group('dinheiro em centavos', () {
    test('formata como o brasileiro lê', () {
      expect(formatarBRL(11990), r'R$ 119,90');
      expect(formatarBRL(1990), r'R$ 19,90');
      expect(formatarBRL(0), r'R$ 0,00');
      expect(formatarBRL(5), r'R$ 0,05');
      expect(formatarBRL(100), r'R$ 1,00');
    });

    test('doze mensalidades somam exatamente 238,80', () {
      // Em double isto daria 238.79999999999998. É o motivo de tudo aqui
      // ser int.
      expect(formatarBRL(Planos.mensal.entrada * 12), r'R$ 238,80');
    });

    test('o preço por mês do anual bate com o anunciado', () {
      expect(formatarBRL(Planos.anual.porMes), r'R$ 9,99');
      expect(formatarBRL(Planos.trimestral.porMes), r'R$ 16,63');
    });
  });

  group('catálogo', () {
    test('todo plano tem id único', () {
      final ids = Planos.todos.map((p) => p.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('exatamente um plano vem destacado', () {
      expect(Planos.todos.where((p) => p.destaque), hasLength(1));
    });

    test('o trial tem os 14 dias de VALORES.md', () {
      expect(Planos.diasDeTrial, 14);
    });
  });
}
