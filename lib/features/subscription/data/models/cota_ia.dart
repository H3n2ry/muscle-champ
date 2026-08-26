/// Cota diária de IA do plano gratuito.
///
/// A escolha de limitar em vez de bloquear é de conversão, não de custo: pelos
/// números de `VALORES.md`, um usuário pesado gasta ~R$ 1,06/mês em IA. Quem
/// nunca viu a foto virar macros não sabe o que estaria comprando — a cota
/// deixa provar e esbarra no limite quando a pessoa já se importa.
///
/// ⚠️ A contagem hoje é do APARELHO (SharedPreferences) e a data é a local.
/// As duas coisas o usuário controla. Isso é aceitável enquanto o Pro também
/// é falso; antes de cobrar de verdade a contagem tem que subir para o
/// `groq-proxy`, que já sabe quem é o usuário pelo JWT.
library;

enum RecursoIa {
  /// Modo FOTO da dieta. Limite mais apertado de propósito: é o recurso que
  /// mais impressiona e sozinho responde por ~88% do custo de IA.
  fotoRefeicao(limiteGratis: 1),

  /// Modo IA por texto ("200g de frango"). O mais barato e o mais usado no
  /// dia a dia, então é o que ganha mais folga.
  macrosTexto(limiteGratis: 3),

  /// Gerar treino por grupo muscular.
  gerarTreino(limiteGratis: 1),

  /// Gerar o cardápio do dia.
  planoDieta(limiteGratis: 1);

  const RecursoIa({required this.limiteGratis});

  /// Quantas vezes por dia o plano gratuito pode usar.
  final int limiteGratis;

  /// Chave curta e estável para gravar o contador. NÃO usar `name`: renomear
  /// o enum zeraria a cota de todo mundo silenciosamente.
  String get chave => switch (this) {
        RecursoIa.fotoRefeicao => 'foto',
        RecursoIa.macrosTexto => 'texto',
        RecursoIa.gerarTreino => 'treino',
        RecursoIa.planoDieta => 'dieta',
      };
}

/// Quanto sobrou hoje de um recurso.
class SaldoDeCota {
  final RecursoIa recurso;
  final int usados;

  /// Assinante não tem cota — a tela precisa saber para não mostrar contador.
  final bool ilimitado;

  const SaldoDeCota({
    required this.recurso,
    required this.usados,
    required this.ilimitado,
  });

  int get restantes =>
      ilimitado ? 999 : (recurso.limiteGratis - usados).clamp(0, 999);

  bool get podeUsar => ilimitado || usados < recurso.limiteGratis;
}
