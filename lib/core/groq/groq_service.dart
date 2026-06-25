import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image/image.dart' as img;
import 'groq_config.dart';

/// Todas as chamadas de IA passam pela Cloud Function `groqProxy` (Callable).
/// A chave Groq vive no Secret Manager do Firebase — nunca chega ao cliente.
/// O proxy valida o usuário logado (Firebase Auth) automaticamente.
class GroqService {
  GroqService._();

  static final _functions =
      FirebaseFunctions.instanceFor(region: GroqConfig.region);

  // ── Transporte ──────────────────────────────────────────────────────────────

  /// Envia o payload (formato OpenAI/Groq) ao proxy e devolve o JSON da resposta.
  static Future<Map<String, dynamic>> _callGroq(
      Map<String, dynamic> payload) async {
    try {
      final callable = _functions.httpsCallable('groqProxy');
      final result = await callable.call<Map<String, dynamic>>(payload);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      // A function lança HttpsError com mensagem legível
      throw Exception(e.message ?? 'Erro ao chamar a IA. Tente novamente.');
    }
  }

  static String _extractContent(Map<String, dynamic> data) {
    return (data['choices'] as List).first['message']['content'] as String;
  }

  // ── Treino ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> generateWorkout(
      String muscleGroup) async {
    final data = await _callGroq({
      'model': GroqConfig.textModel,
      'temperature': 0.7,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': '''Você é um personal trainer experiente.
Gere um treino completo para o agrupamento muscular solicitado.
Retorne SOMENTE JSON válido no formato exato:
{"exercises":[{"name":"Nome do Exercício","sets":3,"reps":12,"tip":"dica curta de execução"}]}
Regras:
- 5 a 8 exercícios por treino
- Nomes dos exercícios em português
- "reps" deve ser um número inteiro (ex: 12, não "8-12")
- "sets" entre 3 e 4
- "tip" máximo 60 caracteres''',
        },
        {'role': 'user', 'content': 'Gere um treino para: $muscleGroup'},
      ],
    });
    final parsed = jsonDecode(_extractContent(data)) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(parsed['exercises'] as List);
  }

  // ── Macros por texto ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> calculateFoodMacros(
      String description) async {
    final data = await _callGroq({
      'model': GroqConfig.textModel,
      'temperature': 0.2,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': '''Você é um nutricionista especialista em composição nutricional.
O usuário descreverá um alimento ou refeição (com ou sem quantidade).
Calcule os macronutrientes e retorne SOMENTE JSON válido:
{"name":"Nome do alimento","weight_g":100,"calories":200,"protein":20.0,"carbs":15.0,"fat":8.0}
Regras:
- "weight_g": quantidade em gramas descrita pelo usuário (use 100 se não especificado)
- "calories": kcal totais para a quantidade descrita
- Valores de protein/carbs/fat em gramas com 1 casa decimal
- "name" em português, descritivo''',
        },
        {'role': 'user', 'content': description},
      ],
    });
    return Map<String, dynamic>.from(jsonDecode(_extractContent(data)) as Map);
  }

  // ── Plano alimentar ───────────────────────────────────────────────────────────

  /// Gera um plano alimentar diário completo baseado nas calorias alvo e objetivo.
  static Future<Map<String, dynamic>> generateDietPlan(
      int calories, String goalType, {
      double? goalProtein,
      double? goalCarbs,
      double? goalFat,
  }) async {
    final goalLabel = const {
      'lose_weight': 'perda de peso',
      'gain_weight': 'ganho de massa muscular',
      'maintain':    'manutenção',
    }[goalType] ?? 'saúde geral';

    final protMeta = goalProtein?.round() ?? (calories * 0.30 ~/ 4);
    final carbMeta = goalCarbs?.round()   ?? (calories * 0.40 ~/ 4);
    final fatMeta  = goalFat?.round()     ?? (calories * 0.30 ~/ 9);

    final data = await _callGroq({
      'model': GroqConfig.textModel,
      'temperature': 0.3,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': '''Você é nutricionista esportivo brasileiro especializado em dietas para atletas.
Crie um plano alimentar diário completo com alimentos típicos do Brasil.
Retorne SOMENTE JSON válido neste formato exato:
{
  "goal_protein_g": $protMeta,
  "goal_carbs_g": $carbMeta,
  "goal_fat_g": $fatMeta,
  "meals": [
    {
      "type": "Café da Manhã",
      "foods": [
        {"name":"Aveia em flocos","weight_g":80,"calories":295,"protein":11.0,"carbs":54.0,"fat":5.5}
      ]
    }
  ]
}
Tipos de refeição (use exatamente esses nomes): "Café da Manhã", "Lanche da Manhã", "Almoço", "Lanche da Tarde", "Jantar"
Regras OBRIGATÓRIAS — respeite com precisão:
- Exatamente 5 refeições
- 2 a 4 alimentos por refeição
- Nomes dos alimentos em português brasileiro
- Pesos realistas (ex: arroz cozido 200g, frango grelhado 150g)
- Calorias e macros calculados corretamente para o peso indicado
- Soma total de PROTEÍNA de todos os alimentos = aproximadamente ${protMeta}g (não ultrapassar)
- Soma total de CARBOIDRATO de todos os alimentos = aproximadamente ${carbMeta}g (não ultrapassar)
- Soma total de GORDURA de todos os alimentos = aproximadamente ${fatMeta}g (não ultrapassar)
- Soma total de CALORIAS de todos os alimentos = aproximadamente $calories kcal (não ultrapassar)
- goal_protein_g = $protMeta, goal_carbs_g = $carbMeta, goal_fat_g = $fatMeta (use esses valores exatos)''',
        },
        {
          'role': 'user',
          'content': 'Meta: $calories kcal/dia | Objetivo: $goalLabel | Proteína: ${protMeta}g | Carboidrato: ${carbMeta}g | Gordura: ${fatMeta}g',
        },
      ],
    });
    return Map<String, dynamic>.from(jsonDecode(_extractContent(data)) as Map);
  }

  // ── Análise de foto ───────────────────────────────────────────────────────────

  // Redimensiona para máx 768px e recomprime em JPEG 80% — reduz tokens.
  // 768px: bom equilíbrio entre qualidade (pratos complexos) e custo.
  static const int _maxImagePx = 768;

  static (String b64, String mime) _optimizeImage(String base64Input) {
    final bytes = base64Decode(base64Input);
    final original = img.decodeImage(bytes);
    if (original == null) {
      final mime = (bytes.length > 4 &&
              bytes[0] == 0x89 &&
              bytes[1] == 0x50 &&
              bytes[2] == 0x4E &&
              bytes[3] == 0x47)
          ? 'image/png'
          : 'image/jpeg';
      return (base64Input, mime);
    }
    final needsResize =
        original.width > _maxImagePx || original.height > _maxImagePx;
    final resized = needsResize
        ? img.copyResize(
            original,
            width: original.width > original.height ? _maxImagePx : -1,
            height: original.width <= original.height ? _maxImagePx : -1,
          )
        : original;
    return (base64Encode(img.encodeJpg(resized, quality: 80)), 'image/jpeg');
  }

  static Future<Map<String, dynamic>> analyzeFoodPhoto(
      String base64Input, {String? portionHint}) async {
    final (optimized, mime) = _optimizeImage(base64Input);
    final portionCtx = portionHint != null
        ? '\nO usuário indica que é uma porção $portionHint — use isso para calibrar o peso.'
        : '';
    final data = await _callGroq({
      'model': GroqConfig.visionModel,
      'temperature': 0.2,
      'max_tokens': 300,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mime;base64,$optimized'},
            },
            {
              'type': 'text',
              'text': 'Você é nutricionista. Analise a foto e identifique o(s) alimento(s).\n'
                  'Se houver um prato com vários itens, some tudo e retorne como refeição única.\n'
                  'Use objetos de referência visíveis (garfo~20cm, faca~22cm, prato~26cm) para estimar o peso total.$portionCtx\n'
                  'Responda SOMENTE com JSON válido, sem nenhum texto antes ou depois:\n'
                  '{"name":"descrição do prato em português","weight_g":PESO_TOTAL_EM_GRAMAS,"calories":KCAL_TOTAIS,"protein":PROTEINA_G,"carbs":CARBO_G,"fat":GORDURA_G}\n'
                  'Se não conseguir identificar nenhum alimento: {"error":"não identificado"}',
            },
          ],
        },
      ],
    });
    final raw = _extractContent(data);
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    final jsonStr = jsonMatch?.group(0) ?? raw;
    return Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
  }
}
