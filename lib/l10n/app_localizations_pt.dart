// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class LPt extends L {
  LPt([String locale = 'pt']) : super(locale);

  @override
  String get navInicio => 'INÍCIO';

  @override
  String get navTreino => 'TREINO';

  @override
  String get navDieta => 'DIETA';

  @override
  String get navRanking => 'RANKING';

  @override
  String get navPerfil => 'PERFIL';

  @override
  String get comum_salvar => 'SALVAR';

  @override
  String get comum_cancelar => 'Cancelar';

  @override
  String get comum_excluir => 'Excluir';

  @override
  String get comum_fechar => 'Fechar';

  @override
  String get comum_copiar => 'Copiar';

  @override
  String get comum_proximo => 'PRÓXIMO';

  @override
  String get comum_tentarNovamente => 'Tentar novamente';

  @override
  String get comum_carregando => 'Carregando...';

  @override
  String get comum_semConexao => 'Sem conexão com a internet.';

  @override
  String get comum_algoDeuErrado => 'Algo deu errado. Tente novamente.';

  @override
  String get idioma_titulo => 'IDIOMA';

  @override
  String get idioma_portugues => 'Português';

  @override
  String get idioma_ingles => 'Inglês';

  @override
  String get idioma_espanhol => 'Espanhol';

  @override
  String get dash_bemVindo => 'BEM-VINDO,';

  @override
  String get dash_missaoDiaria => 'MISSÃO DIÁRIA';

  @override
  String get dash_comeceAgora => 'Começe agora';

  @override
  String get dash_completo => 'completo';

  @override
  String get dash_global => 'Global';

  @override
  String dash_pts(int pontos) {
    return '$pontos pts';
  }

  @override
  String get dash_treinosSemana => 'TREINOS\nSEMANA';

  @override
  String get dash_pesoAtual => 'PESO\nATUAL';

  @override
  String get dash_metaPeso => 'META\nPESO';

  @override
  String get dash_protocolosDiarios => 'PROTOCOLOS DIÁRIOS';

  @override
  String get dash_proximoMarco => 'PRÓXIMO MARCO';

  @override
  String dash_pontosParaNivel(int faltam, int nivel) {
    return '$faltam pontos para o nível $nivel';
  }

  @override
  String get dash_nivelMaximo => 'Nível máximo alcançado.';

  @override
  String nivel_lvl(int nivel) {
    return 'LVL $nivel';
  }

  @override
  String nivel_nivelN(int nivel) {
    return 'NÍVEL $nivel';
  }

  @override
  String nivel_pontoParaNivel(int faltam, int nivel) {
    return '$faltam ponto para o nível $nivel';
  }

  @override
  String nivel_pontosParaNivel(int faltam, int nivel) {
    return '$faltam pontos para o nível $nivel';
  }

  @override
  String get perfil_pontos => 'PONTOS';

  @override
  String get perfil_treinos => 'TREINOS';

  @override
  String get perfil_sequencia => 'SEQUÊNCIA';

  @override
  String perfil_diasConsecutivos(int dias) {
    return '$dias dias consecutivos';
  }

  @override
  String get perfil_imc => 'ÍNDICE DE MASSA CORPORAL';

  @override
  String get perfil_imcAtual => 'IMC ATUAL';

  @override
  String get perfil_altura => 'ALTURA';

  @override
  String get perfil_peso => 'PESO';

  @override
  String perfil_desde(String ano) {
    return 'DESDE $ano';
  }

  @override
  String get perfil_evolucaoPontos => 'EVOLUÇÃO DE PONTOS';

  @override
  String get perfil_editarPerfil => 'Editar perfil';

  @override
  String get perfil_privacidadeDados => 'Privacidade e dados';

  @override
  String get perfil_sair => 'Sair';

  @override
  String get perfil_semanaNaoCarregou => 'Não foi possível carregar a semana';

  @override
  String get objetivo_perderPeso => 'PERDA DE PESO';

  @override
  String get objetivo_ganharMassa => 'GANHO DE MASSA';

  @override
  String get objetivo_manutencao => 'MANUTENÇÃO';

  @override
  String get treino_missoes => 'MISSÕES';

  @override
  String get treino_titulo => 'TREINO';

  @override
  String get treino_meusTreinos => 'MEUS TREINOS';

  @override
  String get treino_fazerHoje => 'FAZER HOJE';

  @override
  String get treino_feitoHoje => 'FEITO HOJE';

  @override
  String get treino_novoTreino => 'NOVO TREINO';

  @override
  String get treino_editarTreino => 'EDITAR TREINO';

  @override
  String get treino_nomeDoTreino => 'Nome do treino';

  @override
  String get treino_exercicios => 'EXERCÍCIOS';

  @override
  String treino_exercicioN(int n) {
    return 'Exercício $n';
  }

  @override
  String get treino_nomeExercicio => 'Nome do exercício';

  @override
  String get treino_series => 'Séries';

  @override
  String get treino_reps => 'Reps';

  @override
  String get treino_pesoKg => 'Peso (kg)';

  @override
  String get treino_biblioteca => 'BIBLIOTECA';

  @override
  String get treino_manual => 'MANUAL';

  @override
  String get treino_salvarTreino => 'SALVAR TREINO';

  @override
  String get treino_salvando => 'SALVANDO...';

  @override
  String get treino_concluirTreino => 'CONCLUIR TREINO';

  @override
  String get treino_gerarComIa => 'GERAR COM IA';

  @override
  String get treino_arrasteParaReordenar =>
      'Arraste para reordenar. Toque em ✓ para concluir.';

  @override
  String get treino_jaRegistradoHoje => 'Treino já registrado hoje!';

  @override
  String get treino_naoFoiPossivelExcluir =>
      'Não foi possível excluir o treino. Tente novamente.';

  @override
  String get treino_naoFoiPossivelCarregarExercicios =>
      'Não foi possível carregar os exercícios do treino.';

  @override
  String get treino_naoFoiPossivelSalvarOrdem =>
      'Não foi possível salvar a ordem.';

  @override
  String treino_exerciciosCount(int n) {
    return '$n exercícios';
  }

  @override
  String treino_exercicioCount(int n) {
    return '$n exercício';
  }

  @override
  String get dieta_registrarRefeicao => 'REGISTRAR REFEIÇÃO';

  @override
  String get dieta_banco => 'BANCO';

  @override
  String get dieta_ia => 'IA';

  @override
  String get dieta_foto => 'FOTO';

  @override
  String get dieta_descrevaAlimento => 'DESCREVA O ALIMENTO';

  @override
  String get dieta_calcularMacros => 'CALCULAR MACROS';

  @override
  String get dieta_calculando => 'CALCULANDO...';

  @override
  String get dieta_adicionarRefeicao => 'ADICIONAR REFEIÇÃO';

  @override
  String get dieta_macrosDoDia => 'MACROS DO DIA';

  @override
  String get dieta_calorias => 'CALORIAS';

  @override
  String get dieta_proteina => 'PROTEÍNA';

  @override
  String get dieta_carbo => 'CARBO';

  @override
  String get dieta_gordura => 'GORDURA';

  @override
  String get dieta_agua => 'ÁGUA';

  @override
  String get dieta_planoDoDia => 'PLANO DO DIA';

  @override
  String get dieta_exemploDescricao =>
      'Ex: \"200g de frango grelhado\"\n\"arroz integral com feijão\"';

  @override
  String get cadastro_conta => 'CONTA';

  @override
  String get cadastro_corpo => 'CORPO';

  @override
  String get cadastro_missao => 'MISSÃO';

  @override
  String get cadastro_criarConta => 'CRIAR CONTA';

  @override
  String get cadastro_privacidade => 'PRIVACIDADE';

  @override
  String get cadastro_tratamosDadosSaude =>
      'O app trata dados de saúde. Precisamos da sua autorização explícita para isso.';

  @override
  String get cadastro_marqueObrigatorios =>
      'Marque os itens obrigatórios (*) para continuar.';

  @override
  String get cadastro_liAceitoTodos => 'Li e aceito todos os termos';

  @override
  String get cadastro_emailJaCadastrado =>
      'Este email já está cadastrado. Faça login.';

  @override
  String get cadastro_senhaRequisitos =>
      'A senha precisa ter no mínimo 8 caracteres, com letra minúscula, maiúscula, número e símbolo.';

  @override
  String get cadastro_muitasTentativas =>
      'Muitas tentativas. Espere alguns minutos e tente de novo.';

  @override
  String get senha_minimo8 => 'Mínimo 8 caracteres';

  @override
  String get senha_minuscula => 'Letra minúscula (a-z)';

  @override
  String get senha_maiuscula => 'Letra maiúscula (A-Z)';

  @override
  String get senha_numero => 'Número (0-9)';

  @override
  String get senha_simbolo => 'Símbolo (!@#\$%...)';

  @override
  String get privacidade_titulo => 'Privacidade e dados';

  @override
  String get privacidade_documentos => 'DOCUMENTOS';

  @override
  String get privacidade_seusConsentimentos => 'SEUS CONSENTIMENTOS';

  @override
  String get privacidade_seusDireitos => 'SEUS DIREITOS';

  @override
  String get privacidade_contato => 'CONTATO';

  @override
  String get privacidade_baixarDados => 'Baixar meus dados';

  @override
  String get privacidade_excluirConta => 'Excluir minha conta';

  @override
  String get privacidade_politicaPrivacidade => 'Política de Privacidade';

  @override
  String get privacidade_termosUso => 'Termos de Uso';

  @override
  String get privacidade_verNoNavegador => 'Ver no navegador';

  @override
  String get privacidade_liEAceito => 'LI E ACEITO';

  @override
  String get privacidade_roleAteOFim => 'Role até o fim para aceitar';

  @override
  String privacidade_versaoDocumentos(String versao) {
    return 'Versão $versao';
  }

  @override
  String get ranking_titulo => 'RANKING';

  @override
  String get ranking_global => 'GLOBAL';

  @override
  String get ranking_amigos => 'AMIGOS';

  @override
  String get dash_atualizacaoSemanal => 'ATUALIZAÇÃO\nSEMANAL';

  @override
  String get dash_registreSeuPeso =>
      'Registre seu peso desta semana\npara acompanhar sua evolução.';

  @override
  String get dash_pular => 'PULAR';

  @override
  String get dash_pesoInvalido => 'Peso inválido';

  @override
  String get dash_pesoAtualizado => 'Peso atualizado!';

  @override
  String get treino_novoExercicio => 'NOVO EXERCÍCIO';

  @override
  String get treino_grupoMuscular => 'GRUPO MUSCULAR';

  @override
  String get treino_exerciciosGerados => 'EXERCÍCIOS GERADOS';

  @override
  String get treino_gerar => 'GERAR';

  @override
  String get treino_gerando => 'GERANDO...';

  @override
  String get treino_semTreinos => 'Nenhum treino ainda';

  @override
  String get treino_crieOuGere => 'Crie manualmente ou gere com IA';

  @override
  String get treino_criarManual => 'CRIAR MANUAL';

  @override
  String get treino_buscarExercicio => 'Buscar exercício';

  @override
  String get treino_descanso => 'DESCANSO';

  @override
  String get ranking_semAmigos => 'Você ainda não tem amigos';

  @override
  String get ranking_buscarUsuarios => 'Buscar usuários';

  @override
  String get ranking_adicionar => 'ADICIONAR';

  @override
  String get ranking_pendente => 'PENDENTE';

  @override
  String get ranking_aceitar => 'ACEITAR';

  @override
  String get ranking_recusar => 'RECUSAR';

  @override
  String get perfil_conquistas => 'CONQUISTAS CHAMP';

  @override
  String get perfil_bioimpedancia => 'BIOIMPEDÂNCIA';

  @override
  String get perfil_semDados => 'Sem dados ainda';

  @override
  String get login_slogan => 'Compete. Evolua. Domine.';

  @override
  String get login_email => 'EMAIL';

  @override
  String get login_senha => 'SENHA';

  @override
  String get login_emailHint => 'seu@email.com';

  @override
  String get login_entrar => 'ENTRAR';

  @override
  String get login_criarConta => 'CRIAR CONTA';

  @override
  String get login_pillTreinos => 'Treinos';

  @override
  String get login_pillDieta => 'Dieta';

  @override
  String get login_pillRanking => 'Ranking';

  @override
  String get login_pillPontos => 'Pontos';

  @override
  String get dieta_adicionarAlimento => 'ADICIONAR ALIMENTO';

  @override
  String get dieta_adicionarARefeicao => 'ADICIONAR À REFEIÇÃO';

  @override
  String get dieta_ajustarPeso => 'AJUSTAR PESO';

  @override
  String get dieta_alimento => 'ALIMENTO';

  @override
  String get dieta_alterar => 'ALTERAR';

  @override
  String get dieta_alterarAlimento => 'ALTERAR ALIMENTO';

  @override
  String get dieta_adicioneRefeicoes =>
      'Adicione refeições e escolha os alimentos do banco';

  @override
  String get dieta_analisando => 'Analisando...';

  @override
  String get dieta_buscarAlternativa => 'Buscar alternativa...';

  @override
  String get dieta_buscarNoBanco => 'Buscar no banco de alimentos';

  @override
  String get dieta_caloriasDoDia => 'CALORIAS DO DIA';

  @override
  String get dieta_carboidrato => 'CARBOIDRATO';

  @override
  String get dieta_confirmar => 'CONFIRMAR';

  @override
  String get dieta_carbAbrev => 'Carb';

  @override
  String get dieta_configureMeta => 'Configure sua meta calórica no perfil';

  @override
  String get dieta_camera => 'CÂMERA';

  @override
  String get dieta_titulo => 'DIETA';

  @override
  String get dieta_definaPeso =>
      'Defina seu peso no perfil para calcular a meta';

  @override
  String get dieta_exBusca => 'Ex: frango, arroz, aveia...';

  @override
  String get dieta_fotoDoAlimento => 'FOTO DO ALIMENTO';

  @override
  String get dieta_galeria => 'GALERIA';

  @override
  String get dieta_gerarPlano => 'GERAR PLANO DO DIA';

  @override
  String get dieta_gerandoPlano => 'Gerando seu plano personalizado...';

  @override
  String get dieta_gordAbrev => 'Gord';

  @override
  String get dieta_hidratacao => 'HIDRATAÇÃO';

  @override
  String get dieta_iaAtiva => 'IA ATIVA';

  @override
  String get dieta_iaAtivaGroq => 'IA ATIVA · GROQ';

  @override
  String get dieta_iaCalibrada => 'IA calibrada pela sua mão';

  @override
  String get dieta_metaPts => 'META +10 PTS';

  @override
  String get dieta_metaOk => 'META ✓';

  @override
  String get dieta_monteSuaDieta => 'Monte sua própria dieta';

  @override
  String get dieta_novaRefeicao => 'NOVA REFEIÇÃO';

  @override
  String get dieta_nutricao => 'NUTRIÇÃO';

  @override
  String get dieta_nenhumAlimento => 'Nenhum alimento ainda';

  @override
  String get dieta_nenhumEncontrado => 'Nenhum alimento encontrado';

  @override
  String get dieta_nenhumaRefeicao => 'Nenhuma refeição registrada hoje';

  @override
  String get dieta_nomeDaRefeicao => 'Nome da refeição';

  @override
  String get dieta_erroHidratacao => 'Não foi possível carregar a hidratação.';

  @override
  String get dieta_erroDieta => 'Não foi possível carregar sua dieta.';

  @override
  String get dieta_ouPersonalize => 'OU PERSONALIZE';

  @override
  String get dieta_pesoGramas => 'PESO (gramas)';

  @override
  String get dieta_refeicoesDoDia => 'REFEIÇÕES DO DIA';

  @override
  String get dieta_regenerar => 'REGENERAR';

  @override
  String get dieta_resultadoCalculado => 'RESULTADO CALCULADO';

  @override
  String get dieta_tamanhoPorcao => 'TAMANHO DA PORÇÃO (opcional)';

  @override
  String get dieta_trocarAlimento => 'TROCAR ALIMENTO';

  @override
  String get dieta_protAbrev => 'Prot';

  @override
  String get dieta_pesoLabel => 'Peso';

  @override
  String get comum_tentar => 'Tentar';

  @override
  String get comum_limpar => 'limpar';

  @override
  String get dieta_recalibrar => 'recalibrar';

  @override
  String get dieta_resetar => 'resetar';

  @override
  String get rank_titulo => 'RANKINGS';

  @override
  String get rank_adicionar => 'ADICIONAR';

  @override
  String get rank_adicionarAmigo => 'ADICIONAR AMIGO';

  @override
  String get rank_aguardando => 'AGUARDANDO';

  @override
  String get rank_amigo => 'AMIGO';

  @override
  String get rank_amigos => 'AMIGOS';

  @override
  String get rank_buscarAtleta => 'Buscar atleta...';

  @override
  String get rank_buscarPorNome => 'Buscar por nome...';

  @override
  String get rank_cancelar => 'CANCELAR';

  @override
  String get rank_elite => 'ELITE';

  @override
  String get rank_erroCarregar => 'Erro ao carregar';

  @override
  String get rank_global => 'GLOBAL';

  @override
  String get rank_remover => 'REMOVER';

  @override
  String get rank_removerAmigo => 'Remover amigo?';

  @override
  String get rank_voce => 'VOCÊ';

  @override
  String get cad_compromisso => 'COMPROMISSO';

  @override
  String get cad_comoTeChamam => 'Como te chamam?';

  @override
  String get cad_crieIdentidade => 'Crie sua identidade de competidor';

  @override
  String get cad_imcCalculado => 'IMC CALCULADO';

  @override
  String get cad_jaTenhoConta => 'Já tenho conta →';

  @override
  String get cad_medidas => 'MEDIDAS';

  @override
  String get cad_objetivoDetectado => 'OBJETIVO DETECTADO';

  @override
  String get cad_quem => 'QUEM';

  @override
  String get cad_quantosDias => 'Quantos dias por semana você vai treinar?';

  @override
  String get cad_requisitosSenha => 'REQUISITOS DA SENHA';

  @override
  String get cad_seu => 'SEU';

  @override
  String get cad_suas => 'SUAS';

  @override
  String get cad_usadasPara => 'Usadas para IMC, meta calórica e hidratação';

  @override
  String get cad_eVoce => 'É VOCÊ?';

  @override
  String get edit_altura => 'ALTURA';

  @override
  String get edit_dadosPessoais => 'DADOS PESSOAIS';

  @override
  String get edit_dataNascimento => 'DATA DE NASCIMENTO';

  @override
  String get edit_editar => 'EDITAR';

  @override
  String get edit_imc => 'IMC';

  @override
  String get edit_medidasCorporais => 'MEDIDAS CORPORAIS';

  @override
  String get edit_nome => 'NOME';

  @override
  String get edit_objetivo => 'OBJETIVO';

  @override
  String get edit_perfil => 'PERFIL';

  @override
  String get edit_pesoAlvo => 'PESO ALVO';

  @override
  String get edit_pesoAtual => 'PESO ATUAL';

  @override
  String get edit_perfilAtualizado => 'Perfil atualizado com sucesso!';

  @override
  String get edit_salvarAlteracoes => 'SALVAR ALTERAÇÕES';

  @override
  String get objetivo_perdaPesoDesc => 'Queimar gordura e definir o corpo';

  @override
  String get objetivo_manutencaoDesc => 'Manter composição corporal atual';

  @override
  String get objetivo_ganhoMassaDesc => 'Aumentar músculo e força';

  @override
  String get objetivo_perdaPeso => 'PERDA DE PESO';

  @override
  String get objetivo_manutencaoUp => 'MANUTENÇÃO';

  @override
  String get objetivo_ganhoMassa => 'GANHO DE MASSA';

  @override
  String get objetivo_perderPesoCap => 'Perder Peso';

  @override
  String get objetivo_ganharMassaCap => 'Ganhar Massa';

  @override
  String get objetivo_manutencaoCap => 'Manutenção';

  @override
  String get imc_abaixoPeso => 'Abaixo do peso';

  @override
  String get imc_normalOk => 'Normal ✓';

  @override
  String get imc_pesoNormal => 'Peso normal';

  @override
  String get imc_sobrepeso => 'Sobrepeso';

  @override
  String get imc_obesidade1 => 'Obesidade I';

  @override
  String get imc_obesidade2 => 'Obesidade II+';

  @override
  String get imc_obesidadeGrau1 => 'Obesidade grau I';

  @override
  String get imc_obesidadeGrau2 => 'Obesidade grau II+';

  @override
  String get comum_obrigatorio => 'Obrigatório';

  @override
  String get comum_emailInvalido => 'Email inválido';

  @override
  String get comum_erro => 'Erro';

  @override
  String get edit_seuNomeCompleto => 'Seu nome completo';

  @override
  String get edit_erroSalvar => 'Erro ao salvar. Tente novamente.';

  @override
  String get rank_nenhumCompetidor => 'Nenhum competidor ainda';

  @override
  String get rank_adicioneAmigos => 'Adicione amigos para competir!';

  @override
  String get rank_digite2Letras => 'Digite pelo menos 2 letras';

  @override
  String get rank_nenhumUsuario => 'Nenhum usuário encontrado';

  @override
  String get rank_pts => 'pts';

  @override
  String get rank_maisAdicionar => '+ ADICIONAR';

  @override
  String rank_seraRemovido(String nome) {
    return '$nome será removido do seu ranking de amigos.';
  }

  @override
  String get cad_informeNascimento => 'Informe sua data de nascimento';

  @override
  String get cad_nomeGuerreiro => 'NOME DE GUERREIRO';

  @override
  String get cad_emailLabel => 'EMAIL';

  @override
  String get cad_senhaLabel => 'SENHA';

  @override
  String get cad_alturaLabel => 'ALTURA';

  @override
  String get cad_pesoAtualLabel => 'PESO ATUAL';

  @override
  String get cad_pesoAlvoLabel => 'PESO ALVO';

  @override
  String get cad_dataNascimentoLabel => 'DATA DE NASCIMENTO';

  @override
  String get cad_dias => 'dias';

  @override
  String get cad_privacidadeLabel => 'PRIVACIDADE';

  @override
  String get cad_stepConta => 'CONTA';

  @override
  String get cad_stepCorpo => 'CORPO';

  @override
  String get cad_stepMissao => 'MISSÃO';

  @override
  String get cad_emailJaCadastradoHifen =>
      'Este e-mail já está cadastrado. Faça login.';

  @override
  String get cad_senhaFraca =>
      'A senha precisa ter no mínimo 8 caracteres, com letra minúscula, maiúscula, número e símbolo.';

  @override
  String get cad_necessarioAceitar =>
      'É necessário aceitar todos os itens obrigatórios para criar a conta.';

  @override
  String get cad_muitasTentativasEspere =>
      'Muitas tentativas. Espere alguns minutos e tente de novo.';

  @override
  String get senha_errMin8 => 'Mínimo 8 caracteres';

  @override
  String get senha_errMinuscula => 'Precisa de letra minúscula (a-z)';

  @override
  String get senha_errMaiuscula => 'Precisa de letra maiúscula (A-Z)';

  @override
  String get senha_errNumero => 'Precisa de número (0-9)';

  @override
  String get senha_errSimbolo => 'Precisa de símbolo (!@#\$%...)';

  @override
  String get req_min8 => 'Mínimo 8 caracteres';

  @override
  String get req_minuscula => 'Letra minúscula (a-z)';

  @override
  String get req_maiuscula => 'Letra maiúscula (A-Z)';

  @override
  String get req_numero => 'Número (0-9)';

  @override
  String get req_simbolo => 'Símbolo (!@#\$%...)';

  @override
  String get freq_iniciante => 'Iniciante';

  @override
  String get freq_regular => 'Regular';

  @override
  String get freq_dedicado => 'Dedicado';

  @override
  String get freq_avancado => 'Avançado';

  @override
  String get freq_elite => 'Elite';

  @override
  String get dieta_digiteQualquerAlimento =>
      'Digite qualquer alimento ou tire uma foto';

  @override
  String get dieta_calculeMacros =>
      'Calcule macros de qualquer alimento ou tire uma foto';

  @override
  String dieta_faltamMl(int ml) {
    return 'Faltam $ml ml para a meta de hoje';
  }

  @override
  String get dieta_copo => 'Copo';

  @override
  String get dieta_caneca => 'Caneca';

  @override
  String get dieta_garrafa => 'Garrafa';

  @override
  String get dieta_manual => 'MANUAL';

  @override
  String get dieta_ok => 'OK';

  @override
  String get dieta_log => '+LOG';

  @override
  String get dieta_refCafeManha => 'Café da Manhã';

  @override
  String get dieta_refLancheManha => 'Lanche da Manhã';

  @override
  String get dieta_refAlmoco => 'Almoço';

  @override
  String get dieta_refLancheTarde => 'Lanche da Tarde';

  @override
  String get dieta_refJantar => 'Jantar';

  @override
  String get dieta_refCeia => 'Ceia';

  @override
  String get dieta_refPreTreino => 'Pré-treino';

  @override
  String get dieta_refPosTreino => 'Pós-treino';

  @override
  String dieta_iaCriaDieta(int kcal) {
    return 'A IA cria uma dieta personalizada para $kcal kcal';
  }

  @override
  String dieta_metaKcal(int kcal) {
    return 'META $kcal kcal';
  }

  @override
  String dieta_pesoRecalculado(int kcal) {
    return 'Peso recalculado para manter ~$kcal kcal do alimento original';
  }

  @override
  String get dieta_sessaoExpirada => 'Sessão expirada. Faça login novamente.';

  @override
  String get dieta_naoFoiPossivelCalcular =>
      'Não foi possível calcular. Tente novamente.';

  @override
  String get dieta_calibrarMoeda =>
      'Calibrar a IA com uma moeda deixa a análise mais precisa';

  @override
  String get dieta_alimentoGenerico => 'Alimento';

  @override
  String get dieta_alimentoFoto => 'Alimento (foto)';

  @override
  String dieta_adicionarKcal(Object kcal) {
    return 'ADICIONAR  •  $kcal kcal';
  }

  @override
  String get dieta_por100g => 'Por 100g:';

  @override
  String get dieta_porcaoPequena => 'PEQUENA';

  @override
  String get dieta_porcaoMedia => 'MÉDIA';

  @override
  String get dieta_porcaoGrande => 'GRANDE';

  @override
  String get dieta_porcaoPrato => 'PRATO';

  @override
  String get dieta_dicaGarfo =>
      'Dica: coloque um garfo, colher ou a mão perto do alimento para melhor estimativa de peso.';

  @override
  String get dieta_visaoIa => 'VISÃO IA';

  @override
  String get perfil_erroCarregar => 'Erro ao carregar perfil';

  @override
  String get perfil_erroFoto => 'Erro ao carregar foto';

  @override
  String get perfil_sequenciaAtiva => 'SEQUÊNCIA ATIVA';

  @override
  String get perfil_metaComposicao => 'META DE COMPOSIÇÃO';

  @override
  String get perfil_bioimpedanciaCorporal => 'BIOIMPEDÂNCIA CORPORAL';

  @override
  String get perfil_sistemaPontuacao => 'SISTEMA DE PONTUAÇÃO';

  @override
  String get perfil_registreComposicao => 'Registre sua composição corporal';

  @override
  String get perfil_composicaoCorporal => 'COMPOSIÇÃO CORPORAL';

  @override
  String get perfil_musculo => 'MÚSCULO';

  @override
  String get perfil_hidratacao => 'HIDRATAÇÃO';

  @override
  String get perfil_ossea => 'ÓSSEA';

  @override
  String get perfil_massaOssea => 'MASSA ÓSSEA';

  @override
  String get perfil_bioimpedanciaUp => 'BIOIMPEDÂNCIA';

  @override
  String get perfil_preenchaValores =>
      'Preencha os valores gerados pelo aparelho de bioimpedância. Todos os campos são opcionais.';

  @override
  String get perfil_nivelMinusculo => 'nível';

  @override
  String perfil_nivelN2(int n) {
    return 'Nível $n';
  }

  @override
  String get perfil_salvarBioimpedancia => 'SALVAR BIOIMPEDÂNCIA';

  @override
  String get perfil_pontosTreino => 'Treino concluído';

  @override
  String get perfil_pontosDieta => 'Meta de dieta atingida';

  @override
  String get perfil_pontosProgressao => 'Progressão de carga (por exercício)';

  @override
  String get perfil_pontosEvolucao => 'Evolução de peso na direção da meta';

  @override
  String perfil_comKg(String kg) {
    return 'com $kg kg';
  }

  @override
  String get perfil_nivelMaximoAlcancado => 'Nível máximo alcançado.';

  @override
  String perfil_percentualObjetivo(String pct) {
    return '$pct% do objetivo';
  }

  @override
  String get perfil_sequencia7Dias => 'SEQUÊNCIA\nDE 7 DIAS';

  @override
  String get treino_arrasteEConclua =>
      'Arraste para reordenar. Toque em ✓ para concluir.';

  @override
  String get treino_naoFoiPossivelExcluirTreino =>
      'Não foi possível excluir o treino. Tente novamente.';

  @override
  String treino_ptsComProgressao(int extra) {
    return '+10 pts  +$extra pts por progressão!';
  }

  @override
  String get treino_concluidoPts => 'Treino concluído! +10 pts';

  @override
  String get treino_sessaoExpirada => 'Sessão expirada. Faça login novamente.';

  @override
  String get treino_erroGerar => 'Erro ao gerar treino. Tente novamente.';

  @override
  String get treino_ouDescreva => 'Ou descreva: \"Peito e Tríceps pesado\"';

  @override
  String get treino_cargasNaHora =>
      'As cargas serão preenchidas na hora do treino.';

  @override
  String get treino_excluirTreino => 'Excluir treino?';

  @override
  String treino_seraRemovido(String nome) {
    return 'O treino \"$nome\" será removido.';
  }

  @override
  String get treino_nenhumCriado => 'Nenhum treino criado';

  @override
  String get treino_crieOuIa =>
      'Crie manualmente ou deixe a IA montar um treino pra você';

  @override
  String get treino_exNome => 'Ex: Peito e Tríceps';

  @override
  String get treino_toqueBiblioteca => 'Toque para escolher da biblioteca';

  @override
  String get treino_bibliotecaExercicios => 'BIBLIOTECA DE EXERCÍCIOS';

  @override
  String get treino_buscarExercicioHint => 'Buscar exercício...';

  @override
  String get treino_nenhumExercicioEncontrado => 'Nenhum exercício encontrado';

  @override
  String treino_exercicioNumero(int n) {
    return 'Exercício $n';
  }

  @override
  String get treino_nomeDoExercicio => 'Nome do exercício';

  @override
  String get treino_seriesLabel => 'Séries';

  @override
  String get treino_atualizeCargas => 'Atualize as cargas se necessário';

  @override
  String treino_exerciciosParen(int n) {
    return '$n exercício(s)';
  }

  @override
  String get treino_treinoUp => 'TREINO';

  @override
  String get treino_treinoComIa => 'TREINO COM IA';

  @override
  String get dash_atualizacaoSemanalQuebra => 'ATUALIZAÇÃO\nSEMANAL';

  @override
  String get dash_registrePesoSemana =>
      'Registre seu peso desta semana\npara acompanhar sua evolução.';

  @override
  String get dash_pesoInvalidoMsg => 'Peso inválido';

  @override
  String get dash_concluida => 'Concluída!';

  @override
  String get dash_historicoPontos => 'HISTÓRICO DE PONTOS';

  @override
  String get dash_pesoAtualQuebra => 'PESO\nATUAL';

  @override
  String get dash_erroCarregar => 'Erro ao carregar';

  @override
  String get conf_digite8 => 'Digite todos os 8 dígitos';

  @override
  String get conf_codigoInvalido =>
      'Código inválido ou expirado. Verifique e tente novamente.';

  @override
  String conf_codigoReenviado(String email) {
    return 'Código reenviado para $email';
  }

  @override
  String get conf_erroReenviar => 'Erro ao reenviar o código. Tente novamente.';

  @override
  String get conf_enviamosCodigo => 'Enviamos um código de 8 dígitos para:';

  @override
  String conf_reenviarEm(int seg) {
    return 'Reenviar código em ${seg}s';
  }

  @override
  String get conf_naoRecebeu => 'Não recebeu o código? Reenviar';

  @override
  String get login_credenciaisInvalidas =>
      'Email ou senha incorretos. Verifique e tente novamente.';

  @override
  String get login_confirmeEmail =>
      'Confirme seu email antes de entrar. Verifique sua caixa de entrada.';

  @override
  String get login_contaNaoEncontrada =>
      'Nenhuma conta encontrada com este email.';

  @override
  String get login_semInternet =>
      'Sem conexão com a internet. Verifique sua rede.';

  @override
  String get login_muitasTentativas =>
      'Muitas tentativas. Aguarde alguns minutos e tente novamente.';

  @override
  String get login_minimo6 => 'Mínimo 6 caracteres';

  @override
  String get cad_emailPlaceholder => 'seu@email.com';

  @override
  String get calib_sessaoExpirada => 'Sessão expirada. Faça login novamente.';

  @override
  String get calib_naoViMoeda =>
      'Não consegui ver a moeda e a mão claramente. Tente de novo com boa luz, moeda bem no centro da palma.';

  @override
  String get calib_naoFoiPossivel =>
      'Não foi possível calibrar. Tente novamente.';

  @override
  String get calib_sucesso =>
      'IA calibrada! As análises de foto ficarão mais precisas.';

  @override
  String get calib_naoFoiPossivelSalvar =>
      'Não foi possível salvar. Tente novamente.';

  @override
  String get calib_explicacao =>
      'A IA aprende o tamanho da sua mão usando uma moeda como régua. Depois, ela usa sua mão como referência para estimar as porções com mais precisão. É só uma vez.';

  @override
  String get calib_abraPalma =>
      'Abra a palma e coloque a moeda no centro. Boa luz, foto de cima.';

  @override
  String get calib_camera => 'CÂMERA';

  @override
  String get calib_medindo => 'Medindo sua mão...';

  @override
  String get calib_maoMedida => 'Mão medida';

  @override
  String get calib_larguraPalma => 'LARGURA DA PALMA';

  @override
  String get calib_confira =>
      'Confira se faz sentido. Se estiver estranho, refaça a foto.';

  @override
  String get calib_salvar => 'SALVAR CALIBRAÇÃO';

  @override
  String get notif_solicitacoes => 'SOLICITAÇÕES DE AMIZADE';

  @override
  String get notif_erroCarregar => 'Erro ao carregar';

  @override
  String get notif_nenhumaPendente => 'Nenhuma solicitação pendente';

  @override
  String get notif_querSerAmigo => 'quer ser seu amigo';

  @override
  String get notif_noti => 'NOTIFI';

  @override
  String get notif_cacoes => 'CAÇÕES';

  @override
  String priv_naoFoiPossivelAbrir(String url) {
    return 'Não foi possível abrir $url';
  }

  @override
  String get priv_contaExcluida => 'Conta e dados excluídos.';

  @override
  String get priv_naoFoiPossivelAtualizar => 'Não foi possível atualizar';

  @override
  String get priv_naoFoiPossivelCarregar => 'Não foi possível carregar';

  @override
  String get priv_exportaTudo =>
      'Exporta tudo que guardamos sobre você em JSON — perfil, treinos, dieta, peso, pontos e consentimentos.';

  @override
  String get priv_apagaConta =>
      'Apaga a conta e todos os dados permanentemente. Não há como desfazer.';

  @override
  String get priv_faleComEncarregado =>
      'Para dúvidas ou pedidos sobre seus dados, fale com o encarregado de proteção de dados:';

  @override
  String priv_versaoDocs(String v) {
    return 'Versão dos documentos: $v';
  }

  @override
  String get priv_excluirConta => 'Excluir conta';

  @override
  String get priv_itemPesoBio => '• Histórico de peso e bioimpedância\n';

  @override
  String get priv_itemTreinos => '• Treinos, modelos e conclusões\n';

  @override
  String get priv_itemDieta => '• Registros de dieta e água\n';

  @override
  String get priv_semBackup => 'Não há backup e não há como desfazer.';

  @override
  String priv_digiteParaConfirmar(String frase) {
    return 'Digite $frase para confirmar:';
  }

  @override
  String get priv_excluir => 'Excluir';

  @override
  String priv_exportacaoGerada(String kb) {
    return 'Exportação gerada — $kb KB de JSON.';
  }

  @override
  String get priv_obrigatorioParaUsar =>
      'Obrigatório para usar o app — para retirar, exclua a conta.';

  @override
  String priv_aceitoNaVersao(String v) {
    return 'Aceito na versão $v — os documentos mudaram desde então.';
  }

  @override
  String doc_versao(String v) {
    return 'Versão $v';
  }

  @override
  String get doc_roleAteOFim => 'Role até o fim para aceitar';

  @override
  String get erro_verifiqueConexao =>
      'Verifique sua conexão e tente novamente.';

  @override
  String get tut_bemVindoTitulo => 'Bem-vindo ao Muscle Champ!';

  @override
  String get tut_bemVindoCorpo =>
      'Seu hub de fitness gamificado. Ganhe pontos treinando e comendo bem, e suba no ranking superando seus amigos.';

  @override
  String get tut_pontosTitulo => 'Pontos, Rank e Streak';

  @override
  String get tut_pontosCorpo =>
      'Veja aqui seus pontos acumulados, posição no ranking global e entre amigos, e sua sequência de dias ativos.';

  @override
  String get tut_treinosIaTitulo => 'Treinos com IA';

  @override
  String get tut_treinosIaCorpo =>
      'Gere treinos personalizados com inteligência artificial ou registre treinos livres com séries, repetições e cargas.';

  @override
  String get tut_gerarTreinoTitulo => 'Gerar Treino com IA';

  @override
  String get tut_gerarTreinoCorpo =>
      'Toque em \"Gerar Treino\", escolha o grupo muscular e a IA monta o plano completo com exercícios, séries e descanso.';

  @override
  String get tut_dietaTitulo => 'Dieta e Nutrição';

  @override
  String get tut_dietaCorpo =>
      'Registre tudo que você come — por texto ou foto — e a IA calcula calorias, proteínas, carboidratos e gorduras.';

  @override
  String get tut_refeicaoTextoTitulo => 'Registrar Refeição por Texto';

  @override
  String get tut_refeicaoTextoCorpo =>
      'Descreva o que comeu (\"100g frango grelhado + arroz branco\") e a IA calcula os macros na hora.';

  @override
  String get tut_fotoTitulo => 'Foto do Prato — Análise por IA';

  @override
  String get tut_fotoCorpo =>
      'Tire uma foto do seu prato e a IA identifica os alimentos e estima automaticamente os macros e calorias.';

  @override
  String get tut_planoTitulo => 'Plano de Dieta com IA';

  @override
  String get tut_planoCorpo =>
      'Gere um cardápio completo para o dia baseado nas suas metas. Troque alimentos com um toque — a IA recalcula os macros para manter as calorias.';

  @override
  String get tut_rankingTitulo => 'Ranking e Competição';

  @override
  String get tut_rankingCorpo =>
      'Dispute posições com todos os usuários do app. Cada treino registrado e meta de dieta atingida vale pontos!';

  @override
  String get tut_amigosTitulo => 'Ranking Global e Amigos';

  @override
  String get tut_amigosCorpo =>
      'Alterne entre o ranking global e o ranking só com seus amigos. Busque usuários pelo nome e mande solicitação de amizade.';

  @override
  String get tut_perfilTitulo => 'Seu Perfil';

  @override
  String get tut_perfilCorpo =>
      'Configure seus dados físicos, defina metas e personalize sua foto de perfil para aparecer no ranking.';

  @override
  String get tut_metasTitulo => 'Metas e Bioimpedância';

  @override
  String get tut_metasCorpo =>
      'Defina peso alvo, calorias diárias e objetivo (ganhar massa / perder peso / manter). Registre medidas de bioimpedância para acompanhar sua evolução corporal.';

  @override
  String get tut_comecar => 'COMEÇAR!';

  @override
  String get tut_proximo => 'PRÓXIMO  →';

  @override
  String get priv_apagaPermanentemente => 'Isto apaga permanentemente:\n\n';

  @override
  String get priv_itemPerfil => '• Perfil, foto e metas\n';

  @override
  String get priv_itemPontos => '• Pontos, ranking e amizades\n\n';

  @override
  String get perfil_metaImc => 'Meta: IMC';

  @override
  String nivel_pontoParaNivelResto(int nivel) {
    return 'ponto para o nível $nivel';
  }

  @override
  String nivel_pontosParaNivelResto(int nivel) {
    return 'pontos para o nível $nivel';
  }

  @override
  String get grupo_peito => 'Peito';

  @override
  String get grupo_costas => 'Costas';

  @override
  String get grupo_ombros => 'Ombros';

  @override
  String get grupo_biceps => 'Bíceps';

  @override
  String get grupo_triceps => 'Tríceps';

  @override
  String get grupo_pernas => 'Pernas';

  @override
  String get grupo_gluteos => 'Glúteos';

  @override
  String get grupo_core => 'Core';

  @override
  String get grupo_fullBody => 'Full Body';

  @override
  String get perfil_semanaAbrev => 'S';

  @override
  String get perfil_evolucaoNaoCarregou =>
      'Não foi possível carregar a evolução';

  @override
  String perfil_tooltipSemana(int total, int ganhos) {
    return '$total pts\n+$ganhos nesta semana';
  }

  @override
  String perfil_semanaDe(String data) {
    return 'Semana de $data';
  }

  @override
  String get pro_titulo => 'MUSCLE CHAMP';

  @override
  String get pro_pro => 'PRO';

  @override
  String get pro_subtitulo => 'Treino, dieta e evolução com IA — sem limite.';

  @override
  String get pro_escolhaPlano => 'ESCOLHA SEU PLANO';

  @override
  String get pro_oQueLibera => 'O QUE O PRO LIBERA';

  @override
  String get pro_maisPopular => 'MAIS ESCOLHIDO';

  @override
  String pro_porMes(String valor) {
    return '$valor/mês';
  }

  @override
  String pro_economia(String valor) {
    return 'economiza $valor por ano';
  }

  @override
  String get pro_periodoMensal => 'Mensal';

  @override
  String get pro_periodoTrimestral => 'Trimestral';

  @override
  String get pro_periodoAnual => 'Anual';

  @override
  String pro_comecarTrial(int dias) {
    return 'COMEÇAR $dias DIAS GRÁTIS';
  }

  @override
  String get pro_agoraNao => 'Agora não';

  @override
  String get pro_restaurar => 'Restaurar compra';

  @override
  String get pro_benefFoto => 'Foto do prato vira macros';

  @override
  String get pro_benefFotoDesc => 'A IA identifica o alimento e estima o peso';

  @override
  String get pro_benefDieta => 'Plano de dieta gerado por IA';

  @override
  String get pro_benefDietaDesc =>
      'Cardápio do dia nas suas metas, com troca de alimento';

  @override
  String get pro_benefTreino => 'Treinos montados por IA';

  @override
  String get pro_benefTreinoDesc =>
      'Escolha o grupo muscular e receba o treino pronto';

  @override
  String get pro_benefHistorico => 'Histórico sem limite';

  @override
  String get pro_benefHistoricoDesc =>
      'Toda a sua evolução de peso, pontos e medidas';

  @override
  String pro_avisoTrial(int dias, String valor, String data) {
    return '$dias dias grátis. Cobramos $valor só em $data. Cancele antes e não paga nada.';
  }

  @override
  String pro_avisoRenovacao(String entrada, String renovacao) {
    return 'Primeiro ano por $entrada. Renova automaticamente por $renovacao por ano.';
  }

  @override
  String pro_avisoRenovacaoSimples(String valor) {
    return 'Renova automaticamente por $valor. Cancele quando quiser.';
  }

  @override
  String get pro_avisoCancelar =>
      'Você cancela pela loja de aplicativos, sem falar com ninguém.';

  @override
  String pro_aoAssinarAceita(String termos, String privacidade) {
    return 'Ao assinar você aceita os $termos e a $privacidade.';
  }

  @override
  String get demo_faixa => 'MODO DEMONSTRAÇÃO';

  @override
  String get demo_explicacao =>
      'Nenhuma cobrança é feita e nenhum dado sai deste aparelho.';

  @override
  String get pag_titulo => 'PAGAMENTO';

  @override
  String get pag_resumo => 'RESUMO';

  @override
  String get pag_hoje => 'Hoje você paga';

  @override
  String get pag_gratis => 'R\$ 0,00';

  @override
  String pag_depoisDoTrial(String data) {
    return 'Depois de $data';
  }

  @override
  String get pag_forma => 'FORMA DE PAGAMENTO';

  @override
  String get pag_cartao => 'Cartão';

  @override
  String get pag_pix => 'Pix';

  @override
  String get pag_numeroCartao => 'NÚMERO DO CARTÃO';

  @override
  String get pag_nomeNoCartao => 'NOME NO CARTÃO';

  @override
  String get pag_validade => 'VALIDADE';

  @override
  String get pag_cvv => 'CVV';

  @override
  String get pag_pixInstrucao =>
      'Na versão real aparece aqui um QR Code com validade de 30 minutos.';

  @override
  String get pag_confirmar => 'CONFIRMAR ASSINATURA';

  @override
  String get pag_processando => 'Processando...';

  @override
  String get pag_seguro => 'Simulação local — nada é transmitido';

  @override
  String get suc_titulo => 'ASSINATURA ATIVA';

  @override
  String get suc_bemVindo => 'Bem-vindo ao Pro.';

  @override
  String suc_trialAte(String data) {
    return 'Avaliação gratuita até $data';
  }

  @override
  String suc_primeiraCobranca(String valor, String data) {
    return 'Primeira cobrança de $valor em $data';
  }

  @override
  String get suc_comecar => 'COMEÇAR A TREINAR';

  @override
  String get perfil_assinatura => 'ASSINATURA';

  @override
  String get perfil_planoGratuito => 'Plano gratuito';

  @override
  String get perfil_verPlanos => 'Ver planos';

  @override
  String get perfil_proAtivo => 'Pro ativo';

  @override
  String perfil_trialRestante(int dias) {
    return '$dias dias de avaliação restantes';
  }

  @override
  String perfil_renovaEm(String data) {
    return 'Renova em $data';
  }

  @override
  String get perfil_cancelarAssinatura => 'Cancelar assinatura';

  @override
  String get perfil_cancelarConfirma =>
      'Cancelar a assinatura? Você mantém o Pro até o fim do período já pago.';

  @override
  String get perfil_assinaturaCancelada => 'Assinatura cancelada.';

  @override
  String cota_restantesHoje(int n, int total) {
    return '$n de $total hoje';
  }

  @override
  String get cota_ilimitado => 'Ilimitado';

  @override
  String get cota_limiteTitulo => 'Você usou sua IA de hoje';

  @override
  String cota_limiteFoto(int n) {
    return 'O plano gratuito analisa $n foto por dia. Volta amanhã ou libere o uso sem limite.';
  }

  @override
  String cota_limiteTexto(int n) {
    return 'O plano gratuito calcula $n alimentos por texto por dia. Volta amanhã ou libere o uso sem limite.';
  }

  @override
  String cota_limiteTreino(int n) {
    return 'O plano gratuito gera $n treino por dia. Volta amanhã ou libere o uso sem limite.';
  }

  @override
  String cota_limiteDieta(int n) {
    return 'O plano gratuito gera $n plano de dieta por dia. Volta amanhã ou libere o uso sem limite.';
  }

  @override
  String get cota_semLimitePro => 'Sem limite no Pro';

  @override
  String get cota_verPlanos => 'VER PLANOS';

  @override
  String get cota_esperarAmanha => 'Espero até amanhã';

  @override
  String get cota_zerarDemo => 'Zerar cota (demo)';

  @override
  String get cota_zerada => 'Cota do dia zerada.';
}
