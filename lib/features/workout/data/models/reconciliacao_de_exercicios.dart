/// Decide o que fazer com cada exercício ao salvar a edição de um template.
///
/// ## Por que isto existe
///
/// `updateExercises` apagava TODOS os exercícios do template e inseria de novo.
/// Como cada linha nova nasce com um UUID novo, qualquer edição — reordenar,
/// corrigir um nome, ajustar uma carga — destruía a identidade das linhas. E
/// junto iam:
///
///   * a `anotacao`, que mora na própria linha;
///   * todo o `historico_de_exercicios`, que aponta para ela com
///     `ON DELETE CASCADE`.
///
/// Em silêncio: a tela salvava, dizia que deu certo, e o gráfico do exercício
/// voltava a zero. Foi assim que o histórico de 11/09 e 15/09/2026 sumiu —
/// confirmado pelos pontos de `load_progression` daqueles dias, que só existem
/// se o histórico tinha acabado de ser gravado.
///
/// Reconciliar em vez de recriar preserva a linha de quem continua no template.
class ReconciliacaoDeExercicios {
  /// Já existiam e continuam: `UPDATE`, que não encosta em `anotacao`.
  final List<Map<String, dynamic>> paraAtualizar;

  /// Entraram agora: `INSERT`.
  final List<Map<String, dynamic>> paraInserir;

  /// Saíram do template: `DELETE`.
  ///
  /// Aqui o cascade é o comportamento CERTO — quem tirou o exercício da ficha
  /// não quer o histórico dele pendurado.
  final List<String> idsParaApagar;

  const ReconciliacaoDeExercicios({
    required this.paraAtualizar,
    required this.paraInserir,
    required this.idsParaApagar,
  });

  /// [idsExistentes] são os ids hoje no banco; [enviados] é a lista da tela, na
  /// ordem final, cada item com `id` (nulo para linha nova), `name`, `sets`,
  /// `reps` e `weight_kg`.
  factory ReconciliacaoDeExercicios.calcular({
    required Set<String> idsExistentes,
    required List<Map<String, dynamic>> enviados,
  }) {
    final atualizar = <Map<String, dynamic>>[];
    final inserir = <Map<String, dynamic>>[];
    final mantidos = <String>{};

    for (var i = 0; i < enviados.length; i++) {
      final e = enviados[i];
      final id = e['id'] as String?;

      // `order_index` vem da posição na lista: a ordem da tela é a ordem final.
      final campos = <String, dynamic>{
        'name': e['name'],
        'sets': e['sets'],
        'reps': e['reps'],
        'weight_kg': e['weight_kg'],
        'order_index': i,
      };

      // Um id que a tela mandou mas que não está mais no banco vira INSERT, não
      // UPDATE de linha inexistente: alguém pode ter apagado o template em
      // outro aparelho enquanto esta tela estava aberta.
      if (id != null && idsExistentes.contains(id)) {
        mantidos.add(id);
        atualizar.add({'id': id, ...campos});
      } else {
        inserir.add(campos);
      }
    }

    return ReconciliacaoDeExercicios(
      paraAtualizar: atualizar,
      paraInserir: inserir,
      idsParaApagar: idsExistentes.difference(mantidos).toList(),
    );
  }
}
