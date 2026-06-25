import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../models/profile_model.dart';

final profileRepositoryProvider =
    Provider<ProfileRepository>((_) => ProfileRepository());

class ProfileRepository {
  // ── Leitura ─────────────────────────────────────────────────────

  Future<ProfileModel> getProfile() async {
    final uid = FB.uid;

    final results = await Future.wait([
      FB.db.collection('users').doc(uid).get(),
      FB.db.collection('workout_completions').where('userId', isEqualTo: uid).get(),
      FB.db
          .collection('bioimpedance_logs')
          .where('userId', isEqualTo: uid)
          .orderBy('measuredAt', descending: true)
          .limit(1)
          .get(),
    ]);

    final userDoc  = results[0] as DocumentSnapshot;
    final workouts = (results[1] as QuerySnapshot).docs;
    final bioSnap  = (results[2] as QuerySnapshot).docs;

    final data        = userDoc.data() as Map<String, dynamic>? ?? {};
    final streak      = _calcStreak(workouts);
    final bio         = bioSnap.isNotEmpty
        ? bioSnap.first.data() as Map<String, dynamic>
        : null;

    return ProfileModel(
      id:            uid,
      name:          data['name'] as String? ?? '',
      email:         FB.auth.currentUser?.email ?? '',
      avatarUrl:     data['avatarUrl'] as String?,
      goalType:      data['goalType'] as String? ?? 'maintain',
      currentWeight: (data['currentWeight'] as num?)?.toDouble() ?? 0,
      targetWeight:  (data['targetWeight']  as num?)?.toDouble() ?? 0,
      heightCm:      (data['heightCm']      as num?)?.toDouble() ?? 0,
      totalPoints:   data['totalPoints'] as int? ?? 0,
      totalWorkouts: workouts.length,
      streak:        streak,
      memberSince:   (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bodyFatPct:    (bio?['bodyFatPct']   as num?)?.toDouble(),
      muscleMassKg:  (bio?['muscleMassKg'] as num?)?.toDouble(),
      visceralFat:   (bio?['visceralFat']  as num?)?.toInt(),
      hydrationPct:  (bio?['hydrationPct'] as num?)?.toDouble(),
      boneMassKg:    (bio?['boneMassKg']   as num?)?.toDouble(),
      bmrKcal:       (bio?['bmrKcal']      as num?)?.toInt(),
      bioUpdatedAt:  bio?['measuredAt'] != null
          ? DateTime.tryParse(bio!['measuredAt'] as String)
          : null,
    );
  }

  int _calcStreak(List<QueryDocumentSnapshot> completions) {
    final dates = completions
        .map((d) => (d.data() as Map<String, dynamic>)['completedDate'] as String?)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;
    int streak = 0;
    DateTime check = DateTime.now();
    for (final d in dates) {
      final date = DateTime.parse(d);
      if (date.year == check.year &&
          date.month == check.month &&
          date.day == check.day) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Edição de perfil ─────────────────────────────────────────────

  Future<void> updateName(String name) async {
    await FB.db.collection('users').doc(FB.uid).update({
      'name':      name,
      'nameLower': name.toLowerCase(),
    });
  }

  Future<void> updateWeight(double weight) async {
    final uid   = FB.uid;
    final today = FB.today;
    await Future.wait([
      FB.db
          .collection('users')
          .doc(uid)
          .update({'currentWeight': weight}),
      FB.db.collection('weight_logs').add({
        'userId':    uid,
        'weight':    weight,
        'date':      today,
        'createdAt': FieldValue.serverTimestamp(),
      }),
    ]);
  }

  Future<void> updateHeight(double heightCm) async {
    await FB.db
        .collection('users')
        .doc(FB.uid)
        .update({'heightCm': heightCm});
  }

  Future<void> updateGoal(String goalType, double targetWeight) async {
    await FB.db.collection('users').doc(FB.uid).update({
      'goalType':     goalType,
      'targetWeight': targetWeight,
    });
  }

  // ── Bioimpedância ─────────────────────────────────────────────────

  Future<void> saveBioimpedance({
    double? bodyFatPct,
    double? muscleMassKg,
    int? visceralFat,
    double? hydrationPct,
    double? boneMassKg,
    int? bmrKcal,
  }) async {
    final uid   = FB.uid;
    final today = FB.today;

    final existing = await FB.db
        .collection('bioimpedance_logs')
        .where('userId', isEqualTo: uid)
        .where('measuredAt', isEqualTo: today)
        .limit(1)
        .get();

    final data = {
      'userId':     uid,
      'measuredAt': today,
      if (bodyFatPct   != null) 'bodyFatPct':   bodyFatPct,
      if (muscleMassKg != null) 'muscleMassKg': muscleMassKg,
      if (visceralFat  != null) 'visceralFat':  visceralFat,
      if (hydrationPct != null) 'hydrationPct': hydrationPct,
      if (boneMassKg   != null) 'boneMassKg':   boneMassKg,
      if (bmrKcal      != null) 'bmrKcal':      bmrKcal,
    };

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update(data);
    } else {
      await FB.db.collection('bioimpedance_logs').add(data);
    }
  }

  // ── Upload de avatar ─────────────────────────────────────────────

  Future<String> uploadAvatar(Uint8List bytes, String ext) async {
    final uid  = FB.uid;
    final mimeMap = {
      'jpg':  'image/jpeg',
      'jpeg': 'image/jpeg',
      'png':  'image/png',
      'webp': 'image/webp',
      'heic': 'image/heic',
    };
    final mime = mimeMap[ext.toLowerCase()] ?? 'image/jpeg';
    final ref  = FB.storage.ref('avatars/$uid/avatar.$ext');
    final meta = SettableMetadata(contentType: mime);
    await ref.putData(bytes, meta);
    final url = await ref.getDownloadURL();
    await FB.db.collection('users').doc(uid).update({'avatarUrl': url});
    return url;
  }
}
