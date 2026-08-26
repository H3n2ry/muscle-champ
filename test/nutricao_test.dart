/// Validação nutricional — roda offline, em cima do que o modelo respondeu.
///
/// A fixture `test/fixtures/nutricao_modelo.json` é gravada por
/// `nutricao_gravar_test.dart`. Aqui só roda a metade Dart do cálculo
/// (conversão de medida + cascata de densidade + travas físicas), que é a
/// parte que erra em silêncio: nenhuma exceção, só um número errado.
///
/// Depois de trocar de modelo no proxy: regrave a fixture e rode isto. Se
/// quebrar, a interpretação derivou — não a aritmética.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/core/groq/groq_service.dart';

import 'nutricao_casos.dart';

void main() {
  final arquivo = File('test/fixtures/nutricao_modelo.json');
  if (!arquivo.existsSync()) {
    test('fixture da bateria nutricional', () {
      fail('Falta test/fixtures/nutricao_modelo.json. Grave com:\n'
          '  GRAVAR_NUTRICAO=1 flutter test test/nutricao_gravar_test.dart');
    });
    return;
  }

  final fixture = jsonDecode(arquivo.readAsStringSync()) as Map<String, dynamic>;
  final respostas = fixture['respostas'] as Map<String, dynamic>;
  final modelos =
      ((fixture['modelos'] as Map?)?.values.toSet() ?? {'<não registrado>'});

  group('bateria nutricional (${modelos.join(", ")})', () {
    for (final caso in casosNutricionais) {
      test(caso.descricao, () {
        final cru = respostas[caso.descricao];
        expect(cru, isNotNull,
            reason: 'caso ausente na fixture — regrave a bateria');

        final raw = Map<String, dynamic>.from(cru as Map);
        final r = GroqService.normalizarNutricao(raw);

        final peso = r['weight_g'] as int;
        final kcal = r['calories'] as int;
        final p = (r['protein'] as num).toDouble();
        final c = (r['carbs'] as num).toDouble();
        final g = (r['fat'] as num).toDouble();

        final contexto = 'modelo devolveu: ${jsonEncode(raw)}\n'
            'app calculou: ${peso}g · ${kcal}kcal · '
            'P$p C$c G$g\n'
            'referência: ${caso.referencia}';

        // 1) Travas físicas — se estas quebrarem, o bug é na metade Dart.
        expect(p + c + g, lessThanOrEqualTo(peso + 0.5),
            reason: 'macros pesam mais que o alimento\n$contexto');
        expect(kcal, lessThanOrEqualTo(peso * 9),
            reason: 'passou do teto de 9 kcal/g\n$contexto');
        expect(kcal, greaterThan(0), reason: 'zerou as calorias\n$contexto');

        // 2) Conversão de medida — se quebrar, a interpretação derivou:
        //    o modelo mandou grama em vez de qty+unit, ou errou a unidade.
        if (caso.pesoEsperado != null) {
          expect(peso, caso.pesoEsperado,
              reason: 'peso convertido errado\n$contexto');
        }

        // 3) Ordem de grandeza calórica.
        expect(kcal, inInclusiveRange(caso.kcalMin, caso.kcalMax),
            reason: 'kcal fora da faixa de referência\n$contexto');
      });
    }
  });

  group('contrato de resposta do modelo', () {
    test('todo item traz qty + unit — o app é quem converte para gramas', () {
      final quebrados = <String>[];
      for (final caso in casosNutricionais) {
        final raw = Map<String, dynamic>.from(respostas[caso.descricao] as Map);
        final itens = raw['items'] is List
            ? List<Map>.from(raw['items'] as List)
            : [raw];
        for (final it in itens) {
          if (it['qty'] == null || it['unit'] == null) {
            quebrados.add('${caso.descricao} → ${jsonEncode(it)}');
          }
        }
      }
      expect(quebrados, isEmpty,
          reason: 'sem qty+unit a conversão de medida não roda e o peso vira '
              'chute:\n${quebrados.join('\n')}');
    });

    test('nenhum item manda calories ou totais — quem calcula é o app', () {
      final quebrados = <String>[];
      for (final caso in casosNutricionais) {
        final raw = Map<String, dynamic>.from(respostas[caso.descricao] as Map);
        final itens = raw['items'] is List
            ? List<Map>.from(raw['items'] as List)
            : [raw];
        for (final it in itens) {
          if (it['calories'] != null) {
            quebrados.add('${caso.descricao} → ${jsonEncode(it)}');
          }
        }
      }
      expect(quebrados, isEmpty,
          reason: 'o modelo voltou a estimar caloria direto — foi exatamente '
              'isso que inflava os valores em até 2×:\n${quebrados.join('\n')}');
    });

    test('todo item traz name_pt — a tabela nutricional é consultada em pt', () {
      final quebrados = <String>[];
      for (final caso in casosNutricionais) {
        final raw = Map<String, dynamic>.from(respostas[caso.descricao] as Map);
        final itens = raw['items'] is List
            ? List<Map>.from(raw['items'] as List)
            : [raw];
        for (final it in itens) {
          if (it['name_pt'] == null) {
            quebrados.add('${caso.descricao} → ${jsonEncode(it)}');
          }
        }
      }
      expect(quebrados, isEmpty,
          reason: 'sem name_pt o app em inglês/espanhol não casa nada na '
              'tabela e cai na densidade crua da IA:\n${quebrados.join('\n')}');
    });
  });
}
