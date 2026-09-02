import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Coloca a impressão digital do conteúdo na URL da fonte de ícones.
///
/// ## Por que isto existe
///
/// `assets/fonts/MaterialIcons-Regular.otf` tem **caminho fixo e conteúdo
/// variável**: o Flutter recorta a fonte para conter só os glifos que o app
/// usa, então adicionar um ícone muda o arquivo e não muda a URL.
///
/// Para o navegador, mesma URL significa mesmo arquivo. Quem já visitou o site
/// guarda a fonte antiga e **nunca mais pergunta** — o ícone novo simplesmente
/// não aparece, sem erro no console e sem falha de layout. Nem deploy, nem
/// purge de CDN, nem `flutter clean` alcançam isso: o pedido não chega a sair
/// do navegador.
///
/// Custou uma tarde inteira de investigação em 02/09/2026, e o que despistou
/// foi que todo teste em URL de preview passava — hostname diferente, cache
/// vazio.
///
/// A correção é a de sempre para asset de caminho fixo: versionar a URL. O
/// `FontManifest.json` é o único lugar que aponta para a fonte, então trocar o
/// caminho ali basta — o navegador passa a pedir uma URL que nunca viu.
///
/// ## Por que isto e o `_headers` ao mesmo tempo
///
/// `web/_headers` já manda `/assets/*` revalidar, o que sozinho resolveria.
/// Só que esse arquivo **não é a última palavra** no domínio próprio: o
/// "Browser Cache TTL" da zona Cloudflare reescreve o Cache-Control na saída, e
/// já apagou o `no-cache` uma vez (virou `max-age=14400`). É uma configuração
/// de painel, fora do repositório, que ninguém revisa em PR.
///
/// A URL versionada não depende de cabeçalho nenhum: cache vazio para uma URL
/// inédita é uma propriedade do navegador, não uma política que alguém possa
/// desligar sem querer.
///
/// ## Uso
///
/// Rodar DEPOIS de `flutter build web`, antes do deploy:
///
///   dart run tool/versionar_fonte_de_icones.dart
///
/// Idempotente: rodar duas vezes no mesmo build dá o mesmo resultado.
void main() {
  final manifesto = File('build/web/assets/FontManifest.json');
  if (!manifesto.existsSync()) {
    stderr.writeln('FontManifest.json não encontrado — rode o build antes.');
    exit(1);
  }

  final lista = jsonDecode(manifesto.readAsStringSync()) as List;
  var mudou = false;

  for (final familia in lista.cast<Map<String, dynamic>>()) {
    for (final fonte in (familia['fonts'] as List).cast<Map<String, dynamic>>()) {
      final caminho = (fonte['asset'] as String).split('?').first;
      final arquivo = File('build/web/assets/$caminho');
      if (!arquivo.existsSync()) continue;

      final hash =
          sha256.convert(arquivo.readAsBytesSync()).toString().substring(0, 8);
      final novo = '$caminho?v=$hash';
      if (fonte['asset'] != novo) {
        fonte['asset'] = novo;
        mudou = true;
      }
      stdout.writeln('  $caminho → v=$hash');
    }
  }

  if (mudou) {
    manifesto.writeAsStringSync(jsonEncode(lista));
    stdout.writeln('FontManifest.json atualizado.');
  } else {
    stdout.writeln('Nada a fazer — já versionado.');
  }
}
