/// Estado de assinatura, lido do servidor.
///
/// Assinatura é estado da CONTA, não do aparelho: quem assina no celular é
/// Pro no navegador e vice-versa.
///
/// O cliente só LÊ a tabela. Quem grava é o servidor: `gravar_assinatura`,
/// chamada pelas Edge Functions do Google Play e do Asaas depois de conferir o
/// pagamento (migração `20261028_assinatura_so_pelo_servidor`). A exceção que
/// ainda existe é `assinar_demo`, que sai quando os dois canais estiverem no ar.
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

  /// Por onde a pessoa paga: 'demo', 'play' (Google Play) ou 'asaas' (site).
  final String origem;

  /// 'trial', 'ativa', 'em_atraso', 'cancelada' ou 'expirada'.
  final String status;

  /// false depois de cancelar: o acesso segue até [expiraEm], sem cobrança.
  final bool renova;

  const Assinatura({
    required this.planoId,
    required this.expiraEm,
    required this.emTrial,
    required this.proximaCobranca,
    this.origem = 'demo',
    this.status = 'ativa',
    this.renova = true,
  });

  /// Paga pelo Google Play: cancelar e trocar de plano são lá, não aqui.
  bool get peloGooglePlay => origem == 'play';

  /// Paga pelo site, via Asaas.
  bool get peloSite => origem == 'asaas';

  bool get ativa => expiraEm.isAfter(DateTime.now());

  int get diasRestantes => expiraEm.difference(DateTime.now()).inDays;

  factory Assinatura.doBanco(Map<String, dynamic> r) => Assinatura(
        planoId: r['plano_id'] as String,
        expiraEm: DateTime.parse(r['expira_em'] as String).toLocal(),
        emTrial: r['em_trial'] as bool? ?? false,
        proximaCobranca: (r['proxima_cobranca'] as num?)?.toInt() ?? 0,
        origem: r['origem'] as String? ?? 'demo',
        status: r['status'] as String? ?? 'ativa',
        renova: r['renova'] as bool? ?? true,
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

  /// Cancela a assinatura de DEMONSTRAÇÃO.
  ///
  /// Assinatura paga não se cancela aqui: apagar a linha não para a cobrança
  /// no Google nem no Asaas. O servidor recusa com `cancelar_pelo_canal`.
  Future<void> cancelar() async {
    await _client.rpc('cancelar_assinatura');
  }

  /// A avaliação gratuita vale uma vez por conta, somando app e site. O
  /// servidor é quem sabe; na dúvida (erro de rede) a tela mostra o trial e o
  /// canal de pagamento recusa se não couber.
  Future<bool> jaUsouTrial() async {
    try {
      return (await _client.rpc('ja_usei_trial')) as bool? ?? false;
    } catch (_) {
      return false;
    }
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
