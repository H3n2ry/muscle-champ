import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

/// Lançado quando o cadastro foi criado mas o email ainda não foi confirmado.
class EmailConfirmationPendingException implements Exception {
  final String email;
  const EmailConfirmationPendingException(this.email);
}

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _fetchProfile(response.user!.id);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String goalType,
    required double heightCm,
    required double currentWeight,
    required double targetWeight,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      // Todos os dados são passados no metadata → trigger cria profile+goals
      data: {
        'name':           name,
        'goal_type':      goalType,
        'height_cm':      heightCm,
        'current_weight': currentWeight,
        'target_weight':  targetWeight,
      },
    );

    // Se não há sessão, confirmação de email está habilitada
    if (response.session == null) {
      // Quando o email já está cadastrado, o Supabase retorna identities vazio
      // em vez de retornar um erro (comportamento anti-enumeração)
      if (response.user?.identities?.isEmpty ?? false) {
        throw Exception('Este e-mail já está cadastrado. Faça login na tela anterior.');
      }
      throw EmailConfirmationPendingException(email);
    }

    return _fetchProfile(response.user!.id);
  }

  /// Verifica se o e-mail já existe em auth.users via RPC com SECURITY DEFINER.
  Future<bool> checkEmailExists(String email) async {
    final result = await _client.rpc(
      'check_email_exists',
      params: {'p_email': email},
    );
    return result as bool;
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.id);
  }

  Future<void> logout() => _client.auth.signOut();

  /// Confirma o e-mail usando o código OTP de 6 dígitos enviado pelo Supabase.
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  /// Reenvia o código OTP de confirmação para o e-mail informado.
  Future<void> resendConfirmation(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  Future<UserModel> _fetchProfile(String userId) async {
    final results = await Future.wait<dynamic>([
      _client.from('profiles').select().eq('id', userId).single(),
      _client.from('goals').select('goal_type').eq('user_id', userId).maybeSingle(),
      _client.from('points').select('amount').eq('user_id', userId),
    ]);

    final profile     = results[0] as Map<String, dynamic>;
    final goal        = results[1] as Map<String, dynamic>?;
    final points      = results[2] as List;
    final totalPoints = points.fold<int>(0, (sum, p) => sum + (p['amount'] as int));

    return UserModel(
      id:          profile['id'] as String,
      name:        profile['name'] as String,
      email:       _client.auth.currentUser?.email ?? '',
      avatarUrl:   profile['avatar_url'] as String?,
      totalPoints: totalPoints,
      goalType:    goal?['goal_type'] as String?,
      createdAt:   DateTime.parse(profile['created_at'] as String),
    );
  }

}
