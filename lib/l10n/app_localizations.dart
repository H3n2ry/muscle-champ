import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// No description provided for @navInicio.
  ///
  /// In pt, this message translates to:
  /// **'INÍCIO'**
  String get navInicio;

  /// No description provided for @navTreino.
  ///
  /// In pt, this message translates to:
  /// **'TREINO'**
  String get navTreino;

  /// No description provided for @navDieta.
  ///
  /// In pt, this message translates to:
  /// **'DIETA'**
  String get navDieta;

  /// No description provided for @navRanking.
  ///
  /// In pt, this message translates to:
  /// **'RANKING'**
  String get navRanking;

  /// No description provided for @navPerfil.
  ///
  /// In pt, this message translates to:
  /// **'PERFIL'**
  String get navPerfil;

  /// No description provided for @comum_salvar.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR'**
  String get comum_salvar;

  /// No description provided for @comum_cancelar.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get comum_cancelar;

  /// No description provided for @comum_excluir.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get comum_excluir;

  /// No description provided for @comum_fechar.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get comum_fechar;

  /// No description provided for @comum_copiar.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get comum_copiar;

  /// No description provided for @comum_proximo.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMO'**
  String get comum_proximo;

  /// No description provided for @comum_tentarNovamente.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get comum_tentarNovamente;

  /// No description provided for @comum_carregando.
  ///
  /// In pt, this message translates to:
  /// **'Carregando...'**
  String get comum_carregando;

  /// No description provided for @comum_semConexao.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet.'**
  String get comum_semConexao;

  /// No description provided for @comum_algoDeuErrado.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado. Tente novamente.'**
  String get comum_algoDeuErrado;

  /// No description provided for @idioma_titulo.
  ///
  /// In pt, this message translates to:
  /// **'IDIOMA'**
  String get idioma_titulo;

  /// No description provided for @idioma_portugues.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get idioma_portugues;

  /// No description provided for @idioma_ingles.
  ///
  /// In pt, this message translates to:
  /// **'Inglês'**
  String get idioma_ingles;

  /// No description provided for @idioma_espanhol.
  ///
  /// In pt, this message translates to:
  /// **'Espanhol'**
  String get idioma_espanhol;

  /// No description provided for @dash_bemVindo.
  ///
  /// In pt, this message translates to:
  /// **'BEM-VINDO,'**
  String get dash_bemVindo;

  /// No description provided for @dash_missaoDiaria.
  ///
  /// In pt, this message translates to:
  /// **'MISSÃO DIÁRIA'**
  String get dash_missaoDiaria;

  /// No description provided for @dash_comeceAgora.
  ///
  /// In pt, this message translates to:
  /// **'Começe agora'**
  String get dash_comeceAgora;

  /// No description provided for @dash_completo.
  ///
  /// In pt, this message translates to:
  /// **'completo'**
  String get dash_completo;

  /// No description provided for @dash_global.
  ///
  /// In pt, this message translates to:
  /// **'Global'**
  String get dash_global;

  /// No description provided for @dash_pts.
  ///
  /// In pt, this message translates to:
  /// **'{pontos} pts'**
  String dash_pts(int pontos);

  /// No description provided for @dash_treinosSemana.
  ///
  /// In pt, this message translates to:
  /// **'TREINOS\nSEMANA'**
  String get dash_treinosSemana;

  /// No description provided for @dash_pesoAtual.
  ///
  /// In pt, this message translates to:
  /// **'PESO\nATUAL'**
  String get dash_pesoAtual;

  /// No description provided for @dash_metaPeso.
  ///
  /// In pt, this message translates to:
  /// **'META\nPESO'**
  String get dash_metaPeso;

  /// No description provided for @dash_protocolosDiarios.
  ///
  /// In pt, this message translates to:
  /// **'PROTOCOLOS DIÁRIOS'**
  String get dash_protocolosDiarios;

  /// No description provided for @dash_proximoMarco.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMO MARCO'**
  String get dash_proximoMarco;

  /// No description provided for @dash_pontosParaNivel.
  ///
  /// In pt, this message translates to:
  /// **'{faltam} pontos para o nível {nivel}'**
  String dash_pontosParaNivel(int faltam, int nivel);

  /// No description provided for @dash_nivelMaximo.
  ///
  /// In pt, this message translates to:
  /// **'Nível máximo alcançado.'**
  String get dash_nivelMaximo;

  /// No description provided for @nivel_lvl.
  ///
  /// In pt, this message translates to:
  /// **'LVL {nivel}'**
  String nivel_lvl(int nivel);

  /// No description provided for @nivel_nivelN.
  ///
  /// In pt, this message translates to:
  /// **'NÍVEL {nivel}'**
  String nivel_nivelN(int nivel);

  /// No description provided for @nivel_pontoParaNivel.
  ///
  /// In pt, this message translates to:
  /// **'{faltam} ponto para o nível {nivel}'**
  String nivel_pontoParaNivel(int faltam, int nivel);

  /// No description provided for @nivel_pontosParaNivel.
  ///
  /// In pt, this message translates to:
  /// **'{faltam} pontos para o nível {nivel}'**
  String nivel_pontosParaNivel(int faltam, int nivel);

  /// No description provided for @perfil_pontos.
  ///
  /// In pt, this message translates to:
  /// **'PONTOS'**
  String get perfil_pontos;

  /// No description provided for @perfil_treinos.
  ///
  /// In pt, this message translates to:
  /// **'TREINOS'**
  String get perfil_treinos;

  /// No description provided for @perfil_sequencia.
  ///
  /// In pt, this message translates to:
  /// **'SEQUÊNCIA'**
  String get perfil_sequencia;

  /// No description provided for @perfil_diasConsecutivos.
  ///
  /// In pt, this message translates to:
  /// **'{dias} dias consecutivos'**
  String perfil_diasConsecutivos(int dias);

  /// No description provided for @perfil_imc.
  ///
  /// In pt, this message translates to:
  /// **'ÍNDICE DE MASSA CORPORAL'**
  String get perfil_imc;

  /// No description provided for @perfil_imcAtual.
  ///
  /// In pt, this message translates to:
  /// **'IMC ATUAL'**
  String get perfil_imcAtual;

  /// No description provided for @perfil_altura.
  ///
  /// In pt, this message translates to:
  /// **'ALTURA'**
  String get perfil_altura;

  /// No description provided for @perfil_peso.
  ///
  /// In pt, this message translates to:
  /// **'PESO'**
  String get perfil_peso;

  /// No description provided for @perfil_desde.
  ///
  /// In pt, this message translates to:
  /// **'DESDE {ano}'**
  String perfil_desde(String ano);

  /// No description provided for @perfil_evolucaoPontos.
  ///
  /// In pt, this message translates to:
  /// **'EVOLUÇÃO DE PONTOS'**
  String get perfil_evolucaoPontos;

  /// No description provided for @perfil_editarPerfil.
  ///
  /// In pt, this message translates to:
  /// **'Editar perfil'**
  String get perfil_editarPerfil;

  /// No description provided for @perfil_privacidadeDados.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade e dados'**
  String get perfil_privacidadeDados;

  /// No description provided for @perfil_sair.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get perfil_sair;

  /// No description provided for @perfil_semanaNaoCarregou.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a semana'**
  String get perfil_semanaNaoCarregou;

  /// No description provided for @objetivo_perderPeso.
  ///
  /// In pt, this message translates to:
  /// **'PERDA DE PESO'**
  String get objetivo_perderPeso;

  /// No description provided for @objetivo_ganharMassa.
  ///
  /// In pt, this message translates to:
  /// **'GANHO DE MASSA'**
  String get objetivo_ganharMassa;

  /// No description provided for @objetivo_manutencao.
  ///
  /// In pt, this message translates to:
  /// **'MANUTENÇÃO'**
  String get objetivo_manutencao;

  /// No description provided for @treino_missoes.
  ///
  /// In pt, this message translates to:
  /// **'MISSÕES'**
  String get treino_missoes;

  /// No description provided for @treino_titulo.
  ///
  /// In pt, this message translates to:
  /// **'TREINO'**
  String get treino_titulo;

  /// No description provided for @treino_meusTreinos.
  ///
  /// In pt, this message translates to:
  /// **'MEUS TREINOS'**
  String get treino_meusTreinos;

  /// No description provided for @treino_fazerHoje.
  ///
  /// In pt, this message translates to:
  /// **'FAZER HOJE'**
  String get treino_fazerHoje;

  /// No description provided for @treino_feitoHoje.
  ///
  /// In pt, this message translates to:
  /// **'FEITO HOJE'**
  String get treino_feitoHoje;

  /// No description provided for @treino_novoTreino.
  ///
  /// In pt, this message translates to:
  /// **'NOVO TREINO'**
  String get treino_novoTreino;

  /// No description provided for @treino_editarTreino.
  ///
  /// In pt, this message translates to:
  /// **'EDITAR TREINO'**
  String get treino_editarTreino;

  /// No description provided for @treino_nomeDoTreino.
  ///
  /// In pt, this message translates to:
  /// **'Nome do treino'**
  String get treino_nomeDoTreino;

  /// No description provided for @treino_exercicios.
  ///
  /// In pt, this message translates to:
  /// **'EXERCÍCIOS'**
  String get treino_exercicios;

  /// No description provided for @treino_exercicioN.
  ///
  /// In pt, this message translates to:
  /// **'Exercício {n}'**
  String treino_exercicioN(int n);

  /// No description provided for @treino_nomeExercicio.
  ///
  /// In pt, this message translates to:
  /// **'Nome do exercício'**
  String get treino_nomeExercicio;

  /// No description provided for @treino_series.
  ///
  /// In pt, this message translates to:
  /// **'Séries'**
  String get treino_series;

  /// No description provided for @treino_reps.
  ///
  /// In pt, this message translates to:
  /// **'Reps'**
  String get treino_reps;

  /// No description provided for @treino_pesoKg.
  ///
  /// In pt, this message translates to:
  /// **'Peso (kg)'**
  String get treino_pesoKg;

  /// No description provided for @treino_biblioteca.
  ///
  /// In pt, this message translates to:
  /// **'BIBLIOTECA'**
  String get treino_biblioteca;

  /// No description provided for @treino_manual.
  ///
  /// In pt, this message translates to:
  /// **'MANUAL'**
  String get treino_manual;

  /// No description provided for @treino_salvarTreino.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR TREINO'**
  String get treino_salvarTreino;

  /// No description provided for @treino_salvando.
  ///
  /// In pt, this message translates to:
  /// **'SALVANDO...'**
  String get treino_salvando;

  /// No description provided for @treino_concluirTreino.
  ///
  /// In pt, this message translates to:
  /// **'CONCLUIR TREINO'**
  String get treino_concluirTreino;

  /// No description provided for @treino_gerarComIa.
  ///
  /// In pt, this message translates to:
  /// **'GERAR COM IA'**
  String get treino_gerarComIa;

  /// No description provided for @treino_arrasteParaReordenar.
  ///
  /// In pt, this message translates to:
  /// **'Arraste para reordenar. Toque em ✓ para concluir.'**
  String get treino_arrasteParaReordenar;

  /// No description provided for @treino_jaRegistradoHoje.
  ///
  /// In pt, this message translates to:
  /// **'Treino já registrado hoje!'**
  String get treino_jaRegistradoHoje;

  /// No description provided for @treino_naoFoiPossivelExcluir.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível excluir o treino. Tente novamente.'**
  String get treino_naoFoiPossivelExcluir;

  /// No description provided for @treino_naoFoiPossivelCarregarExercicios.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os exercícios do treino.'**
  String get treino_naoFoiPossivelCarregarExercicios;

  /// No description provided for @treino_naoFoiPossivelSalvarOrdem.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar a ordem.'**
  String get treino_naoFoiPossivelSalvarOrdem;

  /// No description provided for @treino_exerciciosCount.
  ///
  /// In pt, this message translates to:
  /// **'{n} exercícios'**
  String treino_exerciciosCount(int n);

  /// No description provided for @treino_exercicioCount.
  ///
  /// In pt, this message translates to:
  /// **'{n} exercício'**
  String treino_exercicioCount(int n);

  /// No description provided for @dieta_registrarRefeicao.
  ///
  /// In pt, this message translates to:
  /// **'REGISTRAR REFEIÇÃO'**
  String get dieta_registrarRefeicao;

  /// No description provided for @dieta_banco.
  ///
  /// In pt, this message translates to:
  /// **'BANCO'**
  String get dieta_banco;

  /// No description provided for @dieta_ia.
  ///
  /// In pt, this message translates to:
  /// **'IA'**
  String get dieta_ia;

  /// No description provided for @dieta_foto.
  ///
  /// In pt, this message translates to:
  /// **'FOTO'**
  String get dieta_foto;

  /// No description provided for @dieta_descrevaAlimento.
  ///
  /// In pt, this message translates to:
  /// **'DESCREVA O ALIMENTO'**
  String get dieta_descrevaAlimento;

  /// No description provided for @dieta_calcularMacros.
  ///
  /// In pt, this message translates to:
  /// **'CALCULAR MACROS'**
  String get dieta_calcularMacros;

  /// No description provided for @dieta_calculando.
  ///
  /// In pt, this message translates to:
  /// **'CALCULANDO...'**
  String get dieta_calculando;

  /// No description provided for @dieta_adicionarRefeicao.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR REFEIÇÃO'**
  String get dieta_adicionarRefeicao;

  /// No description provided for @dieta_macrosDoDia.
  ///
  /// In pt, this message translates to:
  /// **'MACROS DO DIA'**
  String get dieta_macrosDoDia;

  /// No description provided for @dieta_calorias.
  ///
  /// In pt, this message translates to:
  /// **'CALORIAS'**
  String get dieta_calorias;

  /// No description provided for @dieta_proteina.
  ///
  /// In pt, this message translates to:
  /// **'PROTEÍNA'**
  String get dieta_proteina;

  /// No description provided for @dieta_carbo.
  ///
  /// In pt, this message translates to:
  /// **'CARBO'**
  String get dieta_carbo;

  /// No description provided for @dieta_gordura.
  ///
  /// In pt, this message translates to:
  /// **'GORDURA'**
  String get dieta_gordura;

  /// No description provided for @dieta_agua.
  ///
  /// In pt, this message translates to:
  /// **'ÁGUA'**
  String get dieta_agua;

  /// No description provided for @dieta_planoDoDia.
  ///
  /// In pt, this message translates to:
  /// **'PLANO DO DIA'**
  String get dieta_planoDoDia;

  /// No description provided for @dieta_exemploDescricao.
  ///
  /// In pt, this message translates to:
  /// **'Ex: \"200g de frango grelhado\"\n\"arroz integral com feijão\"'**
  String get dieta_exemploDescricao;

  /// No description provided for @cadastro_conta.
  ///
  /// In pt, this message translates to:
  /// **'CONTA'**
  String get cadastro_conta;

  /// No description provided for @cadastro_corpo.
  ///
  /// In pt, this message translates to:
  /// **'CORPO'**
  String get cadastro_corpo;

  /// No description provided for @cadastro_missao.
  ///
  /// In pt, this message translates to:
  /// **'MISSÃO'**
  String get cadastro_missao;

  /// No description provided for @cadastro_criarConta.
  ///
  /// In pt, this message translates to:
  /// **'CRIAR CONTA'**
  String get cadastro_criarConta;

  /// No description provided for @cadastro_privacidade.
  ///
  /// In pt, this message translates to:
  /// **'PRIVACIDADE'**
  String get cadastro_privacidade;

  /// No description provided for @cadastro_tratamosDadosSaude.
  ///
  /// In pt, this message translates to:
  /// **'O app trata dados de saúde. Precisamos da sua autorização explícita para isso.'**
  String get cadastro_tratamosDadosSaude;

  /// No description provided for @cadastro_marqueObrigatorios.
  ///
  /// In pt, this message translates to:
  /// **'Marque os itens obrigatórios (*) para continuar.'**
  String get cadastro_marqueObrigatorios;

  /// No description provided for @cadastro_liAceitoTodos.
  ///
  /// In pt, this message translates to:
  /// **'Li e aceito todos os termos'**
  String get cadastro_liAceitoTodos;

  /// No description provided for @cadastro_emailJaCadastrado.
  ///
  /// In pt, this message translates to:
  /// **'Este email já está cadastrado. Faça login.'**
  String get cadastro_emailJaCadastrado;

  /// No description provided for @cadastro_senhaRequisitos.
  ///
  /// In pt, this message translates to:
  /// **'A senha precisa ter no mínimo 8 caracteres, com letra minúscula, maiúscula, número e símbolo.'**
  String get cadastro_senhaRequisitos;

  /// No description provided for @cadastro_muitasTentativas.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Espere alguns minutos e tente de novo.'**
  String get cadastro_muitasTentativas;

  /// No description provided for @senha_minimo8.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get senha_minimo8;

  /// No description provided for @senha_minuscula.
  ///
  /// In pt, this message translates to:
  /// **'Letra minúscula (a-z)'**
  String get senha_minuscula;

  /// No description provided for @senha_maiuscula.
  ///
  /// In pt, this message translates to:
  /// **'Letra maiúscula (A-Z)'**
  String get senha_maiuscula;

  /// No description provided for @senha_numero.
  ///
  /// In pt, this message translates to:
  /// **'Número (0-9)'**
  String get senha_numero;

  /// No description provided for @senha_simbolo.
  ///
  /// In pt, this message translates to:
  /// **'Símbolo (!@#\$%...)'**
  String get senha_simbolo;

  /// No description provided for @privacidade_titulo.
  ///
  /// In pt, this message translates to:
  /// **'Privacidade e dados'**
  String get privacidade_titulo;

  /// No description provided for @privacidade_documentos.
  ///
  /// In pt, this message translates to:
  /// **'DOCUMENTOS'**
  String get privacidade_documentos;

  /// No description provided for @privacidade_seusConsentimentos.
  ///
  /// In pt, this message translates to:
  /// **'SEUS CONSENTIMENTOS'**
  String get privacidade_seusConsentimentos;

  /// No description provided for @privacidade_seusDireitos.
  ///
  /// In pt, this message translates to:
  /// **'SEUS DIREITOS'**
  String get privacidade_seusDireitos;

  /// No description provided for @privacidade_contato.
  ///
  /// In pt, this message translates to:
  /// **'CONTATO'**
  String get privacidade_contato;

  /// No description provided for @privacidade_baixarDados.
  ///
  /// In pt, this message translates to:
  /// **'Baixar meus dados'**
  String get privacidade_baixarDados;

  /// No description provided for @privacidade_excluirConta.
  ///
  /// In pt, this message translates to:
  /// **'Excluir minha conta'**
  String get privacidade_excluirConta;

  /// No description provided for @privacidade_politicaPrivacidade.
  ///
  /// In pt, this message translates to:
  /// **'Política de Privacidade'**
  String get privacidade_politicaPrivacidade;

  /// No description provided for @privacidade_termosUso.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso'**
  String get privacidade_termosUso;

  /// No description provided for @privacidade_verNoNavegador.
  ///
  /// In pt, this message translates to:
  /// **'Ver no navegador'**
  String get privacidade_verNoNavegador;

  /// No description provided for @privacidade_liEAceito.
  ///
  /// In pt, this message translates to:
  /// **'LI E ACEITO'**
  String get privacidade_liEAceito;

  /// No description provided for @privacidade_roleAteOFim.
  ///
  /// In pt, this message translates to:
  /// **'Role até o fim para aceitar'**
  String get privacidade_roleAteOFim;

  /// No description provided for @privacidade_versaoDocumentos.
  ///
  /// In pt, this message translates to:
  /// **'Versão {versao}'**
  String privacidade_versaoDocumentos(String versao);

  /// No description provided for @ranking_titulo.
  ///
  /// In pt, this message translates to:
  /// **'RANKING'**
  String get ranking_titulo;

  /// No description provided for @ranking_global.
  ///
  /// In pt, this message translates to:
  /// **'GLOBAL'**
  String get ranking_global;

  /// No description provided for @ranking_amigos.
  ///
  /// In pt, this message translates to:
  /// **'AMIGOS'**
  String get ranking_amigos;

  /// No description provided for @dash_atualizacaoSemanal.
  ///
  /// In pt, this message translates to:
  /// **'ATUALIZAÇÃO\nSEMANAL'**
  String get dash_atualizacaoSemanal;

  /// No description provided for @dash_registreSeuPeso.
  ///
  /// In pt, this message translates to:
  /// **'Registre seu peso desta semana\npara acompanhar sua evolução.'**
  String get dash_registreSeuPeso;

  /// No description provided for @dash_pular.
  ///
  /// In pt, this message translates to:
  /// **'PULAR'**
  String get dash_pular;

  /// No description provided for @dash_pesoInvalido.
  ///
  /// In pt, this message translates to:
  /// **'Peso inválido'**
  String get dash_pesoInvalido;

  /// No description provided for @dash_pesoAtualizado.
  ///
  /// In pt, this message translates to:
  /// **'Peso atualizado!'**
  String get dash_pesoAtualizado;

  /// No description provided for @treino_novoExercicio.
  ///
  /// In pt, this message translates to:
  /// **'NOVO EXERCÍCIO'**
  String get treino_novoExercicio;

  /// No description provided for @treino_grupoMuscular.
  ///
  /// In pt, this message translates to:
  /// **'GRUPO MUSCULAR'**
  String get treino_grupoMuscular;

  /// No description provided for @treino_exerciciosGerados.
  ///
  /// In pt, this message translates to:
  /// **'EXERCÍCIOS GERADOS'**
  String get treino_exerciciosGerados;

  /// No description provided for @treino_gerar.
  ///
  /// In pt, this message translates to:
  /// **'GERAR'**
  String get treino_gerar;

  /// No description provided for @treino_gerando.
  ///
  /// In pt, this message translates to:
  /// **'GERANDO...'**
  String get treino_gerando;

  /// No description provided for @treino_semTreinos.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum treino ainda'**
  String get treino_semTreinos;

  /// No description provided for @treino_crieOuGere.
  ///
  /// In pt, this message translates to:
  /// **'Crie manualmente ou gere com IA'**
  String get treino_crieOuGere;

  /// No description provided for @treino_criarManual.
  ///
  /// In pt, this message translates to:
  /// **'CRIAR MANUAL'**
  String get treino_criarManual;

  /// No description provided for @treino_buscarExercicio.
  ///
  /// In pt, this message translates to:
  /// **'Buscar exercício'**
  String get treino_buscarExercicio;

  /// No description provided for @treino_descanso.
  ///
  /// In pt, this message translates to:
  /// **'DESCANSO'**
  String get treino_descanso;

  /// No description provided for @ranking_semAmigos.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem amigos'**
  String get ranking_semAmigos;

  /// No description provided for @ranking_buscarUsuarios.
  ///
  /// In pt, this message translates to:
  /// **'Buscar usuários'**
  String get ranking_buscarUsuarios;

  /// No description provided for @ranking_adicionar.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR'**
  String get ranking_adicionar;

  /// No description provided for @ranking_pendente.
  ///
  /// In pt, this message translates to:
  /// **'PENDENTE'**
  String get ranking_pendente;

  /// No description provided for @ranking_aceitar.
  ///
  /// In pt, this message translates to:
  /// **'ACEITAR'**
  String get ranking_aceitar;

  /// No description provided for @ranking_recusar.
  ///
  /// In pt, this message translates to:
  /// **'RECUSAR'**
  String get ranking_recusar;

  /// No description provided for @perfil_conquistas.
  ///
  /// In pt, this message translates to:
  /// **'CONQUISTAS CHAMP'**
  String get perfil_conquistas;

  /// No description provided for @perfil_bioimpedancia.
  ///
  /// In pt, this message translates to:
  /// **'BIOIMPEDÂNCIA'**
  String get perfil_bioimpedancia;

  /// No description provided for @perfil_semDados.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados ainda'**
  String get perfil_semDados;

  /// No description provided for @login_slogan.
  ///
  /// In pt, this message translates to:
  /// **'Compete. Evolua. Domine.'**
  String get login_slogan;

  /// No description provided for @login_email.
  ///
  /// In pt, this message translates to:
  /// **'EMAIL'**
  String get login_email;

  /// No description provided for @login_senha.
  ///
  /// In pt, this message translates to:
  /// **'SENHA'**
  String get login_senha;

  /// No description provided for @login_emailHint.
  ///
  /// In pt, this message translates to:
  /// **'seu@email.com'**
  String get login_emailHint;

  /// No description provided for @login_entrar.
  ///
  /// In pt, this message translates to:
  /// **'ENTRAR'**
  String get login_entrar;

  /// No description provided for @login_criarConta.
  ///
  /// In pt, this message translates to:
  /// **'CRIAR CONTA'**
  String get login_criarConta;

  /// No description provided for @login_pillTreinos.
  ///
  /// In pt, this message translates to:
  /// **'Treinos'**
  String get login_pillTreinos;

  /// No description provided for @login_pillDieta.
  ///
  /// In pt, this message translates to:
  /// **'Dieta'**
  String get login_pillDieta;

  /// No description provided for @login_pillRanking.
  ///
  /// In pt, this message translates to:
  /// **'Ranking'**
  String get login_pillRanking;

  /// No description provided for @login_pillPontos.
  ///
  /// In pt, this message translates to:
  /// **'Pontos'**
  String get login_pillPontos;

  /// No description provided for @dieta_adicionarAlimento.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR ALIMENTO'**
  String get dieta_adicionarAlimento;

  /// No description provided for @dieta_adicionarARefeicao.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR À REFEIÇÃO'**
  String get dieta_adicionarARefeicao;

  /// No description provided for @dieta_ajustarPeso.
  ///
  /// In pt, this message translates to:
  /// **'AJUSTAR PESO'**
  String get dieta_ajustarPeso;

  /// No description provided for @dieta_alimento.
  ///
  /// In pt, this message translates to:
  /// **'ALIMENTO'**
  String get dieta_alimento;

  /// No description provided for @dieta_alterar.
  ///
  /// In pt, this message translates to:
  /// **'ALTERAR'**
  String get dieta_alterar;

  /// No description provided for @dieta_alterarAlimento.
  ///
  /// In pt, this message translates to:
  /// **'ALTERAR ALIMENTO'**
  String get dieta_alterarAlimento;

  /// No description provided for @dieta_adicioneRefeicoes.
  ///
  /// In pt, this message translates to:
  /// **'Adicione refeições e escolha os alimentos do banco'**
  String get dieta_adicioneRefeicoes;

  /// No description provided for @dieta_analisando.
  ///
  /// In pt, this message translates to:
  /// **'Analisando...'**
  String get dieta_analisando;

  /// No description provided for @dieta_buscarAlternativa.
  ///
  /// In pt, this message translates to:
  /// **'Buscar alternativa...'**
  String get dieta_buscarAlternativa;

  /// No description provided for @dieta_buscarNoBanco.
  ///
  /// In pt, this message translates to:
  /// **'Buscar no banco de alimentos'**
  String get dieta_buscarNoBanco;

  /// No description provided for @dieta_caloriasDoDia.
  ///
  /// In pt, this message translates to:
  /// **'CALORIAS DO DIA'**
  String get dieta_caloriasDoDia;

  /// No description provided for @dieta_carboidrato.
  ///
  /// In pt, this message translates to:
  /// **'CARBOIDRATO'**
  String get dieta_carboidrato;

  /// No description provided for @dieta_confirmar.
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMAR'**
  String get dieta_confirmar;

  /// No description provided for @dieta_carbAbrev.
  ///
  /// In pt, this message translates to:
  /// **'Carb'**
  String get dieta_carbAbrev;

  /// No description provided for @dieta_configureMeta.
  ///
  /// In pt, this message translates to:
  /// **'Configure sua meta calórica no perfil'**
  String get dieta_configureMeta;

  /// No description provided for @dieta_camera.
  ///
  /// In pt, this message translates to:
  /// **'CÂMERA'**
  String get dieta_camera;

  /// No description provided for @dieta_titulo.
  ///
  /// In pt, this message translates to:
  /// **'DIETA'**
  String get dieta_titulo;

  /// No description provided for @dieta_definaPeso.
  ///
  /// In pt, this message translates to:
  /// **'Defina seu peso no perfil para calcular a meta'**
  String get dieta_definaPeso;

  /// No description provided for @dieta_exBusca.
  ///
  /// In pt, this message translates to:
  /// **'Ex: frango, arroz, aveia...'**
  String get dieta_exBusca;

  /// No description provided for @dieta_fotoDoAlimento.
  ///
  /// In pt, this message translates to:
  /// **'FOTO DO ALIMENTO'**
  String get dieta_fotoDoAlimento;

  /// No description provided for @dieta_galeria.
  ///
  /// In pt, this message translates to:
  /// **'GALERIA'**
  String get dieta_galeria;

  /// No description provided for @dieta_gerarPlano.
  ///
  /// In pt, this message translates to:
  /// **'GERAR PLANO DO DIA'**
  String get dieta_gerarPlano;

  /// No description provided for @dieta_gerandoPlano.
  ///
  /// In pt, this message translates to:
  /// **'Gerando seu plano personalizado...'**
  String get dieta_gerandoPlano;

  /// No description provided for @dieta_gordAbrev.
  ///
  /// In pt, this message translates to:
  /// **'Gord'**
  String get dieta_gordAbrev;

  /// No description provided for @dieta_hidratacao.
  ///
  /// In pt, this message translates to:
  /// **'HIDRATAÇÃO'**
  String get dieta_hidratacao;

  /// No description provided for @dieta_iaAtiva.
  ///
  /// In pt, this message translates to:
  /// **'IA ATIVA'**
  String get dieta_iaAtiva;

  /// No description provided for @dieta_iaAtivaGroq.
  ///
  /// In pt, this message translates to:
  /// **'IA ATIVA · GROQ'**
  String get dieta_iaAtivaGroq;

  /// No description provided for @dieta_iaCalibrada.
  ///
  /// In pt, this message translates to:
  /// **'IA calibrada pela sua mão'**
  String get dieta_iaCalibrada;

  /// No description provided for @dieta_metaPts.
  ///
  /// In pt, this message translates to:
  /// **'META +10 PTS'**
  String get dieta_metaPts;

  /// No description provided for @dieta_metaOk.
  ///
  /// In pt, this message translates to:
  /// **'META ✓'**
  String get dieta_metaOk;

  /// No description provided for @dieta_monteSuaDieta.
  ///
  /// In pt, this message translates to:
  /// **'Monte sua própria dieta'**
  String get dieta_monteSuaDieta;

  /// No description provided for @dieta_novaRefeicao.
  ///
  /// In pt, this message translates to:
  /// **'NOVA REFEIÇÃO'**
  String get dieta_novaRefeicao;

  /// No description provided for @dieta_nutricao.
  ///
  /// In pt, this message translates to:
  /// **'NUTRIÇÃO'**
  String get dieta_nutricao;

  /// No description provided for @dieta_nenhumAlimento.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum alimento ainda'**
  String get dieta_nenhumAlimento;

  /// No description provided for @dieta_nenhumEncontrado.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum alimento encontrado'**
  String get dieta_nenhumEncontrado;

  /// No description provided for @dieta_nenhumaRefeicao.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma refeição registrada hoje'**
  String get dieta_nenhumaRefeicao;

  /// No description provided for @dieta_nomeDaRefeicao.
  ///
  /// In pt, this message translates to:
  /// **'Nome da refeição'**
  String get dieta_nomeDaRefeicao;

  /// No description provided for @dieta_erroHidratacao.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a hidratação.'**
  String get dieta_erroHidratacao;

  /// No description provided for @dieta_erroDieta.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar sua dieta.'**
  String get dieta_erroDieta;

  /// No description provided for @dieta_ouPersonalize.
  ///
  /// In pt, this message translates to:
  /// **'OU PERSONALIZE'**
  String get dieta_ouPersonalize;

  /// No description provided for @dieta_pesoGramas.
  ///
  /// In pt, this message translates to:
  /// **'PESO (gramas)'**
  String get dieta_pesoGramas;

  /// No description provided for @dieta_refeicoesDoDia.
  ///
  /// In pt, this message translates to:
  /// **'REFEIÇÕES DO DIA'**
  String get dieta_refeicoesDoDia;

  /// No description provided for @dieta_regenerar.
  ///
  /// In pt, this message translates to:
  /// **'REGENERAR'**
  String get dieta_regenerar;

  /// No description provided for @dieta_resultadoCalculado.
  ///
  /// In pt, this message translates to:
  /// **'RESULTADO CALCULADO'**
  String get dieta_resultadoCalculado;

  /// No description provided for @dieta_tamanhoPorcao.
  ///
  /// In pt, this message translates to:
  /// **'TAMANHO DA PORÇÃO (opcional)'**
  String get dieta_tamanhoPorcao;

  /// No description provided for @dieta_trocarAlimento.
  ///
  /// In pt, this message translates to:
  /// **'TROCAR ALIMENTO'**
  String get dieta_trocarAlimento;

  /// No description provided for @dieta_protAbrev.
  ///
  /// In pt, this message translates to:
  /// **'Prot'**
  String get dieta_protAbrev;

  /// No description provided for @dieta_pesoLabel.
  ///
  /// In pt, this message translates to:
  /// **'Peso'**
  String get dieta_pesoLabel;

  /// No description provided for @comum_tentar.
  ///
  /// In pt, this message translates to:
  /// **'Tentar'**
  String get comum_tentar;

  /// No description provided for @comum_limpar.
  ///
  /// In pt, this message translates to:
  /// **'limpar'**
  String get comum_limpar;

  /// No description provided for @dieta_recalibrar.
  ///
  /// In pt, this message translates to:
  /// **'recalibrar'**
  String get dieta_recalibrar;

  /// No description provided for @dieta_resetar.
  ///
  /// In pt, this message translates to:
  /// **'resetar'**
  String get dieta_resetar;

  /// No description provided for @rank_titulo.
  ///
  /// In pt, this message translates to:
  /// **'RANKINGS'**
  String get rank_titulo;

  /// No description provided for @rank_adicionar.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR'**
  String get rank_adicionar;

  /// No description provided for @rank_adicionarAmigo.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR AMIGO'**
  String get rank_adicionarAmigo;

  /// No description provided for @rank_aguardando.
  ///
  /// In pt, this message translates to:
  /// **'AGUARDANDO'**
  String get rank_aguardando;

  /// No description provided for @rank_amigo.
  ///
  /// In pt, this message translates to:
  /// **'AMIGO'**
  String get rank_amigo;

  /// No description provided for @rank_amigos.
  ///
  /// In pt, this message translates to:
  /// **'AMIGOS'**
  String get rank_amigos;

  /// No description provided for @rank_buscarAtleta.
  ///
  /// In pt, this message translates to:
  /// **'Buscar atleta...'**
  String get rank_buscarAtleta;

  /// No description provided for @rank_buscarPorNome.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por nome...'**
  String get rank_buscarPorNome;

  /// No description provided for @rank_cancelar.
  ///
  /// In pt, this message translates to:
  /// **'CANCELAR'**
  String get rank_cancelar;

  /// No description provided for @rank_elite.
  ///
  /// In pt, this message translates to:
  /// **'ELITE'**
  String get rank_elite;

  /// No description provided for @rank_erroCarregar.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar'**
  String get rank_erroCarregar;

  /// No description provided for @rank_global.
  ///
  /// In pt, this message translates to:
  /// **'GLOBAL'**
  String get rank_global;

  /// No description provided for @rank_remover.
  ///
  /// In pt, this message translates to:
  /// **'REMOVER'**
  String get rank_remover;

  /// No description provided for @rank_removerAmigo.
  ///
  /// In pt, this message translates to:
  /// **'Remover amigo?'**
  String get rank_removerAmigo;

  /// No description provided for @rank_voce.
  ///
  /// In pt, this message translates to:
  /// **'VOCÊ'**
  String get rank_voce;

  /// No description provided for @cad_compromisso.
  ///
  /// In pt, this message translates to:
  /// **'COMPROMISSO'**
  String get cad_compromisso;

  /// No description provided for @cad_comoTeChamam.
  ///
  /// In pt, this message translates to:
  /// **'Como te chamam?'**
  String get cad_comoTeChamam;

  /// No description provided for @cad_crieIdentidade.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua identidade de competidor'**
  String get cad_crieIdentidade;

  /// No description provided for @cad_imcCalculado.
  ///
  /// In pt, this message translates to:
  /// **'IMC CALCULADO'**
  String get cad_imcCalculado;

  /// No description provided for @cad_jaTenhoConta.
  ///
  /// In pt, this message translates to:
  /// **'Já tenho conta →'**
  String get cad_jaTenhoConta;

  /// No description provided for @cad_medidas.
  ///
  /// In pt, this message translates to:
  /// **'MEDIDAS'**
  String get cad_medidas;

  /// No description provided for @cad_objetivoDetectado.
  ///
  /// In pt, this message translates to:
  /// **'OBJETIVO DETECTADO'**
  String get cad_objetivoDetectado;

  /// No description provided for @cad_quem.
  ///
  /// In pt, this message translates to:
  /// **'QUEM'**
  String get cad_quem;

  /// No description provided for @cad_quantosDias.
  ///
  /// In pt, this message translates to:
  /// **'Quantos dias por semana você vai treinar?'**
  String get cad_quantosDias;

  /// No description provided for @cad_requisitosSenha.
  ///
  /// In pt, this message translates to:
  /// **'REQUISITOS DA SENHA'**
  String get cad_requisitosSenha;

  /// No description provided for @cad_seu.
  ///
  /// In pt, this message translates to:
  /// **'SEU'**
  String get cad_seu;

  /// No description provided for @cad_suas.
  ///
  /// In pt, this message translates to:
  /// **'SUAS'**
  String get cad_suas;

  /// No description provided for @cad_usadasPara.
  ///
  /// In pt, this message translates to:
  /// **'Usadas para IMC, meta calórica e hidratação'**
  String get cad_usadasPara;

  /// No description provided for @cad_eVoce.
  ///
  /// In pt, this message translates to:
  /// **'É VOCÊ?'**
  String get cad_eVoce;

  /// No description provided for @edit_altura.
  ///
  /// In pt, this message translates to:
  /// **'ALTURA'**
  String get edit_altura;

  /// No description provided for @edit_dadosPessoais.
  ///
  /// In pt, this message translates to:
  /// **'DADOS PESSOAIS'**
  String get edit_dadosPessoais;

  /// No description provided for @edit_dataNascimento.
  ///
  /// In pt, this message translates to:
  /// **'DATA DE NASCIMENTO'**
  String get edit_dataNascimento;

  /// No description provided for @edit_editar.
  ///
  /// In pt, this message translates to:
  /// **'EDITAR'**
  String get edit_editar;

  /// No description provided for @edit_imc.
  ///
  /// In pt, this message translates to:
  /// **'IMC'**
  String get edit_imc;

  /// No description provided for @edit_medidasCorporais.
  ///
  /// In pt, this message translates to:
  /// **'MEDIDAS CORPORAIS'**
  String get edit_medidasCorporais;

  /// No description provided for @edit_nome.
  ///
  /// In pt, this message translates to:
  /// **'NOME'**
  String get edit_nome;

  /// No description provided for @edit_objetivo.
  ///
  /// In pt, this message translates to:
  /// **'OBJETIVO'**
  String get edit_objetivo;

  /// No description provided for @edit_perfil.
  ///
  /// In pt, this message translates to:
  /// **'PERFIL'**
  String get edit_perfil;

  /// No description provided for @edit_pesoAlvo.
  ///
  /// In pt, this message translates to:
  /// **'PESO ALVO'**
  String get edit_pesoAlvo;

  /// No description provided for @edit_pesoAtual.
  ///
  /// In pt, this message translates to:
  /// **'PESO ATUAL'**
  String get edit_pesoAtual;

  /// No description provided for @edit_perfilAtualizado.
  ///
  /// In pt, this message translates to:
  /// **'Perfil atualizado com sucesso!'**
  String get edit_perfilAtualizado;

  /// No description provided for @edit_salvarAlteracoes.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR ALTERAÇÕES'**
  String get edit_salvarAlteracoes;

  /// No description provided for @objetivo_perdaPesoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Queimar gordura e definir o corpo'**
  String get objetivo_perdaPesoDesc;

  /// No description provided for @objetivo_manutencaoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Manter composição corporal atual'**
  String get objetivo_manutencaoDesc;

  /// No description provided for @objetivo_ganhoMassaDesc.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar músculo e força'**
  String get objetivo_ganhoMassaDesc;

  /// No description provided for @objetivo_perdaPeso.
  ///
  /// In pt, this message translates to:
  /// **'PERDA DE PESO'**
  String get objetivo_perdaPeso;

  /// No description provided for @objetivo_manutencaoUp.
  ///
  /// In pt, this message translates to:
  /// **'MANUTENÇÃO'**
  String get objetivo_manutencaoUp;

  /// No description provided for @objetivo_ganhoMassa.
  ///
  /// In pt, this message translates to:
  /// **'GANHO DE MASSA'**
  String get objetivo_ganhoMassa;

  /// No description provided for @objetivo_perderPesoCap.
  ///
  /// In pt, this message translates to:
  /// **'Perder Peso'**
  String get objetivo_perderPesoCap;

  /// No description provided for @objetivo_ganharMassaCap.
  ///
  /// In pt, this message translates to:
  /// **'Ganhar Massa'**
  String get objetivo_ganharMassaCap;

  /// No description provided for @objetivo_manutencaoCap.
  ///
  /// In pt, this message translates to:
  /// **'Manutenção'**
  String get objetivo_manutencaoCap;

  /// No description provided for @imc_abaixoPeso.
  ///
  /// In pt, this message translates to:
  /// **'Abaixo do peso'**
  String get imc_abaixoPeso;

  /// No description provided for @imc_normalOk.
  ///
  /// In pt, this message translates to:
  /// **'Normal ✓'**
  String get imc_normalOk;

  /// No description provided for @imc_pesoNormal.
  ///
  /// In pt, this message translates to:
  /// **'Peso normal'**
  String get imc_pesoNormal;

  /// No description provided for @imc_sobrepeso.
  ///
  /// In pt, this message translates to:
  /// **'Sobrepeso'**
  String get imc_sobrepeso;

  /// No description provided for @imc_obesidade1.
  ///
  /// In pt, this message translates to:
  /// **'Obesidade I'**
  String get imc_obesidade1;

  /// No description provided for @imc_obesidade2.
  ///
  /// In pt, this message translates to:
  /// **'Obesidade II+'**
  String get imc_obesidade2;

  /// No description provided for @imc_obesidadeGrau1.
  ///
  /// In pt, this message translates to:
  /// **'Obesidade grau I'**
  String get imc_obesidadeGrau1;

  /// No description provided for @imc_obesidadeGrau2.
  ///
  /// In pt, this message translates to:
  /// **'Obesidade grau II+'**
  String get imc_obesidadeGrau2;

  /// No description provided for @comum_obrigatorio.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório'**
  String get comum_obrigatorio;

  /// No description provided for @comum_emailInvalido.
  ///
  /// In pt, this message translates to:
  /// **'Email inválido'**
  String get comum_emailInvalido;

  /// No description provided for @comum_erro.
  ///
  /// In pt, this message translates to:
  /// **'Erro'**
  String get comum_erro;

  /// No description provided for @edit_seuNomeCompleto.
  ///
  /// In pt, this message translates to:
  /// **'Seu nome completo'**
  String get edit_seuNomeCompleto;

  /// No description provided for @edit_erroSalvar.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar. Tente novamente.'**
  String get edit_erroSalvar;

  /// No description provided for @rank_nenhumCompetidor.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum competidor ainda'**
  String get rank_nenhumCompetidor;

  /// No description provided for @rank_adicioneAmigos.
  ///
  /// In pt, this message translates to:
  /// **'Adicione amigos para competir!'**
  String get rank_adicioneAmigos;

  /// No description provided for @rank_digite2Letras.
  ///
  /// In pt, this message translates to:
  /// **'Digite pelo menos 2 letras'**
  String get rank_digite2Letras;

  /// No description provided for @rank_nenhumUsuario.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum usuário encontrado'**
  String get rank_nenhumUsuario;

  /// No description provided for @rank_pts.
  ///
  /// In pt, this message translates to:
  /// **'pts'**
  String get rank_pts;

  /// No description provided for @rank_maisAdicionar.
  ///
  /// In pt, this message translates to:
  /// **'+ ADICIONAR'**
  String get rank_maisAdicionar;

  /// No description provided for @rank_seraRemovido.
  ///
  /// In pt, this message translates to:
  /// **'{nome} será removido do seu ranking de amigos.'**
  String rank_seraRemovido(String nome);

  /// No description provided for @cad_informeNascimento.
  ///
  /// In pt, this message translates to:
  /// **'Informe sua data de nascimento'**
  String get cad_informeNascimento;

  /// No description provided for @cad_nomeGuerreiro.
  ///
  /// In pt, this message translates to:
  /// **'NOME DE GUERREIRO'**
  String get cad_nomeGuerreiro;

  /// No description provided for @cad_emailLabel.
  ///
  /// In pt, this message translates to:
  /// **'EMAIL'**
  String get cad_emailLabel;

  /// No description provided for @cad_senhaLabel.
  ///
  /// In pt, this message translates to:
  /// **'SENHA'**
  String get cad_senhaLabel;

  /// No description provided for @cad_alturaLabel.
  ///
  /// In pt, this message translates to:
  /// **'ALTURA'**
  String get cad_alturaLabel;

  /// No description provided for @cad_pesoAtualLabel.
  ///
  /// In pt, this message translates to:
  /// **'PESO ATUAL'**
  String get cad_pesoAtualLabel;

  /// No description provided for @cad_pesoAlvoLabel.
  ///
  /// In pt, this message translates to:
  /// **'PESO ALVO'**
  String get cad_pesoAlvoLabel;

  /// No description provided for @cad_dataNascimentoLabel.
  ///
  /// In pt, this message translates to:
  /// **'DATA DE NASCIMENTO'**
  String get cad_dataNascimentoLabel;

  /// No description provided for @cad_dias.
  ///
  /// In pt, this message translates to:
  /// **'dias'**
  String get cad_dias;

  /// No description provided for @cad_privacidadeLabel.
  ///
  /// In pt, this message translates to:
  /// **'PRIVACIDADE'**
  String get cad_privacidadeLabel;

  /// No description provided for @cad_stepConta.
  ///
  /// In pt, this message translates to:
  /// **'CONTA'**
  String get cad_stepConta;

  /// No description provided for @cad_stepCorpo.
  ///
  /// In pt, this message translates to:
  /// **'CORPO'**
  String get cad_stepCorpo;

  /// No description provided for @cad_stepMissao.
  ///
  /// In pt, this message translates to:
  /// **'MISSÃO'**
  String get cad_stepMissao;

  /// No description provided for @cad_emailJaCadastradoHifen.
  ///
  /// In pt, this message translates to:
  /// **'Este e-mail já está cadastrado. Faça login.'**
  String get cad_emailJaCadastradoHifen;

  /// No description provided for @cad_senhaFraca.
  ///
  /// In pt, this message translates to:
  /// **'A senha precisa ter no mínimo 8 caracteres, com letra minúscula, maiúscula, número e símbolo.'**
  String get cad_senhaFraca;

  /// No description provided for @cad_necessarioAceitar.
  ///
  /// In pt, this message translates to:
  /// **'É necessário aceitar todos os itens obrigatórios para criar a conta.'**
  String get cad_necessarioAceitar;

  /// No description provided for @cad_muitasTentativasEspere.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Espere alguns minutos e tente de novo.'**
  String get cad_muitasTentativasEspere;

  /// No description provided for @senha_errMin8.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get senha_errMin8;

  /// No description provided for @senha_errMinuscula.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de letra minúscula (a-z)'**
  String get senha_errMinuscula;

  /// No description provided for @senha_errMaiuscula.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de letra maiúscula (A-Z)'**
  String get senha_errMaiuscula;

  /// No description provided for @senha_errNumero.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de número (0-9)'**
  String get senha_errNumero;

  /// No description provided for @senha_errSimbolo.
  ///
  /// In pt, this message translates to:
  /// **'Precisa de símbolo (!@#\$%...)'**
  String get senha_errSimbolo;

  /// No description provided for @req_min8.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get req_min8;

  /// No description provided for @req_minuscula.
  ///
  /// In pt, this message translates to:
  /// **'Letra minúscula (a-z)'**
  String get req_minuscula;

  /// No description provided for @req_maiuscula.
  ///
  /// In pt, this message translates to:
  /// **'Letra maiúscula (A-Z)'**
  String get req_maiuscula;

  /// No description provided for @req_numero.
  ///
  /// In pt, this message translates to:
  /// **'Número (0-9)'**
  String get req_numero;

  /// No description provided for @req_simbolo.
  ///
  /// In pt, this message translates to:
  /// **'Símbolo (!@#\$%...)'**
  String get req_simbolo;

  /// No description provided for @freq_iniciante.
  ///
  /// In pt, this message translates to:
  /// **'Iniciante'**
  String get freq_iniciante;

  /// No description provided for @freq_regular.
  ///
  /// In pt, this message translates to:
  /// **'Regular'**
  String get freq_regular;

  /// No description provided for @freq_dedicado.
  ///
  /// In pt, this message translates to:
  /// **'Dedicado'**
  String get freq_dedicado;

  /// No description provided for @freq_avancado.
  ///
  /// In pt, this message translates to:
  /// **'Avançado'**
  String get freq_avancado;

  /// No description provided for @freq_elite.
  ///
  /// In pt, this message translates to:
  /// **'Elite'**
  String get freq_elite;

  /// No description provided for @dieta_digiteQualquerAlimento.
  ///
  /// In pt, this message translates to:
  /// **'Digite qualquer alimento ou tire uma foto'**
  String get dieta_digiteQualquerAlimento;

  /// No description provided for @dieta_calculeMacros.
  ///
  /// In pt, this message translates to:
  /// **'Calcule macros de qualquer alimento ou tire uma foto'**
  String get dieta_calculeMacros;

  /// No description provided for @dieta_faltamMl.
  ///
  /// In pt, this message translates to:
  /// **'Faltam {ml} ml para a meta de hoje'**
  String dieta_faltamMl(int ml);

  /// No description provided for @dieta_copo.
  ///
  /// In pt, this message translates to:
  /// **'Copo'**
  String get dieta_copo;

  /// No description provided for @dieta_caneca.
  ///
  /// In pt, this message translates to:
  /// **'Caneca'**
  String get dieta_caneca;

  /// No description provided for @dieta_garrafa.
  ///
  /// In pt, this message translates to:
  /// **'Garrafa'**
  String get dieta_garrafa;

  /// No description provided for @dieta_manual.
  ///
  /// In pt, this message translates to:
  /// **'MANUAL'**
  String get dieta_manual;

  /// No description provided for @dieta_ok.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get dieta_ok;

  /// No description provided for @dieta_log.
  ///
  /// In pt, this message translates to:
  /// **'+LOG'**
  String get dieta_log;

  /// No description provided for @dieta_refCafeManha.
  ///
  /// In pt, this message translates to:
  /// **'Café da Manhã'**
  String get dieta_refCafeManha;

  /// No description provided for @dieta_refLancheManha.
  ///
  /// In pt, this message translates to:
  /// **'Lanche da Manhã'**
  String get dieta_refLancheManha;

  /// No description provided for @dieta_refAlmoco.
  ///
  /// In pt, this message translates to:
  /// **'Almoço'**
  String get dieta_refAlmoco;

  /// No description provided for @dieta_refLancheTarde.
  ///
  /// In pt, this message translates to:
  /// **'Lanche da Tarde'**
  String get dieta_refLancheTarde;

  /// No description provided for @dieta_refJantar.
  ///
  /// In pt, this message translates to:
  /// **'Jantar'**
  String get dieta_refJantar;

  /// No description provided for @dieta_refCeia.
  ///
  /// In pt, this message translates to:
  /// **'Ceia'**
  String get dieta_refCeia;

  /// No description provided for @dieta_refPreTreino.
  ///
  /// In pt, this message translates to:
  /// **'Pré-treino'**
  String get dieta_refPreTreino;

  /// No description provided for @dieta_refPosTreino.
  ///
  /// In pt, this message translates to:
  /// **'Pós-treino'**
  String get dieta_refPosTreino;

  /// No description provided for @dieta_iaCriaDieta.
  ///
  /// In pt, this message translates to:
  /// **'A IA cria uma dieta personalizada para {kcal} kcal'**
  String dieta_iaCriaDieta(int kcal);

  /// No description provided for @dieta_metaKcal.
  ///
  /// In pt, this message translates to:
  /// **'META {kcal} kcal'**
  String dieta_metaKcal(int kcal);

  /// No description provided for @dieta_pesoRecalculado.
  ///
  /// In pt, this message translates to:
  /// **'Peso recalculado para manter ~{kcal} kcal do alimento original'**
  String dieta_pesoRecalculado(int kcal);

  /// No description provided for @dieta_sessaoExpirada.
  ///
  /// In pt, this message translates to:
  /// **'Sessão expirada. Faça login novamente.'**
  String get dieta_sessaoExpirada;

  /// No description provided for @dieta_naoFoiPossivelCalcular.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível calcular. Tente novamente.'**
  String get dieta_naoFoiPossivelCalcular;

  /// No description provided for @dieta_calibrarMoeda.
  ///
  /// In pt, this message translates to:
  /// **'Calibrar a IA com uma moeda deixa a análise mais precisa'**
  String get dieta_calibrarMoeda;

  /// No description provided for @dieta_alimentoGenerico.
  ///
  /// In pt, this message translates to:
  /// **'Alimento'**
  String get dieta_alimentoGenerico;

  /// No description provided for @dieta_alimentoFoto.
  ///
  /// In pt, this message translates to:
  /// **'Alimento (foto)'**
  String get dieta_alimentoFoto;

  /// No description provided for @dieta_adicionarKcal.
  ///
  /// In pt, this message translates to:
  /// **'ADICIONAR  •  {kcal} kcal'**
  String dieta_adicionarKcal(Object kcal);

  /// No description provided for @dieta_por100g.
  ///
  /// In pt, this message translates to:
  /// **'Por 100g:'**
  String get dieta_por100g;

  /// No description provided for @dieta_porcaoPequena.
  ///
  /// In pt, this message translates to:
  /// **'PEQUENA'**
  String get dieta_porcaoPequena;

  /// No description provided for @dieta_porcaoMedia.
  ///
  /// In pt, this message translates to:
  /// **'MÉDIA'**
  String get dieta_porcaoMedia;

  /// No description provided for @dieta_porcaoGrande.
  ///
  /// In pt, this message translates to:
  /// **'GRANDE'**
  String get dieta_porcaoGrande;

  /// No description provided for @dieta_porcaoPrato.
  ///
  /// In pt, this message translates to:
  /// **'PRATO'**
  String get dieta_porcaoPrato;

  /// No description provided for @dieta_dicaGarfo.
  ///
  /// In pt, this message translates to:
  /// **'Dica: coloque um garfo, colher ou a mão perto do alimento para melhor estimativa de peso.'**
  String get dieta_dicaGarfo;

  /// No description provided for @dieta_visaoIa.
  ///
  /// In pt, this message translates to:
  /// **'VISÃO IA'**
  String get dieta_visaoIa;

  /// No description provided for @perfil_erroCarregar.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar perfil'**
  String get perfil_erroCarregar;

  /// No description provided for @perfil_erroFoto.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar foto'**
  String get perfil_erroFoto;

  /// No description provided for @perfil_sequenciaAtiva.
  ///
  /// In pt, this message translates to:
  /// **'SEQUÊNCIA ATIVA'**
  String get perfil_sequenciaAtiva;

  /// No description provided for @perfil_metaComposicao.
  ///
  /// In pt, this message translates to:
  /// **'META DE COMPOSIÇÃO'**
  String get perfil_metaComposicao;

  /// No description provided for @perfil_bioimpedanciaCorporal.
  ///
  /// In pt, this message translates to:
  /// **'BIOIMPEDÂNCIA CORPORAL'**
  String get perfil_bioimpedanciaCorporal;

  /// No description provided for @perfil_sistemaPontuacao.
  ///
  /// In pt, this message translates to:
  /// **'SISTEMA DE PONTUAÇÃO'**
  String get perfil_sistemaPontuacao;

  /// No description provided for @perfil_registreComposicao.
  ///
  /// In pt, this message translates to:
  /// **'Registre sua composição corporal'**
  String get perfil_registreComposicao;

  /// No description provided for @perfil_composicaoCorporal.
  ///
  /// In pt, this message translates to:
  /// **'COMPOSIÇÃO CORPORAL'**
  String get perfil_composicaoCorporal;

  /// No description provided for @perfil_musculo.
  ///
  /// In pt, this message translates to:
  /// **'MÚSCULO'**
  String get perfil_musculo;

  /// No description provided for @perfil_hidratacao.
  ///
  /// In pt, this message translates to:
  /// **'HIDRATAÇÃO'**
  String get perfil_hidratacao;

  /// No description provided for @perfil_ossea.
  ///
  /// In pt, this message translates to:
  /// **'ÓSSEA'**
  String get perfil_ossea;

  /// No description provided for @perfil_massaOssea.
  ///
  /// In pt, this message translates to:
  /// **'MASSA ÓSSEA'**
  String get perfil_massaOssea;

  /// No description provided for @perfil_bioimpedanciaUp.
  ///
  /// In pt, this message translates to:
  /// **'BIOIMPEDÂNCIA'**
  String get perfil_bioimpedanciaUp;

  /// No description provided for @perfil_preenchaValores.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os valores gerados pelo aparelho de bioimpedância. Todos os campos são opcionais.'**
  String get perfil_preenchaValores;

  /// No description provided for @perfil_nivelMinusculo.
  ///
  /// In pt, this message translates to:
  /// **'nível'**
  String get perfil_nivelMinusculo;

  /// No description provided for @perfil_nivelN2.
  ///
  /// In pt, this message translates to:
  /// **'Nível {n}'**
  String perfil_nivelN2(int n);

  /// No description provided for @perfil_salvarBioimpedancia.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR BIOIMPEDÂNCIA'**
  String get perfil_salvarBioimpedancia;

  /// No description provided for @perfil_pontosTreino.
  ///
  /// In pt, this message translates to:
  /// **'Treino concluído'**
  String get perfil_pontosTreino;

  /// No description provided for @perfil_pontosDieta.
  ///
  /// In pt, this message translates to:
  /// **'Meta de dieta atingida'**
  String get perfil_pontosDieta;

  /// No description provided for @perfil_pontosProgressao.
  ///
  /// In pt, this message translates to:
  /// **'Progressão de carga (por exercício)'**
  String get perfil_pontosProgressao;

  /// No description provided for @perfil_pontosEvolucao.
  ///
  /// In pt, this message translates to:
  /// **'Evolução de peso na direção da meta'**
  String get perfil_pontosEvolucao;

  /// No description provided for @perfil_comKg.
  ///
  /// In pt, this message translates to:
  /// **'com {kg} kg'**
  String perfil_comKg(String kg);

  /// No description provided for @perfil_nivelMaximoAlcancado.
  ///
  /// In pt, this message translates to:
  /// **'Nível máximo alcançado.'**
  String get perfil_nivelMaximoAlcancado;

  /// No description provided for @perfil_percentualObjetivo.
  ///
  /// In pt, this message translates to:
  /// **'{pct}% do objetivo'**
  String perfil_percentualObjetivo(String pct);

  /// No description provided for @perfil_sequencia7Dias.
  ///
  /// In pt, this message translates to:
  /// **'SEQUÊNCIA\nDE 7 DIAS'**
  String get perfil_sequencia7Dias;

  /// No description provided for @treino_arrasteEConclua.
  ///
  /// In pt, this message translates to:
  /// **'Arraste para reordenar. Toque em ✓ para concluir.'**
  String get treino_arrasteEConclua;

  /// No description provided for @treino_naoFoiPossivelExcluirTreino.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível excluir o treino. Tente novamente.'**
  String get treino_naoFoiPossivelExcluirTreino;

  /// No description provided for @treino_ptsComProgressao.
  ///
  /// In pt, this message translates to:
  /// **'+10 pts  +{extra} pts por progressão!'**
  String treino_ptsComProgressao(int extra);

  /// No description provided for @treino_concluidoPts.
  ///
  /// In pt, this message translates to:
  /// **'Treino concluído! +10 pts'**
  String get treino_concluidoPts;

  /// No description provided for @treino_sessaoExpirada.
  ///
  /// In pt, this message translates to:
  /// **'Sessão expirada. Faça login novamente.'**
  String get treino_sessaoExpirada;

  /// No description provided for @treino_erroGerar.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar treino. Tente novamente.'**
  String get treino_erroGerar;

  /// No description provided for @treino_ouDescreva.
  ///
  /// In pt, this message translates to:
  /// **'Ou descreva: \"Peito e Tríceps pesado\"'**
  String get treino_ouDescreva;

  /// No description provided for @treino_cargasNaHora.
  ///
  /// In pt, this message translates to:
  /// **'As cargas serão preenchidas na hora do treino.'**
  String get treino_cargasNaHora;

  /// No description provided for @treino_excluirTreino.
  ///
  /// In pt, this message translates to:
  /// **'Excluir treino?'**
  String get treino_excluirTreino;

  /// No description provided for @treino_seraRemovido.
  ///
  /// In pt, this message translates to:
  /// **'O treino \"{nome}\" será removido.'**
  String treino_seraRemovido(String nome);

  /// No description provided for @treino_nenhumCriado.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum treino criado'**
  String get treino_nenhumCriado;

  /// No description provided for @treino_crieOuIa.
  ///
  /// In pt, this message translates to:
  /// **'Crie manualmente ou deixe a IA montar um treino pra você'**
  String get treino_crieOuIa;

  /// No description provided for @treino_exNome.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Peito e Tríceps'**
  String get treino_exNome;

  /// No description provided for @treino_toqueBiblioteca.
  ///
  /// In pt, this message translates to:
  /// **'Toque para escolher da biblioteca'**
  String get treino_toqueBiblioteca;

  /// No description provided for @treino_bibliotecaExercicios.
  ///
  /// In pt, this message translates to:
  /// **'BIBLIOTECA DE EXERCÍCIOS'**
  String get treino_bibliotecaExercicios;

  /// No description provided for @treino_buscarExercicioHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar exercício...'**
  String get treino_buscarExercicioHint;

  /// No description provided for @treino_nenhumExercicioEncontrado.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum exercício encontrado'**
  String get treino_nenhumExercicioEncontrado;

  /// No description provided for @treino_exercicioNumero.
  ///
  /// In pt, this message translates to:
  /// **'Exercício {n}'**
  String treino_exercicioNumero(int n);

  /// No description provided for @treino_nomeDoExercicio.
  ///
  /// In pt, this message translates to:
  /// **'Nome do exercício'**
  String get treino_nomeDoExercicio;

  /// No description provided for @treino_seriesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Séries'**
  String get treino_seriesLabel;

  /// No description provided for @treino_atualizeCargas.
  ///
  /// In pt, this message translates to:
  /// **'Atualize as cargas se necessário'**
  String get treino_atualizeCargas;

  /// No description provided for @treino_exerciciosParen.
  ///
  /// In pt, this message translates to:
  /// **'{n} exercício(s)'**
  String treino_exerciciosParen(int n);

  /// No description provided for @treino_treinoUp.
  ///
  /// In pt, this message translates to:
  /// **'TREINO'**
  String get treino_treinoUp;

  /// No description provided for @treino_treinoComIa.
  ///
  /// In pt, this message translates to:
  /// **'TREINO COM IA'**
  String get treino_treinoComIa;

  /// No description provided for @dash_atualizacaoSemanalQuebra.
  ///
  /// In pt, this message translates to:
  /// **'ATUALIZAÇÃO\nSEMANAL'**
  String get dash_atualizacaoSemanalQuebra;

  /// No description provided for @dash_registrePesoSemana.
  ///
  /// In pt, this message translates to:
  /// **'Registre seu peso desta semana\npara acompanhar sua evolução.'**
  String get dash_registrePesoSemana;

  /// No description provided for @dash_pesoInvalidoMsg.
  ///
  /// In pt, this message translates to:
  /// **'Peso inválido'**
  String get dash_pesoInvalidoMsg;

  /// No description provided for @dash_concluida.
  ///
  /// In pt, this message translates to:
  /// **'Concluída!'**
  String get dash_concluida;

  /// No description provided for @dash_historicoPontos.
  ///
  /// In pt, this message translates to:
  /// **'HISTÓRICO DE PONTOS'**
  String get dash_historicoPontos;

  /// No description provided for @dash_pesoAtualQuebra.
  ///
  /// In pt, this message translates to:
  /// **'PESO\nATUAL'**
  String get dash_pesoAtualQuebra;

  /// No description provided for @dash_erroCarregar.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar'**
  String get dash_erroCarregar;

  /// No description provided for @conf_digite8.
  ///
  /// In pt, this message translates to:
  /// **'Digite todos os 8 dígitos'**
  String get conf_digite8;

  /// No description provided for @conf_codigoInvalido.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido ou expirado. Verifique e tente novamente.'**
  String get conf_codigoInvalido;

  /// No description provided for @conf_codigoReenviado.
  ///
  /// In pt, this message translates to:
  /// **'Código reenviado para {email}'**
  String conf_codigoReenviado(String email);

  /// No description provided for @conf_erroReenviar.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao reenviar o código. Tente novamente.'**
  String get conf_erroReenviar;

  /// No description provided for @conf_enviamosCodigo.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um código de 8 dígitos para:'**
  String get conf_enviamosCodigo;

  /// No description provided for @conf_reenviarEm.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar código em {seg}s'**
  String conf_reenviarEm(int seg);

  /// No description provided for @conf_naoRecebeu.
  ///
  /// In pt, this message translates to:
  /// **'Não recebeu o código? Reenviar'**
  String get conf_naoRecebeu;

  /// No description provided for @login_credenciaisInvalidas.
  ///
  /// In pt, this message translates to:
  /// **'Email ou senha incorretos. Verifique e tente novamente.'**
  String get login_credenciaisInvalidas;

  /// No description provided for @login_confirmeEmail.
  ///
  /// In pt, this message translates to:
  /// **'Confirme seu email antes de entrar. Verifique sua caixa de entrada.'**
  String get login_confirmeEmail;

  /// No description provided for @login_contaNaoEncontrada.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma conta encontrada com este email.'**
  String get login_contaNaoEncontrada;

  /// No description provided for @login_semInternet.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com a internet. Verifique sua rede.'**
  String get login_semInternet;

  /// No description provided for @login_muitasTentativas.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Aguarde alguns minutos e tente novamente.'**
  String get login_muitasTentativas;

  /// No description provided for @login_minimo6.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get login_minimo6;

  /// No description provided for @cad_emailPlaceholder.
  ///
  /// In pt, this message translates to:
  /// **'seu@email.com'**
  String get cad_emailPlaceholder;

  /// No description provided for @calib_sessaoExpirada.
  ///
  /// In pt, this message translates to:
  /// **'Sessão expirada. Faça login novamente.'**
  String get calib_sessaoExpirada;

  /// No description provided for @calib_naoViMoeda.
  ///
  /// In pt, this message translates to:
  /// **'Não consegui ver a moeda e a mão claramente. Tente de novo com boa luz, moeda bem no centro da palma.'**
  String get calib_naoViMoeda;

  /// No description provided for @calib_naoFoiPossivel.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível calibrar. Tente novamente.'**
  String get calib_naoFoiPossivel;

  /// No description provided for @calib_sucesso.
  ///
  /// In pt, this message translates to:
  /// **'IA calibrada! As análises de foto ficarão mais precisas.'**
  String get calib_sucesso;

  /// No description provided for @calib_naoFoiPossivelSalvar.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar. Tente novamente.'**
  String get calib_naoFoiPossivelSalvar;

  /// No description provided for @calib_explicacao.
  ///
  /// In pt, this message translates to:
  /// **'A IA aprende o tamanho da sua mão usando uma moeda como régua. Depois, ela usa sua mão como referência para estimar as porções com mais precisão. É só uma vez.'**
  String get calib_explicacao;

  /// No description provided for @calib_abraPalma.
  ///
  /// In pt, this message translates to:
  /// **'Abra a palma e coloque a moeda no centro. Boa luz, foto de cima.'**
  String get calib_abraPalma;

  /// No description provided for @calib_camera.
  ///
  /// In pt, this message translates to:
  /// **'CÂMERA'**
  String get calib_camera;

  /// No description provided for @calib_medindo.
  ///
  /// In pt, this message translates to:
  /// **'Medindo sua mão...'**
  String get calib_medindo;

  /// No description provided for @calib_maoMedida.
  ///
  /// In pt, this message translates to:
  /// **'Mão medida'**
  String get calib_maoMedida;

  /// No description provided for @calib_larguraPalma.
  ///
  /// In pt, this message translates to:
  /// **'LARGURA DA PALMA'**
  String get calib_larguraPalma;

  /// No description provided for @calib_confira.
  ///
  /// In pt, this message translates to:
  /// **'Confira se faz sentido. Se estiver estranho, refaça a foto.'**
  String get calib_confira;

  /// No description provided for @calib_salvar.
  ///
  /// In pt, this message translates to:
  /// **'SALVAR CALIBRAÇÃO'**
  String get calib_salvar;

  /// No description provided for @notif_solicitacoes.
  ///
  /// In pt, this message translates to:
  /// **'SOLICITAÇÕES DE AMIZADE'**
  String get notif_solicitacoes;

  /// No description provided for @notif_erroCarregar.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar'**
  String get notif_erroCarregar;

  /// No description provided for @notif_nenhumaPendente.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma solicitação pendente'**
  String get notif_nenhumaPendente;

  /// No description provided for @notif_querSerAmigo.
  ///
  /// In pt, this message translates to:
  /// **'quer ser seu amigo'**
  String get notif_querSerAmigo;

  /// No description provided for @notif_noti.
  ///
  /// In pt, this message translates to:
  /// **'NOTIFI'**
  String get notif_noti;

  /// No description provided for @notif_cacoes.
  ///
  /// In pt, this message translates to:
  /// **'CAÇÕES'**
  String get notif_cacoes;

  /// No description provided for @priv_naoFoiPossivelAbrir.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir {url}'**
  String priv_naoFoiPossivelAbrir(String url);

  /// No description provided for @priv_contaExcluida.
  ///
  /// In pt, this message translates to:
  /// **'Conta e dados excluídos.'**
  String get priv_contaExcluida;

  /// No description provided for @priv_naoFoiPossivelAtualizar.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar'**
  String get priv_naoFoiPossivelAtualizar;

  /// No description provided for @priv_naoFoiPossivelCarregar.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar'**
  String get priv_naoFoiPossivelCarregar;

  /// No description provided for @priv_exportaTudo.
  ///
  /// In pt, this message translates to:
  /// **'Exporta tudo que guardamos sobre você em JSON — perfil, treinos, dieta, peso, pontos e consentimentos.'**
  String get priv_exportaTudo;

  /// No description provided for @priv_apagaConta.
  ///
  /// In pt, this message translates to:
  /// **'Apaga a conta e todos os dados permanentemente. Não há como desfazer.'**
  String get priv_apagaConta;

  /// No description provided for @priv_faleComEncarregado.
  ///
  /// In pt, this message translates to:
  /// **'Para dúvidas ou pedidos sobre seus dados, fale com o encarregado de proteção de dados:'**
  String get priv_faleComEncarregado;

  /// No description provided for @priv_versaoDocs.
  ///
  /// In pt, this message translates to:
  /// **'Versão dos documentos: {v}'**
  String priv_versaoDocs(String v);

  /// No description provided for @priv_excluirConta.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get priv_excluirConta;

  /// No description provided for @priv_itemPesoBio.
  ///
  /// In pt, this message translates to:
  /// **'• Histórico de peso e bioimpedância\n'**
  String get priv_itemPesoBio;

  /// No description provided for @priv_itemTreinos.
  ///
  /// In pt, this message translates to:
  /// **'• Treinos, modelos e conclusões\n'**
  String get priv_itemTreinos;

  /// No description provided for @priv_itemDieta.
  ///
  /// In pt, this message translates to:
  /// **'• Registros de dieta e água\n'**
  String get priv_itemDieta;

  /// No description provided for @priv_semBackup.
  ///
  /// In pt, this message translates to:
  /// **'Não há backup e não há como desfazer.'**
  String get priv_semBackup;

  /// No description provided for @priv_digiteParaConfirmar.
  ///
  /// In pt, this message translates to:
  /// **'Digite {frase} para confirmar:'**
  String priv_digiteParaConfirmar(String frase);

  /// No description provided for @priv_excluir.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get priv_excluir;

  /// No description provided for @priv_exportacaoGerada.
  ///
  /// In pt, this message translates to:
  /// **'Exportação gerada — {kb} KB de JSON.'**
  String priv_exportacaoGerada(String kb);

  /// No description provided for @priv_obrigatorioParaUsar.
  ///
  /// In pt, this message translates to:
  /// **'Obrigatório para usar o app — para retirar, exclua a conta.'**
  String get priv_obrigatorioParaUsar;

  /// No description provided for @priv_aceitoNaVersao.
  ///
  /// In pt, this message translates to:
  /// **'Aceito na versão {v} — os documentos mudaram desde então.'**
  String priv_aceitoNaVersao(String v);

  /// No description provided for @doc_versao.
  ///
  /// In pt, this message translates to:
  /// **'Versão {v}'**
  String doc_versao(String v);

  /// No description provided for @doc_roleAteOFim.
  ///
  /// In pt, this message translates to:
  /// **'Role até o fim para aceitar'**
  String get doc_roleAteOFim;

  /// No description provided for @erro_verifiqueConexao.
  ///
  /// In pt, this message translates to:
  /// **'Verifique sua conexão e tente novamente.'**
  String get erro_verifiqueConexao;

  /// No description provided for @tut_bemVindoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo ao Muscle Champ!'**
  String get tut_bemVindoTitulo;

  /// No description provided for @tut_bemVindoCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Seu hub de fitness gamificado. Ganhe pontos treinando e comendo bem, e suba no ranking superando seus amigos.'**
  String get tut_bemVindoCorpo;

  /// No description provided for @tut_pontosTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Pontos, Rank e Streak'**
  String get tut_pontosTitulo;

  /// No description provided for @tut_pontosCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Veja aqui seus pontos acumulados, posição no ranking global e entre amigos, e sua sequência de dias ativos.'**
  String get tut_pontosCorpo;

  /// No description provided for @tut_treinosIaTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Treinos com IA'**
  String get tut_treinosIaTitulo;

  /// No description provided for @tut_treinosIaCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Gere treinos personalizados com inteligência artificial ou registre treinos livres com séries, repetições e cargas.'**
  String get tut_treinosIaCorpo;

  /// No description provided for @tut_gerarTreinoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Gerar Treino com IA'**
  String get tut_gerarTreinoTitulo;

  /// No description provided for @tut_gerarTreinoCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Gerar Treino\", escolha o grupo muscular e a IA monta o plano completo com exercícios, séries e descanso.'**
  String get tut_gerarTreinoCorpo;

  /// No description provided for @tut_dietaTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Dieta e Nutrição'**
  String get tut_dietaTitulo;

  /// No description provided for @tut_dietaCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Registre tudo que você come — por texto ou foto — e a IA calcula calorias, proteínas, carboidratos e gorduras.'**
  String get tut_dietaCorpo;

  /// No description provided for @tut_refeicaoTextoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Refeição por Texto'**
  String get tut_refeicaoTextoTitulo;

  /// No description provided for @tut_refeicaoTextoCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Descreva o que comeu (\"100g frango grelhado + arroz branco\") e a IA calcula os macros na hora.'**
  String get tut_refeicaoTextoCorpo;

  /// No description provided for @tut_fotoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Foto do Prato — Análise por IA'**
  String get tut_fotoTitulo;

  /// No description provided for @tut_fotoCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Tire uma foto do seu prato e a IA identifica os alimentos e estima automaticamente os macros e calorias.'**
  String get tut_fotoCorpo;

  /// No description provided for @tut_planoTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Plano de Dieta com IA'**
  String get tut_planoTitulo;

  /// No description provided for @tut_planoCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Gere um cardápio completo para o dia baseado nas suas metas. Troque alimentos com um toque — a IA recalcula os macros para manter as calorias.'**
  String get tut_planoCorpo;

  /// No description provided for @tut_rankingTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Ranking e Competição'**
  String get tut_rankingTitulo;

  /// No description provided for @tut_rankingCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Dispute posições com todos os usuários do app. Cada treino registrado e meta de dieta atingida vale pontos!'**
  String get tut_rankingCorpo;

  /// No description provided for @tut_amigosTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Ranking Global e Amigos'**
  String get tut_amigosTitulo;

  /// No description provided for @tut_amigosCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Alterne entre o ranking global e o ranking só com seus amigos. Busque usuários pelo nome e mande solicitação de amizade.'**
  String get tut_amigosCorpo;

  /// No description provided for @tut_perfilTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Seu Perfil'**
  String get tut_perfilTitulo;

  /// No description provided for @tut_perfilCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Configure seus dados físicos, defina metas e personalize sua foto de perfil para aparecer no ranking.'**
  String get tut_perfilCorpo;

  /// No description provided for @tut_metasTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Metas e Bioimpedância'**
  String get tut_metasTitulo;

  /// No description provided for @tut_metasCorpo.
  ///
  /// In pt, this message translates to:
  /// **'Defina peso alvo, calorias diárias e objetivo (ganhar massa / perder peso / manter). Registre medidas de bioimpedância para acompanhar sua evolução corporal.'**
  String get tut_metasCorpo;

  /// No description provided for @tut_comecar.
  ///
  /// In pt, this message translates to:
  /// **'COMEÇAR!'**
  String get tut_comecar;

  /// No description provided for @tut_proximo.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMO  →'**
  String get tut_proximo;

  /// No description provided for @priv_apagaPermanentemente.
  ///
  /// In pt, this message translates to:
  /// **'Isto apaga permanentemente:\n\n'**
  String get priv_apagaPermanentemente;

  /// No description provided for @priv_itemPerfil.
  ///
  /// In pt, this message translates to:
  /// **'• Perfil, foto e metas\n'**
  String get priv_itemPerfil;

  /// No description provided for @priv_itemPontos.
  ///
  /// In pt, this message translates to:
  /// **'• Pontos, ranking e amizades\n\n'**
  String get priv_itemPontos;

  /// No description provided for @perfil_metaImc.
  ///
  /// In pt, this message translates to:
  /// **'Meta: IMC'**
  String get perfil_metaImc;

  /// No description provided for @nivel_pontoParaNivelResto.
  ///
  /// In pt, this message translates to:
  /// **'ponto para o nível {nivel}'**
  String nivel_pontoParaNivelResto(int nivel);

  /// No description provided for @nivel_pontosParaNivelResto.
  ///
  /// In pt, this message translates to:
  /// **'pontos para o nível {nivel}'**
  String nivel_pontosParaNivelResto(int nivel);

  /// No description provided for @grupo_peito.
  ///
  /// In pt, this message translates to:
  /// **'Peito'**
  String get grupo_peito;

  /// No description provided for @grupo_costas.
  ///
  /// In pt, this message translates to:
  /// **'Costas'**
  String get grupo_costas;

  /// No description provided for @grupo_ombros.
  ///
  /// In pt, this message translates to:
  /// **'Ombros'**
  String get grupo_ombros;

  /// No description provided for @grupo_biceps.
  ///
  /// In pt, this message translates to:
  /// **'Bíceps'**
  String get grupo_biceps;

  /// No description provided for @grupo_triceps.
  ///
  /// In pt, this message translates to:
  /// **'Tríceps'**
  String get grupo_triceps;

  /// No description provided for @grupo_pernas.
  ///
  /// In pt, this message translates to:
  /// **'Pernas'**
  String get grupo_pernas;

  /// No description provided for @grupo_gluteos.
  ///
  /// In pt, this message translates to:
  /// **'Glúteos'**
  String get grupo_gluteos;

  /// No description provided for @grupo_core.
  ///
  /// In pt, this message translates to:
  /// **'Core'**
  String get grupo_core;

  /// No description provided for @grupo_fullBody.
  ///
  /// In pt, this message translates to:
  /// **'Full Body'**
  String get grupo_fullBody;

  /// No description provided for @perfil_semanaAbrev.
  ///
  /// In pt, this message translates to:
  /// **'S'**
  String get perfil_semanaAbrev;

  /// No description provided for @perfil_evolucaoNaoCarregou.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a evolução'**
  String get perfil_evolucaoNaoCarregou;

  /// No description provided for @perfil_tooltipSemana.
  ///
  /// In pt, this message translates to:
  /// **'{total} pts\n+{ganhos} nesta semana'**
  String perfil_tooltipSemana(int total, int ganhos);

  /// No description provided for @perfil_semanaDe.
  ///
  /// In pt, this message translates to:
  /// **'Semana de {data}'**
  String perfil_semanaDe(String data);

  /// No description provided for @pro_titulo.
  ///
  /// In pt, this message translates to:
  /// **'MUSCLE CHAMP'**
  String get pro_titulo;

  /// No description provided for @pro_pro.
  ///
  /// In pt, this message translates to:
  /// **'PRO'**
  String get pro_pro;

  /// No description provided for @pro_subtitulo.
  ///
  /// In pt, this message translates to:
  /// **'Treino, dieta e evolução com IA — sem limite.'**
  String get pro_subtitulo;

  /// No description provided for @pro_escolhaPlano.
  ///
  /// In pt, this message translates to:
  /// **'ESCOLHA SEU PLANO'**
  String get pro_escolhaPlano;

  /// No description provided for @pro_oQueLibera.
  ///
  /// In pt, this message translates to:
  /// **'O QUE O PRO LIBERA'**
  String get pro_oQueLibera;

  /// No description provided for @pro_maisPopular.
  ///
  /// In pt, this message translates to:
  /// **'MAIS ESCOLHIDO'**
  String get pro_maisPopular;

  /// No description provided for @pro_porMes.
  ///
  /// In pt, this message translates to:
  /// **'{valor}/mês'**
  String pro_porMes(String valor);

  /// No description provided for @pro_economia.
  ///
  /// In pt, this message translates to:
  /// **'economiza {valor} por ano'**
  String pro_economia(String valor);

  /// No description provided for @pro_periodoMensal.
  ///
  /// In pt, this message translates to:
  /// **'Mensal'**
  String get pro_periodoMensal;

  /// No description provided for @pro_periodoTrimestral.
  ///
  /// In pt, this message translates to:
  /// **'Trimestral'**
  String get pro_periodoTrimestral;

  /// No description provided for @pro_periodoAnual.
  ///
  /// In pt, this message translates to:
  /// **'Anual'**
  String get pro_periodoAnual;

  /// No description provided for @pro_comecarTrial.
  ///
  /// In pt, this message translates to:
  /// **'COMEÇAR {dias} DIAS GRÁTIS'**
  String pro_comecarTrial(int dias);

  /// No description provided for @pro_agoraNao.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get pro_agoraNao;

  /// No description provided for @pro_restaurar.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar compra'**
  String get pro_restaurar;

  /// No description provided for @pro_benefFoto.
  ///
  /// In pt, this message translates to:
  /// **'Foto do prato vira macros'**
  String get pro_benefFoto;

  /// No description provided for @pro_benefFotoDesc.
  ///
  /// In pt, this message translates to:
  /// **'A IA identifica o alimento e estima o peso'**
  String get pro_benefFotoDesc;

  /// No description provided for @pro_benefDieta.
  ///
  /// In pt, this message translates to:
  /// **'Plano de dieta gerado por IA'**
  String get pro_benefDieta;

  /// No description provided for @pro_benefDietaDesc.
  ///
  /// In pt, this message translates to:
  /// **'Cardápio do dia nas suas metas, com troca de alimento'**
  String get pro_benefDietaDesc;

  /// No description provided for @pro_benefTreino.
  ///
  /// In pt, this message translates to:
  /// **'Treinos montados por IA'**
  String get pro_benefTreino;

  /// No description provided for @pro_benefTreinoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o grupo muscular e receba o treino pronto'**
  String get pro_benefTreinoDesc;

  /// No description provided for @pro_benefHistorico.
  ///
  /// In pt, this message translates to:
  /// **'Histórico sem limite'**
  String get pro_benefHistorico;

  /// No description provided for @pro_benefHistoricoDesc.
  ///
  /// In pt, this message translates to:
  /// **'Toda a sua evolução de peso, pontos e medidas'**
  String get pro_benefHistoricoDesc;

  /// No description provided for @pro_avisoTrial.
  ///
  /// In pt, this message translates to:
  /// **'{dias} dias grátis. Cobramos {valor} só em {data}. Cancele antes e não paga nada.'**
  String pro_avisoTrial(int dias, String valor, String data);

  /// No description provided for @pro_avisoRenovacao.
  ///
  /// In pt, this message translates to:
  /// **'Primeiro ano por {entrada}. Renova automaticamente por {renovacao} por ano.'**
  String pro_avisoRenovacao(String entrada, String renovacao);

  /// No description provided for @pro_avisoRenovacaoSimples.
  ///
  /// In pt, this message translates to:
  /// **'Renova automaticamente por {valor}. Cancele quando quiser.'**
  String pro_avisoRenovacaoSimples(String valor);

  /// No description provided for @pro_avisoCancelar.
  ///
  /// In pt, this message translates to:
  /// **'Você cancela pela loja de aplicativos, sem falar com ninguém.'**
  String get pro_avisoCancelar;

  /// No description provided for @pro_aoAssinarAceita.
  ///
  /// In pt, this message translates to:
  /// **'Ao assinar você aceita os {termos} e a {privacidade}.'**
  String pro_aoAssinarAceita(String termos, String privacidade);

  /// No description provided for @demo_faixa.
  ///
  /// In pt, this message translates to:
  /// **'MODO DEMONSTRAÇÃO'**
  String get demo_faixa;

  /// No description provided for @demo_explicacao.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma cobrança é feita e nenhum dado sai deste aparelho.'**
  String get demo_explicacao;

  /// No description provided for @pag_titulo.
  ///
  /// In pt, this message translates to:
  /// **'PAGAMENTO'**
  String get pag_titulo;

  /// No description provided for @pag_resumo.
  ///
  /// In pt, this message translates to:
  /// **'RESUMO'**
  String get pag_resumo;

  /// No description provided for @pag_hoje.
  ///
  /// In pt, this message translates to:
  /// **'Hoje você paga'**
  String get pag_hoje;

  /// No description provided for @pag_gratis.
  ///
  /// In pt, this message translates to:
  /// **'R\$ 0,00'**
  String get pag_gratis;

  /// No description provided for @pag_depoisDoTrial.
  ///
  /// In pt, this message translates to:
  /// **'Depois de {data}'**
  String pag_depoisDoTrial(String data);

  /// No description provided for @pag_forma.
  ///
  /// In pt, this message translates to:
  /// **'FORMA DE PAGAMENTO'**
  String get pag_forma;

  /// No description provided for @pag_cartao.
  ///
  /// In pt, this message translates to:
  /// **'Cartão'**
  String get pag_cartao;

  /// No description provided for @pag_pix.
  ///
  /// In pt, this message translates to:
  /// **'Pix'**
  String get pag_pix;

  /// No description provided for @pag_numeroCartao.
  ///
  /// In pt, this message translates to:
  /// **'NÚMERO DO CARTÃO'**
  String get pag_numeroCartao;

  /// No description provided for @pag_nomeNoCartao.
  ///
  /// In pt, this message translates to:
  /// **'NOME NO CARTÃO'**
  String get pag_nomeNoCartao;

  /// No description provided for @pag_validade.
  ///
  /// In pt, this message translates to:
  /// **'VALIDADE'**
  String get pag_validade;

  /// No description provided for @pag_cvv.
  ///
  /// In pt, this message translates to:
  /// **'CVV'**
  String get pag_cvv;

  /// No description provided for @pag_pixInstrucao.
  ///
  /// In pt, this message translates to:
  /// **'Na versão real aparece aqui um QR Code com validade de 30 minutos.'**
  String get pag_pixInstrucao;

  /// No description provided for @pag_confirmar.
  ///
  /// In pt, this message translates to:
  /// **'CONFIRMAR ASSINATURA'**
  String get pag_confirmar;

  /// No description provided for @pag_processando.
  ///
  /// In pt, this message translates to:
  /// **'Processando...'**
  String get pag_processando;

  /// No description provided for @pag_seguro.
  ///
  /// In pt, this message translates to:
  /// **'Simulação local — nada é transmitido'**
  String get pag_seguro;

  /// No description provided for @suc_titulo.
  ///
  /// In pt, this message translates to:
  /// **'ASSINATURA ATIVA'**
  String get suc_titulo;

  /// No description provided for @suc_bemVindo.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo ao Pro.'**
  String get suc_bemVindo;

  /// No description provided for @suc_trialAte.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação gratuita até {data}'**
  String suc_trialAte(String data);

  /// No description provided for @suc_primeiraCobranca.
  ///
  /// In pt, this message translates to:
  /// **'Primeira cobrança de {valor} em {data}'**
  String suc_primeiraCobranca(String valor, String data);

  /// No description provided for @suc_comecar.
  ///
  /// In pt, this message translates to:
  /// **'COMEÇAR A TREINAR'**
  String get suc_comecar;

  /// No description provided for @perfil_assinatura.
  ///
  /// In pt, this message translates to:
  /// **'ASSINATURA'**
  String get perfil_assinatura;

  /// No description provided for @perfil_planoGratuito.
  ///
  /// In pt, this message translates to:
  /// **'Plano gratuito'**
  String get perfil_planoGratuito;

  /// No description provided for @perfil_verPlanos.
  ///
  /// In pt, this message translates to:
  /// **'Ver planos'**
  String get perfil_verPlanos;

  /// No description provided for @perfil_proAtivo.
  ///
  /// In pt, this message translates to:
  /// **'Pro ativo'**
  String get perfil_proAtivo;

  /// No description provided for @perfil_trialRestante.
  ///
  /// In pt, this message translates to:
  /// **'{dias} dias de avaliação restantes'**
  String perfil_trialRestante(int dias);

  /// No description provided for @perfil_renovaEm.
  ///
  /// In pt, this message translates to:
  /// **'Renova em {data}'**
  String perfil_renovaEm(String data);

  /// No description provided for @perfil_cancelarAssinatura.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar assinatura'**
  String get perfil_cancelarAssinatura;

  /// No description provided for @perfil_cancelarConfirma.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar a assinatura? Você mantém o Pro até o fim do período já pago.'**
  String get perfil_cancelarConfirma;

  /// No description provided for @perfil_assinaturaCancelada.
  ///
  /// In pt, this message translates to:
  /// **'Assinatura cancelada.'**
  String get perfil_assinaturaCancelada;

  /// No description provided for @cota_restantesHoje.
  ///
  /// In pt, this message translates to:
  /// **'{n} de {total} hoje'**
  String cota_restantesHoje(int n, int total);

  /// No description provided for @cota_ilimitado.
  ///
  /// In pt, this message translates to:
  /// **'Ilimitado'**
  String get cota_ilimitado;

  /// No description provided for @cota_limiteTitulo.
  ///
  /// In pt, this message translates to:
  /// **'Você usou sua IA de hoje'**
  String get cota_limiteTitulo;

  /// No description provided for @cota_limiteFoto.
  ///
  /// In pt, this message translates to:
  /// **'O plano gratuito analisa {n} foto por dia. Volta amanhã ou libere o uso sem limite.'**
  String cota_limiteFoto(int n);

  /// No description provided for @cota_limiteTexto.
  ///
  /// In pt, this message translates to:
  /// **'O plano gratuito calcula {n} alimentos por texto por dia. Volta amanhã ou libere o uso sem limite.'**
  String cota_limiteTexto(int n);

  /// No description provided for @cota_limiteTreino.
  ///
  /// In pt, this message translates to:
  /// **'O plano gratuito gera {n} treino por dia. Volta amanhã ou libere o uso sem limite.'**
  String cota_limiteTreino(int n);

  /// No description provided for @cota_limiteDieta.
  ///
  /// In pt, this message translates to:
  /// **'O plano gratuito gera {n} plano de dieta por dia. Volta amanhã ou libere o uso sem limite.'**
  String cota_limiteDieta(int n);

  /// No description provided for @cota_semLimitePro.
  ///
  /// In pt, this message translates to:
  /// **'Sem limite no Pro'**
  String get cota_semLimitePro;

  /// No description provided for @cota_verPlanos.
  ///
  /// In pt, this message translates to:
  /// **'VER PLANOS'**
  String get cota_verPlanos;

  /// No description provided for @cota_esperarAmanha.
  ///
  /// In pt, this message translates to:
  /// **'Espero até amanhã'**
  String get cota_esperarAmanha;

  /// No description provided for @cota_zerarDemo.
  ///
  /// In pt, this message translates to:
  /// **'Zerar cota (demo)'**
  String get cota_zerarDemo;

  /// No description provided for @cota_zerada.
  ///
  /// In pt, this message translates to:
  /// **'Cota do dia zerada.'**
  String get cota_zerada;

  /// No description provided for @pop_titulo.
  ///
  /// In pt, this message translates to:
  /// **'Sua conta está pronta'**
  String get pop_titulo;

  /// No description provided for @pop_tituloRecorrente.
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueie a IA sem limite'**
  String get pop_tituloRecorrente;

  /// No description provided for @pop_subtitulo.
  ///
  /// In pt, this message translates to:
  /// **'{dias} dias grátis para usar tudo sem limite.'**
  String pop_subtitulo(int dias);

  /// No description provided for @pop_noGratisVoceTem.
  ///
  /// In pt, this message translates to:
  /// **'NO PLANO GRATUITO VOCÊ TEM, POR DIA'**
  String get pop_noGratisVoceTem;

  /// No description provided for @pop_linhaFoto.
  ///
  /// In pt, this message translates to:
  /// **'{n} foto do prato analisada'**
  String pop_linhaFoto(int n);

  /// No description provided for @pop_linhaTexto.
  ///
  /// In pt, this message translates to:
  /// **'{n} alimentos calculados por texto'**
  String pop_linhaTexto(int n);

  /// No description provided for @pop_linhaTreino.
  ///
  /// In pt, this message translates to:
  /// **'{n} treino gerado por IA'**
  String pop_linhaTreino(int n);

  /// No description provided for @pop_linhaDieta.
  ///
  /// In pt, this message translates to:
  /// **'{n} plano de dieta'**
  String pop_linhaDieta(int n);

  /// No description provided for @pop_comPro.
  ///
  /// In pt, this message translates to:
  /// **'Com o Pro, tudo isso fica ilimitado.'**
  String get pop_comPro;

  /// No description provided for @pop_continuarGratis.
  ///
  /// In pt, this message translates to:
  /// **'Continuar no plano gratuito'**
  String get pop_continuarGratis;

  /// No description provided for @priv_palavraConfirmacao.
  ///
  /// In pt, this message translates to:
  /// **'EXCLUIR'**
  String get priv_palavraConfirmacao;

  /// No description provided for @priv_falhaExcluir.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao excluir'**
  String get priv_falhaExcluir;

  /// No description provided for @priv_falhaExportar.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao exportar'**
  String get priv_falhaExportar;

  /// No description provided for @priv_seusDados.
  ///
  /// In pt, this message translates to:
  /// **'Seus dados'**
  String get priv_seusDados;

  /// No description provided for @perfil_zonaPerigo.
  ///
  /// In pt, this message translates to:
  /// **'ZONA DE PERIGO'**
  String get perfil_zonaPerigo;

  /// No description provided for @perfil_excluirMinhaConta.
  ///
  /// In pt, this message translates to:
  /// **'Excluir minha conta'**
  String get perfil_excluirMinhaConta;

  /// No description provided for @perfil_excluindo.
  ///
  /// In pt, this message translates to:
  /// **'Excluindo...'**
  String get perfil_excluindo;

  /// No description provided for @cad_limiteEmails.
  ///
  /// In pt, this message translates to:
  /// **'O servidor de e-mail atingiu o limite de envios. Sua conta NÃO foi criada — tente de novo daqui a uma hora.'**
  String get cad_limiteEmails;

  /// No description provided for @conf_limiteEmails.
  ///
  /// In pt, this message translates to:
  /// **'O servidor de e-mail atingiu o limite de envios. Tente reenviar daqui a uma hora.'**
  String get conf_limiteEmails;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'es':
      return LEs();
    case 'pt':
      return LPt();
  }

  throw FlutterError(
      'L.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
