/// Estado de assinatura — POR ENQUANTO FALSO.
///
/// Guarda em SharedPreferences para a tela poder ser avaliada de ponta a
/// ponta (assinar → ver "assinante" no perfil → cancelar). Nada aqui cobra,
/// valida ou conversa com gateway nenhum.
///
/// ⚠️ Substituir por Play Billing (Android) e por um gateway com webhook no
/// servidor (web) antes de qualquer cobrança real. O entitlement precisa
/// morar no Supabase e ser validado no servidor: `SharedPreferences` é do
/// aparelho e o usuário pode editar.
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/plano.dart';

final assinaturaRepositoryProvider =
    Provider<AssinaturaRepository>((_) => AssinaturaRepository());

class Assinatura {
  final String planoId;

  /// Quando a assinatura expira — ou quando o trial vira cobrança.
  final DateTime expiraEm;

  /// Ainda dentro dos [Planos.diasDeTrial] dias de avaliação.
  final bool emTrial;

  /// Quanto será cobrado na próxima renovação.
  final Centavos proximaCobranca;

  const Assinatura({
    required this.planoId,
    required this.expiraEm,
    required this.emTrial,
    required this.proximaCobranca,
  });

  bool get ativa => expiraEm.isAfter(DateTime.now());

  int get diasRestantes => expiraEm.difference(DateTime.now()).inDays;

  Map<String, dynamic> toJson() => {
        'plano_id': planoId,
        'expira_em': expiraEm.toIso8601String(),
        'em_trial': emTrial,
        'proxima_cobranca': proximaCobranca,
      };

  factory Assinatura.fromJson(Map<String, dynamic> j) => Assinatura(
        planoId: j['plano_id'] as String,
        expiraEm: DateTime.parse(j['expira_em'] as String),
        emTrial: j['em_trial'] as bool? ?? false,
        proximaCobranca: (j['proxima_cobranca'] as num?)?.toInt() ?? 0,
      );
}

class AssinaturaRepository {
  /// Escopo por usuário, como todas as chaves do app — sem isso duas contas
  /// no mesmo navegador compartilhariam a assinatura.
  String get _chave {
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
    return 'assinatura_demo_v1_$uid';
  }

  Future<Assinatura?> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final bruto = prefs.getString(_chave);
    if (bruto == null) return null;
    try {
      return Assinatura.fromJson(
          Map<String, dynamic>.from(_decode(bruto)));
    } catch (_) {
      // Formato antigo ou corrompido: some com ele em vez de derrubar a tela.
      await prefs.remove(_chave);
      return null;
    }
  }

  /// Simula a compra. O trial adia a primeira cobrança em
  /// [Planos.diasDeTrial] dias — é a data que a tela precisa mostrar.
  Future<Assinatura> assinar(Plano plano, {bool comTrial = true}) async {
    final agora = DateTime.now();
    final assinatura = Assinatura(
      planoId: plano.id,
      expiraEm: comTrial
          ? agora.add(const Duration(days: Planos.diasDeTrial))
          : DateTime(agora.year, agora.month + plano.periodo.meses, agora.day),
      emTrial: comTrial,
      proximaCobranca: comTrial ? plano.entrada : plano.renovacao,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, _encode(assinatura.toJson()));
    return assinatura;
  }

  Future<void> cancelar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }

  String _encode(Map<String, dynamic> m) => jsonEncode(m);
  Map<String, dynamic> _decode(String s) =>
      Map<String, dynamic>.from(jsonDecode(s) as Map);
}
