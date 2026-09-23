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
  group('preservarIdentidade — o que sobrevive a digitar', () {
    // O formulário devolve um Map NOVO a cada tecla, só com os quatro campos
    // que ele mostra. Sem recolocar o resto, digitar uma letra no nome fazia o
    // exercício virar "linha nova" ao salvar, e com ele iam a anotação e todo o
    // histórico de progressão.
    final antes = <String, dynamic>{
      '_uid': 'ex3',
      'id': 'uuid-do-banco',
      'name': 'Supino',
      'sets': 3,
      'reps': 10,
      'weight_kg': 20.0,
    };
    final digitado = <String, dynamic>{
      'name': 'Supino inclinado',
      'sets': 3,
      'reps': 8,
      'weight_kg': 22.5,
    };

    test('o id do banco sobrevive', () {
      expect(preservarIdentidade(antes, digitado)['id'], 'uuid-do-banco');
    });

    test('o uid da tela sobrevive — é o foco do campo', () {
      expect(preservarIdentidade(antes, digitado)['_uid'], 'ex3');
    });

    test('o que foi digitado vence', () {
      final r = preservarIdentidade(antes, digitado);
      expect(r['name'], 'Supino inclinado');
      expect(r['reps'], 8);
      expect(r['weight_kg'], 22.5);
    });

    test('linha nova continua sem id — não inventa identidade', () {
      final nova = <String, dynamic>{'_uid': 'ex9', 'name': ''};
      expect(preservarIdentidade(nova, digitado).containsKey('id'), isFalse);
      expect(preservarIdentidade(nova, digitado)['_uid'], 'ex9');
    });

    test('a lista de campos protegidos é a que o banco e a tela precisam', () {
      // Se alguém acrescentar um campo que precise sobreviver à digitação,
      // acrescentar aqui também — é o único lugar que decide isso.
      expect(camposDeIdentidade, {'_uid', 'id'});
    });
  });

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
