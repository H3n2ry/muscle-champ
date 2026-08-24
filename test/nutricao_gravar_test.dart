/// Gravador da bateria nutricional — bate na Groq de verdade.
///
/// NÃO roda no `flutter test` normal: precisa de rede e gasta tokens. Para
/// rodar:
///
///     GRAVAR_NUTRICAO=1 flutter test test/nutricao_gravar_test.dart
///
/// Ele grava `test/fixtures/nutricao_modelo.json` com a resposta CRUA do
/// modelo para cada caso. Esse arquivo é o que `nutricao_test.dart` consome
/// offline — assim a validação roda em CI sem rede, e regravar é exatamente
/// o ritual de revalidar depois de uma troca de modelo.
///
/// Usa `GroqService.corpoDaRequisicaoDeMacros`, o mesmo corpo que o app manda.
/// Nada de prompt duplicado aqui: se o prompt mudar, a gravação muda junto.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:muscle_camp/core/groq/groq_service.dart';
import 'package:muscle_camp/core/secrets.dart';

import 'nutricao_casos.dart';

const _arquivo = 'test/fixtures/nutricao_modelo.json';

void main() {
  final ligado = Platform.environment['GRAVAR_NUTRICAO'] == '1';

  test(
    'grava as respostas do modelo para os ${casosNutricionais.length} casos',
    () async {
      final url = Uri.parse('${Secrets.supabaseUrl}/functions/v1/groq-proxy');
      // A anon key é pública por design (vai embutida no app) e o proxy a
      // aceita — é assim que o ai-healthcheck.yml roda sem conta de teste.
      final headers = {
        'Authorization': 'Bearer ${Secrets.supabaseAnonKey}',
        'Content-Type': 'application/json',
      };

      final gravado = <String, dynamic>{};
      // Por caso, não um só para a bateria toda: quando um modelo da cadeia
      // devolve 429 o proxy passa para o próximo e responde normalmente, SEM
      // marcar `x-model-fallback` (esse cabeçalho só sinaliza modelo
      // aposentado). Ou seja, uma bateria pode sair metade em cada modelo e
      // ninguém nota — exatamente o tipo de mistura que invalida a leitura.
      final modelos = <String, String>{};
      final falhas = <String>[];

      for (final caso in casosNutricionais) {
        stdout.writeln('→ ${caso.descricao}');
        try {
          // O nível gratuito da Groq limita por minuto. Sem ritmo e sem
          // repetição a bateria vira uma parede de 429 e a gente confunde
          // "modelo derivou" com "cota estourada".
          http.Response? res;
          for (var tentativa = 1; tentativa <= 4; tentativa++) {
            res = await http
                .post(url,
                    headers: headers,
                    body: GroqService.corpoDaRequisicaoDeMacros(caso.descricao))
                .timeout(const Duration(seconds: 60));
            if (res.statusCode != 429) break;
            final espera = Duration(seconds: 15 * tentativa);
            stdout.writeln('  429 — esperando ${espera.inSeconds}s '
                '(tentativa $tentativa/4)');
            await Future<void>.delayed(espera);
          }
          await Future<void>.delayed(const Duration(seconds: 4));

          if (res == null || res.statusCode != 200) {
            falhas.add(
                '${caso.descricao}: HTTP ${res?.statusCode} ${res?.body}');
            continue;
          }
          modelos[caso.descricao] =
              res.headers['x-model-used'] ?? '<sem cabecalho>';
          if (res.headers['x-model-fallback'] != null) {
            falhas.add('${caso.descricao}: respondeu pelo modelo RESERVA '
                '(${res.headers['x-model-fallback']}) — MODEL_CHAINS precisa '
                'de atualização');
          }

          final envelope = jsonDecode(res.body) as Map<String, dynamic>;
          final conteudo =
              (envelope['choices'] as List).first['message']['content'];
          if (conteudo == null || (conteudo as String).trim().isEmpty) {
            falhas.add('${caso.descricao}: content vazio — sintoma de modelo '
                'de raciocínio estourando o orçamento de tokens');
            continue;
          }
          gravado[caso.descricao] = jsonDecode(conteudo);
        } catch (e) {
          falhas.add('${caso.descricao}: $e');
        }
      }

      File(_arquivo)
        ..createSync(recursive: true)
        ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
          'modelos': modelos,
          'gravado_em': DateTime.now().toIso8601String(),
          'respostas': gravado,
        }));

      final distintos = modelos.values.toSet();
      stdout.writeln('\nmodelos: ${distintos.join(", ")}');
      if (distintos.length > 1) {
        stdout.writeln('ATENÇÃO: a bateria saiu misturada entre modelos — '
            'provavelmente 429 empurrando para o reserva. Regrave com calma '
            'antes de concluir qualquer coisa sobre deriva.');
      }
      stdout.writeln('gravados: ${gravado.length}/${casosNutricionais.length}');
      for (final f in falhas) {
        stdout.writeln('FALHA: $f');
      }

      expect(gravado, hasLength(casosNutricionais.length),
          reason: 'algum caso não foi gravado:\n${falhas.join('\n')}');
    },
    timeout: const Timeout(Duration(minutes: 10)),
    skip: ligado ? false : 'defina GRAVAR_NUTRICAO=1 (usa rede e gasta tokens)',
  );
}
