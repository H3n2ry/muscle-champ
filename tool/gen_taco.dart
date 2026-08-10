// Gera lib/core/groq/taco_table.dart a partir do JSON da TACO.
//
// Fonte: Tabela Brasileira de Composição de Alimentos (TACO), 4ª edição,
// NEPA/UNICAMP — https://nepa.unicamp.br/publicacoes/tabela-taco-pdf/
// JSON: https://github.com/marcelosanto/tabela_taco
//
// Uso: dart run tool/gen_taco.dart caminho/para/TACO.json
import 'dart:convert';
import 'dart:io';

double? _num(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) {
    // TACO usa "NA" (não analisado), "Tr" (traços) e "" para ausente
    if (v == 'Tr') return 0.0;
    return double.tryParse(v.replaceAll(',', '.'));
  }
  return null;
}

String _slug(String s) {
  const de = 'àáâãäåçèéêëìíîïñòóôõöùúûüý';
  const para = 'aaaaaaceeeeiiiinooooouuuuy';
  var r = s.toLowerCase().trim();
  for (var i = 0; i < de.length; i++) {
    r = r.replaceAll(de[i], para[i]);
  }
  return r
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

void main(List<String> args) {
  final path = args.isNotEmpty ? args[0] : 'TACO.json';
  final raw = jsonDecode(File(path).readAsStringSync()) as List;

  final linhas = <String>[];
  final vistos = <String>{};
  var pulados = 0;

  for (final e in raw) {
    final m = e as Map<String, dynamic>;
    final kcal = _num(m['energy_kcal']);
    final p = _num(m['protein_g']);
    final c = _num(m['carbohydrate_g']);
    final g = _num(m['lipid_g']);
    if (kcal == null || p == null || c == null || g == null) {
      pulados++;
      continue;
    }
    final nome = _slug(m['description'] as String);
    if (nome.isEmpty || !vistos.add(nome)) {
      pulados++;
      continue;
    }
    String r1(double v) => (v * 10).round() / 10 == ((v * 10).round() / 10).roundToDouble()
        ? ((v * 10).round() / 10).toStringAsFixed(1)
        : ((v * 10).round() / 10).toString();
    linhas.add("  '$nome': (${kcal.round()}, ${r1(p)}, ${r1(c)}, ${r1(g)}),");
  }

  linhas.sort();

  final buf = StringBuffer()
    ..writeln('// GERADO AUTOMATICAMENTE — não editar à mão.')
    ..writeln('// Regenerar: dart run tool/gen_taco.dart TACO.json')
    ..writeln('//')
    ..writeln('// Fonte: Tabela Brasileira de Composição de Alimentos (TACO),')
    ..writeln('// 4ª edição revisada e ampliada — NEPA/UNICAMP, 2011.')
    ..writeln('// https://nepa.unicamp.br/publicacoes/tabela-taco-pdf/')
    ..writeln('//')
    ..writeln('// Valores por 100g do alimento: (kcal, proteína, carboidrato, gordura).')
    ..writeln('library;')
    ..writeln()
    ..writeln('const Map<String, (double, double, double, double)> kTacoTable = {');
  for (final l in linhas) {
    buf.writeln(l);
  }
  buf.writeln('};');

  File('lib/core/groq/taco_table.dart').writeAsStringSync(buf.toString());
  stdout.writeln('OK: ${linhas.length} alimentos gerados ($pulados pulados)');
}
