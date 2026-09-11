import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/features/workout/data/models/historico_de_exercicio_model.dart';
import 'package:muscle_camp/features/workout/data/models/workout_template_model.dart';

TemplateExerciseModel _ex({String? anotacao}) => TemplateExerciseModel(
      id: 'e1',
      templateId: 't1',
      name: 'Supino inclinado',
      sets: 3,
      reps: 10,
      weightKg: 20,
      orderIndex: 0,
      anotacao: anotacao,
    );

void main() {
  group('anotação no copyWith', () {
    // `anotacao ?? this.anotacao` seria o reflexo, e está errado: passar nulo
    // significaria "não mexe", então apagar o texto não gravaria nada e a
    // anotação antiga voltaria na leitura seguinte. A sentinela separa
    // "omiti o parâmetro" de "quero nulo".
    test('omitir mantém o que já estava', () {
      final antes = _ex(anotacao: 'pegada média');
      expect(antes.copyWith(weightKg: 25).anotacao, 'pegada média');
    });

    test('passar null LIMPA — é como se apaga o texto', () {
      final antes = _ex(anotacao: 'pegada média');
      expect(antes.copyWith(anotacao: null).anotacao, isNull);
    });

    test('passar texto substitui', () {
      expect(_ex(anotacao: 'velha').copyWith(anotacao: 'nova').anotacao, 'nova');
    });

    test('mexer em outro campo não inventa anotação', () {
      expect(_ex().copyWith(reps: 12).anotacao, isNull);
    });
  });

  group('HistoricoDeExercicio', () {
    test('lê o que o banco devolve', () {
      final h = HistoricoDeExercicio.fromJson({
        'data': '2026-09-11',
        'peso_kg': 22.5,
        'series': 3,
        'reps': 8,
        'nome': 'Supino inclinado',
      });
      expect(h.data, DateTime(2026, 9, 11));
      expect(h.pesoKg, 22.5);
      expect(h.series, 3);
      expect(h.reps, 8);
    });

    test('numeric do Postgres pode chegar como int', () {
      // `numeric(6,2)` volta como int quando não tem casa decimal, e um cast
      // direto para double explodiria.
      final h = HistoricoDeExercicio.fromJson({
        'data': '2026-09-11',
        'peso_kg': 20,
        'series': 3,
        'reps': 10,
        'nome': 'Supino',
      });
      expect(h.pesoKg, 20.0);
    });

    test('volume conta carga, séries E repetições', () {
      // Peso sozinho mente: 22kg×3×3 é MENOS trabalho que 20kg×3×5, e um
      // gráfico só de carga mostraria subida onde houve queda.
      final leve = HistoricoDeExercicio(
          data: DateTime(2026, 9, 1),
          pesoKg: 20,
          series: 3,
          reps: 5,
          nome: 'x');
      final pesado = HistoricoDeExercicio(
          data: DateTime(2026, 9, 8),
          pesoKg: 22,
          series: 3,
          reps: 3,
          nome: 'x');

      expect(leve.volume, 300);
      expect(pesado.volume, 198);
      expect(pesado.pesoKg, greaterThan(leve.pesoKg));
      expect(pesado.volume, lessThan(leve.volume));
    });
  });
}
