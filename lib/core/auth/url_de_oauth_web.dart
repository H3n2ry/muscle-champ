import 'package:web/web.dart' as web;

import 'limpeza_da_url.dart';

void limparParametrosDeOAuthDaUrl() {
  final nova = urlSemParametrosDeOAuth(web.window.location.href);
  if (nova == null) return;

  // `replaceState`, não `pushState`: a URL suja não deve virar um passo de
  // histórico para onde o botão "voltar" possa devolver a pessoa.
  web.window.history.replaceState(null, '', nova);
}
