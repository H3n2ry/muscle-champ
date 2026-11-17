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

class ResultadoAssinaturaSite {
  /// Começou a avaliação gratuita: o Pro já vale, sem pagar agora.
  final bool emTrial;

  /// Sem avaliação: página do Asaas onde a pessoa paga. O Pro só chega quando
  /// o webhook confirmar o pagamento.
  final String? linkPagamento;

  const ResultadoAssinaturaSite({required this.emTrial, this.linkPagamento});
}

/// Recusa do servidor, com o código que ele devolveu: `cpf_invalido`,
/// `assinatura_ativa_em_outro_canal`, `asaas_recusou`...
class ErroAssinatura implements Exception {
  final String codigo;
  const ErroAssinatura(this.codigo);

  @override
  String toString() => 'ErroAssinatura($codigo)';
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

  /// Assina pelo site, via Asaas (Edge Function `asaas-assinar`).
  ///
  /// O preço não vai daqui: o servidor lê o plano pelo id. O cartão também
  /// não passa por nós; ele é digitado na página do Asaas ([linkPagamento]).
  Future<ResultadoAssinaturaSite> assinarPeloSite({
    required Plano plano,
    required String nome,
    required String cpf,
    required bool cartao,
  }) async {
    try {
      final r = await _client.functions.invoke('asaas-assinar', body: {
        'plano': plano.id,
        'nome': nome,
        'cpf': cpf,
        'forma': cartao ? 'cartao' : 'pix',
      });
      final d = Map<String, dynamic>.from(r.data as Map);
      return ResultadoAssinaturaSite(
        emTrial: d['status'] == 'trial',
        linkPagamento: d['linkPagamento'] as String?,
      );
    } on FunctionException catch (e) {
      final d = e.details;
      final erro = d is Map ? d['erro'] as String? : null;
      throw ErroAssinatura(erro ?? 'interno');
    }
  }

  /// Cancela a assinatura do site no Asaas. O acesso segue até o fim do
  /// período já pago.
  Future<void> cancelarPeloSite() async {
    try {
      await _client.functions.invoke('asaas-cancelar');
    } on FunctionException catch (e) {
      final d = e.details;
      final erro = d is Map ? d['erro'] as String? : null;
      throw ErroAssinatura(erro ?? 'interno');
    }
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

/// Dígitos verificadores do CPF. O servidor confere de novo; isto só evita a
/// ida e volta por um número digitado errado.
bool cpfValido(String valor) {
  final cpf = valor.replaceAll(RegExp(r'\D'), '');
  if (cpf.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
  int dv(String base, int pesoInicial) {
    var soma = 0;
    for (var i = 0; i < base.length; i++) {
      soma += int.parse(base[i]) * (pesoInicial - i);
    }
    final resto = (soma * 10) % 11;
    return resto == 10 ? 0 : resto;
  }

  return dv(cpf.substring(0, 9), 10) == int.parse(cpf[9]) &&
      dv(cpf.substring(0, 10), 11) == int.parse(cpf[10]);
}
