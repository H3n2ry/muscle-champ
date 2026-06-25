import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../models/diet_model.dart';

final dietRepositoryProvider =
    Provider<DietRepository>((_) => DietRepository());

class DietRepository {
  Future<DietSummaryModel> getTodaySummary() async {
    final uid        = FB.uid;
    final today      = FB.today;
    final todayStart = Timestamp.fromDate(DateTime.parse(today));

    final results = await Future.wait([
      FB.db
          .collection('diet_logs')
          .where('userId', isEqualTo: uid)
          .where('date', isEqualTo: today)
          .orderBy('createdAt')
          .get(),
      FB.db.collection('users').doc(uid).get(),
      FB.db
          .collection('points')
          .where('userId', isEqualTo: uid)
          .where('reason', isEqualTo: 'diet_goal_met')
          .where('createdAt', isGreaterThanOrEqualTo: todayStart)
          .limit(1)
          .get(),
    ]);

    final mealsSnap    = results[0] as QuerySnapshot;
    final userDoc      = results[1] as DocumentSnapshot;
    final userData     = userDoc.data() as Map<String, dynamic>? ?? {};
    final goalCalories = userData['dailyCalories'] as int? ?? 2000;
    final goalType     = userData['goalType'] as String?;

    final meals = mealsSnap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return DietLogModel.fromJson({...data, 'id': d.id});
    }).toList();

    final totals = meals.fold(
      (calories: 0, protein: 0.0, carbs: 0.0, fat: 0.0),
      (acc, m) => (
        calories: acc.calories + m.calories,
        protein:  acc.protein  + m.protein,
        carbs:    acc.carbs    + m.carbs,
        fat:      acc.fat      + m.fat,
      ),
    );

    final goalMet = totals.calories >= goalCalories * 0.9 &&
        totals.calories <= goalCalories * 1.1;

    return DietSummaryModel(
      totalCalories: totals.calories,
      goalCalories:  goalCalories,
      goalType:      goalType,
      totalProtein:  totals.protein,
      totalCarbs:    totals.carbs,
      totalFat:      totals.fat,
      goalMet:       goalMet,
      meals:         meals,
    );
  }

  Future<DietLogModel> addMeal(Map<String, dynamic> data) async {
    final uid   = FB.uid;
    final today = FB.today;

    // Normalizar chave meal_name → mealName
    final normalized = {
      'mealName': data['meal_name'] ?? data['mealName'],
      'calories': data['calories'],
      'protein':  data['protein'],
      'carbs':    data['carbs'],
      'fat':      data['fat'],
    };

    final ref = await FB.db.collection('diet_logs').add({
      ...normalized,
      'userId':    uid,
      'date':      today,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final todayStart = Timestamp.fromDate(DateTime.parse(today));

    // Verificar se meta já foi premiada hoje
    final [mealsSnap, alreadyWon, userDoc] = await Future.wait([
      FB.db
          .collection('diet_logs')
          .where('userId', isEqualTo: uid)
          .where('date', isEqualTo: today)
          .get(),
      FB.db
          .collection('points')
          .where('userId', isEqualTo: uid)
          .where('reason', isEqualTo: 'diet_goal_met')
          .where('createdAt', isGreaterThanOrEqualTo: todayStart)
          .limit(1)
          .get(),
      FB.db.collection('users').doc(uid).get(),
    ]);

    final allMeals = (mealsSnap as QuerySnapshot).docs;
    final userData = ((userDoc as DocumentSnapshot).data() as Map<String, dynamic>? ?? {});
    final goalCal  = userData['dailyCalories'] as int? ?? 2000;
    final totalCal = allMeals.fold<int>(
      0,
      (s, d) => s + ((d.data() as Map<String, dynamic>)['calories'] as int? ?? 0),
    );

    if ((alreadyWon as QuerySnapshot).docs.isEmpty &&
        totalCal >= goalCal * 0.9 &&
        totalCal <= goalCal * 1.1) {
      await FB.db.collection('points').add({
        'userId':    uid,
        'amount':    10,
        'reason':    'diet_goal_met',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FB.db.runTransaction((tx) async {
        final userRef = FB.db.collection('users').doc(uid);
        final ud      = await tx.get(userRef);
        final cur     = ud.data()?['totalPoints'] as int? ?? 0;
        tx.update(userRef, {'totalPoints': cur + 10});
      });
    }

    // Retornar o documento recém criado
    final doc = await ref.get();
    final docData = doc.data()!;
    return DietLogModel.fromJson({...docData, 'id': ref.id});
  }

  Future<void> deleteMeal(String mealId) async {
    await FB.db.collection('diet_logs').doc(mealId).delete();
  }
}
