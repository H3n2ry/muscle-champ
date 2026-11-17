import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/features/subscription/data/repositories/assinatura_repository.dart';

void main() {
  test('CPF com dígitos certos passa, com ou sem máscara', () {
    expect(cpfValido('529.982.247-25'), isTrue);
    expect(cpfValido('52998224725'), isTrue);
  });

  test('CPF com dígito errado, repetido ou curto não passa', () {
    expect(cpfValido('52998224724'), isFalse);
    expect(cpfValido('111.111.111-11'), isFalse);
    expect(cpfValido('5299822472'), isFalse);
    expect(cpfValido(''), isFalse);
  });
}
