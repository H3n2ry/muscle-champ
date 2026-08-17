import 'legal_texts.dart';

/// Conteúdo integral dos documentos legais, embutido no app.
///
/// Fica em Dart (e não só nos HTMLs de `web/`) porque o usuário precisa poder
/// **ler antes de aceitar**, sem sair do app e sem depender de rede. Um aceite
/// dado sem acesso ao texto é frágil — a lei exige informação clara e prévia
/// (LGPD Art. 9 / GDPR Art. 13).
///
/// ⚠️ Ao alterar qualquer texto aqui, replicar em `web/privacidade.html` /
/// `web/termos.html` e subir [LegalTexts.documentVersion] se a mudança for
/// material.
class LegalDocuments {
  LegalDocuments._();

  static const LegalDocument terms = LegalDocument(
    id: 'terms',
    title: 'Termos de Uso',
    sections: [
      LegalSection('1. Aceite',
          'Ao criar uma conta no Muscle Champ você concorda com estes Termos e '
          'com a Política de Privacidade. Se não concordar, não use o aplicativo.'),
      LegalSection('2. Quem pode usar',
          'É necessário ter ${LegalTexts.minimumAge} anos ou mais. Você é '
          'responsável por manter suas credenciais em segurança e pela '
          'atividade realizada na sua conta.'),
      LegalSection('3. O que o app é — e o que não é',
          'O Muscle Champ NÃO é um serviço de saúde. Não é dispositivo médico e '
          'não diagnostica, trata, cura ou previne doenças.\n\n'
          '• Os valores nutricionais são estimativas geradas por inteligência '
          'artificial e podem divergir da composição real dos alimentos\n'
          '• Os treinos sugeridos têm fins educativos\n'
          '• Os dados de composição corporal são informados por você e servem '
          'para acompanhamento pessoal, não como avaliação clínica\n\n'
          'Consulte um nutricionista antes de mudanças alimentares e um '
          'profissional de educação física antes de iniciar um programa de '
          'exercícios. Se você tem condição de saúde preexistente, está grávida '
          'ou tem histórico de transtorno alimentar, procure orientação médica '
          'antes de usar recursos de contagem calórica.'),
      LegalSection('4. Uso aceitável',
          'Você concorda em não:\n\n'
          '• Criar contas falsas ou manipular a pontuação e o ranking\n'
          '• Tentar acessar dados de outros usuários\n'
          '• Fazer engenharia reversa, automatizar acessos ou sobrecarregar a '
          'infraestrutura\n'
          '• Enviar conteúdo ilegal ou que viole direitos de terceiros\n\n'
          'Contas que violarem estas regras podem ser suspensas ou encerradas.'),
      LegalSection('5. Assinatura e pagamento',
          'Recursos pagos são cobrados via Google Play. Preço, periodicidade e '
          'eventual período de teste são exibidos antes da confirmação da compra.\n\n'
          '• Renovação: automática, salvo cancelamento antes do fim do ciclo\n'
          '• Mudança de preço: comunicada com antecedência pelo Google Play; '
          'você pode recusar cancelando\n'
          '• Cancelamento: a qualquer momento, nas assinaturas da sua conta Google\n'
          '• Acesso após cancelar: mantido até o fim do período já pago\n'
          '• Reembolso: conforme a política do Google Play e o CDC\n\n'
          'Direito de arrependimento: consumidores no Brasil podem desistir da '
          'compra em até 7 dias (CDC, Art. 49). No Espaço Econômico Europeu, o '
          'prazo de retratação é de 14 dias. Nos dois casos o pedido é feito '
          'pelo Google Play.'),
      LegalSection('6. Encerramento',
          'Você pode excluir sua conta a qualquer momento em Perfil → '
          'Privacidade e dados. A exclusão apaga seus dados permanentemente e '
          'não gera reembolso automático do período já pago.'),
      LegalSection('7. Disponibilidade',
          'O serviço é fornecido "como está". Não garantimos disponibilidade '
          'ininterrupta nem ausência de erros. Podemos alterar ou descontinuar '
          'funcionalidades, avisando com antecedência razoável quando a mudança '
          'for relevante.'),
      LegalSection('8. Limitação de responsabilidade',
          'Na máxima extensão permitida em lei, não respondemos por danos '
          'indiretos ou lucros cessantes decorrentes do uso do app. Nada nestes '
          'Termos limita direitos que a lei do consumidor garante a você de '
          'forma inafastável.'),
      LegalSection('9. Propriedade intelectual',
          'O aplicativo, a marca e o conteúdo produzido por nós pertencem ao '
          'desenvolvedor. Os dados que você registra pertencem a você, e podem '
          'ser exportados a qualquer momento pelo app.'),
      LegalSection('10. Lei aplicável',
          'Regidos pela lei brasileira, com foro na comarca de São Paulo/SP. '
          'Consumidores podem acionar o foro do próprio domicílio. Para usuários '
          'no EEE, permanecem aplicáveis as proteções imperativas do país de '
          'residência.'),
      LegalSection('11. Contato',
          'Henry de Araujo Fernandes — ${LegalTexts.privacyEmail}'),
    ],
  );

  static const LegalDocument privacy = LegalDocument(
    id: 'privacy',
    title: 'Política de Privacidade',
    sections: [
      LegalSection('1. Quem é o controlador',
          'Henry de Araujo Fernandes\n'
          'Rua Abdo Salem, 353 — São Paulo, SP — CEP 03462-070, Brasil\n\n'
          'Contato de privacidade: ${LegalTexts.privacyEmail}'),
      LegalSection('2. Quais dados tratamos',
          'Fornecidos por você:\n'
          '• Cadastro — nome, e-mail, senha (guardada apenas como hash), data '
          'de nascimento\n'
          '• Perfil físico — peso atual, peso alvo, altura, objetivo [dado de saúde]\n'
          '• Bioimpedância (opcional) — gordura corporal, massa muscular, '
          'gordura visceral, hidratação, massa óssea, taxa metabólica [dado de saúde]\n'
          '• Foto de perfil (opcional)\n'
          '• Calibração de mão (opcional) — medidas usadas como escala nas fotos\n\n'
          'Gerados pelo uso:\n'
          '• Histórico de treinos — exercícios, séries, repetições, cargas, datas\n'
          '• Histórico alimentar e de hidratação [dado de saúde]\n'
          '• Pontuação, ranking e amizades\n'
          '• Registro de consentimentos — finalidade, versão e data\n\n'
          'Transitórios:\n'
          '• Fotos de alimentos — enviadas para análise e NÃO armazenadas.'),
      LegalSection('3. Para que usamos e com que base legal',
          '• Criar e manter sua conta — execução de contrato '
          '(LGPD Art. 7º V / GDPR Art. 6(1)(b))\n'
          '• Calcular metas, macros e progresso — consentimento específico para '
          'dado sensível (LGPD Art. 11 I / GDPR Art. 9(2)(a))\n'
          '• Estimar macros por foto — consentimento específico e destacado\n'
          '• Ranking e amizades — execução de contrato\n'
          '• Marketing — consentimento, opcional\n'
          '• Segurança e prevenção a abuso — legítimo interesse\n\n'
          'Dados de saúde são categoria especial. Sem consentimento explícito o '
          'app não tem como funcionar — mas você pode retirá-lo a qualquer '
          'momento excluindo a conta, o que apaga tudo.'),
      LegalSection('4. Com quem compartilhamos',
          '• Supabase (operador) — todos os dados da conta — AWS São Paulo\n'
          '• Groq (operador) — descrição ou foto da refeição — Estados Unidos\n'
          '• Vercel — hospedagem do app web — nenhum dado pessoal\n'
          '• Google Play — dados de assinatura; não temos acesso ao cartão\n'
          '• Outros usuários — nome, avatar e pontuação no ranking\n\n'
          'Não vendemos dados pessoais e não fazemos publicidade comportamental.'),
      LegalSection('5. Transferência internacional',
          'O armazenamento principal fica no Brasil. A análise por IA ocorre nos '
          'Estados Unidos, na Groq. Nesse envio:\n\n'
          '• Só trafega o necessário — a imagem ou a descrição do alimento\n'
          '• O dado é transiente: não é gravado nem retido para treinamento\n'
          '• Depende do seu consentimento específico, opcional e revogável\n'
          '• Para usuários no EEE/Reino Unido, apoia-se nas Cláusulas '
          'Contratuais Padrão do provedor\n\n'
          'Se você não autorizar, os modos BANCO e IA por texto continuam '
          'disponíveis — apenas o modo FOTO fica indisponível.'),
      LegalSection('6. Seus direitos',
          'Direto no app, em Perfil → Privacidade e dados:\n'
          '• Acesso e portabilidade — "Baixar meus dados" gera um JSON completo\n'
          '• Exclusão — "Excluir minha conta" apaga tudo imediatamente\n'
          '• Revogação de consentimento — alternar os consentimentos opcionais\n'
          '• Correção — editar perfil e metas\n\n'
          'Por e-mail (${LegalTexts.privacyEmail}):\n'
          '• Oposição ao tratamento e limitação\n'
          '• Informação sobre compartilhamento\n'
          '• Revisão de decisões automatizadas\n\n'
          'Prazo de resposta: até 15 dias.\n\n'
          'Reclamação a autoridade: no Brasil, à ANPD (gov.br/anpd). No EEE, à '
          'autoridade do seu país. No Reino Unido, ao ICO.'),
      LegalSection('7. Decisões automatizadas',
          'O app usa IA para sugerir treinos e planos alimentares e para estimar '
          'valores nutricionais. São sugestões e estimativas — não produzem '
          'efeitos jurídicos, e você pode ignorá-las, editá-las ou inserir tudo '
          'manualmente. O app não diagnostica, trata ou previne doenças.'),
      LegalSection('8. Retenção',
          '• Dados da conta — enquanto a conta existir\n'
          '• Após pedido de exclusão — removidos imediatamente\n'
          '• Fotos de alimentos — não armazenadas\n'
          '• Registro de consentimento — enquanto a conta existir'),
      LegalSection('9. Segurança',
          '• Toda comunicação em TLS/HTTPS\n'
          '• Senhas nunca em texto plano\n'
          '• Isolamento por usuário no banco via Row Level Security\n'
          '• Chaves de IA nunca ficam no app — as chamadas passam por um proxy '
          'autenticado no servidor'),
      LegalSection('10. Idade mínima',
          'O Muscle Champ exige ${LegalTexts.minimumAge} anos ou mais. Tratamos '
          'dados de saúde, e abaixo dessa idade a lei exige consentimento '
          'verificável de um responsável, mecanismo que não oferecemos.'),
      LegalSection('11. Alterações',
          'Mudanças relevantes são comunicadas por e-mail ou dentro do app com '
          'pelo menos 30 dias de antecedência. Quando a alteração afeta a base '
          'de consentimento, pediremos que você consinta novamente.'),
    ],
  );

  /// Documento correspondente a um `consent_type`, quando existir.
  static LegalDocument? forConsent(String consentType) {
    switch (consentType) {
      case 'terms':   return terms;
      case 'privacy': return privacy;
      default:        return null;
    }
  }
}

class LegalDocument {
  final String id;
  final String title;
  final List<LegalSection> sections;

  const LegalDocument({
    required this.id,
    required this.title,
    required this.sections,
  });
}

class LegalSection {
  final String heading;
  final String body;
  const LegalSection(this.heading, this.body);
}
