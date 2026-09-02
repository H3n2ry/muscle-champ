import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../legal/legal_texts.dart';

/// O que falta para uma conta poder usar o app.
///
/// Existe por causa do login social. O cadastro por e-mail coleta data de
/// nascimento e consentimentos em três passos, e o trigger `handle_new_user`
/// grava tudo a partir dos metadados do `signUp()`. Um login pelo Google não
/// manda nada disso: o trigger cai nos `COALESCE` e cria a conta com
///
///   • `birth_date` NULL          — a barreira de 16 anos nunca roda
///   • consentimentos `false`     — inclusive os obrigatórios
///   • `document_version` 'unknown'
///   • altura 170 e peso 70/70    — inventados
///
/// A idade é o item grave: `LegalTexts.minimumAge` é aplicada em
/// `register_page._goNext()` e revalidada em `AuthRepository.register()`, e
/// nenhum dos dois está no caminho do OAuth. Sem esta checagem, um menor de 16
/// entraria pelo Google e o app trataria dados de saúde dele sem base legal.
///
/// A mesma checagem resolve o reconsentimento por versão: quando
/// `LegalTexts.documentVersion` sobe, os consentimentos antigos ficam obsoletos
/// e a tela de privacidade apenas os *marca*, sem pedir nada. Aqui eles voltam
/// a ser exigidos de fato.
class CompletudeDoPerfil {
  /// `goals.birth_date` está nulo — nunca houve verificação de idade.
  final bool faltaDataDeNascimento;

  /// Algum consentimento obrigatório está ausente, recusado ou preso numa
  /// versão anterior dos documentos.
  final bool faltaConsentimento;

  const CompletudeDoPerfil({
    required this.faltaDataDeNascimento,
    required this.faltaConsentimento,
  });

  bool get completo => !faltaDataDeNascimento && !faltaConsentimento;

  /// Conta recém-criada por OAuth: não tem nada ainda.
  static const CompletudeDoPerfil vazio = CompletudeDoPerfil(
    faltaDataDeNascimento: true,
    faltaConsentimento: true,
  );
}

/// Espelho síncrono do resultado, para o `redirect` do GoRouter.
///
/// O `redirect` **não pode aguardar** — é síncrono por assinatura — e a
/// completude vem de uma consulta ao banco. Sem este espelho, a única saída
/// seria navegar de dentro do `build` de um widget, que foi a primeira
/// tentativa aqui e entrou em laço: cada rebuild agendava outra navegação.
///
/// `null` significa "ainda não sei" — nesse estado o redirect não decide nada e
/// deixa o app seguir. Quem preenche é o [completudeDoPerfilProvider].
class PerfilIncompleto {
  PerfilIncompleto._();

  static bool? valor;

  /// Chamar no logout: sem isso, a próxima conta herdaria a resposta da
  /// anterior até a primeira consulta terminar.
  static void limpar() => valor = null;
}

/// Lê do banco o que falta na conta logada.
///
/// `autoDispose` porque é estado de conta: cacheado na raiz sobreviveria a um
/// logout e responderia sobre o usuário anterior.
final completudeDoPerfilProvider =
    FutureProvider.autoDispose<CompletudeDoPerfil>((ref) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return CompletudeDoPerfil.vazio;

  final resultados = await Future.wait<dynamic>([
    client.from('goals').select('birth_date').eq('user_id', uid).maybeSingle(),
    client
        .from('user_consents')
        .select('consent_type, granted, document_version, granted_at')
        .eq('user_id', uid)
        // `ascending: true` EXPLÍCITO. O padrão do postgrest-dart é
        // DECRESCENTE, e omitir isto quebrou o gate de um jeito difícil de ver:
        // a redução abaixo guarda a última linha de cada tipo, que em ordem
        // decrescente é a mais ANTIGA — a linha `granted: false` que o trigger
        // cria no cadastro OAuth. Resultado: perfil completo lido como
        // incompleto, e a pessoa presa num anel entre o app e esta tela.
        .order('granted_at', ascending: true),
  ]);

  final goals = resultados[0] as Map<String, dynamic>?;
  final linhas = (resultados[1] as List).cast<Map<String, dynamic>>();

  // `user_consents` é append-only: revogar grava linha nova em vez de apagar.
  // Então o que vale é a ÚLTIMA linha de cada finalidade, e a consulta vem
  // ordenada por data justamente para esta redução.
  final vigente = <String, Map<String, dynamic>>{};
  for (final linha in linhas) {
    vigente[linha['consent_type'] as String] = linha;
  }

  final obrigatorios =
      LegalTexts.signupConsents.where((c) => c.required).map((c) => c.type);

  final faltaConsentimento = obrigatorios.any((tipo) {
    final linha = vigente[tipo];
    if (linha == null) return true;
    if (linha['granted'] != true) return true;
    // Versão antiga conta como faltando: o texto mudou desde o aceite.
    return linha['document_version'] != LegalTexts.documentVersion;
  });

  final resultado = CompletudeDoPerfil(
    faltaDataDeNascimento: goals?['birth_date'] == null,
    faltaConsentimento: faltaConsentimento,
  );
  PerfilIncompleto.valor = !resultado.completo;
  return resultado;
});
