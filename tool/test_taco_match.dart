// Valida o casamento conservador contra a tabela TACO real.
// Uso: dart run tool/test_taco_match.dart
import '../lib/core/groq/taco_table.dart';

String slug(String s) {
  const de = 'àáâãäåçèéêëìíîïñòóôõöùúûüý';
  const para = 'aaaaaaceeeeiiiinooooouuuuy';
  var r = s.toLowerCase().trim();
  for (var i = 0; i < de.length; i++) {
    r = r.replaceAll(de[i], para[i]);
  }
  return r.replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<String> toks(String s) =>
    slug(s).split(' ').where((t) => t.length > 2).toList();

String raiz(String t) => t.length <= 4 ? t : t.substring(0, t.length - 1);
bool casaToken(String a, String b) =>
    a == b || (a.length > 4 && b.length > 4 && raiz(a) == raiz(b));

const preparo = {
  'cru', 'crua', 'crus', 'cruas', 'cozido', 'cozida', 'cozidos', 'cozidas',
  'grelhado', 'grelhada', 'assado', 'assada', 'refogado', 'refogada',
  'frito', 'frita', 'fritas', 'torrado', 'torrada', 'tostado', 'tostada',
  'seco', 'seca', 'fresco', 'fresca', 'natural', 'defumado', 'defumada',
  'sem', 'com', 'pele', 'osso', 'casca', 'sal', 'agua', 'file', 'files',
  'seco3', 'maduro', 'madura', 'seleta', 'inteiro', 'inteira',
};

String? lookupChave(String name) {
  final q = toks(name);
  if (q.isEmpty) return null;
  final cabeca = q.first;
  String? melhor;
  var menosSobra = 1 << 30;
  for (final chave in kTacoTable.keys) {
    final kt = chave.split(' ').where((t) => t.length > 2).toList();
    if (kt.isEmpty || kt.first != cabeca) continue;
    if (!q.every((x) => kt.any((k) => casaToken(k, x)))) continue;
    final sobra = kt.where((k) => !q.any((x) => casaToken(k, x))).toList();
    if (sobra.any((s) => !preparo.contains(s))) continue;
    if (sobra.length < menosSobra) {
      menosSobra = sobra.length;
      melhor = chave;
    }
  }
  return melhor;
}

var ok = 0, falhou = 0;
void t(String consulta, String? esperado) {
  final c = lookupChave(consulta);
  final v = c == null ? null : kTacoTable[c];
  final bom = esperado == null ? c == null : (c != null && c.contains(esperado));
  bom ? ok++ : falhou++;
  final kcal = v == null ? '' : ' ${v.$1.round()}kcal';
  print('${bom ? "PASS" : "FALHA"} | "$consulta" -> ${c ?? "(nada -> usa categoria)"}$kcal');
}

void main() {
  print('total na TACO: ${kTacoTable.length}\n');

  print('--- deve achar o alimento certo ---');
  t('abacaxi', 'abacaxi cru');
  t('quiabo', 'quiabo');
  t('chuchu', 'chuchu');
  t('inhame', 'inhame');
  t('jabuticaba', 'jabuticaba');
  t('pequi', 'pequi');
  t('goiaba', 'goiaba');
  t('mandioca cozida', 'mandioca');
  t('couve refogada', 'couve');
  t('arroz integral cozido', 'arroz integral cozido');
  t('batata doce cozida', 'batata doce cozida');
  t('feijao preto cozido', 'feijao preto cozido');

  print('\n--- casamentos errados que passavam antes ---');
  t('carambola', 'carambola');
  t('castanha do para', 'castanha do para');

  print('\n--- deve recusar (cai na categoria, que e calibrada) ---');
  t('xyzabc', null);
  t('sushi', null);
  t('pizza de calabresa', null);

  print('\n=== $ok passaram, $falhou falharam ===');
}
