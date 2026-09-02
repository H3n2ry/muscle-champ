import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/shared/widgets/barra_liquida.dart';
import 'package:muscle_camp/shared/widgets/tutorial_overlay.dart';

/// O tutorial mira os alvos da barra de navegação, e essas duas coisas moram em
/// arquivos diferentes.
///
/// Quando a barra passou de cinco abas ocupando a largura toda para três alvos
/// centralizados, o tutorial continuou dividindo a tela por cinco. Nada quebrou
/// em tempo de compilação e nada apareceu no console: o holofote simplesmente
/// passou a iluminar o vazio nos passos 2 a 9. Como o tutorial só roda para
/// conta nova, ninguém viu.
///
/// Estes testes existem para que a próxima mudança de forma da barra falhe aqui
/// em vez de falhar na frente de quem está abrindo o app pela primeira vez.
void main() {
  group('o tutorial acompanha a forma da barra', () {
    test('existe um alvo de holofote para cada slot da barra', () {
      final alvosDeNav =
          SpotTarget.values.where((a) => a.name.startsWith('nav')).toList();

      expect(
        alvosDeNav.length,
        BarraLiquida.slots,
        reason: 'A barra tem ${BarraLiquida.slots} slots e o tutorial conhece '
            '${alvosDeNav.length} alvos ($alvosDeNav). Mudou a barra? '
            'Acerte SpotTarget e os passos em _kSteps junto.',
      );
    });

    test('os slots saem na ordem e dentro da tela', () {
      for (final largura in [320.0, 390.0, 768.0, 1920.0]) {
        final centros = List.generate(
          BarraLiquida.slots,
          (i) => BarraLiquida.centroDoSlot(i, largura),
        );

        expect(centros, orderedEquals(centros.toList()..sort()),
            reason: 'slots fora de ordem em ${largura}px');
        expect(centros.first, greaterThan(0),
            reason: 'primeiro slot saiu pela esquerda em ${largura}px');
        expect(centros.last, lessThan(largura),
            reason: 'último slot saiu pela direita em ${largura}px');
      }
    });

    test('a barra fica centrada, inclusive quando bate o teto de largura', () {
      // Numa tela larga a barra para de crescer e passa a ser centralizada.
      // Sem isso a bolha do ativo ia parar no canto de um monitor de 1920px.
      for (final largura in [390.0, 1920.0]) {
        final meio = BarraLiquida.centroDoSlot(1, largura);
        expect(meio, closeTo(largura / 2, 0.01),
            reason: 'o slot do meio deveria estar no meio da tela');
      }
    });

    test('o teto de largura vale onde deve valer', () {
      // Estreito: a barra ocupa a tela menos as margens.
      final estreito = BarraLiquida.centroDoSlot(2, 390) -
          BarraLiquida.centroDoSlot(0, 390);
      expect(
        estreito,
        closeTo((390 - BarraLiquida.margemLateral * 2) / BarraLiquida.slots * 2,
            0.01),
      );

      // Largo: para de crescer em larguraMaxima.
      final largo = BarraLiquida.centroDoSlot(2, 1920) -
          BarraLiquida.centroDoSlot(0, 1920);
      expect(
        largo,
        closeTo(BarraLiquida.larguraMaxima / BarraLiquida.slots * 2, 0.01),
      );
    });
  });
}
