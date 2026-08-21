// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class LEs extends L {
  LEs([String locale = 'es']) : super(locale);

  @override
  String get navInicio => 'INICIO';

  @override
  String get navTreino => 'ENTRENO';

  @override
  String get navDieta => 'DIETA';

  @override
  String get navRanking => 'RANKING';

  @override
  String get navPerfil => 'PERFIL';

  @override
  String get comum_salvar => 'GUARDAR';

  @override
  String get comum_cancelar => 'Cancelar';

  @override
  String get comum_excluir => 'Eliminar';

  @override
  String get comum_fechar => 'Cerrar';

  @override
  String get comum_copiar => 'Copiar';

  @override
  String get comum_proximo => 'SIGUIENTE';

  @override
  String get comum_tentarNovamente => 'Intentar de nuevo';

  @override
  String get comum_carregando => 'Cargando...';

  @override
  String get comum_semConexao => 'Sin conexión a internet.';

  @override
  String get comum_algoDeuErrado => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get idioma_titulo => 'IDIOMA';

  @override
  String get idioma_portugues => 'Portugués';

  @override
  String get idioma_ingles => 'Inglés';

  @override
  String get idioma_espanhol => 'Español';

  @override
  String get dash_bemVindo => 'BIENVENIDO,';

  @override
  String get dash_missaoDiaria => 'MISIÓN DIARIA';

  @override
  String get dash_comeceAgora => 'Empieza ahora';

  @override
  String get dash_completo => 'completado';

  @override
  String get dash_global => 'Global';

  @override
  String dash_pts(int pontos) {
    return '$pontos pts';
  }

  @override
  String get dash_treinosSemana => 'ENTRENOS\nSEMANA';

  @override
  String get dash_pesoAtual => 'PESO\nACTUAL';

  @override
  String get dash_metaPeso => 'PESO\nOBJETIVO';

  @override
  String get dash_protocolosDiarios => 'PROTOCOLOS DIARIOS';

  @override
  String get dash_proximoMarco => 'PRÓXIMA META';

  @override
  String dash_pontosParaNivel(int faltam, int nivel) {
    return '$faltam puntos para el nivel $nivel';
  }

  @override
  String get dash_nivelMaximo => 'Nivel máximo alcanzado.';

  @override
  String nivel_lvl(int nivel) {
    return 'NVL $nivel';
  }

  @override
  String nivel_nivelN(int nivel) {
    return 'NIVEL $nivel';
  }

  @override
  String nivel_pontoParaNivel(int faltam, int nivel) {
    return '$faltam punto para el nivel $nivel';
  }

  @override
  String nivel_pontosParaNivel(int faltam, int nivel) {
    return '$faltam puntos para el nivel $nivel';
  }

  @override
  String get perfil_pontos => 'PUNTOS';

  @override
  String get perfil_treinos => 'ENTRENOS';

  @override
  String get perfil_sequencia => 'RACHA';

  @override
  String perfil_diasConsecutivos(int dias) {
    return '$dias días seguidos';
  }

  @override
  String get perfil_imc => 'ÍNDICE DE MASA CORPORAL';

  @override
  String get perfil_imcAtual => 'IMC ACTUAL';

  @override
  String get perfil_altura => 'ALTURA';

  @override
  String get perfil_peso => 'PESO';

  @override
  String perfil_desde(String ano) {
    return 'DESDE $ano';
  }

  @override
  String get perfil_evolucaoPontos => 'EVOLUCIÓN DE PUNTOS';

  @override
  String get perfil_editarPerfil => 'Editar perfil';

  @override
  String get perfil_privacidadeDados => 'Privacidad y datos';

  @override
  String get perfil_sair => 'Cerrar sesión';

  @override
  String get perfil_semanaNaoCarregou => 'No se pudo cargar la semana';

  @override
  String get objetivo_perderPeso => 'PÉRDIDA DE PESO';

  @override
  String get objetivo_ganharMassa => 'GANANCIA MUSCULAR';

  @override
  String get objetivo_manutencao => 'MANTENIMIENTO';

  @override
  String get treino_missoes => 'MISIONES';

  @override
  String get treino_titulo => 'ENTRENO';

  @override
  String get treino_meusTreinos => 'MIS ENTRENOS';

  @override
  String get treino_fazerHoje => 'HACER HOY';

  @override
  String get treino_feitoHoje => 'HECHO HOY';

  @override
  String get treino_novoTreino => 'NUEVO ENTRENO';

  @override
  String get treino_editarTreino => 'EDITAR ENTRENO';

  @override
  String get treino_nomeDoTreino => 'Nombre del entreno';

  @override
  String get treino_exercicios => 'EJERCICIOS';

  @override
  String treino_exercicioN(int n) {
    return 'Ejercicio $n';
  }

  @override
  String get treino_nomeExercicio => 'Nombre del ejercicio';

  @override
  String get treino_series => 'Series';

  @override
  String get treino_reps => 'Reps';

  @override
  String get treino_pesoKg => 'Peso (kg)';

  @override
  String get treino_biblioteca => 'BIBLIOTECA';

  @override
  String get treino_manual => 'MANUAL';

  @override
  String get treino_salvarTreino => 'GUARDAR ENTRENO';

  @override
  String get treino_salvando => 'GUARDANDO...';

  @override
  String get treino_concluirTreino => 'TERMINAR ENTRENO';

  @override
  String get treino_gerarComIa => 'GENERAR CON IA';

  @override
  String get treino_arrasteParaReordenar =>
      'Arrastra para reordenar. Toca ✓ al terminar.';

  @override
  String get treino_jaRegistradoHoje => '¡Entreno ya registrado hoy!';

  @override
  String get treino_naoFoiPossivelExcluir =>
      'No se pudo eliminar el entreno. Inténtalo de nuevo.';

  @override
  String get treino_naoFoiPossivelCarregarExercicios =>
      'No se pudieron cargar los ejercicios del entreno.';

  @override
  String get treino_naoFoiPossivelSalvarOrdem => 'No se pudo guardar el orden.';

  @override
  String treino_exerciciosCount(int n) {
    return '$n ejercicios';
  }

  @override
  String treino_exercicioCount(int n) {
    return '$n ejercicio';
  }

  @override
  String get dieta_registrarRefeicao => 'REGISTRAR COMIDA';

  @override
  String get dieta_banco => 'BASE';

  @override
  String get dieta_ia => 'IA';

  @override
  String get dieta_foto => 'FOTO';

  @override
  String get dieta_descrevaAlimento => 'DESCRIBE EL ALIMENTO';

  @override
  String get dieta_calcularMacros => 'CALCULAR MACROS';

  @override
  String get dieta_calculando => 'CALCULANDO...';

  @override
  String get dieta_adicionarRefeicao => 'AÑADIR COMIDA';

  @override
  String get dieta_macrosDoDia => 'MACROS DEL DÍA';

  @override
  String get dieta_calorias => 'CALORÍAS';

  @override
  String get dieta_proteina => 'PROTEÍNA';

  @override
  String get dieta_carbo => 'CARBOS';

  @override
  String get dieta_gordura => 'GRASA';

  @override
  String get dieta_agua => 'AGUA';

  @override
  String get dieta_planoDoDia => 'PLAN DEL DÍA';

  @override
  String get dieta_exemploDescricao =>
      'Ej: \"200g de pollo a la plancha\"\n\"arroz integral con frijoles\"';

  @override
  String get cadastro_conta => 'CUENTA';

  @override
  String get cadastro_corpo => 'CUERPO';

  @override
  String get cadastro_missao => 'MISIÓN';

  @override
  String get cadastro_criarConta => 'CREAR CUENTA';

  @override
  String get cadastro_privacidade => 'PRIVACIDAD';

  @override
  String get cadastro_tratamosDadosSaude =>
      'La app trata datos de salud. Necesitamos tu autorización explícita para eso.';

  @override
  String get cadastro_marqueObrigatorios =>
      'Marca los elementos obligatorios (*) para continuar.';

  @override
  String get cadastro_liAceitoTodos => 'He leído y acepto todos los términos';

  @override
  String get cadastro_emailJaCadastrado =>
      'Este correo ya está registrado. Inicia sesión.';

  @override
  String get cadastro_senhaRequisitos =>
      'La contraseña necesita al menos 8 caracteres, con minúscula, mayúscula, número y símbolo.';

  @override
  String get cadastro_muitasTentativas =>
      'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';

  @override
  String get senha_minimo8 => 'Mínimo 8 caracteres';

  @override
  String get senha_minuscula => 'Letra minúscula (a-z)';

  @override
  String get senha_maiuscula => 'Letra mayúscula (A-Z)';

  @override
  String get senha_numero => 'Número (0-9)';

  @override
  String get senha_simbolo => 'Símbolo (!@#\$%...)';

  @override
  String get privacidade_titulo => 'Privacidad y datos';

  @override
  String get privacidade_documentos => 'DOCUMENTOS';

  @override
  String get privacidade_seusConsentimentos => 'TUS CONSENTIMIENTOS';

  @override
  String get privacidade_seusDireitos => 'TUS DERECHOS';

  @override
  String get privacidade_contato => 'CONTACTO';

  @override
  String get privacidade_baixarDados => 'Descargar mis datos';

  @override
  String get privacidade_excluirConta => 'Eliminar mi cuenta';

  @override
  String get privacidade_politicaPrivacidade => 'Política de Privacidad';

  @override
  String get privacidade_termosUso => 'Términos de Uso';

  @override
  String get privacidade_verNoNavegador => 'Abrir en el navegador';

  @override
  String get privacidade_liEAceito => 'HE LEÍDO Y ACEPTO';

  @override
  String get privacidade_roleAteOFim =>
      'Desplázate hasta el final para aceptar';

  @override
  String privacidade_versaoDocumentos(String versao) {
    return 'Versión $versao';
  }

  @override
  String get ranking_titulo => 'RANKING';

  @override
  String get ranking_global => 'GLOBAL';

  @override
  String get ranking_amigos => 'AMIGOS';

  @override
  String get dash_atualizacaoSemanal => 'ACTUALIZACIÓN\nSEMANAL';

  @override
  String get dash_registreSeuPeso =>
      'Registra tu peso de esta semana\npara seguir tu evolución.';

  @override
  String get dash_pular => 'OMITIR';

  @override
  String get dash_pesoInvalido => 'Peso inválido';

  @override
  String get dash_pesoAtualizado => '¡Peso actualizado!';

  @override
  String get treino_novoExercicio => 'NUEVO EJERCICIO';

  @override
  String get treino_grupoMuscular => 'GRUPO MUSCULAR';

  @override
  String get treino_exerciciosGerados => 'EJERCICIOS GENERADOS';

  @override
  String get treino_gerar => 'GENERAR';

  @override
  String get treino_gerando => 'GENERANDO...';

  @override
  String get treino_semTreinos => 'Aún no hay entrenos';

  @override
  String get treino_crieOuGere => 'Créalo manualmente o genéralo con IA';

  @override
  String get treino_criarManual => 'CREAR MANUAL';

  @override
  String get treino_buscarExercicio => 'Buscar ejercicio';

  @override
  String get treino_descanso => 'DESCANSO';

  @override
  String get ranking_semAmigos => 'Todavía no tienes amigos';

  @override
  String get ranking_buscarUsuarios => 'Buscar usuarios';

  @override
  String get ranking_adicionar => 'AÑADIR';

  @override
  String get ranking_pendente => 'PENDIENTE';

  @override
  String get ranking_aceitar => 'ACEPTAR';

  @override
  String get ranking_recusar => 'RECHAZAR';

  @override
  String get perfil_conquistas => 'LOGROS CHAMP';

  @override
  String get perfil_bioimpedancia => 'COMPOSICIÓN CORPORAL';

  @override
  String get perfil_semDados => 'Sin datos aún';

  @override
  String get login_slogan => 'Compite. Evoluciona. Domina.';

  @override
  String get login_email => 'CORREO';

  @override
  String get login_senha => 'CONTRASEÑA';

  @override
  String get login_emailHint => 'tu@correo.com';

  @override
  String get login_entrar => 'ENTRAR';

  @override
  String get login_criarConta => 'CREAR CUENTA';

  @override
  String get login_pillTreinos => 'Entrenos';

  @override
  String get login_pillDieta => 'Dieta';

  @override
  String get login_pillRanking => 'Ranking';

  @override
  String get login_pillPontos => 'Puntos';

  @override
  String get dieta_adicionarAlimento => 'AÑADIR ALIMENTO';

  @override
  String get dieta_adicionarARefeicao => 'AÑADIR A LA COMIDA';

  @override
  String get dieta_ajustarPeso => 'AJUSTAR PESO';

  @override
  String get dieta_alimento => 'ALIMENTO';

  @override
  String get dieta_alterar => 'CAMBIAR';

  @override
  String get dieta_alterarAlimento => 'CAMBIAR ALIMENTO';

  @override
  String get dieta_adicioneRefeicoes =>
      'Añade comidas y elige alimentos de la base';

  @override
  String get dieta_analisando => 'Analizando...';

  @override
  String get dieta_buscarAlternativa => 'Buscar alternativa...';

  @override
  String get dieta_buscarNoBanco => 'Buscar en la base de alimentos';

  @override
  String get dieta_caloriasDoDia => 'CALORÍAS DEL DÍA';

  @override
  String get dieta_carboidrato => 'CARBOHIDRATO';

  @override
  String get dieta_confirmar => 'CONFIRMAR';

  @override
  String get dieta_carbAbrev => 'Carb';

  @override
  String get dieta_configureMeta => 'Configura tu meta calórica en el perfil';

  @override
  String get dieta_camera => 'CÁMARA';

  @override
  String get dieta_titulo => 'DIETA';

  @override
  String get dieta_definaPeso =>
      'Define tu peso en el perfil para calcular la meta';

  @override
  String get dieta_exBusca => 'Ej: pollo, arroz, avena...';

  @override
  String get dieta_fotoDoAlimento => 'FOTO DEL ALIMENTO';

  @override
  String get dieta_galeria => 'GALERÍA';

  @override
  String get dieta_gerarPlano => 'GENERAR PLAN DEL DÍA';

  @override
  String get dieta_gerandoPlano => 'Generando tu plan personalizado...';

  @override
  String get dieta_gordAbrev => 'Gras';

  @override
  String get dieta_hidratacao => 'HIDRATACIÓN';

  @override
  String get dieta_iaAtiva => 'IA ACTIVA';

  @override
  String get dieta_iaAtivaGroq => 'IA ACTIVA · GROQ';

  @override
  String get dieta_iaCalibrada => 'IA calibrada por tu mano';

  @override
  String get dieta_metaPts => 'META +10 PTS';

  @override
  String get dieta_metaOk => 'META ✓';

  @override
  String get dieta_monteSuaDieta => 'Arma tu propia dieta';

  @override
  String get dieta_novaRefeicao => 'NUEVA COMIDA';

  @override
  String get dieta_nutricao => 'NUTRICIÓN';

  @override
  String get dieta_nenhumAlimento => 'Aún no hay alimentos';

  @override
  String get dieta_nenhumEncontrado => 'No se encontró ningún alimento';

  @override
  String get dieta_nenhumaRefeicao => 'Ninguna comida registrada hoy';

  @override
  String get dieta_nomeDaRefeicao => 'Nombre de la comida';

  @override
  String get dieta_erroHidratacao => 'No se pudo cargar la hidratación.';

  @override
  String get dieta_erroDieta => 'No se pudo cargar tu dieta.';

  @override
  String get dieta_ouPersonalize => 'O PERSONALIZA';

  @override
  String get dieta_pesoGramas => 'PESO (gramos)';

  @override
  String get dieta_refeicoesDoDia => 'COMIDAS DEL DÍA';

  @override
  String get dieta_regenerar => 'REGENERAR';

  @override
  String get dieta_resultadoCalculado => 'RESULTADO CALCULADO';

  @override
  String get dieta_tamanhoPorcao => 'TAMAÑO DE LA PORCIÓN (opcional)';

  @override
  String get dieta_trocarAlimento => 'CAMBIAR ALIMENTO';

  @override
  String get dieta_protAbrev => 'Prot';

  @override
  String get dieta_pesoLabel => 'Peso';

  @override
  String get comum_tentar => 'Reintentar';

  @override
  String get comum_limpar => 'limpiar';

  @override
  String get dieta_recalibrar => 'recalibrar';

  @override
  String get dieta_resetar => 'reiniciar';

  @override
  String get rank_titulo => 'RANKINGS';

  @override
  String get rank_adicionar => 'AÑADIR';

  @override
  String get rank_adicionarAmigo => 'AÑADIR AMIGO';

  @override
  String get rank_aguardando => 'PENDIENTE';

  @override
  String get rank_amigo => 'AMIGO';

  @override
  String get rank_amigos => 'AMIGOS';

  @override
  String get rank_buscarAtleta => 'Buscar atleta...';

  @override
  String get rank_buscarPorNome => 'Buscar por nombre...';

  @override
  String get rank_cancelar => 'CANCELAR';

  @override
  String get rank_elite => 'ELITE';

  @override
  String get rank_erroCarregar => 'Error al cargar';

  @override
  String get rank_global => 'GLOBAL';

  @override
  String get rank_remover => 'ELIMINAR';

  @override
  String get rank_removerAmigo => '¿Eliminar amigo?';

  @override
  String get rank_voce => 'TÚ';

  @override
  String get cad_compromisso => 'COMPROMISO';

  @override
  String get cad_comoTeChamam => '¿Cómo te llaman?';

  @override
  String get cad_crieIdentidade => 'Crea tu identidad de competidor';

  @override
  String get cad_imcCalculado => 'IMC CALCULADO';

  @override
  String get cad_jaTenhoConta => 'Ya tengo cuenta →';

  @override
  String get cad_medidas => 'MEDIDAS';

  @override
  String get cad_objetivoDetectado => 'OBJETIVO DETECTADO';

  @override
  String get cad_quem => 'QUIÉN';

  @override
  String get cad_quantosDias => '¿Cuántos días por semana vas a entrenar?';

  @override
  String get cad_requisitosSenha => 'REQUISITOS DE CONTRASEÑA';

  @override
  String get cad_seu => 'TU';

  @override
  String get cad_suas => 'TUS';

  @override
  String get cad_usadasPara => 'Usadas para IMC, meta calórica e hidratación';

  @override
  String get cad_eVoce => '¿ERES TÚ?';

  @override
  String get edit_altura => 'ALTURA';

  @override
  String get edit_dadosPessoais => 'DATOS PERSONALES';

  @override
  String get edit_dataNascimento => 'FECHA DE NACIMIENTO';

  @override
  String get edit_editar => 'EDITAR';

  @override
  String get edit_imc => 'IMC';

  @override
  String get edit_medidasCorporais => 'MEDIDAS CORPORALES';

  @override
  String get edit_nome => 'NOMBRE';

  @override
  String get edit_objetivo => 'OBJETIVO';

  @override
  String get edit_perfil => 'PERFIL';

  @override
  String get edit_pesoAlvo => 'PESO OBJETIVO';

  @override
  String get edit_pesoAtual => 'PESO ACTUAL';

  @override
  String get edit_perfilAtualizado => '¡Perfil actualizado con éxito!';

  @override
  String get edit_salvarAlteracoes => 'GUARDAR CAMBIOS';

  @override
  String get objetivo_perdaPesoDesc => 'Quemar grasa y definir el cuerpo';

  @override
  String get objetivo_manutencaoDesc =>
      'Mantener la composición corporal actual';

  @override
  String get objetivo_ganhoMassaDesc => 'Aumentar músculo y fuerza';

  @override
  String get objetivo_perdaPeso => 'PÉRDIDA DE PESO';

  @override
  String get objetivo_manutencaoUp => 'MANTENIMIENTO';

  @override
  String get objetivo_ganhoMassa => 'GANANCIA DE MASA';

  @override
  String get objetivo_perderPesoCap => 'Perder Peso';

  @override
  String get objetivo_ganharMassaCap => 'Ganar Masa';

  @override
  String get objetivo_manutencaoCap => 'Mantenimiento';

  @override
  String get imc_abaixoPeso => 'Bajo peso';

  @override
  String get imc_normalOk => 'Normal ✓';

  @override
  String get imc_pesoNormal => 'Peso normal';

  @override
  String get imc_sobrepeso => 'Sobrepeso';

  @override
  String get imc_obesidade1 => 'Obesidad I';

  @override
  String get imc_obesidade2 => 'Obesidad II+';

  @override
  String get imc_obesidadeGrau1 => 'Obesidad grado I';

  @override
  String get imc_obesidadeGrau2 => 'Obesidad grado II+';

  @override
  String get comum_obrigatorio => 'Obligatorio';

  @override
  String get comum_emailInvalido => 'Email inválido';

  @override
  String get comum_erro => 'Error';

  @override
  String get edit_seuNomeCompleto => 'Tu nombre completo';

  @override
  String get edit_erroSalvar => 'Error al guardar. Inténtalo de nuevo.';

  @override
  String get rank_nenhumCompetidor => 'Aún no hay competidores';

  @override
  String get rank_adicioneAmigos => '¡Añade amigos para competir!';

  @override
  String get rank_digite2Letras => 'Escribe al menos 2 letras';

  @override
  String get rank_nenhumUsuario => 'No se encontró ningún usuario';

  @override
  String get rank_pts => 'pts';

  @override
  String get rank_maisAdicionar => '+ AÑADIR';

  @override
  String rank_seraRemovido(String nome) {
    return '$nome será eliminado de tu ranking de amigos.';
  }

  @override
  String get cad_informeNascimento => 'Indica tu fecha de nacimiento';

  @override
  String get cad_nomeGuerreiro => 'NOMBRE DE GUERRERO';

  @override
  String get cad_emailLabel => 'EMAIL';

  @override
  String get cad_senhaLabel => 'CONTRASEÑA';

  @override
  String get cad_alturaLabel => 'ALTURA';

  @override
  String get cad_pesoAtualLabel => 'PESO ACTUAL';

  @override
  String get cad_pesoAlvoLabel => 'PESO OBJETIVO';

  @override
  String get cad_dataNascimentoLabel => 'FECHA DE NACIMIENTO';

  @override
  String get cad_dias => 'días';

  @override
  String get cad_privacidadeLabel => 'PRIVACIDAD';

  @override
  String get cad_stepConta => 'CUENTA';

  @override
  String get cad_stepCorpo => 'CUERPO';

  @override
  String get cad_stepMissao => 'MISIÓN';

  @override
  String get cad_emailJaCadastradoHifen =>
      'Este email ya está registrado. Inicia sesión.';

  @override
  String get cad_senhaFraca =>
      'La contraseña necesita al menos 8 caracteres, con minúscula, mayúscula, número y símbolo.';

  @override
  String get cad_necessarioAceitar =>
      'Debes aceptar todos los elementos obligatorios para crear la cuenta.';

  @override
  String get cad_muitasTentativasEspere =>
      'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';

  @override
  String get senha_errMin8 => 'Mínimo 8 caracteres';

  @override
  String get senha_errMinuscula => 'Necesita una minúscula (a-z)';

  @override
  String get senha_errMaiuscula => 'Necesita una mayúscula (A-Z)';

  @override
  String get senha_errNumero => 'Necesita un número (0-9)';

  @override
  String get senha_errSimbolo => 'Necesita un símbolo (!@#\$%...)';

  @override
  String get req_min8 => 'Mínimo 8 caracteres';

  @override
  String get req_minuscula => 'Letra minúscula (a-z)';

  @override
  String get req_maiuscula => 'Letra mayúscula (A-Z)';

  @override
  String get req_numero => 'Número (0-9)';

  @override
  String get req_simbolo => 'Símbolo (!@#\$%...)';

  @override
  String get freq_iniciante => 'Principiante';

  @override
  String get freq_regular => 'Regular';

  @override
  String get freq_dedicado => 'Dedicado';

  @override
  String get freq_avancado => 'Avanzado';

  @override
  String get freq_elite => 'Élite';

  @override
  String get dieta_digiteQualquerAlimento =>
      'Escribe cualquier alimento o toma una foto';

  @override
  String get dieta_calculeMacros =>
      'Calcula macros de cualquier alimento o toma una foto';

  @override
  String dieta_faltamMl(int ml) {
    return 'Faltan $ml ml para la meta de hoy';
  }

  @override
  String get dieta_copo => 'Vaso';

  @override
  String get dieta_caneca => 'Taza';

  @override
  String get dieta_garrafa => 'Botella';

  @override
  String get dieta_manual => 'MANUAL';

  @override
  String get dieta_ok => 'OK';

  @override
  String get dieta_log => '+LOG';

  @override
  String get dieta_refCafeManha => 'Desayuno';

  @override
  String get dieta_refLancheManha => 'Media Mañana';

  @override
  String get dieta_refAlmoco => 'Almuerzo';

  @override
  String get dieta_refLancheTarde => 'Merienda';

  @override
  String get dieta_refJantar => 'Cena';

  @override
  String get dieta_refCeia => 'Recena';

  @override
  String get dieta_refPreTreino => 'Pre-entreno';

  @override
  String get dieta_refPosTreino => 'Post-entreno';

  @override
  String dieta_iaCriaDieta(int kcal) {
    return 'La IA crea una dieta personalizada para $kcal kcal';
  }

  @override
  String dieta_metaKcal(int kcal) {
    return 'META $kcal kcal';
  }

  @override
  String dieta_pesoRecalculado(int kcal) {
    return 'Peso recalculado para mantener ~$kcal kcal del alimento original';
  }

  @override
  String get dieta_sessaoExpirada => 'Sesión expirada. Inicia sesión de nuevo.';

  @override
  String get dieta_naoFoiPossivelCalcular =>
      'No se pudo calcular. Inténtalo de nuevo.';

  @override
  String get dieta_calibrarMoeda =>
      'Calibrar la IA con una moneda hace el análisis más preciso';

  @override
  String get dieta_alimentoGenerico => 'Alimento';

  @override
  String get dieta_alimentoFoto => 'Alimento (foto)';

  @override
  String dieta_adicionarKcal(Object kcal) {
    return 'AÑADIR  •  $kcal kcal';
  }

  @override
  String get dieta_por100g => 'Por 100g:';

  @override
  String get dieta_porcaoPequena => 'PEQUEÑA';

  @override
  String get dieta_porcaoMedia => 'MEDIANA';

  @override
  String get dieta_porcaoGrande => 'GRANDE';

  @override
  String get dieta_porcaoPrato => 'PLATO';

  @override
  String get dieta_dicaGarfo =>
      'Consejo: pon un tenedor, cuchara o la mano junto al alimento para estimar mejor el peso.';

  @override
  String get dieta_visaoIa => 'VISIÓN IA';

  @override
  String get perfil_erroCarregar => 'Error al cargar el perfil';

  @override
  String get perfil_erroFoto => 'Error al cargar la foto';

  @override
  String get perfil_sequenciaAtiva => 'RACHA ACTIVA';

  @override
  String get perfil_metaComposicao => 'META DE COMPOSICIÓN';

  @override
  String get perfil_bioimpedanciaCorporal => 'BIOIMPEDANCIA CORPORAL';

  @override
  String get perfil_sistemaPontuacao => 'SISTEMA DE PUNTUACIÓN';

  @override
  String get perfil_registreComposicao => 'Registra tu composición corporal';

  @override
  String get perfil_composicaoCorporal => 'COMPOSICIÓN CORPORAL';

  @override
  String get perfil_musculo => 'MÚSCULO';

  @override
  String get perfil_hidratacao => 'HIDRATACIÓN';

  @override
  String get perfil_ossea => 'ÓSEA';

  @override
  String get perfil_massaOssea => 'MASA ÓSEA';

  @override
  String get perfil_bioimpedanciaUp => 'BIOIMPEDANCIA';

  @override
  String get perfil_preenchaValores =>
      'Rellena los valores del aparato de bioimpedancia. Todos los campos son opcionales.';

  @override
  String get perfil_nivelMinusculo => 'nivel';

  @override
  String perfil_nivelN2(int n) {
    return 'Nivel $n';
  }

  @override
  String get perfil_salvarBioimpedancia => 'GUARDAR BIOIMPEDANCIA';

  @override
  String get perfil_pontosTreino => 'Entrenamiento completado';

  @override
  String get perfil_pontosDieta => 'Meta de dieta alcanzada';

  @override
  String get perfil_pontosProgressao => 'Progresión de carga (por ejercicio)';

  @override
  String get perfil_pontosEvolucao => 'Evolución de peso hacia la meta';

  @override
  String perfil_comKg(String kg) {
    return 'con $kg kg';
  }

  @override
  String get perfil_nivelMaximoAlcancado => 'Nivel máximo alcanzado.';

  @override
  String perfil_percentualObjetivo(String pct) {
    return '$pct% del objetivo';
  }

  @override
  String get perfil_sequencia7Dias => 'RACHA\nDE 7 DÍAS';

  @override
  String get treino_arrasteEConclua =>
      'Arrastra para reordenar. Toca ✓ para completar.';

  @override
  String get treino_naoFoiPossivelExcluirTreino =>
      'No se pudo eliminar el entrenamiento. Inténtalo de nuevo.';

  @override
  String treino_ptsComProgressao(int extra) {
    return '+10 pts  +$extra pts por progresión!';
  }

  @override
  String get treino_concluidoPts => '¡Entrenamiento completado! +10 pts';

  @override
  String get treino_sessaoExpirada =>
      'Sesión expirada. Inicia sesión de nuevo.';

  @override
  String get treino_erroGerar =>
      'Error al generar el entrenamiento. Inténtalo de nuevo.';

  @override
  String get treino_ouDescreva => 'O descríbelo: \"Pecho y tríceps pesado\"';

  @override
  String get treino_cargasNaHora =>
      'Las cargas se rellenan durante el entrenamiento.';

  @override
  String get treino_excluirTreino => '¿Eliminar entrenamiento?';

  @override
  String treino_seraRemovido(String nome) {
    return 'El entrenamiento \"$nome\" será eliminado.';
  }

  @override
  String get treino_nenhumCriado => 'Ningún entrenamiento creado';

  @override
  String get treino_crieOuIa =>
      'Créalo manualmente o deja que la IA lo arme por ti';

  @override
  String get treino_exNome => 'Ej: Pecho y Tríceps';

  @override
  String get treino_toqueBiblioteca => 'Toca para elegir de la biblioteca';

  @override
  String get treino_bibliotecaExercicios => 'BIBLIOTECA DE EJERCICIOS';

  @override
  String get treino_buscarExercicioHint => 'Buscar ejercicio...';

  @override
  String get treino_nenhumExercicioEncontrado =>
      'No se encontró ningún ejercicio';

  @override
  String treino_exercicioNumero(int n) {
    return 'Ejercicio $n';
  }

  @override
  String get treino_nomeDoExercicio => 'Nombre del ejercicio';

  @override
  String get treino_seriesLabel => 'Series';

  @override
  String get treino_atualizeCargas => 'Actualiza las cargas si hace falta';

  @override
  String treino_exerciciosParen(int n) {
    return '$n ejercicio(s)';
  }

  @override
  String get treino_treinoUp => 'ENTRENO';

  @override
  String get treino_treinoComIa => 'ENTRENO CON IA';

  @override
  String get dash_atualizacaoSemanalQuebra => 'ACTUALIZACIÓN\nSEMANAL';

  @override
  String get dash_registrePesoSemana =>
      'Registra tu peso de esta semana\npara seguir tu evolución.';

  @override
  String get dash_pesoInvalidoMsg => 'Peso inválido';

  @override
  String get dash_concluida => '¡Completada!';

  @override
  String get dash_historicoPontos => 'HISTORIAL DE PUNTOS';

  @override
  String get dash_pesoAtualQuebra => 'PESO\nACTUAL';

  @override
  String get dash_erroCarregar => 'Error al cargar';

  @override
  String get conf_digite8 => 'Escribe los 8 dígitos';

  @override
  String get conf_codigoInvalido =>
      'Código inválido o caducado. Verifícalo e inténtalo de nuevo.';

  @override
  String conf_codigoReenviado(String email) {
    return 'Código reenviado a $email';
  }

  @override
  String get conf_erroReenviar =>
      'Error al reenviar el código. Inténtalo de nuevo.';

  @override
  String get conf_enviamosCodigo => 'Enviamos un código de 8 dígitos a:';

  @override
  String conf_reenviarEm(int seg) {
    return 'Reenviar código en ${seg}s';
  }

  @override
  String get conf_naoRecebeu => '¿No recibiste el código? Reenviar';

  @override
  String get login_credenciaisInvalidas =>
      'Email o contraseña incorrectos. Verifícalos e inténtalo de nuevo.';

  @override
  String get login_confirmeEmail =>
      'Confirma tu email antes de entrar. Revisa tu bandeja de entrada.';

  @override
  String get login_contaNaoEncontrada =>
      'No se encontró ninguna cuenta con este email.';

  @override
  String get login_semInternet => 'Sin conexión a internet. Revisa tu red.';

  @override
  String get login_muitasTentativas =>
      'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';

  @override
  String get login_minimo6 => 'Mínimo 6 caracteres';

  @override
  String get cad_emailPlaceholder => 'tu@email.com';

  @override
  String get calib_sessaoExpirada => 'Sesión expirada. Inicia sesión de nuevo.';

  @override
  String get calib_naoViMoeda =>
      'No pude ver la moneda y la mano con claridad. Inténtalo de nuevo con buena luz y la moneda centrada en la palma.';

  @override
  String get calib_naoFoiPossivel => 'No se pudo calibrar. Inténtalo de nuevo.';

  @override
  String get calib_sucesso =>
      '¡IA calibrada! Los análisis de fotos serán más precisos.';

  @override
  String get calib_naoFoiPossivelSalvar =>
      'No se pudo guardar. Inténtalo de nuevo.';

  @override
  String get calib_explicacao =>
      'La IA aprende el tamaño de tu mano usando una moneda como regla. Luego usa tu mano como referencia para estimar las porciones con más precisión. Solo una vez.';

  @override
  String get calib_abraPalma =>
      'Abre la palma y pon la moneda en el centro. Buena luz, foto desde arriba.';

  @override
  String get calib_camera => 'CÁMARA';

  @override
  String get calib_medindo => 'Midiendo tu mano...';

  @override
  String get calib_maoMedida => 'Mano medida';

  @override
  String get calib_larguraPalma => 'ANCHO DE LA PALMA';

  @override
  String get calib_confira =>
      'Comprueba que tenga sentido. Si se ve raro, repite la foto.';

  @override
  String get calib_salvar => 'GUARDAR CALIBRACIÓN';

  @override
  String get notif_solicitacoes => 'SOLICITUDES DE AMISTAD';

  @override
  String get notif_erroCarregar => 'Error al cargar';

  @override
  String get notif_nenhumaPendente => 'Ninguna solicitud pendiente';

  @override
  String get notif_querSerAmigo => 'quiere ser tu amigo';

  @override
  String get notif_noti => 'NOTIFI';

  @override
  String get notif_cacoes => 'CACIONES';

  @override
  String priv_naoFoiPossivelAbrir(String url) {
    return 'No se pudo abrir $url';
  }

  @override
  String get priv_contaExcluida => 'Cuenta y datos eliminados.';

  @override
  String get priv_naoFoiPossivelAtualizar => 'No se pudo actualizar';

  @override
  String get priv_naoFoiPossivelCarregar => 'No se pudo cargar';

  @override
  String get priv_exportaTudo =>
      'Exporta todo lo que guardamos sobre ti en JSON — perfil, entrenamientos, dieta, peso, puntos y consentimientos.';

  @override
  String get priv_apagaConta =>
      'Elimina la cuenta y todos los datos permanentemente. No se puede deshacer.';

  @override
  String get priv_faleComEncarregado =>
      'Para dudas o solicitudes sobre tus datos, contacta al encargado de protección de datos:';

  @override
  String priv_versaoDocs(String v) {
    return 'Versión de los documentos: $v';
  }

  @override
  String get priv_excluirConta => 'Eliminar cuenta';

  @override
  String get priv_itemPesoBio => '• Historial de peso y bioimpedancia\n';

  @override
  String get priv_itemTreinos =>
      '• Entrenamientos, plantillas y finalizaciones\n';

  @override
  String get priv_itemDieta => '• Registros de dieta y agua\n';

  @override
  String get priv_semBackup =>
      'No hay copia de seguridad ni forma de deshacer.';

  @override
  String priv_digiteParaConfirmar(String frase) {
    return 'Escribe $frase para confirmar:';
  }

  @override
  String get priv_excluir => 'Eliminar';

  @override
  String priv_exportacaoGerada(String kb) {
    return 'Exportación generada — $kb KB de JSON.';
  }

  @override
  String get priv_obrigatorioParaUsar =>
      'Obligatorio para usar la app — para retirarlo, elimina la cuenta.';

  @override
  String priv_aceitoNaVersao(String v) {
    return 'Aceptado en la versión $v — los documentos cambiaron desde entonces.';
  }

  @override
  String doc_versao(String v) {
    return 'Versión $v';
  }

  @override
  String get doc_roleAteOFim => 'Desplázate hasta el final para aceptar';

  @override
  String get erro_verifiqueConexao =>
      'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get tut_bemVindoTitulo => '¡Bienvenido a Muscle Champ!';

  @override
  String get tut_bemVindoCorpo =>
      'Tu hub de fitness gamificado. Gana puntos entrenando y comiendo bien, y sube en el ranking superando a tus amigos.';

  @override
  String get tut_pontosTitulo => 'Puntos, Rango y Racha';

  @override
  String get tut_pontosCorpo =>
      'Mira tus puntos acumulados, tu posición en el ranking global y entre amigos, y tu racha de días activos.';

  @override
  String get tut_treinosIaTitulo => 'Entrenamientos con IA';

  @override
  String get tut_treinosIaCorpo =>
      'Genera entrenamientos personalizados con IA o registra entrenamientos libres con series, repeticiones y cargas.';

  @override
  String get tut_gerarTreinoTitulo => 'Generar Entrenamiento con IA';

  @override
  String get tut_gerarTreinoCorpo =>
      'Toca \"Generar Entrenamiento\", elige el grupo muscular y la IA arma el plan completo con ejercicios, series y descanso.';

  @override
  String get tut_dietaTitulo => 'Dieta y Nutrición';

  @override
  String get tut_dietaCorpo =>
      'Registra todo lo que comes — por texto o foto — y la IA calcula calorías, proteínas, carbohidratos y grasas.';

  @override
  String get tut_refeicaoTextoTitulo => 'Registrar Comida por Texto';

  @override
  String get tut_refeicaoTextoCorpo =>
      'Describe lo que comiste (\"100g de pollo a la plancha + arroz blanco\") y la IA calcula los macros al instante.';

  @override
  String get tut_fotoTitulo => 'Foto del Plato — Análisis por IA';

  @override
  String get tut_fotoCorpo =>
      'Toma una foto de tu plato y la IA identifica los alimentos y estima automáticamente los macros y calorías.';

  @override
  String get tut_planoTitulo => 'Plan de Dieta con IA';

  @override
  String get tut_planoCorpo =>
      'Genera un menú completo para el día según tus metas. Cambia alimentos con un toque — la IA recalcula los macros para mantener las calorías.';

  @override
  String get tut_rankingTitulo => 'Ranking y Competición';

  @override
  String get tut_rankingCorpo =>
      '¡Compite por posiciones con todos los usuarios de la app. Cada entrenamiento registrado y meta de dieta alcanzada vale puntos!';

  @override
  String get tut_amigosTitulo => 'Ranking Global y Amigos';

  @override
  String get tut_amigosCorpo =>
      'Alterna entre el ranking global y el de solo amigos. Busca usuarios por nombre y envía solicitudes de amistad.';

  @override
  String get tut_perfilTitulo => 'Tu Perfil';

  @override
  String get tut_perfilCorpo =>
      'Configura tus datos físicos, define metas y personaliza tu foto de perfil para aparecer en el ranking.';

  @override
  String get tut_metasTitulo => 'Metas y Bioimpedancia';

  @override
  String get tut_metasCorpo =>
      'Define peso objetivo, calorías diarias y objetivo (ganar masa / perder peso / mantener). Registra medidas de bioimpedancia para seguir tu evolución corporal.';

  @override
  String get tut_comecar => '¡EMPEZAR!';

  @override
  String get tut_proximo => 'SIGUIENTE  →';

  @override
  String get priv_apagaPermanentemente => 'Esto elimina permanentemente:\n\n';

  @override
  String get priv_itemPerfil => '• Perfil, foto y metas\n';

  @override
  String get priv_itemPontos => '• Puntos, ranking y amistades\n\n';

  @override
  String get perfil_metaImc => 'Meta: IMC';

  @override
  String nivel_pontoParaNivelResto(int nivel) {
    return 'punto para el nivel $nivel';
  }

  @override
  String nivel_pontosParaNivelResto(int nivel) {
    return 'puntos para el nivel $nivel';
  }

  @override
  String get grupo_peito => 'Pecho';

  @override
  String get grupo_costas => 'Espalda';

  @override
  String get grupo_ombros => 'Hombros';

  @override
  String get grupo_biceps => 'Bíceps';

  @override
  String get grupo_triceps => 'Tríceps';

  @override
  String get grupo_pernas => 'Piernas';

  @override
  String get grupo_gluteos => 'Glúteos';

  @override
  String get grupo_core => 'Core';

  @override
  String get grupo_fullBody => 'Cuerpo Completo';
}
