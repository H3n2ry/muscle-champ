/// Planos de assinatura — números de `VALORES.md`.
///
/// ⚠️ Isto é a vitrine de DEMONSTRAÇÃO. Em produção o preço não sai daqui:
/// no Google Play ele é definido por região no Play Console e o app exibe o
/// que o Play Billing devolver. Manter valor fixo no cliente faria o usuário
/// de outro país ver R$ e ser cobrado em outra moeda.
library;

/// Dinheiro em centavos, nunca `double`.
///
/// 19.90 não existe em binário; somar doze mensalidades em `double` já rende
/// 238.79999999999998. Em centavos a conta é exata e a escada de coerência
/// abaixo pode ser verificada por teste.
typedef Centavos = int;

enum Periodicidade {
  mensal(meses: 1),
  trimestral(meses: 3),
  anual(meses: 12);

  const Periodicidade({required this.meses});
  final int meses;
}

class Plano {
  final String id;
  final Periodicidade periodo;

  /// O que o usuário paga AGORA, na primeira assinatura.
  final Centavos entrada;

  /// O que passa a pagar na renovação. Igual à entrada quando não há degrau.
  ///
  /// Existe porque o anual tem preço de entrada menor que o de renovação.
  /// A copy precisa dizer os dois — ver [precisaAvisarRenovacao].
  final Centavos renovacao;

  final bool destaque;

  const Plano({
    required this.id,
    required this.periodo,
    required this.entrada,
    required this.renovacao,
    this.destaque = false,
  });

  /// Preço mensal equivalente, em centavos, arredondado.
  Centavos get porMes => (entrada / periodo.meses).round();

  /// Quanto se economiza, em centavos, contra pagar 12 mensais.
  Centavos economiaAnualContra(Plano mensal) {
    final anualizado = (entrada / periodo.meses * 12).round();
    return (mensal.entrada * 12) - anualizado;
  }

  /// O CDC trata "de R$ X por R$ Y" como preço de referência artificial
  /// quando o X nunca é cobrado na entrada. Por isso a tela nunca risca um
  /// preço: ela diz "primeiro ano por A, renova por B".
  bool get precisaAvisarRenovacao => renovacao != entrada;
}

/// Catálogo. `mensal` é a âncora de comparação dos demais.
class Planos {
  Planos._();

  static const mensal = Plano(
    id: 'mensal',
    periodo: Periodicidade.mensal,
    entrada: 1990,
    renovacao: 1990,
  );

  static const trimestral = Plano(
    id: 'trimestral',
    periodo: Periodicidade.trimestral,
    entrada: 4990,
    renovacao: 4990,
  );

  static const anual = Plano(
    id: 'anual',
    periodo: Periodicidade.anual,
    entrada: 11990,
    renovacao: 14990,
    destaque: true,
  );

  /// Janela promocional dos 6 primeiros meses de vida do app.
  /// Fora dela o catálogo é [todos]; aqui só para a tela poder ser avaliada.
  static const lancamento = Plano(
    id: 'lancamento',
    periodo: Periodicidade.anual,
    entrada: 8990,
    renovacao: 14990,
    destaque: true,
  );

  static const todos = [anual, trimestral, mensal];

  /// Dias de avaliação gratuita antes da primeira cobrança.
  static const diasDeTrial = 14;
}

/// `R$ 119,90`. Formatação manual em vez de `NumberFormat` porque o valor é
/// sempre BRL — a cobrança acontece no Brasil, mesmo com o app em inglês.
String formatarBRL(Centavos v) {
  final reais = v ~/ 100;
  final centavos = (v % 100).toString().padLeft(2, '0');
  return 'R\$ $reais,$centavos';
}
