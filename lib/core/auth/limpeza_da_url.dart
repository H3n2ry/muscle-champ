/// A parte pura da limpeza da URL de OAuth, separada do navegador para poder
/// ser testada. Ver `url_de_oauth.dart` para o porquê de tudo isto existir.
library;

/// Parâmetros que o retorno do OAuth deixa na query e que não servem mais
/// depois da troca por sessão.
///
/// `code` é o que causa o estrago: é ele que faz o `supabase_flutter` tentar
/// uma segunda troca a cada carregamento. Os outros chegam junto quando o
/// provedor devolve erro, e ficariam na URL pelo mesmo motivo.
const parametrosDeOAuth = {
  'code',
  'state',
  'error',
  'error_code',
  'error_description',
};

/// Devolve a URL sem os parâmetros de OAuth, ou `null` quando não há nada a
/// fazer — assim quem chama não mexe no histórico à toa.
///
/// ⚠️ O fragmento volta INTACTO. O app usa hash routing, então `#/dashboard` é
/// a rota atual: apagá-lo jogaria a pessoa para fora da tela em que ela está.
String? urlSemParametrosDeOAuth(String href) {
  final atual = Uri.parse(href);

  final restante = Map<String, String>.from(atual.queryParameters)
    ..removeWhere((chave, _) => parametrosDeOAuth.contains(chave));
  if (restante.length == atual.queryParameters.length) return null;

  final nova = StringBuffer('${atual.origin}${atual.path}');
  if (restante.isNotEmpty) {
    nova.write('?');
    nova.write(restante.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&'));
  }
  if (atual.fragment.isNotEmpty) nova.write('#${atual.fragment}');
  return nova.toString();
}
