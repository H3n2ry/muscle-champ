import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/features/profile/data/repositories/profile_repository.dart';

/// Segunda-feira de referência para as 6 semanas do gráfico.
/// Semana 0 abre em 13/07/2026 (segunda) e a 5ª fecha em 23/08/2026.
final _inicio = DateTime.utc(2026, 7, 13);

DateTime _dia(int mes, int dia) => DateTime.utc(2026, mes, dia);

List<WeeklyPoints> _montar(int total, List<(DateTime, int)> lancamentos) =>
    ProfileRepository.montarEvolucao(
      totalPoints: total,
      inicioJanela: _inicio,
      lancamentos: lancamentos,
    );

void main() {
  group('montarEvolucao — a curva de pontos do perfil', () {
    test('devolve sempre 6 barras, uma por semana', () {
      final ws = _montar(0, []);
      expect(ws, hasLength(ProfileRepository.semanasNoGrafico));
      expect(ws.first.inicioDaSemana, _inicio);
      expect(ws.last.inicioDaSemana, _inicio.add(const Duration(days: 35)));
    });

    test('a última barra fecha exatamente no total do perfil', () {
      final ws = _montar(430, [
        (_dia(7, 15), 30),
        (_dia(8, 3), 100),
        (_dia(8, 20), 50),
      ]);
      expect(ws.last.acumulado, 430);
    });

    test('nunca desce: acumulado é monotônico', () {
      final ws = _montar(200, [
        (_dia(7, 14), 10),
        (_dia(8, 18), 90),
      ]);
      for (var i = 1; i < ws.length; i++) {
        expect(ws[i].acumulado, greaterThanOrEqualTo(ws[i - 1].acumulado));
      }
    });

    test('pontos anteriores à janela viram o piso da curva', () {
      // 500 no total, só 80 caíram nas 6 semanas → a curva começa em 420.
      final ws = _montar(500, [(_dia(8, 20), 80)]);
      expect(ws.first.acumulado, 420);
      expect(ws.first.ganhos, 0);
      expect(ws.last.acumulado, 500);
    });

    test('sem atividade recente a curva fica reta no total', () {
      final ws = _montar(300, []);
      expect(ws.map((w) => w.acumulado), everyElement(300));
      expect(ws.map((w) => w.ganhos), everyElement(0));
    });

    test('conta zerada fica toda em zero — é o caso do "sem dados"', () {
      final ws = _montar(0, []);
      expect(ws.last.acumulado, 0);
    });

    test('cada lançamento cai na semana da sua data', () {
      final ws = _montar(60, [
        (_dia(7, 13), 10), // segunda que abre a semana 0
        (_dia(7, 19), 10), // domingo que fecha a semana 0
        (_dia(7, 20), 20), // segunda seguinte → semana 1
        (_dia(8, 23), 20), // domingo que fecha a semana 5
      ]);
      expect(ws[0].ganhos, 20);
      expect(ws[1].ganhos, 20);
      expect(ws[2].ganhos, 0);
      expect(ws[5].ganhos, 20);
    });

    test('data anterior à janela encosta na primeira semana em vez de sumir',
        () {
      // O filtro do banco é por timestamptz e o balde aqui é por data: um ponto
      // gravado na virada pode chegar um dia antes. Se sumisse, a última barra
      // não fecharia no total.
      final ws = _montar(100, [(_dia(7, 12), 100)]);
      expect(ws.first.ganhos, 100);
      expect(ws.last.acumulado, 100);
    });

    test('data posterior à janela encosta na última semana', () {
      final ws = _montar(100, [(_dia(9, 30), 100)]);
      expect(ws.last.ganhos, 100);
      expect(ws.last.acumulado, 100);
    });

    test('vários lançamentos no mesmo dia somam na mesma semana', () {
      final ws = _montar(45, [
        (_dia(8, 5), 10),
        (_dia(8, 5), 25),
        (_dia(8, 5), 10),
      ]);
      expect(ws[3].ganhos, 45);
      expect(ws.last.acumulado, 45);
    });
  });

  group('diaUtc — normalização de data', () {
    test('ignora a hora e o fuso do timestamp', () {
      expect(ProfileRepository.diaUtc('2026-08-21T23:45:00-03:00'),
          DateTime.utc(2026, 8, 21));
      expect(ProfileRepository.diaUtc('2026-08-21'), DateTime.utc(2026, 8, 21));
    });

    test('o resultado é sempre UTC, para .inDays não escorregar', () {
      expect(ProfileRepository.diaUtc('2026-08-21T10:00:00Z').isUtc, isTrue);
    });

    test('semanas consecutivas distam exatamente 7 dias', () {
      final a = ProfileRepository.diaUtc('2026-07-13T00:00:00-03:00');
      final b = ProfileRepository.diaUtc('2026-07-20T22:00:00-03:00');
      expect(b.difference(a).inDays, 7);
    });
  });
}
