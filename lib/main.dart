import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/auth/url_de_oauth.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/paleta_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nada aqui pode impedir o `runApp` de ser chamado.
  //
  // Antes, qualquer exceção nesta função derrubava o boot antes do primeiro
  // frame: sem log visível, sem tela, sem erro — só branco permanente. É o
  // sintoma mais caro de diagnosticar, porque não distingue app quebrado de
  // rede lenta, e some do console assim que o usuário recarrega.
  //
  // A divisão abaixo é: o Supabase é condição de existência do app (sessão,
  // dados e IA passam por ele), então falhar nele leva a uma tela que explica.
  // O resto é acessório e só registra no log.
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e, s) {
    debugPrint('Falha ao inicializar o Supabase: $e\n$s');
    runApp(_AppDeFalhaNoBoot(erro: e.toString()));
    return;
  }

  // O retorno do login com Google deixa `?code=…` na barra de endereço e o
  // supabase_flutter não a limpa. Como ele reprocessa a URL a cada
  // carregamento, o F5 seguinte tenta trocar um código já consumido e joga
  // "Code verifier could not be found in local storage" no console — para
  // sempre, naquela URL.
  //
  // Tem que ser DEPOIS do initialize, que é quem faz a troca válida.
  try {
    limparParametrosDeOAuthDaUrl();
  } catch (e) {
    debugPrint('Falha ao limpar os parâmetros de OAuth da URL: $e');
  }

  // Cor do app antes do primeiro frame. Vem do cache local (a conta é a
  // verdade, mas esperar a rede aqui abriria o app na cor errada e piscaria
  // meio segundo depois). Precisa vir DEPOIS do `Supabase.initialize`, que é
  // quem restaura a sessão e portanto quem sabe de qual usuário é a cor.
  //
  // Falhando, o app abre na paleta padrão — bem melhor que não abrir.
  try {
    await PaletaStore.aplicarDoCache();
  } catch (e) {
    debugPrint('Falha ao aplicar a paleta do cache: $e');
  }

  // Cosmético e no-op no web. Não tem por que derrubar o boot.
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  } catch (e) {
    debugPrint('Falha ao configurar orientação/status bar: $e');
  }

  runApp(const ProviderScope(child: MuscleCampApp()));
}

/// Tela de último recurso: o app não conseguiu nem inicializar.
///
/// Não usa o tema nem os providers — eles dependem justamente do que falhou.
/// Só cores cruas, para que esta tela apareça mesmo com tudo o resto quebrado.
class _AppDeFalhaNoBoot extends StatelessWidget {
  const _AppDeFalhaNoBoot({required this.erro});

  final String erro;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded,
                    color: AppColors.primary, size: 56),
                const SizedBox(height: 20),
                const Text(
                  'Não foi possível iniciar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Falha ao conectar com o servidor. Verifique sua internet e '
                  'tente novamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    erro,
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
