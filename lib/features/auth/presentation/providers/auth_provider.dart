import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/firebase/firebase_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

// Stream do estado de autenticação do Firebase
final authSessionProvider = StreamProvider<User?>((ref) {
  return FB.auth.authStateChanges();
});

// Usuário atual com dados do perfil
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authSessionProvider).valueOrNull;
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).getCurrentUser();
});

// Controller para login/cadastro/logout
final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(AuthController.new);

class AuthController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() {
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          ),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String goalType,
    required double heightCm,
    required double currentWeight,
    required double targetWeight,
    required int weeklyWorkoutGoal,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
            goalType: goalType,
            heightCm: heightCm,
            currentWeight: currentWeight,
            targetWeight: targetWeight,
            weeklyWorkoutGoal: weeklyWorkoutGoal,
          ),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
