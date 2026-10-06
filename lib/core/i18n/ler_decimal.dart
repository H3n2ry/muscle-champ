/// Lê um número digitado por gente: aceita vírgula ou ponto como separador
/// decimal. Devolve `null` para o que não for número, inclusive texto vazio —
/// quem chama decide o que isso significa, em vez de virar 0 sem ninguém ver.
///
/// `double.tryParse` sozinho não aceita vírgula, e o teclado numérico em pt-BR
/// e espanhol costuma oferecer justamente a vírgula. Até 06/10/2026, "22,5" na
/// carga do treino virava `null`, o `?? 0` de quem chamava completava, e o
/// CONCLUIR TREINO gravava 0 kg — com a tela ainda mostrando "22,5".
double? lerDecimal(String? texto) {
  final t = (texto ?? '').trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final n = double.tryParse(t);
  // tryParse aceita "NaN" e "Infinity"; nenhum dos dois é peso.
  if (n == null || !n.isFinite) return null;
  return n;
}
