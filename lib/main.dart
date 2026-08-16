import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_colors.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientação e status bar não podem derrubar o boot: no web são no-op e em
  // alguns navegadores a chamada rejeita. Falha aqui não impede o app de abrir.
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
  } catch (_) {
    // segue o jogo — é só cosmético
  }

  // Se o Supabase.initialize lançasse aqui sem tratamento, o runApp nunca
  // rodava e o resultado era tela branca eterna, sem nenhuma pista do motivo.
  // Agora o app SEMPRE sobe: ou normal, ou numa tela que diz o que falhou.
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    runApp(_BootErrorApp(error: e.toString()));
    return;
  }

  runApp(const ProviderScope(child: MuscleCampApp()));
}

/// Tela de último recurso: aparece quando o app não consegue nem inicializar.
/// Melhor mostrar o erro do que uma página branca sem explicação.
class _BootErrorApp extends StatelessWidget {
  const _BootErrorApp({required this.error});

  final String error;

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
                const Icon(Icons.cloud_off_rounded,
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
                const Text(
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
                    error,
                    style: const TextStyle(
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
