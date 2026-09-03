import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_camp/core/auth/limpeza_da_url.dart';

/// Depois do login com Google a pessoa volta para `musclechamp.com.br/?code=…`
/// e o `supabase_flutter` não limpa isso. Como ele reprocessa a URL a cada
/// carregamento, o F5 seguinte tenta trocar um código já consumido e derruba
/// "Code verifier could not be found in local storage" no console.
void main() {
  const site = 'https://musclechamp.com.br';

  group('urlSemParametrosDeOAuth', () {
    test('tira o code que faz a segunda troca ser tentada', () {
      expect(
        urlSemParametrosDeOAuth('$site/?code=1f36fc9f-8e8a-4925-96c4-abc'),
        '$site/',
      );
    });

    test('devolve null quando não há nada de OAuth — não mexe no histórico', () {
      expect(urlSemParametrosDeOAuth('$site/'), isNull);
      expect(urlSemParametrosDeOAuth('$site/#/dashboard'), isNull);
      expect(urlSemParametrosDeOAuth('$site/?utm_source=insta'), isNull);
    });

    test('⚠️ preserva o fragmento — ele é a rota, não enfeite', () {
      // O app usa hash routing. Levar o `#/diet` junto com o `?code=` jogaria a
      // pessoa para fora da tela em que ela está.
      expect(
        urlSemParametrosDeOAuth('$site/?code=abc#/diet'),
        '$site/#/diet',
      );
      expect(
        urlSemParametrosDeOAuth('$site/?code=abc#/atleta/42'),
        '$site/#/atleta/42',
      );
    });

    test('preserva parâmetros que não são de OAuth', () {
      expect(
        urlSemParametrosDeOAuth('$site/?utm_source=insta&code=abc'),
        '$site/?utm_source=insta',
      );
    });

    test('leva junto os parâmetros de erro do provedor', () {
      // Google recusado: vem `error` em vez de `code`, e ficaria na URL pelo
      // mesmo motivo.
      expect(
        urlSemParametrosDeOAuth(
            '$site/?error=access_denied&error_description=User+denied'),
        '$site/',
      );
      expect(urlSemParametrosDeOAuth('$site/?state=xyz'), '$site/');
    });

    test('não inventa mudança quando roda duas vezes', () {
      final uma = urlSemParametrosDeOAuth('$site/?code=abc#/dashboard')!;
      expect(urlSemParametrosDeOAuth(uma), isNull);
    });
  });
}
