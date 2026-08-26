/// Textos legais versionados e regras de conformidade (LGPD + GDPR).
///
/// A [documentVersion] é gravada em `user_consents.document_version` a cada
/// consentimento. Ao mudar qualquer texto abaixo de forma materialmente
/// relevante, **suba a versão** — usuários existentes precisam reconsentir
/// (GDPR Art. 7, LGPD Art. 8 §6).
class LegalTexts {
  LegalTexts._();

  /// Versão dos documentos legais. Formato ISO (data da última revisão).
  static const String documentVersion = '2026-08-17';

  // ── URLs públicas ────────────────────────────────────────────────────────
  // TODO(legal): trocar pelo domínio próprio quando musclechamp.com.br existir.
  // O Google Play exige que a Política de Privacidade esteja numa URL pública
  // e estável, e que exista uma URL de exclusão de conta acessível sem login.
  static const String privacyUrl  = 'https://muscle-champ.vercel.app/privacidade.html';
  static const String termsUrl    = 'https://muscle-champ.vercel.app/termos.html';
  static const String deletionUrl = 'https://muscle-champ.vercel.app/excluir-conta.html';

  /// Canal para exercício de direitos do titular (LGPD Art. 18 / GDPR Art. 15-22).
  /// Precisa bater com o e-mail publicado em docs/juridico/PRIVACY.md.
  // TODO(legal): migrar para privacidade@musclechamp.com.br quando o domínio existir.
  static const String privacyEmail = 'afd3vs@gmail.com';

  // ── Idade mínima ─────────────────────────────────────────────────────────
  /// 16 anos. É o piso do GDPR Art. 8 para consentimento sem autorização
  /// parental (alguns Estados-Membros reduzem para 13, mas 16 é seguro em
  /// todos). No Brasil a LGPD Art. 14 exige consentimento de responsável para
  /// menores de 12; adotar 16 cobre os dois regimes com uma regra só e evita
  /// ter que construir um fluxo de consentimento parental verificável.
  static const int minimumAge = 16;

  /// Calcula a idade em anos completos numa data de referência.
  static int ageFrom(DateTime birthDate, {DateTime? on}) {
    final ref = on ?? DateTime.now();
    var age = ref.year - birthDate.year;
    final hadBirthday = (ref.month > birthDate.month) ||
        (ref.month == birthDate.month && ref.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age;
  }

  static bool isOldEnough(DateTime birthDate) =>
      ageFrom(birthDate) >= minimumAge;

  static const String underageMessage =
      'É necessário ter pelo menos $minimumAge anos para criar uma conta. '
      'O app trata dados de saúde, e abaixo dessa idade a lei exige '
      'consentimento verificável de um responsável.';

  // ── Disclaimers obrigatórios ─────────────────────────────────────────────
  // Exigidos pela política de apps de saúde do Google Play e pela restrição
  // do CFN (o app não pode dar diagnóstico nutricional, apenas estimativa).

  static const String nutritionDisclaimer =
      'Os valores nutricionais são estimativas geradas por inteligência '
      'artificial e podem não refletir a composição exata dos alimentos. '
      'Não substituem orientação de nutricionista.';

  static const String workoutDisclaimer =
      'As sugestões de treino são geradas por inteligência artificial e têm '
      'fins educativos. Consulte um profissional de educação física antes de '
      'iniciar qualquer programa de exercícios.';

  static const String bioimpedanceDisclaimer =
      'Os dados de composição corporal são informados por você e servem apenas '
      'para acompanhamento pessoal. Não constituem avaliação clínica.';

  static const String generalHealthDisclaimer =
      'O Muscle Champ não é um dispositivo médico e não diagnostica, trata ou '
      'previne doenças. Em caso de dúvida sobre sua saúde, procure um médico.';

  // ── Itens de consentimento ───────────────────────────────────────────────
  /// Consentimentos coletados no cadastro. Os `required` bloqueiam a criação
  /// da conta; os demais são livres (GDPR Art. 7(4) — consentimento não pode
  /// ser condicionado a algo desnecessário para o serviço).
  static const List<ConsentItem> signupConsents = [
    ConsentItem(
      type: 'terms',
      required: true,
      label: 'Li e aceito os Termos de Uso',
      detail: 'Regras de uso do app, assinatura e cancelamento.',
    ),
    ConsentItem(
      type: 'privacy',
      required: true,
      label: 'Li e aceito a Política de Privacidade',
      detail: 'Como seus dados são coletados, usados, guardados e apagados.',
    ),
    ConsentItem(
      type: 'health_data',
      required: true,
      label: 'Autorizo o tratamento dos meus dados de saúde',
      detail:
          'Peso, altura, composição corporal, histórico alimentar e de treinos. '
          'São dados sensíveis (LGPD Art. 11 / GDPR Art. 9) e o app não '
          'funciona sem eles. Você pode apagar tudo a qualquer momento.',
    ),
    ConsentItem(
      type: 'ai_photo_transfer',
      required: false,
      label: 'Autorizo a análise de fotos por IA',
      detail:
          'Ao usar o modo FOTO, a imagem da refeição é enviada para a Groq '
          '(servidores nos EUA) para estimar os macros. A foto não é '
          'armazenada. Sem esta autorização, os modos BANCO e IA por texto '
          'continuam funcionando normalmente.',
    ),
    ConsentItem(
      type: 'marketing',
      required: false,
      label: 'Quero receber novidades e dicas por e-mail',
      detail: 'Opcional. Pode ser desativado quando quiser no perfil.',
    ),
  ];
}

/// Um item de consentimento apresentado ao usuário.
class ConsentItem {
  final String type;
  final bool required;
  final String label;
  final String detail;

  const ConsentItem({
    required this.type,
    required this.required,
    required this.label,
    required this.detail,
  });
}
