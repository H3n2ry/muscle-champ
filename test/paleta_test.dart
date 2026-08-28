import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/core/theme/app_colors.dart';
import 'package:muscle_camp/core/theme/paleta.dart';
import 'package:muscle_camp/core/theme/paleta_provider.dart';

/// Luminância relativa da WCAG 2.1.
double _luminancia(Color c) {
  double canal(int v) {
    final s = v / 255.0;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * canal(c.red) +
      0.7152 * canal(c.green) +
      0.0722 * canal(c.blue);
}

double _contraste(Color a, Color b) {
  final la = _luminancia(a);
  final lb = _luminancia(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('Paleta — legibilidade', () {
    // É a razão de a lista ser fechada em vez de um seletor livre. Sem este
    // teste a promessa "toda cor daqui é legível" é só um comentário.
    test('a tinta é legível sobre o acento dela (WCAG AA, 4.5:1)', () {
      for (final p in Paleta.todas) {
        final r = _contraste(p.onPrimary, p.primary);
        expect(r, greaterThanOrEqualTo(4.5),
            reason: '${p.id}: onPrimary sobre primary dá ${r.toStringAsFixed(2)}:1');
      }
    });

    test('o texto secundário é legível sobre o fundo do app', () {
      for (final p in Paleta.todas) {
        final r = _contraste(p.onSurfaceVariant, AppColors.background);
        expect(r, greaterThanOrEqualTo(4.5),
            reason: '${p.id}: onSurfaceVariant sobre o fundo dá '
                '${r.toStringAsFixed(2)}:1');
      }
    });

    test('o acento se destaca do fundo do app', () {
      // 3:1 é o mínimo da WCAG para elementos gráficos e bordas — que é o que
      // o acento é na maior parte das telas (anéis, barras, ícones).
      for (final p in Paleta.todas) {
        final r = _contraste(p.primary, AppColors.background);
        expect(r, greaterThanOrEqualTo(3.0),
            reason: '${p.id}: primary sobre o fundo dá ${r.toStringAsFixed(2)}:1');
      }
    });
  });

  group('Paleta — contrato', () {
    /// Cópia da restrição `profiles_tema_valido`, em
    /// `supabase/migrations/20260827_tema_do_app_por_conta.sql`.
    ///
    /// Um id novo no Dart sem o mesmo id no banco faz a gravação estourar em
    /// produção e só ali — o app pinta a cor, o servidor recusa, e na próxima
    /// abertura a escolha sumiu.
    const idsAceitosPeloBanco = {
      'limao', 'roxo', 'ciano', 'ambar', 'coral', 'azul', 'rosa',
    };

    test('os ids batem com a restrição do banco', () {
      expect(Paleta.todas.map((p) => p.id).toSet(), idsAceitosPeloBanco);
    });

    test('não há id repetido', () {
      final ids = Paleta.todas.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('id desconhecido ou nulo cai no limão', () {
      expect(Paleta.doId(null).id, 'limao');
      expect(Paleta.doId('turquesa-neon').id, 'limao');
      expect(Paleta.doId('').id, 'limao');
    });

    test('cada id conhecido devolve a própria paleta', () {
      for (final p in Paleta.todas) {
        expect(identical(Paleta.doId(p.id), p), isTrue, reason: p.id);
      }
    });
  });

  group('AppColors', () {
    tearDown(() => AppColors.paleta = Paleta.limao);

    test('as cores acompanham a paleta trocada', () {
      AppColors.paleta = Paleta.rosa;
      expect(AppColors.primary, Paleta.rosa.primary);
      expect(AppColors.onPrimary, Paleta.rosa.onPrimary);
      expect(AppColors.onSurfaceVariant, Paleta.rosa.onSurfaceVariant);
      expect(AppColors.outline, Paleta.rosa.outline);
      // `success` é o próprio acento — verde no limão, rosa aqui.
      expect(AppColors.success, Paleta.rosa.primary);
    });

    test('as cores de significado NÃO acompanham', () {
      const alertaAntes = AppColors.warning;
      const erroAntes = AppColors.error;
      AppColors.paleta = Paleta.ciano;
      // Um alerta que muda de cor com o tema deixa de alertar.
      expect(AppColors.warning, alertaAntes);
      expect(AppColors.error, erroAntes);
    });

    test('o fundo não muda com a paleta', () {
      AppColors.paleta = Paleta.coral;
      expect(AppColors.background, const Color(0xFF121413));
      expect(AppColors.onSurface, const Color(0xFFE4E2E1));
    });
  });

  group('repintarTudo', () {
    tearDown(() => AppColors.paleta = Paleta.limao);

    // A parte mais frágil do recurso. As cores são um `static`: ninguém as
    // observa, então trocar o valor não repinta nada por conta própria.
    testWidgets('repinta a árvore inteira', (t) async {
      await t.pumpWidget(const MaterialApp(home: _Sonda()));
      expect(_corAtual(t), Paleta.limao.primary);

      AppColors.paleta = Paleta.rosa;
      repintarTudo();
      await t.pump();

      expect(_corAtual(t), Paleta.rosa.primary);
    });

    // O motivo de não trocar a `key` do app e remontar: a troca de cor fica no
    // fim da página de perfil, e remontar jogaria o usuário para o topo a cada
    // cor experimentada.
    testWidgets('preserva o State — não remonta', (t) async {
      _Sonda.montagens = 0;
      await t.pumpWidget(const MaterialApp(home: _Sonda()));
      expect(_Sonda.montagens, 1);

      AppColors.paleta = Paleta.azul;
      repintarTudo();
      await t.pump();

      expect(_corAtual(t), Paleta.azul.primary);
      expect(_Sonda.montagens, 1, reason: 'initState rodou de novo: remontou');
    });
  });
}

Color? _corAtual(WidgetTester t) {
  final c = t.widget<Container>(find.byKey(const ValueKey('sonda')));
  return (c.decoration as BoxDecoration?)?.color;
}

/// Widget que lê a cor no `build` e conta quantas vezes foi montado.
class _Sonda extends StatefulWidget {
  const _Sonda();

  static int montagens = 0;

  @override
  State<_Sonda> createState() => _SondaState();
}

class _SondaState extends State<_Sonda> {
  @override
  void initState() {
    super.initState();
    _Sonda.montagens++;
  }

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('sonda'),
        decoration: BoxDecoration(color: AppColors.primary),
      );
}
