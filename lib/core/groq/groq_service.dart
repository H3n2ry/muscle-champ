import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'groq_config.dart';

class GroqService {
  GroqService._();

  // ── Calibração da IA de dieta ──────────────────────────────────────────────
  // O modelo tende a inflar calorias quando "chuta" o total direto. Ancorar em
  // valores por 100g + obrigar a regra de Atwater (4/4/9) corrige o exagero e
  // torna a resposta estável entre chamadas parecidas.

  static const String _kNutritionReference = '''
TABELA DE CALIBRAÇÃO — alimentos comuns, valores por 100g do alimento
PRONTO/COZIDO. Serve para padronizar os mais frequentes; NÃO é uma lista
fechada. Alimento fora dela: use seu conhecimento nutricional normalmente.

Arroz branco cozido: 128kcal P2.5 C28 G0.2 | Arroz integral cozido: 124kcal P2.6 C26 G1.0
Feijão cozido: 76kcal P4.8 C13.6 G0.5 | Lentilha cozida: 116kcal P9 C20 G0.4
Peito de frango grelhado: 165kcal P31 C0 G3.6 | Coxa de frango assada: 209kcal P26 C0 G11
Patinho/coxão mole grelhado: 219kcal P32 C0 G9 | Contrafilé grelhado: 278kcal P29 C0 G18
Tilápia grelhada: 128kcal P26 C0 G2.7 | Salmão grelhado: 208kcal P22 C0 G13
Ovo inteiro cozido: 143kcal P13 C1.1 G9.5 | Clara de ovo: 52kcal P11 C0.7 G0.2
Batata cozida: 87kcal P1.9 C20 G0.1 | Batata doce cozida: 86kcal P1.6 C20 G0.1
Macarrão cozido: 158kcal P5.8 C31 G0.9 | Mandioca cozida: 125kcal P1 C30 G0.3
Pão francês: 300kcal P8 C58 G3 | Pão de forma: 253kcal P9 C48 G3
Aveia em flocos: 389kcal P17 C66 G7 | Tapioca (goma): 240kcal P0 C60 G0
Leite integral: 61kcal P3.2 C4.8 G3.3 | Iogurte natural: 60kcal P4 C4.7 G3
Queijo minas frescal: 264kcal P17 C3 G20 | Requeijão: 257kcal P10 C4 G22
Banana: 89kcal P1.1 C23 G0.3 | Maçã: 52kcal P0.3 C14 G0.2 | Laranja: 47kcal P0.9 C12 G0.1
Salada de folhas: 15kcal P1.4 C2.9 G0.2 | Legumes cozidos: 35kcal P2 C7 G0.3
Azeite/óleo: 884kcal P0 C0 G100 | Manteiga: 717kcal P0.9 C0.1 G81
Castanhas/amendoim: 567kcal P26 C16 G49 | Whey protein (pó): 380kcal P78 C8 G5
Açúcar: 387kcal P0 C100 G0 | Refrigerante: 42kcal P0 C10.6 G0

PRATOS PRONTOS E LANCHES (por 100g):
Sushi/temaki: 150kcal P8 C30 G1.5 | Yakisoba: 140kcal P7 C20 G3.5
Estrogonofe de frango: 150kcal P11 C6 G9 | Feijoada: 180kcal P12 C10 G10
Pizza (calabresa/mussarela): 270kcal P12 C30 G11 | Lasanha: 165kcal P9 C15 G7.5
Coxinha/salgado frito: 280kcal P8 C30 G14 | Pastel frito: 320kcal P8 C32 G18
Hambúrguer (lanche completo): 250kcal P12 C25 G11 | Batata frita: 312kcal P3.4 C41 G15
Açaí com granola: 200kcal P2 C35 G6 | Sorvete: 207kcal P3.5 C24 G11
Pão de queijo: 300kcal P6 C36 G14 | Esfiha de carne: 250kcal P10 C30 G10
Strogonoff de carne: 190kcal P13 C6 G13 | Escondidinho: 150kcal P8 C15 G6
Salgadinho de pacote: 520kcal P6 C60 G28 | Chocolate ao leite: 535kcal P7.6 C59 G30

MEDIDAS CASEIRAS → GRAMAS:
1 ovo = 50g | 1 colher de sopa de arroz = 25g | 1 colher de sopa de feijão = 20g
1 concha de feijão = 80g | 1 filé de frango = 120g | 1 bife médio = 100g
1 fatia de pão de forma = 25g | 1 pão francês = 50g | 1 fatia de queijo = 20g
1 banana média = 100g | 1 maçã média = 130g | 1 copo de leite = 200ml = 200g
1 xícara de arroz cozido = 160g | 1 colher de sopa de azeite = 10g
1 prato de refeição completo = 350g a 500g''';

  static const String _kAtwaterRule = '''
NÃO FAÇA CONTAS. O aplicativo calcula tudo. Você só informa DOIS dados:
  A) "weight_g" = peso TOTAL de tudo somado, em gramas
  B) os valores POR 100g do alimento (protein_per_100g, carbs_per_100g, fat_per_100g)

Os valores por 100g descrevem o ALIMENTO, não a porção — nunca multiplique por
quantidade, nunca some por unidade. Quem multiplica pelo peso é o aplicativo.

DE ONDE TIRAR OS VALORES POR 100g:
1. Se o alimento está na tabela acima, use os valores dela (garante consistência).
2. Se NÃO está, use seu próprio conhecimento nutricional — a tabela é só uma
   referência de alimentos comuns, não uma lista fechada. Nunca recuse nem
   force o alimento a virar outro só porque não está listada.
3. Ao usar conhecimento próprio, confira se a densidade é plausível:
   Verduras/legumes: 15-80 kcal/100g | Frutas: 30-100 (abacate/coco: 150-350)
   Carnes/peixes magros: 100-180 | Carnes gordas/embutidos: 250-400
   Grãos e massas cozidos: 100-160 | Pães e biscoitos: 250-450
   Laticínios: 40-120 (queijos duros: 250-400) | Castanhas/sementes: 500-650
   Óleos e gorduras puras: 850-900 | Doces e frituras: 300-550
   Regra física: proteína + carboidrato + gordura nunca somam mais que 100g
   em 100g de alimento (o resto é água e fibra).
4. VÁRIOS ALIMENTOS: NUNCA some nem calcule média. Liste cada alimento
   separadamente em "items" — o aplicativo soma. Um item por alimento citado.

PESO — regra mais importante:
- Se o usuário informou gramas/ml, use EXATAMENTE esse número. Não arredonde
  para cima, não acrescente nada. "200g de X" significa weight_g = 200.
- Só estime o peso quando ele NÃO foi informado.
- O peso total nunca é maior que a soma dos itens citados. Não invente
  acompanhamentos, molhos ou porções que não foram mencionados.

PORÇÕES DE PRATOS PRONTOS (quando o peso não for informado):
1 fatia de pizza = 110g | 1 coxinha/salgado = 80g | 1 hambúrguer médio = 200g
1 pastel = 100g | 1 esfiha = 80g | 1 pão de queijo = 30g | 1 marmita = 450g
1 prato de massa = 300g | 1 cumbuca de açaí = 300g | 1 peça de sushi = 25g

EXEMPLO CORRETO — "2 ovos cozidos":
  1 ovo = 50g, então weight_g = 100 (2 x 50)
  ovo por 100g = P13 C1.1 G9.5  ->  use EXATAMENTE esses valores por 100g
  {"name":"2 ovos cozidos","weight_g":100,"protein_per_100g":13,"carbs_per_100g":1.1,"fat_per_100g":9.5}
  (ERRADO seria dobrar para 26/2.2/19 — o peso já representa os 2 ovos)

Se houver VÁRIOS alimentos diferentes, calcule a média ponderada por 100g do
conjunto e informe o peso total.

IMPORTANTE: seja conservador no peso. Na dúvida entre dois pesos, use o MENOR.
Não invente acompanhamentos que não foram citados/vistos.''';

  /// Normaliza e valida a resposta nutricional da IA.
  ///
  /// A IA erra aritmética com frequência (ex: aplicar os valores "por 100g" a
  /// cada unidade em vez de ao total). Por isso ela devolve a DENSIDADE do
  /// alimento (por 100g) + o peso total, e a conta final é feita aqui:
  ///   macro = (macro_por_100g x peso_g) / 100
  ///   calorias = proteina*4 + carboidrato*4 + gordura*9
  /// Se a densidade não vier, cai no modo antigo (macros absolutos) e apenas
  /// corrige as calorias por Atwater.
  static Map<String, dynamic> _normalizeNutrition(Map<String, dynamic> raw) {
    if (raw['error'] != null) return raw;

    double num0(dynamic v) {
      final d = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
      return d.isFinite && d > 0 ? d : 0.0;
    }

    // Refeição com vários itens: soma item a item aqui (a IA não faz média
    // ponderada de forma confiável — é conta, e é onde ela erra).
    final items = raw['items'];
    if (items is List && items.isNotEmpty) {
      var totalW = 0.0, totalP = 0.0, totalC = 0.0, totalF = 0.0;
      for (final it in items) {
        if (it is! Map) continue;
        final m = Map<String, dynamic>.from(it);
        final w = num0(m['weight_g']).clamp(0.0, 3000.0);
        if (w <= 0) continue;
        var p = num0(m['protein_per_100g']) * w / 100;
        var c = num0(m['carbs_per_100g']) * w / 100;
        var f = num0(m['fat_per_100g']) * w / 100;
        // Trava física por item: macros não pesam mais que o alimento
        final s = p + c + f;
        if (s > w) {
          final k = w / s;
          p *= k;
          c *= k;
          f *= k;
        }
        totalW += w;
        totalP += p;
        totalC += c;
        totalF += f;
      }
      if (totalW > 0) {
        var kcal = totalP * 4 + totalC * 4 + totalF * 9;
        if (kcal > totalW * 9) kcal = totalW * 9;
        double r1(double v) => (v * 10).round() / 10;
        return {
          'name': raw['name'] ?? 'Refeição',
          'weight_g': totalW.round(),
          'calories': kcal.round(),
          'protein': r1(totalP),
          'carbs': r1(totalC),
          'fat': r1(totalF),
        };
      }
    }

    final weight = num0(raw['weight_g']).clamp(1.0, 3000.0);

    // Caminho preferido: a IA informou os valores por 100g → app faz a conta.
    final p100 = num0(raw['protein_per_100g']);
    final c100 = num0(raw['carbs_per_100g']);
    final f100 = num0(raw['fat_per_100g']);
    final hasDensity = (p100 + c100 + f100) > 0;

    var protein = hasDensity ? p100 * weight / 100 : num0(raw['protein']);
    var carbs = hasDensity ? c100 * weight / 100 : num0(raw['carbs']);
    var fat = hasDensity ? f100 * weight / 100 : num0(raw['fat']);

    // Macros não podem pesar mais que o próprio alimento
    final macroSum = protein + carbs + fat;
    if (macroSum > weight) {
      final k = weight / macroSum;
      protein *= k;
      carbs *= k;
      fat *= k;
    }

    final atwater = protein * 4 + carbs * 4 + fat * 9;
    final reported = num0(raw['calories']);

    // Com densidade, a conta é nossa e Atwater é a verdade. Sem densidade,
    // aceita o valor da IA só se for coerente com os macros.
    var calories = hasDensity
        ? atwater
        : ((reported > 0 &&
                atwater > 0 &&
                (reported - atwater).abs() / atwater <= 0.12)
            ? reported
            : atwater);

    // Teto físico: nenhum alimento passa de 9 kcal/g (gordura pura)
    final maxByWeight = weight * 9;
    if (calories > maxByWeight) calories = maxByWeight;

    double r1(double v) => (v * 10).round() / 10;

    return {
      ...raw,
      'weight_g': weight.round(),
      'calories': calories.round(),
      'protein': r1(protein),
      'carbs': r1(carbs),
      'fat': r1(fat),
    }..removeWhere((k, _) => k.endsWith('_per_100g'));
  }

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
      // temperature 0 + seed fixo: a mesma descrição sempre gera o mesmo
      // resultado, e descrições parecidas param de oscilar.
      'temperature': 0,
      'top_p': 1,
      'seed': 42,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': '''Você é um nutricionista brasileiro. Calcule os macronutrientes
do alimento ou refeição descrito pelo usuário.

$_kNutritionReference

$_kAtwaterRule

QUANTIDADE:
- Se o usuário informar gramas/ml, use exatamente esse valor.
- Se informar medida caseira (ovo, colher, fatia, concha, filé), converta pela tabela.
- Se não informar quantidade nenhuma, use a porção caseira típica do alimento
  (ex: "arroz" = 1 colher de servir = 100g; "frango" = 1 filé = 120g).
- "weight_g" é o peso TOTAL somando todos os itens citados.

Retorne SOMENTE JSON válido, sem texto antes ou depois, com UM item por
alimento citado (mesmo que seja só um):
{"name":"Resumo curto da refeição","items":[
  {"name":"2 ovos cozidos","weight_g":100,"protein_per_100g":13.0,"carbs_per_100g":1.1,"fat_per_100g":9.5},
  {"name":"1 fatia de pizza","weight_g":110,"protein_per_100g":12.0,"carbs_per_100g":30.0,"fat_per_100g":11.0}
]}
- "name" do topo: resumo curto em português da refeição inteira
- cada item: nome, peso em gramas e os valores POR 100g daquele alimento
- NÃO envie "calories", nem totais, nem médias — o app soma e calcula tudo''',
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
    return _normalizeNutrition(
        Map<String, dynamic>.from(jsonDecode(content) as Map));
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

$_kNutritionReference

CALORIAS de cada alimento = (proteina x 4) + (carboidrato x 4) + (gordura x 9).
Calcule os macros proporcionalmente ao peso usando a tabela acima — nunca estime
as calorias por conta própria.

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
      'temperature': 0,
      'top_p': 1,
      'seed': 42,
      'max_tokens': 400,
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
                  'Se houver um prato com vários itens, calcule item a item e some tudo.\n'
                  'Use objetos de referência visíveis (garfo~20cm, faca~22cm, prato~26cm) '
                  'para estimar o peso.$portionCtx$handCtx\n'
                  '\n$_kNutritionReference\n'
                  '\n$_kAtwaterRule\n'
                  '\nPESOS TÍPICOS (use como âncora — não exagere):\n'
                  'Porção de arroz no prato: 100-150g | Porção de feijão: 80-120g\n'
                  'Filé de carne/frango: 100-150g | Porção de salada: 50-100g\n'
                  'Porção de batata frita: 100-150g | Sanduíche/lanche: 150-250g\n'
                  'Prato de refeição completo: 350-500g no total\n'
                  'Só passe de 500g se o prato estiver visivelmente muito cheio.\n'
                  '\nO peso é do alimento PRONTO como servido, sem contar prato/talheres.\n'
                  'Responda SOMENTE com JSON válido, sem nenhum texto antes ou depois, '
                  'com UM item por alimento visível no prato:\n'
                  '{"name":"descrição do prato em português","items":[\n'
                  '  {"name":"arroz branco","weight_g":120,"protein_per_100g":2.5,"carbs_per_100g":28,"fat_per_100g":0.2},\n'
                  '  {"name":"peito de frango grelhado","weight_g":130,"protein_per_100g":31,"carbs_per_100g":0,"fat_per_100g":3.6}\n'
                  ']}\n'
                  'Cada item traz o peso DAQUELE alimento e os valores POR 100g dele. '
                  'NÃO envie calorias, totais nem médias — o app soma e calcula.\n'
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
    return _normalizeNutrition(
        Map<String, dynamic>.from(jsonDecode(jsonStr) as Map));
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
