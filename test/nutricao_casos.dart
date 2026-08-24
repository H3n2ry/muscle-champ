/// Bateria de validação nutricional — os casos.
///
/// Usada por dois arquivos:
///  • `nutricao_gravar_test.dart` — bate na Groq e grava as respostas cruas.
///  • `nutricao_test.dart`        — roda offline em cima do que foi gravado.
///
/// Existe porque a metade que INTERPRETA ("2 ovos cozidos" → alimento + qtd +
/// unidade) é o modelo, e a Groq troca de modelo sem avisar. A metade que faz
/// CONTA é Dart e não muda sozinha. Depois de cada troca de modelo é preciso
/// regravar e reconferir — ver README no topo de `nutricao_gravar_test.dart`.
library;

class CasoNutricional {
  /// O que o usuário digitaria no modo IA.
  final String descricao;

  /// Faixa de kcal aceitável para o resultado final.
  ///
  /// É faixa, não valor exato, de propósito: medidas caseiras variam de pessoa
  /// para pessoa e um rastreador precisa acertar a ordem de grandeza, não a
  /// caloria. Fora da faixa é bug; dentro é aceitável.
  final int kcalMin;
  final int kcalMax;

  /// Peso em gramas que a conversão de medida deveria produzir.
  /// Nulo quando a própria porção é ambígua (ex.: "pizza", sem quantidade).
  final int? pesoEsperado;

  /// De onde saiu a referência — para quem for revisar a faixa depois.
  final String referencia;

  const CasoNutricional(
    this.descricao, {
    required this.kcalMin,
    required this.kcalMax,
    required this.referencia,
    this.pesoEsperado,
  });
}

/// Os casos. Agrupados pelo risco que cada bloco cobre.
const casosNutricionais = <CasoNutricional>[
  // ── Gramas explícitas ───────────────────────────────────────────────────
  // Caminho mais comum e o que menos pode errar: o usuário já deu o número.
  CasoNutricional('200g de frango grelhado',
      pesoEsperado: 200,
      kcalMin: 280,
      kcalMax: 380,
      referencia: 'TACO peito de frango grelhado 159kcal/100g → 318'),
  CasoNutricional('150g de arroz branco cozido',
      pesoEsperado: 150,
      kcalMin: 165,
      kcalMax: 215,
      referencia: 'TACO arroz branco cozido 128kcal/100g → 192'),
  CasoNutricional('100g de batata doce cozida',
      pesoEsperado: 100,
      kcalMin: 65,
      kcalMax: 105,
      referencia: 'TACO batata doce cozida 77kcal/100g'),

  // ── Medidas caseiras ────────────────────────────────────────────────────
  // Aqui o parsing é tudo: se o modelo devolver gramas em vez de qty+unit,
  // a conversão do app não roda e o peso sai errado sem erro nenhum.
  CasoNutricional('2 ovos cozidos',
      pesoEsperado: 100,
      kcalMin: 120,
      kcalMax: 170,
      referencia: '2 × 50g, ovo cozido 143kcal/100g → 143'),
  CasoNutricional('1 concha de feijão',
      pesoEsperado: 80,
      kcalMin: 45,
      kcalMax: 85,
      referencia: 'concha 80g, feijão cozido 76kcal/100g → 61'),
  CasoNutricional('1 colher de sopa de azeite',
      pesoEsperado: 10,
      kcalMin: 75,
      kcalMax: 95,
      referencia: 'colher 10g, azeite 884kcal/100g → 88'),
  CasoNutricional('1 fatia de pão de forma',
      pesoEsperado: 25,
      kcalMin: 50,
      kcalMax: 80,
      referencia: 'fatia 25g, pão de forma 253kcal/100g → 63'),
  CasoNutricional('1 filé de frango grelhado',
      pesoEsperado: 120,
      kcalMin: 165,
      kcalMax: 235,
      referencia: 'filé 120g × 165kcal/100g → 198'),
  CasoNutricional('1 xícara de arroz cozido',
      pesoEsperado: 160,
      kcalMin: 175,
      kcalMax: 230,
      referencia: 'xícara de arroz 160g × 128kcal/100g → 205'),
  CasoNutricional('1 copo de leite integral',
      pesoEsperado: 200,
      kcalMin: 100,
      kcalMax: 145,
      referencia: 'copo de leite 200ml × 61kcal/100g → 122'),

  // ── Fração e linguagem solta ────────────────────────────────────────────
  CasoNutricional('meia banana',
      pesoEsperado: 50,
      kcalMin: 30,
      kcalMax: 65,
      referencia: 'banana 100g/unidade × 0,5 × 89kcal/100g → 45'),
  CasoNutricional('uma banana',
      pesoEsperado: 100,
      kcalMin: 70,
      kcalMax: 110,
      referencia: 'banana média 100g × 89kcal/100g → 89'),
  CasoNutricional('meio mamão papaia',
      kcalMin: 25,
      kcalMax: 120,
      referencia: 'mamão 45kcal/100g; meio papaia entre 60g e 250g'),

  // ── Sem quantidade dita ─────────────────────────────────────────────────
  // O prompt manda assumir a porção típica. Faixa larga de propósito: o que
  // importa é não explodir para "uma pizza inteira".
  CasoNutricional('banana',
      kcalMin: 60,
      kcalMax: 130,
      referencia: 'porção típica = 1 unidade'),
  CasoNutricional('pizza de calabresa',
      kcalMin: 200,
      kcalMax: 450,
      referencia: 'porção típica = 1 fatia 110g × 270kcal/100g → 297'),

  // ── Refeição composta ───────────────────────────────────────────────────
  // Caminho de "items": o app soma item a item porque o modelo erra média
  // ponderada. Se ele mandar um item só com a média, o total despenca.
  CasoNutricional('arroz, feijão e um bife',
      kcalMin: 350,
      kcalMax: 650,
      referencia: '150g arroz 192 + 80g feijão 61 + 100g bife 219 → 472'),
  CasoNutricional('pão francês com manteiga e um café com leite',
      kcalMin: 250,
      kcalMax: 500,
      referencia: '50g pão 150 + 12g manteiga 86 + 200g café c/ leite ~90'),
  // Faixa larga no piso de propósito. Dentro de um prato composto o modelo
  // não escolhe a medida de cada componente — manda tudo como "1 unidade",
  // que o app resolve em 100g cada. O peso total sai certo (~400g), mas a
  // divisão fica uniforme: sobra salada e falta arroz, e o total cai ~15%.
  // Insistir no prompt não pegou; e a incerteza do próprio pedido ("a marmita
  // de quem?") é maior que esses 15%. Fica registrado como limitação.
  CasoNutricional('uma marmita de frango com arroz, feijão e salada',
      kcalMin: 350,
      kcalMax: 900,
      referencia: 'marmita 400-450g; composição uniforme dá 384, real ~460'),
  CasoNutricional('prato feito com arroz, feijão, bife e batata frita',
      kcalMin: 550,
      kcalMax: 1100,
      referencia: 'PF completo, literatura entre 700 e 1000'),

  // ── Bebidas ─────────────────────────────────────────────────────────────
  CasoNutricional('1 lata de coca-cola',
      pesoEsperado: 350,
      kcalMin: 120,
      kcalMax: 175,
      referencia: 'lata 350ml × 42kcal/100ml → 147'),
  CasoNutricional('1 copo de suco de laranja natural',
      pesoEsperado: 250,
      kcalMin: 90,
      kcalMax: 145,
      referencia: 'copo de suco 250ml × 45kcal/100ml → 113'),
  CasoNutricional('uma taça de vinho tinto',
      pesoEsperado: 150,
      kcalMin: 90,
      kcalMax: 145,
      referencia: 'taça 150ml, vinho tinto ~85kcal/100ml → 128'),

  // ── Lanches e pratos prontos ────────────────────────────────────────────
  CasoNutricional('1 pão de queijo',
      pesoEsperado: 30,
      kcalMin: 70,
      kcalMax: 115,
      referencia: 'pão de queijo 30g × 300kcal/100g → 90'),
  CasoNutricional('2 fatias de pizza de mussarela',
      pesoEsperado: 220,
      kcalMin: 480,
      kcalMax: 720,
      referencia: '2 × 110g × 270kcal/100g → 594'),
  CasoNutricional('1 coxinha',
      pesoEsperado: 80,
      kcalMin: 175,
      kcalMax: 265,
      referencia: 'coxinha 80g × 280kcal/100g → 224'),
  CasoNutricional('1 big mac',
      kcalMin: 400,
      kcalMax: 700,
      referencia: 'rótulo McDonald\'s Brasil: 503kcal'),

  // ── Os que já falharam no matcher TACO ──────────────────────────────────
  // Registrados como falha conhecida antes desta bateria existir.
  CasoNutricional('1 goiaba',
      pesoEsperado: 150,
      kcalMin: 55,
      kcalMax: 110,
      referencia: 'goiaba 150g/unidade × 54kcal/100g → 81'),
  CasoNutricional('100g de couve refogada',
      pesoEsperado: 100,
      kcalMin: 45,
      kcalMax: 115,
      referencia: 'TACO couve refogada 90kcal/100g (leva óleo)'),
  CasoNutricional('3 castanhas do pará',
      kcalMin: 55,
      kcalMax: 145,
      referencia: '3 × ~5g × 699kcal/100g → 105'),

  // ── Doces — onde o modelo historicamente superestimava ──────────────────
  CasoNutricional('1 brigadeiro',
      pesoEsperado: 20,
      kcalMin: 60,
      kcalMax: 105,
      referencia: 'brigadeiro 20g × 400kcal/100g → 80'),
  CasoNutricional('1 pote de açaí com granola',
      kcalMin: 400,
      kcalMax: 900,
      referencia: 'cumbuca 300g × 200kcal/100g → 600'),

  // ── Suplemento ──────────────────────────────────────────────────────────
  CasoNutricional('1 scoop de whey protein',
      kcalMin: 90,
      kcalMax: 160,
      referencia: 'scoop ~30g × 380kcal/100g → 114'),
];
