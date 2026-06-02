/// Banco de dados local de alimentos com valores nutricionais por 100g.
/// Fontes: TACO (Tabela Brasileira de Composição de Alimentos) +
///         USDA FoodData Central (valores aproximados/médios).
library;

class FoodItem {
  final String name;
  final String category;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  const FoodItem({
    required this.name,
    required this.category,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });

  /// Calcula os valores nutricionais para um peso específico em gramas.
  NutritionResult calculate(double weightGrams) {
    final factor = weightGrams / 100.0;
    return NutritionResult(
      foodName: name,
      weightGrams: weightGrams,
      calories: (kcalPer100g * factor).round(),
      protein: double.parse((proteinPer100g * factor).toStringAsFixed(1)),
      carbs: double.parse((carbsPer100g * factor).toStringAsFixed(1)),
      fat: double.parse((fatPer100g * factor).toStringAsFixed(1)),
    );
  }
}

class NutritionResult {
  final String foodName;
  final double weightGrams;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionResult({
    required this.foodName,
    required this.weightGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// BASE DE DADOS
// ─────────────────────────────────────────────────────────────────────────────

class FoodDatabase {
  FoodDatabase._();

  static const List<FoodItem> items = [
    // ── PROTEÍNAS ANIMAIS ────────────────────────────────────────────────────
    FoodItem(
      name: 'Frango (peito grelhado)',
      category: 'Proteína',
      kcalPer100g: 165,
      proteinPer100g: 31.0,
      carbsPer100g: 0.0,
      fatPer100g: 3.6,
    ),
    FoodItem(
      name: 'Frango (coxa assada)',
      category: 'Proteína',
      kcalPer100g: 209,
      proteinPer100g: 24.7,
      carbsPer100g: 0.0,
      fatPer100g: 11.6,
    ),
    FoodItem(
      name: 'Carne bovina (patinho)',
      category: 'Proteína',
      kcalPer100g: 219,
      proteinPer100g: 26.4,
      carbsPer100g: 0.0,
      fatPer100g: 12.0,
    ),
    FoodItem(
      name: 'Carne bovina (alcatra)',
      category: 'Proteína',
      kcalPer100g: 185,
      proteinPer100g: 28.2,
      carbsPer100g: 0.0,
      fatPer100g: 7.5,
    ),
    FoodItem(
      name: 'Salmão grelhado',
      category: 'Proteína',
      kcalPer100g: 208,
      proteinPer100g: 20.4,
      carbsPer100g: 0.0,
      fatPer100g: 13.4,
    ),
    FoodItem(
      name: 'Atum em lata (água)',
      category: 'Proteína',
      kcalPer100g: 116,
      proteinPer100g: 25.5,
      carbsPer100g: 0.0,
      fatPer100g: 1.0,
    ),
    FoodItem(
      name: 'Tilápia grelhada',
      category: 'Proteína',
      kcalPer100g: 128,
      proteinPer100g: 26.2,
      carbsPer100g: 0.0,
      fatPer100g: 2.7,
    ),
    FoodItem(
      name: 'Ovo inteiro cozido',
      category: 'Proteína',
      kcalPer100g: 155,
      proteinPer100g: 12.6,
      carbsPer100g: 1.1,
      fatPer100g: 10.6,
    ),
    FoodItem(
      name: 'Clara de ovo',
      category: 'Proteína',
      kcalPer100g: 52,
      proteinPer100g: 10.9,
      carbsPer100g: 0.7,
      fatPer100g: 0.2,
    ),
    FoodItem(
      name: 'Camarão cozido',
      category: 'Proteína',
      kcalPer100g: 99,
      proteinPer100g: 20.9,
      carbsPer100g: 0.9,
      fatPer100g: 1.1,
    ),

    // ── LATICÍNIOS ───────────────────────────────────────────────────────────
    FoodItem(
      name: 'Queijo cottage',
      category: 'Laticínio',
      kcalPer100g: 98,
      proteinPer100g: 11.1,
      carbsPer100g: 3.4,
      fatPer100g: 4.3,
    ),
    FoodItem(
      name: 'Iogurte grego (integral)',
      category: 'Laticínio',
      kcalPer100g: 97,
      proteinPer100g: 9.0,
      carbsPer100g: 3.6,
      fatPer100g: 5.0,
    ),
    FoodItem(
      name: 'Iogurte natural desnatado',
      category: 'Laticínio',
      kcalPer100g: 56,
      proteinPer100g: 5.7,
      carbsPer100g: 7.7,
      fatPer100g: 0.4,
    ),
    FoodItem(
      name: 'Leite integral',
      category: 'Laticínio',
      kcalPer100g: 61,
      proteinPer100g: 3.2,
      carbsPer100g: 4.8,
      fatPer100g: 3.3,
    ),
    FoodItem(
      name: 'Leite desnatado',
      category: 'Laticínio',
      kcalPer100g: 35,
      proteinPer100g: 3.6,
      carbsPer100g: 5.1,
      fatPer100g: 0.1,
    ),
    FoodItem(
      name: 'Queijo mussarela',
      category: 'Laticínio',
      kcalPer100g: 280,
      proteinPer100g: 22.2,
      carbsPer100g: 2.2,
      fatPer100g: 20.3,
    ),

    // ── SUPLEMENTOS ──────────────────────────────────────────────────────────
    FoodItem(
      name: 'Whey Protein (pó)',
      category: 'Suplemento',
      kcalPer100g: 380,
      proteinPer100g: 80.0,
      carbsPer100g: 5.0,
      fatPer100g: 3.5,
    ),
    FoodItem(
      name: 'Caseína (pó)',
      category: 'Suplemento',
      kcalPer100g: 360,
      proteinPer100g: 75.0,
      carbsPer100g: 6.0,
      fatPer100g: 3.0,
    ),

    // ── CARBOIDRATOS / GRÃOS ─────────────────────────────────────────────────
    FoodItem(
      name: 'Arroz branco cozido',
      category: 'Carboidrato',
      kcalPer100g: 130,
      proteinPer100g: 2.7,
      carbsPer100g: 28.2,
      fatPer100g: 0.3,
    ),
    FoodItem(
      name: 'Arroz integral cozido',
      category: 'Carboidrato',
      kcalPer100g: 124,
      proteinPer100g: 2.6,
      carbsPer100g: 25.8,
      fatPer100g: 1.0,
    ),
    FoodItem(
      name: 'Aveia em flocos',
      category: 'Carboidrato',
      kcalPer100g: 394,
      proteinPer100g: 13.9,
      carbsPer100g: 67.0,
      fatPer100g: 8.5,
    ),
    FoodItem(
      name: 'Macarrão cozido',
      category: 'Carboidrato',
      kcalPer100g: 131,
      proteinPer100g: 5.0,
      carbsPer100g: 24.9,
      fatPer100g: 1.1,
    ),
    FoodItem(
      name: 'Pão integral',
      category: 'Carboidrato',
      kcalPer100g: 247,
      proteinPer100g: 9.4,
      carbsPer100g: 41.3,
      fatPer100g: 3.6,
    ),
    FoodItem(
      name: 'Pão francês',
      category: 'Carboidrato',
      kcalPer100g: 300,
      proteinPer100g: 8.0,
      carbsPer100g: 58.6,
      fatPer100g: 3.1,
    ),
    FoodItem(
      name: 'Batata doce cozida',
      category: 'Carboidrato',
      kcalPer100g: 86,
      proteinPer100g: 1.6,
      carbsPer100g: 20.1,
      fatPer100g: 0.1,
    ),
    FoodItem(
      name: 'Batata inglesa cozida',
      category: 'Carboidrato',
      kcalPer100g: 87,
      proteinPer100g: 1.9,
      carbsPer100g: 20.1,
      fatPer100g: 0.1,
    ),
    FoodItem(
      name: 'Mandioca cozida',
      category: 'Carboidrato',
      kcalPer100g: 125,
      proteinPer100g: 0.6,
      carbsPer100g: 30.1,
      fatPer100g: 0.3,
    ),
    FoodItem(
      name: 'Quinoa cozida',
      category: 'Carboidrato',
      kcalPer100g: 120,
      proteinPer100g: 4.4,
      carbsPer100g: 21.3,
      fatPer100g: 1.9,
    ),

    // ── LEGUMINOSAS ──────────────────────────────────────────────────────────
    FoodItem(
      name: 'Feijão preto cozido',
      category: 'Leguminosa',
      kcalPer100g: 132,
      proteinPer100g: 8.9,
      carbsPer100g: 23.7,
      fatPer100g: 0.5,
    ),
    FoodItem(
      name: 'Feijão carioca cozido',
      category: 'Leguminosa',
      kcalPer100g: 128,
      proteinPer100g: 8.3,
      carbsPer100g: 23.0,
      fatPer100g: 0.5,
    ),
    FoodItem(
      name: 'Lentilha cozida',
      category: 'Leguminosa',
      kcalPer100g: 116,
      proteinPer100g: 9.0,
      carbsPer100g: 20.1,
      fatPer100g: 0.4,
    ),
    FoodItem(
      name: 'Grão de bico cozido',
      category: 'Leguminosa',
      kcalPer100g: 164,
      proteinPer100g: 8.9,
      carbsPer100g: 27.4,
      fatPer100g: 2.6,
    ),

    // ── FRUTAS ───────────────────────────────────────────────────────────────
    FoodItem(
      name: 'Banana',
      category: 'Fruta',
      kcalPer100g: 89,
      proteinPer100g: 1.1,
      carbsPer100g: 23.0,
      fatPer100g: 0.3,
    ),
    FoodItem(
      name: 'Maçã',
      category: 'Fruta',
      kcalPer100g: 52,
      proteinPer100g: 0.3,
      carbsPer100g: 13.8,
      fatPer100g: 0.2,
    ),
    FoodItem(
      name: 'Laranja',
      category: 'Fruta',
      kcalPer100g: 47,
      proteinPer100g: 0.9,
      carbsPer100g: 11.8,
      fatPer100g: 0.1,
    ),
    FoodItem(
      name: 'Morango',
      category: 'Fruta',
      kcalPer100g: 32,
      proteinPer100g: 0.7,
      carbsPer100g: 7.7,
      fatPer100g: 0.3,
    ),
    FoodItem(
      name: 'Abacate',
      category: 'Fruta',
      kcalPer100g: 160,
      proteinPer100g: 2.0,
      carbsPer100g: 8.5,
      fatPer100g: 14.7,
    ),
    FoodItem(
      name: 'Manga',
      category: 'Fruta',
      kcalPer100g: 60,
      proteinPer100g: 0.8,
      carbsPer100g: 15.0,
      fatPer100g: 0.4,
    ),
    FoodItem(
      name: 'Uva',
      category: 'Fruta',
      kcalPer100g: 69,
      proteinPer100g: 0.7,
      carbsPer100g: 18.1,
      fatPer100g: 0.2,
    ),

    // ── VEGETAIS / VERDURAS ──────────────────────────────────────────────────
    FoodItem(
      name: 'Brócolis cozido',
      category: 'Vegetal',
      kcalPer100g: 35,
      proteinPer100g: 2.4,
      carbsPer100g: 7.2,
      fatPer100g: 0.4,
    ),
    FoodItem(
      name: 'Espinafre cozido',
      category: 'Vegetal',
      kcalPer100g: 23,
      proteinPer100g: 2.9,
      carbsPer100g: 3.6,
      fatPer100g: 0.4,
    ),
    FoodItem(
      name: 'Cenoura crua',
      category: 'Vegetal',
      kcalPer100g: 41,
      proteinPer100g: 0.9,
      carbsPer100g: 9.6,
      fatPer100g: 0.2,
    ),
    FoodItem(
      name: 'Tomate cru',
      category: 'Vegetal',
      kcalPer100g: 18,
      proteinPer100g: 0.9,
      carbsPer100g: 3.9,
      fatPer100g: 0.2,
    ),
    FoodItem(
      name: 'Alface cru',
      category: 'Vegetal',
      kcalPer100g: 14,
      proteinPer100g: 1.4,
      carbsPer100g: 2.1,
      fatPer100g: 0.2,
    ),
    FoodItem(
      name: 'Abobrinha cozida',
      category: 'Vegetal',
      kcalPer100g: 17,
      proteinPer100g: 1.2,
      carbsPer100g: 3.5,
      fatPer100g: 0.1,
    ),
    FoodItem(
      name: 'Chuchu cozido',
      category: 'Vegetal',
      kcalPer100g: 22,
      proteinPer100g: 0.9,
      carbsPer100g: 4.9,
      fatPer100g: 0.1,
    ),

    // ── GORDURAS SAUDÁVEIS / OLEAGINOSAS ─────────────────────────────────────
    FoodItem(
      name: 'Azeite de oliva',
      category: 'Gordura',
      kcalPer100g: 884,
      proteinPer100g: 0.0,
      carbsPer100g: 0.0,
      fatPer100g: 100.0,
    ),
    FoodItem(
      name: 'Manteiga de amendoim',
      category: 'Gordura',
      kcalPer100g: 588,
      proteinPer100g: 25.1,
      carbsPer100g: 20.1,
      fatPer100g: 50.4,
    ),
    FoodItem(
      name: 'Amêndoas',
      category: 'Gordura',
      kcalPer100g: 579,
      proteinPer100g: 21.2,
      carbsPer100g: 21.6,
      fatPer100g: 49.9,
    ),
    FoodItem(
      name: 'Castanha de caju',
      category: 'Gordura',
      kcalPer100g: 553,
      proteinPer100g: 18.2,
      carbsPer100g: 30.2,
      fatPer100g: 43.9,
    ),
    FoodItem(
      name: 'Castanha do Pará',
      category: 'Gordura',
      kcalPer100g: 656,
      proteinPer100g: 14.3,
      carbsPer100g: 12.3,
      fatPer100g: 66.4,
    ),
    FoodItem(
      name: 'Azeite de coco',
      category: 'Gordura',
      kcalPer100g: 862,
      proteinPer100g: 0.0,
      carbsPer100g: 0.0,
      fatPer100g: 100.0,
    ),
  ];

  /// Busca alimentos pelo nome (case-insensitive, ignora acentos).
  static List<FoodItem> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = _normalize(query.trim());
    return items
        .where((f) => _normalize(f.name).contains(q) ||
            _normalize(f.category).contains(q))
        .toList();
  }

  static String _normalize(String s) {
    const accents = 'àáâãäåæçèéêëìíîïðñòóôõöùúûüýÿ';
    const normal  = 'aaaaaaaceeeeiiiiðnooooouuuuyy';
    var result = s.toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], normal[i]);
    }
    return result;
  }
}
