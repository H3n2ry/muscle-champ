import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/core/i18n/ler_decimal.dart';

/// O teclado numérico em pt-BR oferece vírgula. `double.tryParse` não a aceita,
/// e a carga "22,5" virava 0 kg gravado no CONCLUIR TREINO.
void main() {
  test('vírgula e ponto valem o mesmo', () {
    expect(lerDecimal('22,5'), 22.5);
    expect(lerDecimal('22.5'), 22.5);
    expect(lerDecimal('80'), 80.0);
  });

  test('espaço em volta não atrapalha', () {
    expect(lerDecimal(' 72,3 '), 72.3);
  });

  test('vírgula no meio da digitação não zera', () {
    // O campo do treino lê a cada tecla: "22," é um estado de passagem.
    expect(lerDecimal('22,'), 22.0);
    expect(lerDecimal(',5'), 0.5);
  });

  test('o que não é número volta nulo, não zero', () {
    for (final t in ['', '   ', null, 'abc', '1,2,3', '1.234,5', 'NaN', 'Infinity']) {
      expect(lerDecimal(t), isNull, reason: 'entrada: "$t"');
    }
  });
}
