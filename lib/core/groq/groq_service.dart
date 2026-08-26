import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../i18n/locale_provider.dart';
import 'groq_config.dart';
import 'taco_table.dart';

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
Salada de folhas: 15kcal P1.4 C2.9 G0.2 | Legumes cozidos: 35kcal P2 C7 G0.3

FRUTAS (por 100g, fruta fresca sem casca/semente — quase todas ficam entre
30 e 70kcal; você costuma SUPERESTIMAR frutas, use exatamente estes valores):
Abacaxi: 48kcal P0.9 C12.3 G0.1 | Melancia: 33kcal P0.9 C8.1 G0.2
Melão: 29kcal P0.7 C7.5 G0.1 | Mamão: 45kcal P0.8 C11.6 G0.1
Morango: 32kcal P0.7 C7.7 G0.3 | Acerola: 33kcal P0.9 C8 G0.2
Laranja: 47kcal P0.9 C12 G0.1 | Tangerina: 53kcal P0.8 C13 G0.3
Limão: 29kcal P1.1 C9 G0.3 | Maracujá (polpa): 68kcal P2 C13 G0.4
Maçã: 52kcal P0.3 C14 G0.2 | Pera: 57kcal P0.4 C15 G0.1
Pêssego: 39kcal P0.9 C10 G0.3 | Ameixa: 46kcal P0.7 C11 G0.3
Goiaba: 54kcal P1.1 C13 G0.4 | Caju (fruta): 43kcal P0.8 C10 G0.3
Kiwi: 61kcal P1.1 C15 G0.5 | Uva: 69kcal P0.7 C18 G0.2
Manga: 60kcal P0.8 C15 G0.4 | Banana: 89kcal P1.1 C23 G0.3
Caqui: 71kcal P0.6 C18 G0.2 | Figo: 74kcal P0.8 C19 G0.3
Jaca: 95kcal P1.7 C24 G0.6 | Graviola: 62kcal P1 C15 G0.3
Abacate: 96kcal P1.2 C6 G8.4 | Coco fresco: 354kcal P3.3 C15 G33
Frutas secas (mais concentradas): Uva passa: 299kcal P3.1 C79 G0.5
Damasco seco: 241kcal P3.4 C63 G0.5 | Tâmara: 282kcal P2.5 C75 G0.4
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

DOCES E SOBREMESAS (por 100g — você costuma SUPERESTIMAR estes, use os valores):
Doce de leite: 306kcal P5.5 C58.5 G6 | Leite condensado: 321kcal P7.9 C55 G8.7
Brigadeiro: 400kcal P5 C55 G18 | Beijinho: 380kcal P4 C56 G16
Pudim de leite: 150kcal P5 C24 G4 | Mousse de chocolate: 200kcal P4 C25 G10
Bolo simples: 300kcal P5 C50 G9 | Bolo de chocolate: 370kcal P5 C52 G16
Brownie: 400kcal P5 C50 G20 | Paçoca: 480kcal P14 C50 G25
Goiabada: 270kcal P0.4 C68 G0.1 | Geleia de frutas: 250kcal P0.4 C62 G0.1
Mel: 309kcal P0.3 C84 G0 | Açaí puro (polpa): 58kcal P0.8 C6.2 G3.9
Sorvete de creme: 207kcal P3.5 C24 G11 | Chantilly: 260kcal P2 C12 G23

OUTROS COMUNS (por 100g):
Linguiça: 300kcal P16 C1 G26 | Bacon: 540kcal P37 C1.4 G42
Presunto: 145kcal P18 C1.5 G7.5 | Peito de peru: 100kcal P18 C2 G2
Carne moída refogada: 220kcal P24 C0 G14 | Picanha grelhada: 290kcal P26 C0 G20
Sardinha em lata: 200kcal P24 C0 G11 | Atum em lata (água): 116kcal P26 C0 G1
Cuscuz de milho: 113kcal P2.5 C25 G0.5 | Polenta: 85kcal P2 C18 G0.5
Farofa pronta: 400kcal P4 C60 G16 | Molho de tomate: 35kcal P1.5 C7 G0.3
Maionese: 680kcal P1 C2 G75 | Ketchup: 100kcal P1.2 C24 G0.2
Suco natural de laranja: 45kcal P0.7 C10.4 G0.2 | Cerveja: 43kcal P0.5 C3.6 G0
Café sem açúcar: 2kcal P0.1 C0.3 G0 | Leite achocolatado: 80kcal P3 C13 G2

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
3. ATENÇÃO — você tende a SUPERESTIMAR a densidade calórica. Sempre que usar
   conhecimento próprio, escolha o valor mais BAIXO da faixa plausível:
   Verduras/legumes: 15-80 kcal/100g
   Frutas frescas: 30-70 (raras passam disso: banana 89, jaca 95, abacate 96;
   só coco 354 e frutas SECAS 240-300 sao realmente caloricas)
   Carnes/peixes magros: 100-180 | Carnes gordas/embutidos: 250-400
   Grãos e massas cozidos: 100-160 | Pães e biscoitos: 250-450
   Laticínios: 40-120 (queijos duros: 250-400) | Castanhas/sementes: 500-650
   Óleos e gorduras puras: 850-900 | Frituras: 280-400
   Doces cremosos (doce de leite, pudim, mousse, sorvete): 150-320
   Doces concentrados (brigadeiro, paçoca, chocolate): 380-540
   Alimentos com água (sopas, caldos, iogurtes, bebidas): 20-120
   Referência mental: quase nenhum alimento comum passa de 400 kcal/100g.
   Acima disso só óleo, manteiga, castanha, bacon, chocolate e frito seco.
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

IMPORTANTE: seja conservador no peso. Na dúvida entre dois pesos, use o MENOR.
Não invente acompanhamentos que não foram citados/vistos.''';

  /// Densidades oficiais (por 100g) dos alimentos mais comuns — fonte TACO/USDA.
  ///
  /// Mesmo com a tabela no prompt, o modelo desvia ~10-15% para cima. Aqui os
  /// valores são aplicados pelo app: quando o nome do item casa com um destes,
  /// a densidade da IA é descartada e esta é usada. Alimento fora da lista
  /// continua usando o valor do modelo.
  /// Valores: (kcal, proteína, carboidrato, gordura) por 100g.
  ///
  /// As kcal são as oficiais da tabela, não a soma 4/4/9 — em alimentos com
  /// fibra (frutas, vegetais, grãos) Atwater superestima ~10%, porque conta
  /// fibra como 4kcal/g quando ela rende ~2.
  static const Map<String, (double, double, double, double)> _kDensity = {
    // Frutas — (kcal, P, C, G)
    'abacaxi': (48, 0.9, 12.3, 0.1),      'melancia': (33, 0.9, 8.1, 0.2),
    'melao': (29, 0.7, 7.5, 0.1),         'mamao': (45, 0.8, 11.6, 0.1),
    'morango': (32, 0.7, 7.7, 0.3),       'acerola': (33, 0.9, 8.0, 0.2),
    'laranja': (47, 0.9, 12.0, 0.1),      'tangerina': (53, 0.8, 13.0, 0.3),
    'mexerica': (53, 0.8, 13.0, 0.3),     'limao': (29, 1.1, 9.0, 0.3),
    'maracuja': (68, 2.0, 13.0, 0.4),     'maca': (52, 0.3, 14.0, 0.2),
    'pera': (57, 0.4, 15.0, 0.1),         'pessego': (39, 0.9, 10.0, 0.3),
    'ameixa': (46, 0.7, 11.0, 0.3),       'goiaba': (54, 1.1, 13.0, 0.4),
    'kiwi': (61, 1.1, 15.0, 0.5),         'uva': (69, 0.7, 18.0, 0.2),
    'manga': (60, 0.8, 15.0, 0.4),        'banana': (89, 1.1, 23.0, 0.3),
    'caqui': (71, 0.6, 18.0, 0.2),        'figo': (74, 0.8, 19.0, 0.3),
    'jaca': (95, 1.7, 24.0, 0.6),         'graviola': (62, 1.0, 15.0, 0.3),
    'abacate': (96, 1.2, 6.0, 8.4),       'coco': (354, 3.3, 15.0, 33.0),
    'uva passa': (299, 3.1, 79.0, 0.5),   'damasco seco': (241, 3.4, 63.0, 0.5),
    'tamara': (282, 2.5, 75.0, 0.4),
    // Chaves genéricas: a IA às vezes devolve o nome curto ("arroz", "leite").
    // O matcher prefere a chave mais longa, então "arroz integral" continua
    // ganhando de "arroz" quando o nome é específico.
    'arroz': (128, 2.5, 28.0, 0.2),        'leite': (61, 3.2, 4.8, 3.3),
    'queijo': (264, 17.0, 3.0, 20.0),      'pao': (300, 8.0, 58.0, 3.0),
    'carne': (219, 32.0, 0.0, 9.0),        'peixe': (128, 26.0, 0.0, 2.7),
    'suco': (45, 0.6, 10.5, 0.2),          'iogurte': (60, 4.0, 4.7, 3.0),
    'vinho': (83, 0.1, 2.6, 0.0),          'refresco': (30, 0.0, 7.5, 0.0),
    'biscoito': (450, 7.0, 70.0, 15.0),    'bolacha': (450, 7.0, 70.0, 15.0),
    'torta': (250, 6.0, 25.0, 14.0),       'sopa': (50, 3.0, 6.0, 1.5),
    'salgado': (280, 8.0, 30.0, 14.0),     'doce': (350, 3.0, 60.0, 11.0),
    // Base da dieta
    'arroz branco': (128, 2.5, 28.0, 0.2), 'arroz integral': (124, 2.6, 26.0, 1.0),
    'feijao': (76, 4.8, 13.6, 0.5),        'lentilha': (116, 9.0, 20.0, 0.4),
    'batata': (87, 1.9, 20.0, 0.1),        'batata doce': (86, 1.6, 20.0, 0.1),
    'macarrao': (158, 5.8, 31.0, 0.9),     'mandioca': (125, 1.0, 30.0, 0.3),
    'aveia': (389, 17.0, 66.0, 7.0),       'tapioca': (240, 0.0, 60.0, 0.0),
    'cuscuz': (113, 2.5, 25.0, 0.5),       'polenta': (85, 2.0, 18.0, 0.5),
    'pao frances': (300, 8.0, 58.0, 3.0),  'pao de forma': (253, 9.0, 48.0, 3.0),
    // Proteínas
    'frango': (165, 31.0, 0.0, 3.6),       'peito de frango': (165, 31.0, 0.0, 3.6),
    'coxa de frango': (209, 26.0, 0.0, 11.0), 'patinho': (219, 32.0, 0.0, 9.0),
    'contrafile': (278, 29.0, 0.0, 18.0),  'picanha': (290, 26.0, 0.0, 20.0),
    'carne moida': (220, 24.0, 0.0, 14.0), 'tilapia': (128, 26.0, 0.0, 2.7),
    'salmao': (208, 22.0, 0.0, 13.0),      'sardinha': (200, 24.0, 0.0, 11.0),
    'atum': (116, 26.0, 0.0, 1.0),         'ovo': (143, 13.0, 1.1, 9.5),
    'clara de ovo': (52, 11.0, 0.7, 0.2),  'linguica': (300, 16.0, 1.0, 26.0),
    'bacon': (540, 37.0, 1.4, 42.0),       'presunto': (145, 18.0, 1.5, 7.5),
    'peito de peru': (100, 18.0, 2.0, 2.0),
    // Laticínios e gorduras
    'leite integral': (61, 3.2, 4.8, 3.3), 'iogurte natural': (60, 4.0, 4.7, 3.0),
    'queijo minas': (264, 17.0, 3.0, 20.0), 'requeijao': (257, 10.0, 4.0, 22.0),
    'azeite': (884, 0.0, 0.0, 100.0),      'oleo': (884, 0.0, 0.0, 100.0),
    'manteiga': (717, 0.9, 0.1, 81.0),     'maionese': (680, 1.0, 2.0, 75.0),
    'castanha': (567, 26.0, 16.0, 49.0),   'amendoim': (567, 26.0, 16.0, 49.0),
    'whey': (380, 78.0, 8.0, 5.0),
    // Doces
    'doce de leite': (306, 5.5, 58.5, 6.0), 'leite condensado': (321, 7.9, 55.0, 8.7),
    'brigadeiro': (400, 5.0, 55.0, 18.0),  'pudim': (150, 5.0, 24.0, 4.0),
    'mousse de chocolate': (200, 4.0, 25.0, 10.0),
    'bolo de chocolate': (370, 5.0, 52.0, 16.0), 'bolo': (300, 5.0, 50.0, 9.0),
    'brownie': (400, 5.0, 50.0, 20.0),     'pacoca': (480, 14.0, 50.0, 25.0),
    'goiabada': (270, 0.4, 68.0, 0.1),     'geleia': (250, 0.4, 62.0, 0.1),
    'mel': (309, 0.3, 84.0, 0.0),          'acai': (58, 0.8, 6.2, 3.9),
    // A polpa pura tem 58kcal; o que se come na tigela vem com xarope e
    // granola e passa de 200. Sem esta chave o casamento por substring pegava
    // 'acai' e registrava um terço do valor real.
    'acai com granola': (200, 2.0, 35.0, 6.0),
    'acai na tigela': (200, 2.0, 35.0, 6.0),
    'sorvete': (207, 3.5, 24.0, 11.0),     'chocolate': (535, 7.6, 59.0, 30.0),
    'acucar': (387, 0.0, 100.0, 0.0),
    // Pratos prontos
    'sushi': (150, 8.0, 30.0, 1.5),        'yakisoba': (140, 7.0, 20.0, 3.5),
    'estrogonofe': (150, 11.0, 6.0, 9.0),  'strogonoff': (150, 11.0, 6.0, 9.0),
    'feijoada': (180, 12.0, 10.0, 10.0),   'pizza': (270, 12.0, 30.0, 11.0),
    'lasanha': (165, 9.0, 15.0, 7.5),      'coxinha': (280, 8.0, 30.0, 14.0),
    'pastel': (320, 8.0, 32.0, 18.0),      'hamburguer': (250, 12.0, 25.0, 11.0),
    'batata frita': (312, 3.4, 41.0, 15.0), 'pao de queijo': (300, 6.0, 36.0, 14.0),
    'esfiha': (250, 10.0, 30.0, 10.0),     'escondidinho': (150, 8.0, 15.0, 6.0),
    'farofa': (400, 4.0, 60.0, 16.0),
    // Vegetais e bebidas
    'salada': (15, 1.4, 2.9, 0.2),         'alface': (15, 1.4, 2.9, 0.2),
    'brocolis': (35, 2.8, 7.0, 0.4),       'tomate': (18, 0.9, 3.9, 0.2),
    'cenoura': (41, 0.9, 10.0, 0.2),       'legumes': (35, 2.0, 7.0, 0.3),
    'molho de tomate': (35, 1.5, 7.0, 0.3), 'ketchup': (100, 1.2, 24.0, 0.2),
    // Refogados levam óleo: tratá-los como verdura crua subestimava em 3×.
    // A TACO tem estes, mas o matcher recusa "couve refogada" — o substantivo
    // principal dela é "couve, manteiga, refogada".
    'couve refogada': (90, 4.4, 8.1, 4.7),
    'abobrinha refogada': (60, 1.2, 4.5, 4.2),
    'chuchu refogado': (55, 0.7, 4.3, 4.0),
    // Bebidas (por 100ml — densidade ~1g/ml, tratadas como gramas)
    'agua': (0, 0.0, 0.0, 0.0),            'agua de coco': (22, 0.7, 5.3, 0.2),
    'cafe': (2, 0.1, 0.3, 0.0),            'cafe com acucar': (20, 0.1, 5.0, 0.0),
    'cafe com leite': (40, 2.0, 3.5, 1.8), 'cappuccino': (65, 2.5, 9.0, 2.2),
    'cha': (1, 0.0, 0.2, 0.0),             'cha gelado': (30, 0.0, 7.5, 0.0),
    'refrigerante': (42, 0.0, 10.6, 0.0),  'refrigerante zero': (0, 0.0, 0.1, 0.0),
    'suco de laranja': (45, 0.7, 10.4, 0.2), 'suco de uva': (60, 0.4, 15.0, 0.1),
    'suco de caixa': (50, 0.3, 12.0, 0.1), 'suco em po': (30, 0.0, 7.5, 0.0),
    'suco natural': (45, 0.6, 10.5, 0.2),  'limonada': (35, 0.1, 9.0, 0.0),
    'leite desnatado': (35, 3.4, 5.0, 0.2), 'iogurte liquido': (70, 2.5, 12.0, 1.2),
    'vitamina de banana': (90, 3.0, 15.0, 2.0), 'smoothie': (70, 1.5, 15.0, 0.5),
    'cerveja': (43, 0.5, 3.6, 0.0),        'cerveja sem alcool': (25, 0.4, 5.5, 0.0),
    'vinho tinto': (83, 0.1, 2.6, 0.0),    'vinho branco': (82, 0.1, 2.6, 0.0),
    'destilado': (231, 0.0, 0.0, 0.0),     'vodka': (231, 0.0, 0.0, 0.0),
    'cachaca': (231, 0.0, 0.0, 0.0),       'whisky': (250, 0.0, 0.0, 0.0),
    'caipirinha': (150, 0.0, 15.0, 0.0),   'energetico': (45, 0.0, 11.0, 0.0),
    'energetico zero': (3, 0.0, 0.5, 0.0), 'isotonico': (25, 0.0, 6.0, 0.0),
    'achocolatado': (80, 3.0, 13.0, 2.0),
  };

  /// Peso de uma unidade de medida caseira, em gramas.
  ///
  /// A IA informa a medida como o usuário falou ("2 ovos", "1 concha de
  /// feijão") e a conversão para gramas acontece aqui — estimar peso é
  /// medição, e o modelo é ruim nisso. Chave: 'unidade|alimento' quando o
  /// peso depende do alimento, ou só 'unidade' para o padrão.
  static const Map<String, double> _kMedidas = {
    // unidade (peça inteira)
    'unidade|ovo': 50,          'unidade|pao frances': 50,
    'unidade|banana': 100,      'unidade|maca': 130,
    'unidade|laranja': 180,     'unidade|pera': 160,
    'unidade|tangerina': 120,   'unidade|mexerica': 120,
    'unidade|kiwi': 75,         'unidade|pessego': 130,
    'unidade|ameixa': 60,       'unidade|goiaba': 150,
    'unidade|coxinha': 80,      'unidade|pastel': 100,
    'unidade|esfiha': 80,       'unidade|pao de queijo': 30,
    'unidade|hamburguer': 200,  'unidade|sushi': 25,
    'unidade|brigadeiro': 20,   'unidade|pacoca': 25,
    'unidade|acai': 300,        // "um açaí" é a tigela, não 100g de polpa
    'unidade|mamao': 400,       'unidade|abacate': 300,
    'unidade|melancia': 5000,   'unidade|melao': 1200,
    'unidade|vinho': 150,       'unidade|cerveja': 350,
    'unidade': 100,             // padrão quando o alimento não está listado
    // fatia
    'fatia|pizza': 110,         'fatia|pao de forma': 25,
    'fatia|queijo': 20,         'fatia|presunto': 15,
    'fatia|bolo': 80,           'fatia|mamao': 150,
    'fatia|melancia': 200,      'fatia|abacaxi': 80,
    'fatia': 40,
    // colheres
    'colher de sopa|arroz': 25, 'colher de sopa|feijao': 20,
    'colher de sopa|azeite': 10, 'colher de sopa|oleo': 10,
    'colher de sopa|acucar': 12, 'colher de sopa|manteiga': 12,
    'colher de sopa|requeijao': 15, 'colher de sopa|maionese': 15,
    'colher de sopa|aveia': 15, 'colher de sopa|farofa': 20,
    'colher de sopa': 15,
    'colher de cha|acucar': 4,  'colher de cha': 5,
    'colher de servir|arroz': 100, 'colher de servir': 80,
    // porções servidas
    'concha|feijao': 80,        'concha': 100,
    'file|frango': 120,         'file|carne': 100,   'file': 120,
    'bife|carne': 100,          'bife': 100,
    'prato|arroz': 150,         'prato|massa': 300,
    'prato|feijoada': 400,      'prato': 400,
    'marmita': 450,             'porcao': 100,
    'cumbuca|acai': 300,        'cumbuca': 300,
    // líquidos (ml ≈ g)
    'copo|leite': 200,          'copo|suco': 250,
    'copo|refrigerante': 250,   'copo|cerveja': 300,
    'copo': 250,
    'xicara|arroz': 160,        'xicara|cafe': 150,  'xicara': 240,
    'lata': 350,                'garrafa': 500,
    'taca|vinho': 150,          'taca': 150,
    'dose|destilado': 50,       'dose': 50,
    // Medidas que o modelo usa mesmo sem estarem na lista antiga do prompt.
    // Sem elas a unidade não resolvia e a refeição inteira virava 1 grama.
    'pote|acai': 300,           'pote|iogurte': 170,  'pote': 200,
    'scoop|whey': 30,           'scoop': 30,
  };

  /// Peso de UMA peça quando o alimento não está em [_kMedidas].
  ///
  /// Só vale para `unit: "unidade"`. Existe porque o default de 100g erra por
  /// ordem de grandeza nos alimentos pequenos: "3 castanhas do pará" virava
  /// 300g e 1701kcal, vinte vezes o valor real.
  static const Map<String, double> _kUnidadeDaCategoria = {
    'oleaginosa': 5,          // castanha, noz, amêndoa
    'fruta_seca': 8,          // damasco, tâmara, uva passa
    'biscoito': 8,
    'ovo': 50,
    'doce_concentrado': 20,   // brigadeiro, paçoca, bombom
    'queijo': 20,
    'embutido': 30,
    'sanduiche': 180,         // Big Mac e afins pesam bem mais que 100g
  };

  /// Peso assumido quando a unidade é desconhecida.
  ///
  /// Antes o item era descartado; se fosse o único, a refeição caía no
  /// `clamp(1.0, ...)` e o usuário registrava **1 kcal** por um pote de açaí,
  /// sem erro nenhum na tela. Uma porção plausível erra menos que zero.
  static const double _kPorcaoPadrao = 100;

  /// Converte (quantidade, unidade, alimento) em gramas.
  /// Retorna null quando a unidade não é reconhecida.
  static double? _resolverPeso(double qtd, String? unidade, String? alimento,
      [String? categoria]) {
    if (unidade == null || qtd <= 0) return null;
    final u = _slug(unidade);
    // gramas e ml vêm prontos
    if (u == 'g' || u == 'grama' || u == 'gramas' ||
        u == 'ml' || u == 'mililitro' || u == 'mililitros') {
      return qtd;
    }
    if (u == 'kg' || u == 'quilo' || u == 'quilos') return qtd * 1000;
    if (u == 'l' || u == 'litro' || u == 'litros') return qtd * 1000;

    final a = alimento == null ? '' : _slug(alimento);
    // 'unidade|alimento' é o mais confiável; a chave genérica é o último
    // recurso e fica separada para a categoria poder entrar na frente dela.
    String? especifica;
    String? generica;
    for (final chave in _kMedidas.keys) {
      final partes = chave.split('|');
      if (partes[0] != u) continue;
      if (partes.length == 1) {
        generica = chave;
      } else if (a.contains(partes[1]) &&
          (especifica == null ||
              partes[1].length > especifica.split('|')[1].length)) {
        especifica = chave;
      }
    }
    if (especifica != null) return qtd * _kMedidas[especifica]!;

    // Alimento desconhecido: a categoria evita o erro de ordem de grandeza do
    // default de 100g. Só para "unidade" — nas outras medidas o valor genérico
    // já é o certo (uma colher de sopa é 15g independente do que tem nela).
    if (u == 'unidade') {
      final porCategoria = _kUnidadeDaCategoria[categoria];
      if (porCategoria != null) return qtd * porCategoria;
    }

    return generica == null ? null : qtd * _kMedidas[generica]!;
  }

  static String _slug(String s) {
    const de = 'àáâãäåçèéêëìíîïñòóôõöùúûüý';
    const para = 'aaaaaaceeeeiiiinooooouuuuy';
    var r = s.toLowerCase().trim();
    for (var i = 0; i < de.length; i++) {
      r = r.replaceAll(de[i], para[i]);
    }
    return r.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Busca a densidade oficial pelo nome do alimento. Prefere a correspondência
  /// mais específica (ex: "peito de frango" antes de "frango").
  /// Densidade por categoria — usada quando o alimento não está em nenhuma
  /// tabela. A IA classifica (tarefa que ela faz bem) em vez de estimar
  /// números (tarefa que ela faz mal).
  static const Map<String, (double, double, double, double)> _kCategoria = {
    'verdura': (25, 1.8, 4.5, 0.3),
    'legume': (40, 2.0, 8.0, 0.3),
    'fruta': (55, 0.8, 13.0, 0.3),
    'fruta_seca': (280, 3.0, 70.0, 0.5),
    'cereal': (130, 3.0, 27.0, 0.5),
    'leguminosa': (90, 6.0, 15.0, 0.6),
    'tuberculo': (90, 1.8, 20.0, 0.2),
    'massa': (150, 5.5, 30.0, 1.0),
    'pao': (280, 8.5, 53.0, 3.5),
    'biscoito': (450, 7.0, 70.0, 15.0),
    'carne_magra': (150, 28.0, 0.0, 4.0),
    'carne_gorda': (280, 26.0, 0.0, 19.0),
    'embutido': (300, 16.0, 2.0, 25.0),
    'peixe': (140, 24.0, 0.0, 4.5),
    'ovo': (143, 13.0, 1.1, 9.5),
    'laticinio': (70, 4.0, 5.0, 3.5),
    'queijo': (300, 20.0, 3.0, 23.0),
    'oleaginosa': (570, 20.0, 20.0, 48.0),
    'gordura': (880, 0.0, 0.0, 99.0),
    'doce_cremoso': (220, 4.0, 35.0, 7.0),
    'doce_concentrado': (420, 6.0, 60.0, 18.0),
    'frito': (320, 8.0, 32.0, 18.0),
    'prato_pronto': (170, 10.0, 15.0, 8.0),
    'sanduiche': (250, 12.0, 26.0, 11.0),
    'sopa': (50, 3.0, 6.0, 1.5),
    'bebida_zero': (2, 0.0, 0.4, 0.0),
    'bebida_acucarada': (45, 0.2, 11.0, 0.0),
    'suco_natural': (45, 0.6, 10.5, 0.2),
    'bebida_alcoolica': (70, 0.3, 3.0, 0.0),
    'suplemento': (380, 60.0, 20.0, 6.0),
  };

  static List<String> _tokens(String s) =>
      _slug(s).split(' ').where((t) => t.length > 2).toList();

  /// Busca na TACO por sobreposição de palavras — os nomes lá são formais
  /// ("Arroz, integral, cozido"), então `contains` não funciona.
  /// Radical da palavra: corta a desinência de gênero/número para que
  /// "moido"/"moida", "cozido"/"cozida" e "file"/"files" casem.
  static String _raiz(String t) =>
      t.length <= 4 ? t : t.substring(0, t.length - 1);

  static bool _casaToken(String a, String b) =>
      a == b || (a.length > 4 && b.length > 4 && _raiz(a) == _raiz(b));

  /// Palavras que apenas descrevem preparo/corte — podem sobrar na chave da
  /// TACO sem mudar de qual alimento se trata.
  static const Set<String> _kPreparo = {
    'cru', 'crua', 'crus', 'cruas', 'cozido', 'cozida', 'cozidos', 'cozidas',
    'grelhado', 'grelhada', 'assado', 'assada', 'refogado', 'refogada',
    'frito', 'frita', 'fritas', 'torrado', 'torrada', 'tostado', 'tostada',
    'seco', 'seca', 'fresco', 'fresca', 'natural', 'defumado', 'defumada',
    'sem', 'com', 'pele', 'osso', 'casca', 'sal', 'agua', 'file', 'files',
    'seco3', 'maduro', 'madura', 'seleta', 'inteiro', 'inteira',
  };

  /// Busca na TACO de forma CONSERVADORA: só aceita quando a correspondência
  /// é inequívoca. Um valor plausível porém errado (ex: "abacaxi" cair em
  /// "abacaxi polpa congelada", 31kcal em vez de 48) é pior que não achar —
  /// sem match, a categoria assume, e ela é calibrada.
  ///
  /// Critérios: o substantivo principal casa exatamente, todas as palavras da
  /// consulta são explicadas pela chave, e o que sobra na chave é só preparo.
  static (double, double, double, double)? _lookupTaco(String name) {
    final q = _tokens(name);
    if (q.isEmpty) return null;
    final cabeca = q.first;

    String? melhor;
    var menosSobra = 1 << 30;
    for (final chave in kTacoTable.keys) {
      final kt = chave.split(' ').where((t) => t.length > 2).toList();
      if (kt.isEmpty || kt.first != cabeca) continue; // principal exato

      // toda palavra da consulta precisa aparecer na chave
      if (!q.every((x) => kt.any((k) => _casaToken(k, x)))) continue;

      // o que sobra na chave só pode ser descrição de preparo
      final sobra =
          kt.where((k) => !q.any((x) => _casaToken(k, x))).toList();
      if (sobra.any((s) => !_kPreparo.contains(s))) continue;

      // entre as válidas, a mais simples (menos palavras sobrando)
      if (sobra.length < menosSobra) {
        menosSobra = sobra.length;
        melhor = chave;
      }
    }
    return melhor == null ? null : kTacoTable[melhor];
  }

  /// Cascata: tabela curada → TACO → categoria informada pela IA.
  static (double, double, double, double)? _lookupDensity(String? name,
      [String? categoria]) {
    if (name == null || name.isEmpty) return null;
    final n = _slug(name);

    // 1) tabela curada (calibrada à mão, cobre pratos prontos e bebidas)
    String? melhor;
    for (final chave in _kDensity.keys) {
      if (n.contains(chave) &&
          (melhor == null || chave.length > melhor.length)) {
        melhor = chave;
      }
    }
    if (melhor != null) return _kDensity[melhor];

    // 2) TACO (581 alimentos básicos brasileiros)
    final taco = _lookupTaco(name);
    if (taco != null) return taco;

    // 3) categoria classificada pela IA
    if (categoria != null) {
      final c = _slug(categoria).replaceAll(' ', '_');
      if (_kCategoria.containsKey(c)) return _kCategoria[c];
    }
    return null;
  }

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
      // kcal somadas item a item: de tabela quando o alimento é conhecido,
      // por Atwater quando não é. Misturar os dois é mais preciso do que
      // aplicar Atwater no total (que superestima fibra dos conhecidos).
      var totalKcal = 0.0;
      for (final it in items) {
        if (it is! Map) continue;
        final m = Map<String, dynamic>.from(it);
        // Preferido: a IA manda a medida como o usuário falou (qty + unit) e
        // o app converte. weight_g fica como retrocompatibilidade.
        final nome = m['name'] as String?;
        final categoria = m['categoria'] as String?;
        var bruto = _resolverPeso(
                num0(m['qty']), m['unit'] as String?, nome, categoria) ??
            num0(m['weight_g']);
        if (bruto <= 0) {
          // Unidade fora do vocabulário ("1 pote", "1 scoop"): assume porção.
          // Descartar era pior — zerava o item e, sendo o único, a refeição
          // inteira desabava para 1 grama sem nenhum sinal na tela.
          final q = num0(m['qty']);
          bruto = (q > 0 ? q : 1) * _kPorcaoPadrao;
        }
        final w = bruto.clamp(0.0, 3000.0);
        if (w <= 0) continue;
        // Alimento conhecido → usa os valores oficiais, ignora os da IA
        //
        // A busca casa por nome em PORTUGUÊS (_kDensity, kTacoTable). Com o app
        // em inglês ou espanhol o `name` vem traduzido e não casaria nada, caindo
        // na densidade crua da IA. Por isso o modelo devolve `name_pt` junto: o
        // usuário lê no idioma dele, a tabela continua sendo consultada em
        // português. Sem `name_pt` (resposta antiga), usa `name`.
        final nomeBusca = (m['name_pt'] as String?) ?? nome;
        final oficial = _lookupDensity(nomeBusca, m['categoria'] as String?);
        var p = (oficial?.$2 ?? num0(m['protein_per_100g'])) * w / 100;
        var c = (oficial?.$3 ?? num0(m['carbs_per_100g'])) * w / 100;
        var f = (oficial?.$4 ?? num0(m['fat_per_100g'])) * w / 100;
        // Trava física por item: macros não pesam mais que o alimento
        final s = p + c + f;
        if (s > w) {
          final k = w / s;
          p *= k;
          c *= k;
          f *= k;
        }
        totalKcal += oficial != null
            ? oficial.$1 * w / 100
            : p * 4 + c * 4 + f * 9;
        totalW += w;
        totalP += p;
        totalC += c;
        totalF += f;
      }
      if (totalW > 0) {
        var kcal = totalKcal;
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

    // Item único: a IA devolve o objeto direto, sem o array "items".
    // Aceita qty/unit (preferido) e weight_g (retrocompatibilidade).
    var pesoBruto = _resolverPeso(num0(raw['qty']), raw['unit'] as String?,
            raw['name'] as String?, raw['categoria'] as String?) ??
        num0(raw['weight_g']);
    if (pesoBruto <= 0) {
      final q = num0(raw['qty']);
      pesoBruto = (q > 0 ? q : 1) * _kPorcaoPadrao;
    }
    final weight = pesoBruto.clamp(1.0, 3000.0);

    // Caminho preferido: a IA informou os valores por 100g → app faz a conta.
    // Se o alimento for conhecido, a densidade oficial tem prioridade.
    // name_pt: mesmo motivo do caminho por itens — a tabela é em português.
    final oficial = _lookupDensity(
        (raw['name_pt'] as String?) ?? raw['name'] as String?,
        raw['categoria'] as String?);
    final p100 = oficial?.$2 ?? num0(raw['protein_per_100g']);
    final c100 = oficial?.$3 ?? num0(raw['carbs_per_100g']);
    final f100 = oficial?.$4 ?? num0(raw['fat_per_100g']);
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
    var calories = oficial != null
        ? oficial.$1 * weight / 100 // kcal de tabela
        : (hasDensity
            ? atwater
            : ((reported > 0 &&
                    atwater > 0 &&
                    (reported - atwater).abs() / atwater <= 0.12)
                ? reported
                : atwater));

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
      'task': 'text',
      'temperature': 0.7,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': '''Você é um personal trainer experiente.
Gere um treino completo para o agrupamento muscular solicitado.
Retorne SOMENTE JSON válido no formato exato:
{"exercises":[{"name":"Nome do Exercício","sets":3,"reps":12,"tip":"dica curta de execução"}]}

IDIOMA: ${AiLocale.instrucao}

Regras:
- 5 a 8 exercícios por treino
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

  /// Corpo exato da requisição de [calculateFoodMacros].
  ///
  /// Existe separado para a bateria de validação nutricional poder gravar
  /// respostas do modelo com o prompt REAL. Se o gravador tivesse a própria
  /// cópia do prompt, os dois divergiriam com o tempo e a bateria passaria a
  /// validar uma coisa que o app não faz.
  @visibleForTesting
  static String corpoDaRequisicaoDeMacros(String description) => jsonEncode({
        'task': 'text',
        // temperature 0 + seed fixo: a mesma descrição sempre gera o mesmo
        // resultado, e descrições parecidas param de oscilar.
        'temperature': 0,
        'top_p': 1,
        'seed': 42,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': _promptMacros},
          {'role': 'user', 'content': description},
        ],
      });

  /// Metade em Dart do cálculo nutricional, exposta para teste.
  ///
  /// É aqui que mora a aritmética — conversão de medida, cascata de densidade
  /// e travas físicas. Erra em silêncio, então precisa de teste em cima.
  @visibleForTesting
  static Map<String, dynamic> normalizarNutricao(Map<String, dynamic> raw) =>
      _normalizeNutrition(raw);

  static Future<Map<String, dynamic>> calculateFoodMacros(
      String description) async {
    final body = corpoDaRequisicaoDeMacros(description);

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

  static String get _promptMacros => '''Você é um nutricionista brasileiro. Calcule os macronutrientes
do alimento ou refeição descrito pelo usuário.

IDIOMA: ${AiLocale.instrucao}
Além de `name` no idioma do usuário, inclua SEMPRE `name_pt` com o nome do
alimento em português do Brasil. O aplicativo consulta a tabela nutricional
brasileira por esse campo — sem ele a precisão cai. Quando o idioma já for
português, repita o mesmo valor nos dois campos.

$_kNutritionReference

$_kAtwaterRule

QUANTIDADE — NÃO converta para gramas. O aplicativo converte.
Informe a medida do jeito que o usuário falou, em "qty" (número) e "unit":
- unidades aceitas: g, ml, kg, l, unidade, fatia, colher de sopa, colher de chá,
  colher de servir, concha, file, bife, prato, marmita, porcao, cumbuca,
  copo, xicara, lata, garrafa, taca, dose, pote, scoop
- "2 ovos"            -> qty 2, unit "unidade"
- "1 concha de feijão"-> qty 1, unit "concha"
- "200g de frango"    -> qty 200, unit "g"
- "1 copo de suco"    -> qty 1, unit "copo"
- "meia banana"       -> qty 0.5, unit "unidade"
- "1 taça de vinho"   -> qty 1, unit "taca"
- "1 scoop de whey"   -> qty 1, unit "scoop"
- Use a unidade MAIS ESPECÍFICA da lista. "unidade" é o último recurso —
  dentro de uma marmita ou prato feito, prefira concha/colher/file/porcao,
  senão o app assume peça inteira para cada item e a conta sai errada.
- Sem quantidade dita: use a porção típica (1 unidade / 1 porção / 1 copo)

Retorne SOMENTE JSON válido, sem texto antes ou depois, com UM item por
alimento citado (mesmo que seja só um):
{"name":"Resumo curto da refeição","items":[
  {"name":"ovo cozido","name_pt":"ovo cozido","qty":2,"unit":"unidade","categoria":"ovo","protein_per_100g":13.0,"carbs_per_100g":1.1,"fat_per_100g":9.5},
  {"name":"pizza de calabresa","name_pt":"pizza de calabresa","qty":1,"unit":"fatia","categoria":"prato_pronto","protein_per_100g":12.0,"carbs_per_100g":30.0,"fat_per_100g":11.0}
]}
- "name_pt" é OBRIGATÓRIO em CADA item, mesmo em português (repita o "name")
- "name" do topo: resumo curto em português da refeição inteira
- "name" do item: o alimento SEM a quantidade (use "ovo cozido", não "2 ovos")
- os *_per_100g: densidade daquele alimento, nunca multiplicada pela quantidade
- NÃO envie "calories", "weight_g", totais nem médias — o app calcula tudo

"categoria" — escolha UMA desta lista (o app usa como rede de segurança
quando não reconhece o alimento):
verdura, legume, fruta, fruta_seca, cereal, leguminosa, tuberculo, massa,
pao, biscoito, carne_magra, carne_gorda, embutido, peixe, ovo, laticinio,
queijo, oleaginosa, gordura, doce_cremoso, doce_concentrado, frito,
prato_pronto, sanduiche, sopa, bebida_zero, bebida_acucarada, suco_natural,
bebida_alcoolica, suplemento''';

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
      'task': 'text',
      'temperature': 0.3,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content': '''Você é nutricionista esportivo brasileiro especializado em dietas para atletas.
Crie um plano alimentar diário completo com alimentos típicos do Brasil.

IDIOMA: ${AiLocale.instrucao}
Mantenha os alimentos brasileiros, apenas escreva os nomes no idioma pedido.
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
      'task': 'vision',
      'temperature': 0,
      'top_p': 1,
      'seed': 42,
      // Qwen pensa antes de responder por padrão; sem isso o raciocínio
      // consome o max_tokens e o JSON vem cortado.
      'reasoning_effort': 'none',
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
                  'IDIOMA: ${AiLocale.instrucao}\n'
                  'Inclua SEMPRE `name_pt` com o nome em português do Brasil, além '
                  'de `name` no idioma do usuário: o app consulta a tabela '
                  'nutricional brasileira por esse campo.\n'
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
      'task': 'vision',
      'temperature': 0.1,
      'reasoning_effort': 'none',
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
