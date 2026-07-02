import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'groq_config.dart';

class GroqService {
  GroqService._();

  static Future<List<Map<String, dynamic>>> generateWorkout(
      String muscleGroup) async {
    final body = jsonEncode({
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
        {
          'role': 'user',
          'content': 'Gere um treino para: $muscleGroup',
        },
      ],
    });

    final res = await http
        .post(
          Uri.parse(GroqConfig.baseUrl),
          headers: _headers(),
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    _assertOk(res);
    final content = _extractContent(res);
    final parsed = jsonDecode(content) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(parsed['exercises'] as List);
  }

  static Future<Map<String, dynamic>> calculateFoodMacros(
      String description) async {
    final body = jsonEncode({
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
        {
          'role': 'user',
          'content': description,
        },
      ],
    });

    final res = await http
        .post(
          Uri.parse(GroqConfig.baseUrl),
          headers: _headers(),
          body: body,
        )
        .timeout(const Duration(seconds: 20));

    _assertOk(res);
    final content = _extractContent(res);
    return Map<String, dynamic>.from(jsonDecode(content) as Map);
  }

  /// Gera um plano alimentar diário completo baseado nas calorias alvo e objetivo.
  /// Retorna Map com goal_protein_g, goal_carbs_g, goal_fat_g e lista de meals.
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

    // Metas exatas fornecidas pelo app (calculadas com base nas kcal do usuário)
    final protMeta  = goalProtein?.round() ?? (calories * 0.30 ~/ 4);
    final carbMeta  = goalCarbs?.round()   ?? (calories * 0.40 ~/ 4);
    final fatMeta   = goalFat?.round()     ?? (calories * 0.30 ~/ 9);

    final body = jsonEncode({
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

    final res = await http
        .post(Uri.parse(GroqConfig.baseUrl), headers: _headers(), body: body)
        .timeout(const Duration(seconds: 45));

    _assertOk(res);
    final content = _extractContent(res);
    return Map<String, dynamic>.from(jsonDecode(content) as Map);
  }

  // Redimensiona para máx 512px e recomprime em JPEG 75% — reduz ~73% dos tokens.
  // Funciona com qualquer formato (JPG, PNG, WEBP) vindo de câmera ou galeria.
  // 768px: bom equilíbrio entre qualidade (pratos complexos) e tokens
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
    // Só redimensiona se a imagem for maior que o limite
    final needsResize = original.width > _maxImagePx || original.height > _maxImagePx;
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
      String base64Input, {
      String? portionHint,
      double? handLengthCm,
      double? handWidthCm,
  }) async {
    final (optimized, mime) = _optimizeImage(base64Input);
    final portionCtx = portionHint != null
        ? '\nO usuário indica que é uma porção $portionHint — use isso para calibrar o peso.'
        : '';
    // Calibração da mão: régua pessoal para escala. Se a mão aparecer na foto
    // ao lado da comida, é referência precisa; senão, dá noção do tamanho corporal.
    final handCtx = (handLengthCm != null && handWidthCm != null)
        ? '\nCALIBRAÇÃO DO USUÁRIO: a mão dele mede ${handLengthCm.toStringAsFixed(1)}cm de comprimento '
            '(punho à ponta do dedo médio) e ${handWidthCm.toStringAsFixed(1)}cm de largura de palma. '
            'Se a mão aparecer na foto ao lado da comida, use-a como régua PRECISA para medir a porção. '
            'Se não aparecer, use essas medidas como noção do porte físico do usuário para calibrar melhor a estimativa.'
        : '';
    final body = jsonEncode({
      'model': GroqConfig.visionModel,
      'temperature': 0.2,
      'max_tokens': 300,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mime;base64,$optimized',
              },
            },
            {
              'type': 'text',
              'text': 'Você é nutricionista. Analise a foto e identifique o(s) alimento(s).\n'
                  'Se houver um prato com vários itens, some tudo e retorne como refeição única.\n'
                  'Use objetos de referência visíveis (garfo~20cm, faca~22cm, prato~26cm) para estimar o peso total.$portionCtx$handCtx\n'
                  'Responda SOMENTE com JSON válido, sem nenhum texto antes ou depois:\n'
                  '{"name":"descrição do prato em português","weight_g":PESO_TOTAL_EM_GRAMAS,"calories":KCAL_TOTAIS,"protein":PROTEINA_G,"carbs":CARBO_G,"fat":GORDURA_G}\n'
                  'Se não conseguir identificar nenhum alimento: {"error":"não identificado"}',
            },
          ],
        },
      ],
    });

    final res = await http
        .post(
          Uri.parse(GroqConfig.baseUrl),
          headers: _headers(),
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    _assertOk(res);
    final raw = _extractContent(res);
    // extrai o bloco JSON mesmo que o modelo inclua texto extra
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    final jsonStr = jsonMatch?.group(0) ?? raw;
    return Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
  }

  /// Calibração (uma vez): mede a mão do usuário usando uma moeda de diâmetro
  /// conhecido como referência de escala. Retorna `hand_length_cm`,
  /// `hand_width_cm` e `error` (se a moeda ou a mão não forem identificadas).
  static Future<Map<String, dynamic>> calibrateHand(
      String base64Input, double coinDiameterMm) async {
    final (optimized, mime) = _optimizeImage(base64Input);
    final body = jsonEncode({
      'model': GroqConfig.visionModel,
      'temperature': 0.1,
      'max_tokens': 200,
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
              'text': 'Nesta foto há uma MOEDA circular apoiada sobre a palma de uma MÃO aberta.\n'
                  'A moeda tem exatamente ${coinDiameterMm.toStringAsFixed(0)} mm de diâmetro — use-a como referência de escala.\n'
                  'Meça a mão comparando com a moeda:\n'
                  '- comprimento: do punho à ponta do dedo médio, em cm\n'
                  '- largura: da palma na altura dos nós dos dedos, em cm\n'
                  'Valores plausíveis: comprimento 15–22cm, largura 7–11cm.\n'
                  'Responda SOMENTE com JSON válido, sem texto antes ou depois:\n'
                  '{"hand_length_cm":COMPRIMENTO,"hand_width_cm":LARGURA}\n'
                  'Se não houver moeda E mão claramente visíveis: {"error":"não identificado"}',
            },
          ],
        },
      ],
    });

    final res = await http
        .post(Uri.parse(GroqConfig.baseUrl), headers: _headers(), body: body)
        .timeout(const Duration(seconds: 30));

    _assertOk(res);
    final raw = _extractContent(res);
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
    final jsonStr = jsonMatch?.group(0) ?? raw;
    return Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  // Autentica no groq-proxy com o JWT do usuário logado.
  // A chave Groq nunca chega ao cliente — fica no Supabase Vault.
  static Map<String, String> _headers() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }
    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  static void _assertOk(http.Response res) {
    if (res.statusCode != 200) {
      // Extrai a mensagem legível da resposta JSON da Groq, se disponível
      String? groqMsg;
      try {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        groqMsg = (json['error'] as Map?)?['message'] as String?;
      } catch (_) {
        // Resposta não é JSON válido — usa mensagem genérica
      }
      throw Exception(groqMsg ?? 'Groq ${res.statusCode}: ${res.body}');
    }
  }

  static String _extractContent(http.Response res) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['choices'] as List).first['message']['content'] as String;
  }
}
