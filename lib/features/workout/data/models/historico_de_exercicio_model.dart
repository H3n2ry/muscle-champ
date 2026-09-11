/// Uma sessão passada de um exercício: o que foi levantado naquele dia.
///
/// ⚠️ Este histórico **começa vazio para todo mundo**, inclusive para quem
/// treina há meses.
///
/// Até 11/09/2026 nenhum dado de sessão passada sobrevivia: o
/// `complete_workout_template` lia o peso antigo, contava a progressão para dar
/// os pontos e então sobrescrevia `template_exercises.weight_kg`. O número
/// anterior morria ali, e `workout_completions` guardava só que houve treino,
/// nunca o que foi feito. Não há como preencher para trás — o dado nunca
/// existiu. Enche a partir do primeiro treino concluído depois daquela data.
class HistoricoDeExercicio {
  final DateTime data;
  final double pesoKg;
  final int series;
  final int reps;

  /// Cópia do nome no dia em que foi feito. O exercício pode ter sido
  /// renomeado depois, e uma sessão antiga deve continuar dizendo o que era.
  final String nome;

  const HistoricoDeExercicio({
    required this.data,
    required this.pesoKg,
    required this.series,
    required this.reps,
    required this.nome,
  });

  factory HistoricoDeExercicio.fromJson(Map<String, dynamic> j) =>
      HistoricoDeExercicio(
        data:   DateTime.parse(j['data'] as String),
        pesoKg: (j['peso_kg'] as num).toDouble(),
        series: (j['series'] as num).toInt(),
        reps:   (j['reps'] as num).toInt(),
        nome:   j['nome'] as String,
      );

  /// Volume da sessão — carga × séries × reps.
  ///
  /// Peso sozinho mente: quem sobe de 20kg×5 para 22kg×3 levantou MENOS no
  /// total, e o gráfico de carga mostraria uma subida. O volume é o que
  /// responde "treinei mais forte que da última vez?", que é a pergunta que a
  /// pessoa está realmente fazendo ao abrir isto.
  double get volume => pesoKg * series * reps;
}
