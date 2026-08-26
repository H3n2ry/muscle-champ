/// O que um competidor vê de outro.
///
/// O que NÃO está aqui é tão importante quanto o que está: peso atual, peso
/// alvo, altura, data de nascimento e meta calórica ficam de fora. Peso é dado
/// de saúde (LGPD Art. 11 / GDPR Art. 9) e o consentimento do cadastro
/// autoriza o app a tratar, não a publicar para outros usuários.
///
/// Quem garante isso é a RPC `get_perfil_publico`, que lista campo a campo o
/// que sai do banco — as tabelas continuam fechadas por RLS.
library;

class ExercicioPublico {
  final String nome;
  final int series;
  final int reps;
  final double? pesoKg;

  const ExercicioPublico({
    required this.nome,
    required this.series,
    required this.reps,
    this.pesoKg,
  });

  factory ExercicioPublico.doJson(Map<String, dynamic> j) => ExercicioPublico(
        nome: j['nome'] as String? ?? '',
        series: (j['series'] as num?)?.toInt() ?? 0,
        reps: (j['reps'] as num?)?.toInt() ?? 0,
        pesoKg: (j['peso_kg'] as num?)?.toDouble(),
      );
}

class TreinoPublico {
  /// Necessário para copiar: a RPC recebe o id do treino de origem.
  final String id;
  final String nome;
  final List<ExercicioPublico> exercicios;

  const TreinoPublico({
    required this.id,
    required this.nome,
    required this.exercicios,
  });

  factory TreinoPublico.doJson(Map<String, dynamic> j) => TreinoPublico(
        id: j['id'] as String? ?? '',
        nome: j['nome'] as String? ?? '',
        exercicios: ((j['exercicios'] as List?) ?? const [])
            .map((e) => ExercicioPublico.doJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class PerfilPublico {
  final String id;
  final String nome;
  final String? avatarUrl;
  final DateTime membroDesde;

  /// Só o tipo — 'lose_weight' / 'gain_weight' / 'maintain'. Sem os pesos.
  final String objetivo;
  final int metaSemanal;

  final int totalPontos;
  final int totalTreinos;
  final int streak;

  /// Vinculo com quem esta olhando: proprio | amigos | pendente | nenhum.
  /// So 'nenhum' mostra o selo de adicionar — nos outros casos ele seria
  /// um botao que nao faz nada ou que refaz um pedido ja feito.
  final String amizade;

  final List<TreinoPublico> treinos;

  const PerfilPublico({
    required this.id,
    required this.nome,
    required this.avatarUrl,
    required this.membroDesde,
    required this.objetivo,
    required this.metaSemanal,
    required this.totalPontos,
    required this.totalTreinos,
    required this.streak,
    required this.amizade,
    required this.treinos,
  });

  factory PerfilPublico.doJson(Map<String, dynamic> j) => PerfilPublico(
        id: j['id'] as String,
        nome: j['nome'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
        membroDesde: DateTime.parse(j['membro_desde'] as String).toLocal(),
        objetivo: j['objetivo'] as String? ?? 'maintain',
        metaSemanal: (j['meta_semanal'] as num?)?.toInt() ?? 0,
        totalPontos: (j['total_pontos'] as num?)?.toInt() ?? 0,
        totalTreinos: (j['total_treinos'] as num?)?.toInt() ?? 0,
        streak: (j['streak'] as num?)?.toInt() ?? 0,
        amizade: j['amizade'] as String? ?? 'nenhum',
        treinos: ((j['treinos'] as List?) ?? const [])
            .map((t) => TreinoPublico.doJson(Map<String, dynamic>.from(t)))
            .toList(),
      );
}
