import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/features/workout/data/models/reconciliacao_de_exercicios.dart';

Map<String, dynamic> _ex(String? id, String nome, {double peso = 20}) => {
      'id': id,
      'name': nome,
      'sets': 3,
      'reps': 10,
      'weight_kg': peso,
    };

/// Salvar a edição de um template apagava TODAS as linhas e reinseria, e cada
/// uma voltava com UUID novo — levando junto a anotação e todo o histórico de
/// progressão, que aponta para a linha com ON DELETE CASCADE.
///
/// Aconteceu de verdade: o histórico de 11/09 e 15/09/2026 sumiu assim.
void main() {
  group('reconciliação ao salvar a edição', () {
    test('quem já existia é ATUALIZADO, não recriado', () {
      // O caso que causou a perda: mexer em um exercício não pode custar a
      // identidade dos outros.
      final plano = ReconciliacaoDeExercicios.calcular(
        idsExistentes: {'a', 'b'},
        enviados: [_ex('a', 'Supino', peso: 25), _ex('b', 'Remada')],
      );

      expect(plano.paraAtualizar.map((e) => e['id']), ['a', 'b']);
      expect(plano.paraInserir, isEmpty);
      expect(plano.idsParaApagar, isEmpty);
    });

    test('reordenar não apaga nada — só muda order_index', () {
      final plano = ReconciliacaoDeExercicios.calcular(
        idsExistentes: {'a', 'b'},
        enviados: [_ex('b', 'Remada'), _ex('a', 'Supino')],
      );

      expect(plano.idsParaApagar, isEmpty);
      expect(plano.paraInserir, isEmpty);
      expect(
        {
          for (final e in plano.paraAtualizar) e['id']: e['order_index'],
        },
        {'b': 0, 'a': 1},
      );
    });

    test('exercício novo entra como INSERT', () {
      final plano = ReconciliacaoDeExercicios.calcular(
        idsExistentes: {'a'},
        enviados: [_ex('a', 'Supino'), _ex(null, 'Crucifixo')],
      );

      expect(plano.paraAtualizar.single['id'], 'a');
      expect(plano.paraInserir.single['name'], 'Crucifixo');
      expect(plano.paraInserir.single['order_index'], 1);
      expect(plano.idsParaApagar, isEmpty);
    });

    test('quem saiu da ficha é apagado — aí o cascade está certo', () {
      final plano = ReconciliacaoDeExercicios.calcular(
        idsExistentes: {'a', 'b'},
        enviados: [_ex('a', 'Supino')],
      );

      expect(plano.idsParaApagar, ['b']);
      expect(plano.paraAtualizar.single['id'], 'a');
    });

    test('esvaziar a lista apaga tudo', () {
      final plano = ReconciliacaoDeExercicios.calcular(
        idsExistentes: {'a', 'b'},
        enviados: const [],
      );

      expect(plano.idsParaApagar.toSet(), {'a', 'b'});
      expect(plano.paraAtualizar, isEmpty);
      expect(plano.paraInserir, isEmpty);
    });

    test('id que não existe mais no banco vira INSERT, não UPDATE órfão', () {
      // A tela pode estar aberta enquanto outro aparelho mexe no template.
      // Um UPDATE de linha inexistente não faria nada e o exercício sumiria
      // da ficha sem ninguém perceber.
      final plano = ReconciliacaoDeExercicios.calcular(
        idsExistentes: {'a'},
        enviados: [_ex('fantasma', 'Supino')],
      );

      expect(plano.paraAtualizar, isEmpty);
      expect(plano.paraInserir.single['name'], 'Supino');
      expect(plano.idsParaApagar, ['a']);
    });

    test('template novo: tudo é INSERT', () {
      final plano = ReconciliacaoDeExercicios.calcular(
        idsExistentes: const {},
        enviados: [_ex(null, 'Supino'), _ex(null, 'Remada')],
      );

      expect(plano.paraInserir.length, 2);
      expect(plano.paraAtualizar, isEmpty);
      expect(plano.idsParaApagar, isEmpty);
    });

    test('order_index acompanha a posição final da lista', () {
      final plano = ReconciliacaoDeExercicios.calcular(
        idsExistentes: {'a'},
        enviados: [_ex(null, 'Novo'), _ex('a', 'Velho')],
      );

      expect(plano.paraInserir.single['order_index'], 0);
      expect(plano.paraAtualizar.single['order_index'], 1);
    });
  });
}
