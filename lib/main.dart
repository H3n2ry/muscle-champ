import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/paleta_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Cor do app antes do primeiro frame. Vem do cache local (a conta é a
  // verdade, mas esperar a rede aqui abriria o app na cor errada e piscaria
  // meio segundo depois). Precisa vir DEPOIS do `Supabase.initialize`, que é
  // quem restaura a sessão e portanto quem sabe de qual usuário é a cor.
  await PaletaStore.aplicarDoCache();

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

  runApp(const ProviderScope(child: MuscleCampApp()));
}
