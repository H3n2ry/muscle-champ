/// Estado de assinatura — POR ENQUANTO FALSO, mas agora no servidor.
///
/// Já morou em SharedPreferences e isso estava errado por um motivo simples:
/// assinatura é estado da CONTA, não do aparelho. Quem assinava no celular e
/// abria no PC voltava a ser plano gratuito.
///
/// ⚠️ Continua sem cobrar nada. E hoje o próprio cliente escreve a linha
/// (política "DEMO" na migração `20260825_assinatura_e_cota_no_servidor`), o
/// que significa que alguém com o token pode se declarar Pro. Aceitável
/// enquanto nada é cobrado. Quando o billing for real: apagar as políticas de
/// insert/update/delete e deixar só a de select — quem escreve passa a ser o
/// webhook do gateway, com a service role.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Quanto será cobrado na próxima renovação, em centavos.
  final Centavos proximaCobranca;

  const Assinatura({
    required this.planoId,
    required this.expiraEm,
    required this.emTrial,
    required this.proximaCobranca,
  });

  bool get ativa => expiraEm.isAfter(DateTime.now());

  int get diasRestantes => expiraEm.difference(DateTime.now()).inDays;

  factory Assinatura.doBanco(Map<String, dynamic> r) => Assinatura(
        planoId: r['plano_id'] as String,
        expiraEm: DateTime.parse(r['expira_em'] as String).toLocal(),
        emTrial: r['em_trial'] as bool? ?? false,
        proximaCobranca: (r['proxima_cobranca'] as num?)?.toInt() ?? 0,
      );
}

class AssinaturaRepository {
  final _client = Supabase.instance.client;

  Future<Assinatura?> carregar() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client
        .from('assinaturas')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return Assinatura.doBanco(row);
  }

  /// Simula a compra. O trial adia a primeira cobrança em
  /// [Planos.diasDeTrial] dias — é a data que a tela mostra.
  Future<Assinatura> assinar(Plano plano, {bool comTrial = true}) async {
    final uid = _client.auth.currentUser!.id;
    final agora = DateTime.now();
    final expira = comTrial
        ? agora.add(const Duration(days: Planos.diasDeTrial))
        : DateTime(agora.year, agora.month + plano.periodo.meses, agora.day);

    // upsert: assinar de novo por cima de uma assinatura existente é troca de
    // plano, não erro de chave duplicada.
    final row = await _client
        .from('assinaturas')
        .upsert({
          'user_id': uid,
          'plano_id': plano.id,
          'expira_em': expira.toUtc().toIso8601String(),
          'em_trial': comTrial,
          'proxima_cobranca': comTrial ? plano.entrada : plano.renovacao,
          'atualizado_em': agora.toUtc().toIso8601String(),
        })
        .select()
        .single();

    return Assinatura.doBanco(row);
  }

  Future<void> cancelar() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from('assinaturas').delete().eq('user_id', uid);
  }
}
