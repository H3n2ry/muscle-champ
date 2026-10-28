import 'package:muscle_camp/core/secrets.dart';

class SupabaseConfig {
  SupabaseConfig._();

  // O build de teste (tool/publicar_preview.sh) troca o projeto via
  // --dart-define para não gravar nada no banco de produção. Sem os defines,
  // vale o de sempre (Secrets).
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: Secrets.supabaseUrl,
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: Secrets.supabaseAnonKey,
  );
}
