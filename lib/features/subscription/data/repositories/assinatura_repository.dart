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

  /// Simula a compra.
  ///
  /// Passa por RPC porque a tabela nao aceita mais escrita do cliente. O
  /// servidor e quem decide a data e o modo: sempre trial de 14 dias. Antes,
  /// com politica de INSERT aberta, dava para gravar "Pro ate 2099".
  Future<Assinatura> assinar(Plano plano, {bool comTrial = true}) async {
    final row = await _client.rpc('assinar_demo', params: {
      'p_plano_id': plano.id,
      'p_proxima_cobranca': comTrial ? plano.entrada : plano.renovacao,
    });
    return Assinatura.doBanco(Map<String, dynamic>.from(row as Map));
  }

  /// Cancelar continua sendo direito do assinante, entao a RPC e aberta a
  /// qualquer usuario — e assim continua depois do billing.
  Future<void> cancelar() async {
    await _client.rpc('cancelar_assinatura');
  }

  /// Conta de desenvolvimento? Decide se o atalho de zerar cota aparece.
  ///
  /// Sem isto o botao apareceria para todo mundo e daria erro — a RPC agora
  /// recusa quem nao esta na lista.
  Future<bool> souContaDeTeste() async {
    try {
      return (await _client.rpc('sou_conta_de_teste')) as bool? ?? false;
    } catch (_) {
      return false;
    }
  }
}
