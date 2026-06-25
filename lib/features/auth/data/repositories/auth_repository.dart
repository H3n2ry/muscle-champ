import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../../../../core/firebase/firebase_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

/// Lançado quando o cadastro foi criado mas o email ainda não foi confirmado.
class EmailConfirmationPendingException implements Exception {
  final String email;
  const EmailConfirmationPendingException(this.email);
}

class AuthRepository {
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final cred = await FB.auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchProfile(cred.user!.uid);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String goalType,
    required double heightCm,
    required double currentWeight,
    required double targetWeight,
    required int weeklyWorkoutGoal,
  }) async {
    final cred = await FB.auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    // Calcular meta calórica (Mifflin-St Jeor simplificado)
    final bmr  = 10 * currentWeight + 6.25 * heightCm - 500;
    final tdee = bmr * 1.55;
    int calories;
    if (goalType == 'lose_weight') {
      calories = (tdee - 500).clamp(1200, 9999).toInt();
    } else if (goalType == 'gain_weight') {
      calories = (tdee + 300).clamp(1200, 9999).toInt();
    } else {
      calories = tdee.clamp(1200, 9999).toInt();
    }

    await FB.db.collection('users').doc(uid).set({
      'name':              name,
      'nameLower':         name.toLowerCase(),
      'email':             email,
      'avatarUrl':         null,
      'createdAt':         FieldValue.serverTimestamp(),
      'goalType':          goalType,
      'heightCm':          heightCm,
      'currentWeight':     currentWeight,
      'targetWeight':      targetWeight,
      'dailyCalories':     calories,
      'weeklyWorkoutGoal': weeklyWorkoutGoal,
      'totalPoints':       0,
    });

    return _fetchProfile(uid);
  }

  /// Verifica se o e-mail já está cadastrado no Firebase Auth.
  Future<bool> checkEmailExists(String email) async {
    // ignore: deprecated_member_use
    final methods = await FB.auth.fetchSignInMethodsForEmail(email);
    return methods.isNotEmpty;
  }

  Future<UserModel?> getCurrentUser() async {
    final user = FB.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.uid);
  }

  Future<void> logout() => FB.auth.signOut();

  /// Firebase não usa OTP de 6 dígitos por padrão — método mantido por
  /// compatibilidade com a tela confirm_email_page.
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    // No-op: Firebase não requer confirmação de email por padrão.
  }

  /// Reenvia o email de verificação para o usuário atual.
  Future<void> resendConfirmation(String email) async {
    await FB.auth.currentUser?.sendEmailVerification();
  }

  Future<UserModel> _fetchProfile(String uid) async {
    final doc = await FB.db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('Perfil não encontrado');
    final data = doc.data()!;

    return UserModel(
      id:          uid,
      name:        data['name'] as String? ?? '',
      email:       FB.auth.currentUser?.email ?? '',
      avatarUrl:   data['avatarUrl'] as String?,
      totalPoints: data['totalPoints'] as int? ?? 0,
      goalType:    data['goalType'] as String?,
      createdAt:   (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
