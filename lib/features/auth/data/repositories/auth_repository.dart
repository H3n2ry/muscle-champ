import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/legal/legal_texts.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

/// Lançado quando o cadastro foi criado mas o email ainda não foi confirmado.
class EmailConfirmationPendingException implements Exception {
  final String email;
  const EmailConfirmationPendingException(this.email);
}

/// Lançado quando o titular não atinge a idade mínima (LegalTexts.minimumAge).
class UnderageException implements Exception {
  const UnderageException();
  @override
  String toString() => LegalTexts.underageMessage;
}

/// Lançado quando a senha nova enviada na recuperação é igual à atual.
///
/// Vale uma exceção própria porque o tratamento é diferente de qualquer outra
/// falha: o código de recuperação já foi consumido, a sessão está aberta, e a
/// pessoa só precisa escolher outra senha — não pedir um código novo.
class SamePasswordException implements Exception {
  const SamePasswordException();
}

/// Lançado quando falta um consentimento obrigatório para operar o serviço.
class MissingConsentException implements Exception {
  final String consentType;
  const MissingConsentException(this.consentType);
  @override
  String toString() =>
      'É necessário aceitar todos os itens obrigatórios para criar a conta.';
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
    required int weeklyWorkoutGoal,
    required Map<String, bool> consents,
    DateTime? birthDate,
  }) async {
    // Barreira de idade — dado de saúde exige consentimento parental
    // verificável abaixo de LegalTexts.minimumAge, fluxo que o app não tem.
    if (birthDate == null || !LegalTexts.isOldEnough(birthDate)) {
      throw const UnderageException();
    }

    // Os consentimentos obrigatórios são checados na UI, mas revalidar aqui
    // impede que uma chamada direta ao repositório crie conta sem base legal.
    for (final item in LegalTexts.signupConsents.where((c) => c.required)) {
      if (consents[item.type] != true) {
        throw MissingConsentException(item.type);
      }
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name':                 name,
        'goal_type':            goalType,
        'height_cm':            heightCm,
        'current_weight':       currentWeight,
        'target_weight':        targetWeight,
        'weekly_workout_goal':  weeklyWorkoutGoal,
        'birth_date':           birthDate.toIso8601String().substring(0, 10),
        // Lidos pelo trigger handle_new_user, que grava em user_consents
        'consent_version':      LegalTexts.documentVersion,
        'consent_locale':       'pt-BR',
        'consent_terms':        consents['terms'] ?? false,
        'consent_privacy':      consents['privacy'] ?? false,
        'consent_health':       consents['health_data'] ?? false,
        'consent_ai_photo':     consents['ai_photo_transfer'] ?? false,
        'consent_marketing':    consents['marketing'] ?? false,
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

  // ── Recuperação de senha ───────────────────────────────────────────────────

  /// Dispara o e-mail de recuperação com o código OTP.
  ///
  /// Não retorna nada e não distingue e-mail existente de inexistente — de
  /// propósito. O Supabase responde igual nos dois casos para não virar um
  /// oráculo de "esta pessoa tem conta aqui", e a UI precisa manter a mesma
  /// resposta. Não usar `checkEmailExists` neste fluxo.
  ///
  /// Depende do template "Reset Password" no painel do Supabase conter
  /// `{{ .Token }}`. O template padrão manda `{{ .ConfirmationURL }}` (link), e
  /// com ele nenhum código chega ao usuário.
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Troca o código de recuperação por uma sessão autenticada.
  ///
  /// Separado de [updatePassword] porque **o código é de uso único**: assim que
  /// isto retorna, ele está queimado. Se a gravação da senha falhar depois
  /// (senha igual à anterior, rede caindo), refazer esta etapa com o mesmo
  /// código dá 403 — a tela precisa reaproveitar a sessão em vez de recomeçar.
  Future<void> verifyRecoveryCode({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  /// Grava a senha nova na sessão aberta por [verifyRecoveryCode].
  ///
  /// Lança [SamePasswordException] quando a senha nova é igual à atual — o
  /// Supabase devolve 422 nesse caso, e é o erro mais provável de todos, já que
  /// quem esqueceu a senha costuma tentar primeiro a que achava que era.
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('should be different') ||
          msg.contains('same_password')) {
        throw const SamePasswordException();
      }
      rethrow;
    }
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
