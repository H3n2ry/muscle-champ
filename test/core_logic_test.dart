// Testes do núcleo de lógica pura — tudo que roda sem Supabase.
//
// Cobre as regras de negócio que erram em silêncio: aritmética de macros,
// serialização do plano de dieta (que é persistido e some se quebrar), IMC,
// idade, e as buscas dos catálogos locais.

import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/features/diet/data/datasources/food_database.dart';
import 'package:muscle_camp/features/diet/data/models/diet_model.dart';
import 'package:muscle_camp/features/diet/data/models/water_model.dart';
import 'package:muscle_camp/features/profile/data/models/profile_model.dart';
import 'package:muscle_camp/features/workout/data/datasources/exercise_library.dart';
import 'package:muscle_camp/features/workout/data/models/workout_template_model.dart';

void main() {
  // ── Banco de alimentos ────────────────────────────────────────────────────
  group('FoodDatabase', () {
    test('catálogo não está vazio e não tem valores impossíveis', () {
      expect(FoodDatabase.items, isNotEmpty);

      for (final f in FoodDatabase.items) {
        expect(f.name.trim(), isNotEmpty, reason: 'alimento sem nome');
        expect(f.kcalPer100g, greaterThanOrEqualTo(0), reason: f.name);

        // Limite físico: nada supera 9 kcal/g (gordura pura = 900 kcal/100g)
        expect(f.kcalPer100g, lessThanOrEqualTo(900), reason: f.name);

        // Macros não podem pesar mais que o próprio alimento
        final somaMacros = f.proteinPer100g + f.carbsPer100g + f.fatPer100g;
        expect(somaMacros, lessThanOrEqualTo(100.5),
            reason: '${f.name}: macros somam ${somaMacros}g em 100g');
      }
    });

    test('busca vazia retorna lista vazia', () {
      expect(FoodDatabase.search(''), isEmpty);
      expect(FoodDatabase.search('   '), isEmpty);
    });

    test('busca ignora caixa e acento', () {
      // Usa um item real do catálogo para não depender de conteúdo específico
      final comAcento = FoodDatabase.items.firstWhere(
        (f) => RegExp('[àáâãçéêíóôõú]', caseSensitive: false).hasMatch(f.name),
        orElse: () => FoodDatabase.items.first,
      );

      final semAcento = comAcento.name
          .toUpperCase()
          .replaceAll(RegExp('[ÀÁÂÃ]'), 'A')
          .replaceAll('Ç', 'C')
          .replaceAll(RegExp('[ÉÊ]'), 'E')
          .replaceAll('Í', 'I')
          .replaceAll(RegExp('[ÓÔÕ]'), 'O')
          .replaceAll('Ú', 'U');

      final achados = FoodDatabase.search(semAcento);
      expect(achados.map((f) => f.name), contains(comAcento.name),
          reason: 'buscar "$semAcento" deveria achar "${comAcento.name}"');
    });

    test('busca não retorna nada para termo inexistente', () {
      expect(FoodDatabase.search('zzzqqqxyz'), isEmpty);
    });
  });

  group('FoodItem.calculate', () {
    const arroz = FoodItem(
      name: 'Arroz teste',
      category: 'Cereais',
      kcalPer100g: 128,
      proteinPer100g: 2.5,
      carbsPer100g: 28.1,
      fatPer100g: 0.2,
    );

    test('100g devolve os valores da tabela', () {
      final r = arroz.calculate(100);
      expect(r.calories, 128);
      expect(r.protein, 2.5);
      expect(r.carbs, 28.1);
      expect(r.fat, 0.2);
      expect(r.weightGrams, 100);
      expect(r.foodName, 'Arroz teste');
    });

    test('escala proporcionalmente', () {
      expect(arroz.calculate(200).calories, 256);
      expect(arroz.calculate(50).calories, 64);
      expect(arroz.calculate(200).protein, 5.0);
      expect(arroz.calculate(50).carbs, closeTo(14.1, 0.05));
    });

    test('peso zero zera tudo', () {
      final r = arroz.calculate(0);
      expect(r.calories, 0);
      expect(r.protein, 0);
    });

    test('arredonda macros para uma casa decimal', () {
      final r = arroz.calculate(33);
      expect(r.protein.toStringAsFixed(1), r.protein.toString());
    });
  });

  // ── Biblioteca de exercícios ──────────────────────────────────────────────
  group('ExerciseLibrary', () {
    test('todo grupo tem pelo menos um exercício e nenhum nome vazio', () {
      expect(ExerciseLibrary.allGroups, isNotEmpty);

      for (final g in ExerciseLibrary.allGroups) {
        final ex = ExerciseLibrary.byGroup[g]!;
        expect(ex, isNotEmpty, reason: 'grupo "$g" está vazio');
        for (final nome in ex) {
          expect(nome.trim(), isNotEmpty, reason: 'exercício sem nome em "$g"');
        }
      }
    });

    test('não há exercício duplicado dentro do mesmo grupo', () {
      for (final g in ExerciseLibrary.allGroups) {
        final ex = ExerciseLibrary.byGroup[g]!;
        expect(ex.toSet().length, ex.length, reason: 'duplicata em "$g"');
      }
    });

    test('busca vazia retorna lista vazia', () {
      expect(ExerciseLibrary.search(''), isEmpty);
      expect(ExerciseLibrary.search('  '), isEmpty);
    });

    test('busca é case-insensitive e por substring', () {
      final primeiro = ExerciseLibrary.byGroup.values.first.first;
      expect(ExerciseLibrary.search(primeiro.toUpperCase()), contains(primeiro));
      expect(ExerciseLibrary.search(primeiro.toLowerCase()), contains(primeiro));
    });
  });

  // ── Perfil ────────────────────────────────────────────────────────────────
  group('ProfileModel', () {
    ProfileModel perfil({
      double peso = 80,
      double altura = 180,
      DateTime? nascimento,
      double? gordura,
    }) =>
        ProfileModel(
          id: 'u1',
          name: 'Teste',
          email: 't@t.com',
          goalType: 'maintain',
          currentWeight: peso,
          targetWeight: 75,
          heightCm: altura,
          birthDate: nascimento,
          totalPoints: 0,
          totalWorkouts: 0,
          streak: 0,
          memberSince: DateTime(2026, 1, 1),
          bodyFatPct: gordura,
        );

    test('IMC = peso / altura²', () {
      // 80 / 1.8² = 24.69
      expect(perfil().bmi, closeTo(24.69, 0.01));
      expect(perfil(peso: 60, altura: 170).bmi, closeTo(20.76, 0.01));
    });

    test('IMC é null com dados insuficientes', () {
      expect(perfil(altura: 0).bmi, isNull);
      expect(perfil(peso: 0).bmi, isNull);
    });

    test('idade é null sem data de nascimento', () {
      expect(perfil().age, isNull);
    });

    test('idade conta anos completos', () {
      final hoje = DateTime.now();

      // Aniversário foi hoje → idade cheia
      final fezHoje = DateTime(hoje.year - 30, hoje.month, hoje.day);
      expect(perfil(nascimento: fezHoje).age, 30);

      // Aniversário é amanhã → ainda não completou
      final fazAmanha =
          DateTime(hoje.year - 30, hoje.month, hoje.day).add(const Duration(days: 1));
      expect(perfil(nascimento: fazAmanha).age, 29);
    });

    test('hasBioimpedance reflete presença de qualquer medida', () {
      expect(perfil().hasBioimpedance, isFalse);
      expect(perfil(gordura: 18.5).hasBioimpedance, isTrue);
    });
  });

  // ── Resumo da dieta ───────────────────────────────────────────────────────
  group('DietSummaryModel', () {
    DietSummaryModel resumo({
      int consumido = 1000,
      int meta = 2000,
      double prot = 0,
      double carb = 0,
      double gord = 0,
    }) =>
        DietSummaryModel(
          totalCalories: consumido,
          goalCalories: meta,
          totalProtein: prot,
          totalCarbs: carb,
          totalFat: gord,
          goalMet: false,
          meals: const [],
        );

    test('progresso calórico é a razão consumido/meta', () {
      expect(resumo().calorieProgress, closeTo(0.5, 0.001));
    });

    test('progresso satura em 1.0 mesmo estourando a meta', () {
      expect(resumo(consumido: 5000).calorieProgress, 1.0);
    });

    test('meta zero não divide por zero', () {
      expect(resumo(meta: 0).calorieProgress, 0);
      expect(resumo(meta: 0).proteinProgress, 0);
    });

    test('split de macros 30/40/30 fecha 100% das calorias', () {
      final r = resumo(meta: 2000);
      final kcalDosMacros =
          r.goalProtein * 4 + r.goalCarbs * 4 + r.goalFat * 9;
      expect(kcalDosMacros, closeTo(2000, 0.01),
          reason: 'as metas de macro precisam somar a meta calórica');
    });

    test('metas de macro batem com o split documentado', () {
      final r = resumo(meta: 2000);
      expect(r.goalProtein, closeTo(150, 0.01)); // 30% / 4 kcal
      expect(r.goalCarbs, closeTo(200, 0.01));   // 40% / 4 kcal
      expect(r.goalFat, closeTo(66.67, 0.01));   // 30% / 9 kcal
    });

    test('progresso por macro satura em 1.0', () {
      final r = resumo(meta: 2000, prot: 999, carb: 999, gord: 999);
      expect(r.proteinProgress, 1.0);
      expect(r.carbsProgress, 1.0);
      expect(r.fatProgress, 1.0);
    });
  });

  // ── Hidratação ────────────────────────────────────────────────────────────
  group('WaterSummary', () {
    test('progresso e restante', () {
      const w = WaterSummary(totalMl: 900, goalMl: 3000);
      expect(w.progress, closeTo(0.3, 0.001));
      expect(w.remainingMl, 2100);
      expect(w.goalMet, isFalse);
    });

    test('meta batida satura e zera o restante', () {
      const w = WaterSummary(totalMl: 3500, goalMl: 3000);
      expect(w.progress, 1.0);
      expect(w.remainingMl, 0);
      expect(w.goalMet, isTrue);
    });

    test('meta exata conta como batida', () {
      const w = WaterSummary(totalMl: 3000, goalMl: 3000);
      expect(w.goalMet, isTrue);
      expect(w.remainingMl, 0);
    });

    test('meta ausente não quebra', () {
      const w = WaterSummary(totalMl: 500, goalMl: 0);
      expect(w.progress, 0.0);
      expect(w.remainingMl, 0);
      expect(w.goalMet, isFalse);
    });
  });

  // ── Plano de dieta: serialização ──────────────────────────────────────────
  // Crítico: o plano é persistido em SharedPreferences. Roundtrip quebrado
  // significa usuário perdendo o plano ao reabrir o app.
  group('DietPlan — persistência', () {
    DietPlan planoExemplo() => const DietPlan(
          targetCalories: 2200,
          goalProtein: 165,
          goalCarbs: 220,
          goalFat: 73.3,
          meals: [
            DietPlanMeal(type: 'Café da Manhã', foods: [
              DietPlanFood(
                  name: 'Ovos mexidos',
                  weightG: 120,
                  calories: 186,
                  protein: 15.6,
                  carbs: 1.2,
                  fat: 13.2),
              DietPlanFood(
                  name: 'Pão integral',
                  weightG: 50,
                  calories: 123,
                  protein: 4.5,
                  carbs: 22.0,
                  fat: 1.8),
            ]),
            DietPlanMeal(type: 'Almoço', foods: [
              DietPlanFood(
                  name: 'Frango grelhado',
                  weightG: 150,
                  calories: 247,
                  protein: 46.5,
                  carbs: 0,
                  fat: 5.4),
            ]),
          ],
        );

    test('roundtrip toJson → fromJson preserva tudo', () {
      final original = planoExemplo();
      final volta =
          DietPlan.fromJson(original.toJson(), original.targetCalories);

      expect(volta.targetCalories, original.targetCalories);
      expect(volta.goalProtein, original.goalProtein);
      expect(volta.goalCarbs, original.goalCarbs);
      expect(volta.goalFat, original.goalFat);
      expect(volta.meals.length, original.meals.length);

      for (var i = 0; i < original.meals.length; i++) {
        expect(volta.meals[i].type, original.meals[i].type);
        expect(volta.meals[i].foods.length, original.meals[i].foods.length);

        for (var k = 0; k < original.meals[i].foods.length; k++) {
          final a = original.meals[i].foods[k];
          final b = volta.meals[i].foods[k];
          expect(b.name, a.name);
          expect(b.weightG, a.weightG);
          expect(b.calories, a.calories);
          expect(b.protein, a.protein);
          expect(b.carbs, a.carbs);
          expect(b.fat, a.fat);
        }
      }
    });

    test('totais somam item a item', () {
      final p = planoExemplo();
      expect(p.meals[0].totalCalories, 186 + 123);
      expect(p.meals[0].totalProtein, closeTo(15.6 + 4.5, 0.001));
      expect(p.totalCalories, 186 + 123 + 247);
    });

    test('withWeight recalcula proporcionalmente', () {
      const f = DietPlanFood(
          name: 'Frango',
          weightG: 100,
          calories: 165,
          protein: 31,
          carbs: 0,
          fat: 3.6);

      final dobro = f.withWeight(200);
      expect(dobro.weightG, 200);
      expect(dobro.calories, 330);
      expect(dobro.protein, 62.0);
      expect(dobro.fat, closeTo(7.2, 0.01));

      final metade = f.withWeight(50);
      expect(metade.calories, 83); // 82.5 arredondado
      expect(metade.protein, closeTo(15.5, 0.01));
    });

    test('withWeight não divide por zero', () {
      const f = DietPlanFood(
          name: 'X', weightG: 0, calories: 10, protein: 1, carbs: 1, fat: 1);
      expect(f.withWeight(100).calories, 10, reason: 'deve devolver o próprio');
    });

    test('copyWithMeal e copyWithFood não mutam o original', () {
      final p = planoExemplo();
      final caloriasAntes = p.totalCalories;

      const novo = DietPlanFood(
          name: 'Aveia',
          weightG: 40,
          calories: 150,
          protein: 5,
          carbs: 27,
          fat: 3);

      final alterado = p.copyWithMeal(0, p.meals[0].copyWithFood(0, novo));

      expect(p.totalCalories, caloriasAntes, reason: 'original foi mutado');
      expect(alterado.meals[0].foods[0].name, 'Aveia');
      expect(alterado.totalCalories, isNot(caloriasAntes));
    });
  });

  // ── Modelos de treino ─────────────────────────────────────────────────────
  group('WorkoutTemplateModel', () {
    test('fromJson aplica defaults para campos ausentes', () {
      final t = WorkoutTemplateModel.fromJson({'id': 'a', 'name': 'Peito'});
      expect(t.id, 'a');
      expect(t.name, 'Peito');
      expect(t.doneToday, isFalse);
      expect(t.exerciseCount, 0);
    });

    test('fromJson lê done_today e exercise_count', () {
      final t = WorkoutTemplateModel.fromJson({
        'id': 'a',
        'name': 'Costas',
        'done_today': true,
        'exercise_count': 5,
      });
      expect(t.doneToday, isTrue);
      expect(t.exerciseCount, 5);
    });

    test('copyWith recalcula exerciseCount a partir da lista', () {
      final t = WorkoutTemplateModel.fromJson(
          {'id': 'a', 'name': 'X', 'exercise_count': 9});

      final comExercicios = t.copyWith(exercises: const [
        TemplateExerciseModel(
            id: 'e1',
            templateId: 'a',
            name: 'Supino',
            sets: 3,
            reps: 10,
            weightKg: 40,
            orderIndex: 0),
      ]);

      expect(comExercicios.exerciseCount, 1,
          reason: 'deve refletir a lista, não o valor antigo');
    });

    test('TemplateExerciseModel.fromJson converte números', () {
      final e = TemplateExerciseModel.fromJson({
        'id': 'e1',
        'template_id': 't1',
        'name': 'Agachamento',
        'sets': 4,
        'reps': 8,
        'weight_kg': 60, // int no JSON, double no modelo
      });
      expect(e.weightKg, 60.0);
      expect(e.weightKg, isA<double>());
      expect(e.orderIndex, 0, reason: 'default quando ausente');
    });
  });
}
