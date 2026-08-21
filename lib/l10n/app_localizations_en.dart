// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get navInicio => 'HOME';

  @override
  String get navTreino => 'WORKOUT';

  @override
  String get navDieta => 'DIET';

  @override
  String get navRanking => 'RANKING';

  @override
  String get navPerfil => 'PROFILE';

  @override
  String get comum_salvar => 'SAVE';

  @override
  String get comum_cancelar => 'Cancel';

  @override
  String get comum_excluir => 'Delete';

  @override
  String get comum_fechar => 'Close';

  @override
  String get comum_copiar => 'Copy';

  @override
  String get comum_proximo => 'NEXT';

  @override
  String get comum_tentarNovamente => 'Try again';

  @override
  String get comum_carregando => 'Loading...';

  @override
  String get comum_semConexao => 'No internet connection.';

  @override
  String get comum_algoDeuErrado => 'Something went wrong. Please try again.';

  @override
  String get idioma_titulo => 'LANGUAGE';

  @override
  String get idioma_portugues => 'Portuguese';

  @override
  String get idioma_ingles => 'English';

  @override
  String get idioma_espanhol => 'Spanish';

  @override
  String get dash_bemVindo => 'WELCOME,';

  @override
  String get dash_missaoDiaria => 'DAILY MISSION';

  @override
  String get dash_comeceAgora => 'Start now';

  @override
  String get dash_completo => 'complete';

  @override
  String get dash_global => 'Global';

  @override
  String dash_pts(int pontos) {
    return '$pontos pts';
  }

  @override
  String get dash_treinosSemana => 'WORKOUTS\nTHIS WEEK';

  @override
  String get dash_pesoAtual => 'CURRENT\nWEIGHT';

  @override
  String get dash_metaPeso => 'TARGET\nWEIGHT';

  @override
  String get dash_protocolosDiarios => 'DAILY PROTOCOLS';

  @override
  String get dash_proximoMarco => 'NEXT MILESTONE';

  @override
  String dash_pontosParaNivel(int faltam, int nivel) {
    return '$faltam points to level $nivel';
  }

  @override
  String get dash_nivelMaximo => 'Max level reached.';

  @override
  String nivel_lvl(int nivel) {
    return 'LVL $nivel';
  }

  @override
  String nivel_nivelN(int nivel) {
    return 'LEVEL $nivel';
  }

  @override
  String nivel_pontoParaNivel(int faltam, int nivel) {
    return '$faltam point to level $nivel';
  }

  @override
  String nivel_pontosParaNivel(int faltam, int nivel) {
    return '$faltam points to level $nivel';
  }

  @override
  String get perfil_pontos => 'POINTS';

  @override
  String get perfil_treinos => 'WORKOUTS';

  @override
  String get perfil_sequencia => 'STREAK';

  @override
  String perfil_diasConsecutivos(int dias) {
    return '$dias days in a row';
  }

  @override
  String get perfil_imc => 'BODY MASS INDEX';

  @override
  String get perfil_imcAtual => 'CURRENT BMI';

  @override
  String get perfil_altura => 'HEIGHT';

  @override
  String get perfil_peso => 'WEIGHT';

  @override
  String perfil_desde(String ano) {
    return 'SINCE $ano';
  }

  @override
  String get perfil_evolucaoPontos => 'POINTS OVER TIME';

  @override
  String get perfil_editarPerfil => 'Edit profile';

  @override
  String get perfil_privacidadeDados => 'Privacy and data';

  @override
  String get perfil_sair => 'Sign out';

  @override
  String get perfil_semanaNaoCarregou => 'Couldn\'t load this week';

  @override
  String get objetivo_perderPeso => 'WEIGHT LOSS';

  @override
  String get objetivo_ganharMassa => 'MUSCLE GAIN';

  @override
  String get objetivo_manutencao => 'MAINTENANCE';

  @override
  String get treino_missoes => 'MISSIONS';

  @override
  String get treino_titulo => 'WORKOUT';

  @override
  String get treino_meusTreinos => 'MY WORKOUTS';

  @override
  String get treino_fazerHoje => 'DO IT TODAY';

  @override
  String get treino_feitoHoje => 'DONE TODAY';

  @override
  String get treino_novoTreino => 'NEW WORKOUT';

  @override
  String get treino_editarTreino => 'EDIT WORKOUT';

  @override
  String get treino_nomeDoTreino => 'Workout name';

  @override
  String get treino_exercicios => 'EXERCISES';

  @override
  String treino_exercicioN(int n) {
    return 'Exercise $n';
  }

  @override
  String get treino_nomeExercicio => 'Exercise name';

  @override
  String get treino_series => 'Sets';

  @override
  String get treino_reps => 'Reps';

  @override
  String get treino_pesoKg => 'Weight (kg)';

  @override
  String get treino_biblioteca => 'LIBRARY';

  @override
  String get treino_manual => 'MANUAL';

  @override
  String get treino_salvarTreino => 'SAVE WORKOUT';

  @override
  String get treino_salvando => 'SAVING...';

  @override
  String get treino_concluirTreino => 'FINISH WORKOUT';

  @override
  String get treino_gerarComIa => 'GENERATE WITH AI';

  @override
  String get treino_arrasteParaReordenar => 'Drag to reorder. Tap ✓ when done.';

  @override
  String get treino_jaRegistradoHoje => 'Workout already logged today!';

  @override
  String get treino_naoFoiPossivelExcluir =>
      'Couldn\'t delete the workout. Please try again.';

  @override
  String get treino_naoFoiPossivelCarregarExercicios =>
      'Couldn\'t load the workout\'s exercises.';

  @override
  String get treino_naoFoiPossivelSalvarOrdem => 'Couldn\'t save the order.';

  @override
  String treino_exerciciosCount(int n) {
    return '$n exercises';
  }

  @override
  String treino_exercicioCount(int n) {
    return '$n exercise';
  }

  @override
  String get dieta_registrarRefeicao => 'LOG MEAL';

  @override
  String get dieta_banco => 'DATABASE';

  @override
  String get dieta_ia => 'AI';

  @override
  String get dieta_foto => 'PHOTO';

  @override
  String get dieta_descrevaAlimento => 'DESCRIBE THE FOOD';

  @override
  String get dieta_calcularMacros => 'CALCULATE MACROS';

  @override
  String get dieta_calculando => 'CALCULATING...';

  @override
  String get dieta_adicionarRefeicao => 'ADD MEAL';

  @override
  String get dieta_macrosDoDia => 'TODAY\'S MACROS';

  @override
  String get dieta_calorias => 'CALORIES';

  @override
  String get dieta_proteina => 'PROTEIN';

  @override
  String get dieta_carbo => 'CARBS';

  @override
  String get dieta_gordura => 'FAT';

  @override
  String get dieta_agua => 'WATER';

  @override
  String get dieta_planoDoDia => 'TODAY\'S PLAN';

  @override
  String get dieta_exemploDescricao =>
      'e.g. \"200g grilled chicken\"\n\"brown rice with beans\"';

  @override
  String get cadastro_conta => 'ACCOUNT';

  @override
  String get cadastro_corpo => 'BODY';

  @override
  String get cadastro_missao => 'MISSION';

  @override
  String get cadastro_criarConta => 'CREATE ACCOUNT';

  @override
  String get cadastro_privacidade => 'PRIVACY';

  @override
  String get cadastro_tratamosDadosSaude =>
      'This app handles health data. We need your explicit consent for that.';

  @override
  String get cadastro_marqueObrigatorios =>
      'Check the required items (*) to continue.';

  @override
  String get cadastro_liAceitoTodos => 'I have read and accept all terms';

  @override
  String get cadastro_emailJaCadastrado =>
      'This email is already registered. Please sign in.';

  @override
  String get cadastro_senhaRequisitos =>
      'Password needs at least 8 characters, with lowercase, uppercase, a number and a symbol.';

  @override
  String get cadastro_muitasTentativas =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get senha_minimo8 => 'At least 8 characters';

  @override
  String get senha_minuscula => 'Lowercase letter (a-z)';

  @override
  String get senha_maiuscula => 'Uppercase letter (A-Z)';

  @override
  String get senha_numero => 'Number (0-9)';

  @override
  String get senha_simbolo => 'Symbol (!@#\$%...)';

  @override
  String get privacidade_titulo => 'Privacy and data';

  @override
  String get privacidade_documentos => 'DOCUMENTS';

  @override
  String get privacidade_seusConsentimentos => 'YOUR CONSENTS';

  @override
  String get privacidade_seusDireitos => 'YOUR RIGHTS';

  @override
  String get privacidade_contato => 'CONTACT';

  @override
  String get privacidade_baixarDados => 'Download my data';

  @override
  String get privacidade_excluirConta => 'Delete my account';

  @override
  String get privacidade_politicaPrivacidade => 'Privacy Policy';

  @override
  String get privacidade_termosUso => 'Terms of Use';

  @override
  String get privacidade_verNoNavegador => 'Open in browser';

  @override
  String get privacidade_liEAceito => 'I HAVE READ AND ACCEPT';

  @override
  String get privacidade_roleAteOFim => 'Scroll to the end to accept';

  @override
  String privacidade_versaoDocumentos(String versao) {
    return 'Version $versao';
  }

  @override
  String get ranking_titulo => 'RANKING';

  @override
  String get ranking_global => 'GLOBAL';

  @override
  String get ranking_amigos => 'FRIENDS';

  @override
  String get dash_atualizacaoSemanal => 'WEEKLY\nCHECK-IN';

  @override
  String get dash_registreSeuPeso =>
      'Log this week\'s weight\nto track your progress.';

  @override
  String get dash_pular => 'SKIP';

  @override
  String get dash_pesoInvalido => 'Invalid weight';

  @override
  String get dash_pesoAtualizado => 'Weight updated!';

  @override
  String get treino_novoExercicio => 'NEW EXERCISE';

  @override
  String get treino_grupoMuscular => 'MUSCLE GROUP';

  @override
  String get treino_exerciciosGerados => 'GENERATED EXERCISES';

  @override
  String get treino_gerar => 'GENERATE';

  @override
  String get treino_gerando => 'GENERATING...';

  @override
  String get treino_semTreinos => 'No workouts yet';

  @override
  String get treino_crieOuGere => 'Create one manually or generate with AI';

  @override
  String get treino_criarManual => 'CREATE MANUALLY';

  @override
  String get treino_buscarExercicio => 'Search exercise';

  @override
  String get treino_descanso => 'REST';

  @override
  String get ranking_semAmigos => 'You have no friends yet';

  @override
  String get ranking_buscarUsuarios => 'Search users';

  @override
  String get ranking_adicionar => 'ADD';

  @override
  String get ranking_pendente => 'PENDING';

  @override
  String get ranking_aceitar => 'ACCEPT';

  @override
  String get ranking_recusar => 'DECLINE';

  @override
  String get perfil_conquistas => 'CHAMP ACHIEVEMENTS';

  @override
  String get perfil_bioimpedancia => 'BODY COMPOSITION';

  @override
  String get perfil_semDados => 'No data yet';

  @override
  String get login_slogan => 'Compete. Evolve. Dominate.';

  @override
  String get login_email => 'EMAIL';

  @override
  String get login_senha => 'PASSWORD';

  @override
  String get login_emailHint => 'you@email.com';

  @override
  String get login_entrar => 'SIGN IN';

  @override
  String get login_criarConta => 'CREATE ACCOUNT';

  @override
  String get login_pillTreinos => 'Workouts';

  @override
  String get login_pillDieta => 'Diet';

  @override
  String get login_pillRanking => 'Ranking';

  @override
  String get login_pillPontos => 'Points';

  @override
  String get dieta_adicionarAlimento => 'ADD FOOD';

  @override
  String get dieta_adicionarARefeicao => 'ADD TO MEAL';

  @override
  String get dieta_ajustarPeso => 'ADJUST WEIGHT';

  @override
  String get dieta_alimento => 'FOOD';

  @override
  String get dieta_alterar => 'CHANGE';

  @override
  String get dieta_alterarAlimento => 'CHANGE FOOD';

  @override
  String get dieta_adicioneRefeicoes =>
      'Add meals and pick foods from the database';

  @override
  String get dieta_analisando => 'Analyzing...';

  @override
  String get dieta_buscarAlternativa => 'Search alternative...';

  @override
  String get dieta_buscarNoBanco => 'Search the food database';

  @override
  String get dieta_caloriasDoDia => 'TODAY\'S CALORIES';

  @override
  String get dieta_carboidrato => 'CARBOHYDRATE';

  @override
  String get dieta_confirmar => 'CONFIRM';

  @override
  String get dieta_carbAbrev => 'Carb';

  @override
  String get dieta_configureMeta => 'Set your calorie goal in the profile';

  @override
  String get dieta_camera => 'CAMERA';

  @override
  String get dieta_titulo => 'DIET';

  @override
  String get dieta_definaPeso =>
      'Set your weight in the profile to calculate the goal';

  @override
  String get dieta_exBusca => 'e.g. chicken, rice, oats...';

  @override
  String get dieta_fotoDoAlimento => 'FOOD PHOTO';

  @override
  String get dieta_galeria => 'GALLERY';

  @override
  String get dieta_gerarPlano => 'GENERATE TODAY\'S PLAN';

  @override
  String get dieta_gerandoPlano => 'Generating your personalized plan...';

  @override
  String get dieta_gordAbrev => 'Fat';

  @override
  String get dieta_hidratacao => 'HYDRATION';

  @override
  String get dieta_iaAtiva => 'AI ACTIVE';

  @override
  String get dieta_iaAtivaGroq => 'AI ACTIVE · GROQ';

  @override
  String get dieta_iaCalibrada => 'AI calibrated by your hand';

  @override
  String get dieta_metaPts => 'GOAL +10 PTS';

  @override
  String get dieta_metaOk => 'GOAL ✓';

  @override
  String get dieta_monteSuaDieta => 'Build your own diet';

  @override
  String get dieta_novaRefeicao => 'NEW MEAL';

  @override
  String get dieta_nutricao => 'NUTRITION';

  @override
  String get dieta_nenhumAlimento => 'No food yet';

  @override
  String get dieta_nenhumEncontrado => 'No food found';

  @override
  String get dieta_nenhumaRefeicao => 'No meals logged today';

  @override
  String get dieta_nomeDaRefeicao => 'Meal name';

  @override
  String get dieta_erroHidratacao => 'Couldn\'t load hydration.';

  @override
  String get dieta_erroDieta => 'Couldn\'t load your diet.';

  @override
  String get dieta_ouPersonalize => 'OR CUSTOMIZE';

  @override
  String get dieta_pesoGramas => 'WEIGHT (grams)';

  @override
  String get dieta_refeicoesDoDia => 'TODAY\'S MEALS';

  @override
  String get dieta_regenerar => 'REGENERATE';

  @override
  String get dieta_resultadoCalculado => 'CALCULATED RESULT';

  @override
  String get dieta_tamanhoPorcao => 'PORTION SIZE (optional)';

  @override
  String get dieta_trocarAlimento => 'SWAP FOOD';

  @override
  String get dieta_protAbrev => 'Prot';

  @override
  String get dieta_pesoLabel => 'Weight';

  @override
  String get comum_tentar => 'Retry';

  @override
  String get comum_limpar => 'clear';

  @override
  String get dieta_recalibrar => 'recalibrate';

  @override
  String get dieta_resetar => 'reset';

  @override
  String get rank_titulo => 'RANKINGS';

  @override
  String get rank_adicionar => 'ADD';

  @override
  String get rank_adicionarAmigo => 'ADD FRIEND';

  @override
  String get rank_aguardando => 'PENDING';

  @override
  String get rank_amigo => 'FRIEND';

  @override
  String get rank_amigos => 'FRIENDS';

  @override
  String get rank_buscarAtleta => 'Search athlete...';

  @override
  String get rank_buscarPorNome => 'Search by name...';

  @override
  String get rank_cancelar => 'CANCEL';

  @override
  String get rank_elite => 'ELITE';

  @override
  String get rank_erroCarregar => 'Failed to load';

  @override
  String get rank_global => 'GLOBAL';

  @override
  String get rank_remover => 'REMOVE';

  @override
  String get rank_removerAmigo => 'Remove friend?';

  @override
  String get rank_voce => 'YOU';

  @override
  String get cad_compromisso => 'COMMITMENT';

  @override
  String get cad_comoTeChamam => 'What should we call you?';

  @override
  String get cad_crieIdentidade => 'Create your competitor identity';

  @override
  String get cad_imcCalculado => 'CALCULATED BMI';

  @override
  String get cad_jaTenhoConta => 'I already have an account →';

  @override
  String get cad_medidas => 'MEASUREMENTS';

  @override
  String get cad_objetivoDetectado => 'DETECTED GOAL';

  @override
  String get cad_quem => 'WHO';

  @override
  String get cad_quantosDias => 'How many days a week will you train?';

  @override
  String get cad_requisitosSenha => 'PASSWORD REQUIREMENTS';

  @override
  String get cad_seu => 'YOUR';

  @override
  String get cad_suas => 'YOUR';

  @override
  String get cad_usadasPara => 'Used for BMI, calorie goal and hydration';

  @override
  String get cad_eVoce => 'IS THIS YOU?';

  @override
  String get edit_altura => 'HEIGHT';

  @override
  String get edit_dadosPessoais => 'PERSONAL DATA';

  @override
  String get edit_dataNascimento => 'DATE OF BIRTH';

  @override
  String get edit_editar => 'EDIT';

  @override
  String get edit_imc => 'BMI';

  @override
  String get edit_medidasCorporais => 'BODY MEASUREMENTS';

  @override
  String get edit_nome => 'NAME';

  @override
  String get edit_objetivo => 'GOAL';

  @override
  String get edit_perfil => 'PROFILE';

  @override
  String get edit_pesoAlvo => 'TARGET WEIGHT';

  @override
  String get edit_pesoAtual => 'CURRENT WEIGHT';

  @override
  String get edit_perfilAtualizado => 'Profile updated successfully!';

  @override
  String get edit_salvarAlteracoes => 'SAVE CHANGES';

  @override
  String get objetivo_perdaPesoDesc => 'Burn fat and get defined';

  @override
  String get objetivo_manutencaoDesc => 'Keep your current body composition';

  @override
  String get objetivo_ganhoMassaDesc => 'Build muscle and strength';

  @override
  String get objetivo_perdaPeso => 'WEIGHT LOSS';

  @override
  String get objetivo_manutencaoUp => 'MAINTENANCE';

  @override
  String get objetivo_ganhoMassa => 'MUSCLE GAIN';

  @override
  String get objetivo_perderPesoCap => 'Lose Weight';

  @override
  String get objetivo_ganharMassaCap => 'Gain Muscle';

  @override
  String get objetivo_manutencaoCap => 'Maintenance';

  @override
  String get imc_abaixoPeso => 'Underweight';

  @override
  String get imc_normalOk => 'Normal ✓';

  @override
  String get imc_pesoNormal => 'Normal weight';

  @override
  String get imc_sobrepeso => 'Overweight';

  @override
  String get imc_obesidade1 => 'Obesity I';

  @override
  String get imc_obesidade2 => 'Obesity II+';

  @override
  String get imc_obesidadeGrau1 => 'Obesity class I';

  @override
  String get imc_obesidadeGrau2 => 'Obesity class II+';

  @override
  String get comum_obrigatorio => 'Required';

  @override
  String get comum_emailInvalido => 'Invalid email';

  @override
  String get comum_erro => 'Error';

  @override
  String get edit_seuNomeCompleto => 'Your full name';

  @override
  String get edit_erroSalvar => 'Save failed. Try again.';

  @override
  String get rank_nenhumCompetidor => 'No competitors yet';

  @override
  String get rank_adicioneAmigos => 'Add friends to compete!';

  @override
  String get rank_digite2Letras => 'Type at least 2 letters';

  @override
  String get rank_nenhumUsuario => 'No user found';

  @override
  String get rank_pts => 'pts';

  @override
  String get rank_maisAdicionar => '+ ADD';

  @override
  String rank_seraRemovido(String nome) {
    return '$nome will be removed from your friends ranking.';
  }

  @override
  String get cad_informeNascimento => 'Enter your date of birth';

  @override
  String get cad_nomeGuerreiro => 'WARRIOR NAME';

  @override
  String get cad_emailLabel => 'EMAIL';

  @override
  String get cad_senhaLabel => 'PASSWORD';

  @override
  String get cad_alturaLabel => 'HEIGHT';

  @override
  String get cad_pesoAtualLabel => 'CURRENT WEIGHT';

  @override
  String get cad_pesoAlvoLabel => 'TARGET WEIGHT';

  @override
  String get cad_dataNascimentoLabel => 'DATE OF BIRTH';

  @override
  String get cad_dias => 'days';

  @override
  String get cad_privacidadeLabel => 'PRIVACY';

  @override
  String get cad_stepConta => 'ACCOUNT';

  @override
  String get cad_stepCorpo => 'BODY';

  @override
  String get cad_stepMissao => 'MISSION';

  @override
  String get cad_emailJaCadastradoHifen =>
      'This email is already registered. Please log in.';

  @override
  String get cad_senhaFraca =>
      'Password needs at least 8 characters, with lowercase, uppercase, a digit and a symbol.';

  @override
  String get cad_necessarioAceitar =>
      'You must accept all required items to create the account.';

  @override
  String get cad_muitasTentativasEspere =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get senha_errMin8 => 'At least 8 characters';

  @override
  String get senha_errMinuscula => 'Needs a lowercase letter (a-z)';

  @override
  String get senha_errMaiuscula => 'Needs an uppercase letter (A-Z)';

  @override
  String get senha_errNumero => 'Needs a digit (0-9)';

  @override
  String get senha_errSimbolo => 'Needs a symbol (!@#\$%...)';

  @override
  String get req_min8 => 'At least 8 characters';

  @override
  String get req_minuscula => 'Lowercase letter (a-z)';

  @override
  String get req_maiuscula => 'Uppercase letter (A-Z)';

  @override
  String get req_numero => 'Digit (0-9)';

  @override
  String get req_simbolo => 'Symbol (!@#\$%...)';

  @override
  String get freq_iniciante => 'Beginner';

  @override
  String get freq_regular => 'Regular';

  @override
  String get freq_dedicado => 'Dedicated';

  @override
  String get freq_avancado => 'Advanced';

  @override
  String get freq_elite => 'Elite';

  @override
  String get dieta_digiteQualquerAlimento => 'Type any food or take a photo';

  @override
  String get dieta_calculeMacros =>
      'Calculate macros for any food or take a photo';

  @override
  String dieta_faltamMl(int ml) {
    return '$ml ml to go for today’s goal';
  }

  @override
  String get dieta_copo => 'Glass';

  @override
  String get dieta_caneca => 'Mug';

  @override
  String get dieta_garrafa => 'Bottle';

  @override
  String get dieta_manual => 'MANUAL';

  @override
  String get dieta_ok => 'OK';

  @override
  String get dieta_log => '+LOG';

  @override
  String get dieta_refCafeManha => 'Breakfast';

  @override
  String get dieta_refLancheManha => 'Morning Snack';

  @override
  String get dieta_refAlmoco => 'Lunch';

  @override
  String get dieta_refLancheTarde => 'Afternoon Snack';

  @override
  String get dieta_refJantar => 'Dinner';

  @override
  String get dieta_refCeia => 'Supper';

  @override
  String get dieta_refPreTreino => 'Pre-workout';

  @override
  String get dieta_refPosTreino => 'Post-workout';

  @override
  String dieta_iaCriaDieta(int kcal) {
    return 'The AI builds a custom diet for $kcal kcal';
  }

  @override
  String dieta_metaKcal(int kcal) {
    return 'GOAL $kcal kcal';
  }

  @override
  String dieta_pesoRecalculado(int kcal) {
    return 'Weight recalculated to keep ~$kcal kcal from the original food';
  }

  @override
  String get dieta_sessaoExpirada => 'Session expired. Please log in again.';

  @override
  String get dieta_naoFoiPossivelCalcular => 'Could not calculate. Try again.';

  @override
  String get dieta_calibrarMoeda =>
      'Calibrating the AI with a coin makes the analysis more accurate';

  @override
  String get dieta_alimentoGenerico => 'Food';

  @override
  String get dieta_alimentoFoto => 'Food (photo)';

  @override
  String dieta_adicionarKcal(Object kcal) {
    return 'ADD  •  $kcal kcal';
  }

  @override
  String get dieta_por100g => 'Per 100g:';

  @override
  String get dieta_porcaoPequena => 'SMALL';

  @override
  String get dieta_porcaoMedia => 'MEDIUM';

  @override
  String get dieta_porcaoGrande => 'LARGE';

  @override
  String get dieta_porcaoPrato => 'PLATE';

  @override
  String get dieta_dicaGarfo =>
      'Tip: place a fork, spoon or your hand next to the food for a better weight estimate.';

  @override
  String get dieta_visaoIa => 'AI VISION';

  @override
  String get perfil_erroCarregar => 'Failed to load profile';

  @override
  String get perfil_erroFoto => 'Failed to load photo';

  @override
  String get perfil_sequenciaAtiva => 'ACTIVE STREAK';

  @override
  String get perfil_metaComposicao => 'COMPOSITION GOAL';

  @override
  String get perfil_bioimpedanciaCorporal => 'BODY BIOIMPEDANCE';

  @override
  String get perfil_sistemaPontuacao => 'SCORING SYSTEM';

  @override
  String get perfil_registreComposicao => 'Log your body composition';

  @override
  String get perfil_composicaoCorporal => 'BODY COMPOSITION';

  @override
  String get perfil_musculo => 'MUSCLE';

  @override
  String get perfil_hidratacao => 'HYDRATION';

  @override
  String get perfil_ossea => 'BONE';

  @override
  String get perfil_massaOssea => 'BONE MASS';

  @override
  String get perfil_bioimpedanciaUp => 'BIOIMPEDANCE';

  @override
  String get perfil_preenchaValores =>
      'Fill in the values from your bioimpedance scale. All fields are optional.';

  @override
  String get perfil_nivelMinusculo => 'level';

  @override
  String perfil_nivelN2(int n) {
    return 'Level $n';
  }

  @override
  String get perfil_salvarBioimpedancia => 'SAVE BIOIMPEDANCE';

  @override
  String get perfil_pontosTreino => 'Workout completed';

  @override
  String get perfil_pontosDieta => 'Diet goal reached';

  @override
  String get perfil_pontosProgressao => 'Load progression (per exercise)';

  @override
  String get perfil_pontosEvolucao => 'Weight moving toward the goal';

  @override
  String perfil_comKg(String kg) {
    return 'at $kg kg';
  }

  @override
  String get perfil_nivelMaximoAlcancado => 'Maximum level reached.';

  @override
  String perfil_percentualObjetivo(String pct) {
    return '$pct% of the goal';
  }

  @override
  String get perfil_sequencia7Dias => '7-DAY\nSTREAK';

  @override
  String get treino_arrasteEConclua => 'Drag to reorder. Tap ✓ to complete.';

  @override
  String get treino_naoFoiPossivelExcluirTreino =>
      'Could not delete the workout. Try again.';

  @override
  String treino_ptsComProgressao(int extra) {
    return '+10 pts  +$extra pts for progression!';
  }

  @override
  String get treino_concluidoPts => 'Workout completed! +10 pts';

  @override
  String get treino_sessaoExpirada => 'Session expired. Please log in again.';

  @override
  String get treino_erroGerar => 'Failed to generate the workout. Try again.';

  @override
  String get treino_ouDescreva => 'Or describe it: \"Heavy chest and triceps\"';

  @override
  String get treino_cargasNaHora => 'Weights get filled in during the workout.';

  @override
  String get treino_excluirTreino => 'Delete workout?';

  @override
  String treino_seraRemovido(String nome) {
    return 'The workout \"$nome\" will be removed.';
  }

  @override
  String get treino_nenhumCriado => 'No workouts created';

  @override
  String get treino_crieOuIa =>
      'Create one manually or let the AI build it for you';

  @override
  String get treino_exNome => 'e.g. Chest and Triceps';

  @override
  String get treino_toqueBiblioteca => 'Tap to pick from the library';

  @override
  String get treino_bibliotecaExercicios => 'EXERCISE LIBRARY';

  @override
  String get treino_buscarExercicioHint => 'Search exercise...';

  @override
  String get treino_nenhumExercicioEncontrado => 'No exercise found';

  @override
  String treino_exercicioNumero(int n) {
    return 'Exercise $n';
  }

  @override
  String get treino_nomeDoExercicio => 'Exercise name';

  @override
  String get treino_seriesLabel => 'Sets';

  @override
  String get treino_atualizeCargas => 'Update the weights if needed';

  @override
  String treino_exerciciosParen(int n) {
    return '$n exercise(s)';
  }

  @override
  String get treino_treinoUp => 'WORKOUT';

  @override
  String get treino_treinoComIa => 'AI WORKOUT';

  @override
  String get dash_atualizacaoSemanalQuebra => 'WEEKLY\nCHECK-IN';

  @override
  String get dash_registrePesoSemana =>
      'Log this week’s weight\nto track your progress.';

  @override
  String get dash_pesoInvalidoMsg => 'Invalid weight';

  @override
  String get dash_concluida => 'Done!';

  @override
  String get dash_historicoPontos => 'POINTS HISTORY';

  @override
  String get dash_pesoAtualQuebra => 'CURRENT\nWEIGHT';

  @override
  String get dash_erroCarregar => 'Failed to load';

  @override
  String get conf_digite8 => 'Enter all 8 digits';

  @override
  String get conf_codigoInvalido =>
      'Invalid or expired code. Check it and try again.';

  @override
  String conf_codigoReenviado(String email) {
    return 'Code resent to $email';
  }

  @override
  String get conf_erroReenviar => 'Failed to resend the code. Try again.';

  @override
  String get conf_enviamosCodigo => 'We sent an 8-digit code to:';

  @override
  String conf_reenviarEm(int seg) {
    return 'Resend code in ${seg}s';
  }

  @override
  String get conf_naoRecebeu => 'Didn’t get the code? Resend';

  @override
  String get login_credenciaisInvalidas =>
      'Wrong email or password. Check them and try again.';

  @override
  String get login_confirmeEmail =>
      'Confirm your email before logging in. Check your inbox.';

  @override
  String get login_contaNaoEncontrada => 'No account found with this email.';

  @override
  String get login_semInternet => 'No internet connection. Check your network.';

  @override
  String get login_muitasTentativas =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get login_minimo6 => 'At least 6 characters';

  @override
  String get cad_emailPlaceholder => 'you@email.com';

  @override
  String get calib_sessaoExpirada => 'Session expired. Please log in again.';

  @override
  String get calib_naoViMoeda =>
      'I couldn’t see the coin and hand clearly. Try again in good light, with the coin centered on your palm.';

  @override
  String get calib_naoFoiPossivel => 'Calibration failed. Try again.';

  @override
  String get calib_sucesso =>
      'AI calibrated! Photo analysis will be more accurate.';

  @override
  String get calib_naoFoiPossivelSalvar => 'Could not save. Try again.';

  @override
  String get calib_explicacao =>
      'The AI learns your hand size using a coin as a ruler. Then it uses your hand as a reference to estimate portions more accurately. Just once.';

  @override
  String get calib_abraPalma =>
      'Open your palm and place the coin in the center. Good light, shot from above.';

  @override
  String get calib_camera => 'CAMERA';

  @override
  String get calib_medindo => 'Measuring your hand...';

  @override
  String get calib_maoMedida => 'Hand measured';

  @override
  String get calib_larguraPalma => 'PALM WIDTH';

  @override
  String get calib_confira =>
      'Check that it makes sense. If it looks off, retake the photo.';

  @override
  String get calib_salvar => 'SAVE CALIBRATION';

  @override
  String get notif_solicitacoes => 'FRIEND REQUESTS';

  @override
  String get notif_erroCarregar => 'Failed to load';

  @override
  String get notif_nenhumaPendente => 'No pending requests';

  @override
  String get notif_querSerAmigo => 'wants to be your friend';

  @override
  String get notif_noti => 'NOTIFI';

  @override
  String get notif_cacoes => 'CATIONS';

  @override
  String priv_naoFoiPossivelAbrir(String url) {
    return 'Could not open $url';
  }

  @override
  String get priv_contaExcluida => 'Account and data deleted.';

  @override
  String get priv_naoFoiPossivelAtualizar => 'Could not update';

  @override
  String get priv_naoFoiPossivelCarregar => 'Could not load';

  @override
  String get priv_exportaTudo =>
      'Exports everything we store about you as JSON — profile, workouts, diet, weight, points and consents.';

  @override
  String get priv_apagaConta =>
      'Permanently deletes the account and all data. There is no undo.';

  @override
  String get priv_faleComEncarregado =>
      'For questions or requests about your data, contact the data protection officer:';

  @override
  String priv_versaoDocs(String v) {
    return 'Document version: $v';
  }

  @override
  String get priv_excluirConta => 'Delete account';

  @override
  String get priv_itemPesoBio => '• Weight and bioimpedance history\n';

  @override
  String get priv_itemTreinos => '• Workouts, templates and completions\n';

  @override
  String get priv_itemDieta => '• Diet and water logs\n';

  @override
  String get priv_semBackup => 'There is no backup and no undo.';

  @override
  String priv_digiteParaConfirmar(String frase) {
    return 'Type $frase to confirm:';
  }

  @override
  String get priv_excluir => 'Delete';

  @override
  String priv_exportacaoGerada(String kb) {
    return 'Export generated — $kb KB of JSON.';
  }

  @override
  String get priv_obrigatorioParaUsar =>
      'Required to use the app — to withdraw it, delete your account.';

  @override
  String priv_aceitoNaVersao(String v) {
    return 'Accepted on version $v — the documents have changed since then.';
  }

  @override
  String doc_versao(String v) {
    return 'Version $v';
  }

  @override
  String get doc_roleAteOFim => 'Scroll to the end to accept';

  @override
  String get erro_verifiqueConexao => 'Check your connection and try again.';

  @override
  String get tut_bemVindoTitulo => 'Welcome to Muscle Champ!';

  @override
  String get tut_bemVindoCorpo =>
      'Your gamified fitness hub. Earn points by training and eating well, and climb the ranking past your friends.';

  @override
  String get tut_pontosTitulo => 'Points, Rank and Streak';

  @override
  String get tut_pontosCorpo =>
      'See your accumulated points, your global and friends ranking position, and your active-day streak.';

  @override
  String get tut_treinosIaTitulo => 'AI Workouts';

  @override
  String get tut_treinosIaCorpo =>
      'Generate personalized workouts with AI, or log free workouts with sets, reps and weights.';

  @override
  String get tut_gerarTreinoTitulo => 'Generate an AI Workout';

  @override
  String get tut_gerarTreinoCorpo =>
      'Tap \"Generate Workout\", pick the muscle group, and the AI builds the full plan with exercises, sets and rest.';

  @override
  String get tut_dietaTitulo => 'Diet and Nutrition';

  @override
  String get tut_dietaCorpo =>
      'Log everything you eat — by text or photo — and the AI calculates calories, protein, carbs and fat.';

  @override
  String get tut_refeicaoTextoTitulo => 'Log a Meal by Text';

  @override
  String get tut_refeicaoTextoCorpo =>
      'Describe what you ate (\"100g grilled chicken + white rice\") and the AI works out the macros on the spot.';

  @override
  String get tut_fotoTitulo => 'Plate Photo — AI Analysis';

  @override
  String get tut_fotoCorpo =>
      'Take a photo of your plate and the AI identifies the foods and estimates macros and calories automatically.';

  @override
  String get tut_planoTitulo => 'AI Diet Plan';

  @override
  String get tut_planoCorpo =>
      'Generate a full daily menu based on your goals. Swap foods with one tap — the AI recalculates macros to keep the calories.';

  @override
  String get tut_rankingTitulo => 'Ranking and Competition';

  @override
  String get tut_rankingCorpo =>
      'Compete for position with every user in the app. Each logged workout and diet goal reached is worth points!';

  @override
  String get tut_amigosTitulo => 'Global and Friends Ranking';

  @override
  String get tut_amigosCorpo =>
      'Switch between the global ranking and the friends-only one. Search users by name and send friend requests.';

  @override
  String get tut_perfilTitulo => 'Your Profile';

  @override
  String get tut_perfilCorpo =>
      'Set up your body data, define goals and customize your profile photo to show in the ranking.';

  @override
  String get tut_metasTitulo => 'Goals and Bioimpedance';

  @override
  String get tut_metasCorpo =>
      'Set target weight, daily calories and goal (gain muscle / lose weight / maintain). Log bioimpedance measurements to track your body composition.';

  @override
  String get tut_comecar => 'START!';

  @override
  String get tut_proximo => 'NEXT  →';

  @override
  String get priv_apagaPermanentemente => 'This permanently deletes:\n\n';

  @override
  String get priv_itemPerfil => '• Profile, photo and goals\n';

  @override
  String get priv_itemPontos => '• Points, ranking and friendships\n\n';

  @override
  String get perfil_metaImc => 'Goal: BMI';

  @override
  String nivel_pontoParaNivelResto(int nivel) {
    return 'point to level $nivel';
  }

  @override
  String nivel_pontosParaNivelResto(int nivel) {
    return 'points to level $nivel';
  }

  @override
  String get grupo_peito => 'Chest';

  @override
  String get grupo_costas => 'Back';

  @override
  String get grupo_ombros => 'Shoulders';

  @override
  String get grupo_biceps => 'Biceps';

  @override
  String get grupo_triceps => 'Triceps';

  @override
  String get grupo_pernas => 'Legs';

  @override
  String get grupo_gluteos => 'Glutes';

  @override
  String get grupo_core => 'Core';

  @override
  String get grupo_fullBody => 'Full Body';
}
