/// Tira da URL os parâmetros que o provedor de OAuth deixou para trás.
///
/// ## O problema
///
/// Depois do login com Google a pessoa volta para `musclechamp.com.br/?code=…`.
/// O `supabase_flutter` troca esse código por sessão e **não mexe na URL** —
/// verificado na 2.12.4: não existe um `replaceState` na biblioteca inteira.
///
/// Só que ele reprocessa a URL a **cada carregamento**: `_startDeeplinkObserver`
/// chama `getInitialLink()`, vê que ainda há `?code=`, e tenta trocar de novo.
/// Na segunda vez o verificador PKCE já foi consumido e apagado do
/// `localStorage`, então vem:
///
///     Uncaught Error: Code verifier could not be found in local storage.
///
/// A pessoa continua logada — a sessão da primeira troca está guardada — mas
/// todo F5 naquela URL repete o erro, e o código fica no histórico do navegador
/// e em qualquer link que ela copie dali.
///
/// ## A limpeza
///
/// Roda **depois** do `Supabase.initialize`, que já espera a troca acontecer
/// (`_startDeeplinkObserver` faz `await _handleInitialUri()`). Antes disso não
/// haveria o que trocar.
///
/// ⚠️ Mexe só na QUERY STRING, nunca no fragmento. O app usa hash routing, então
/// o `#/dashboard` É a rota atual — apagá-lo jogaria a pessoa para fora da tela
/// em que ela está. Dá para mexer só na query porque o fluxo é PKCE, que devolve
/// o código na query; o fluxo implícito, que usaria o fragmento, não está em uso.
library;

export 'url_de_oauth_nao_web.dart'
    if (dart.library.js_interop) 'url_de_oauth_web.dart';
