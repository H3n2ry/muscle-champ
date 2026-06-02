import 'package:muscle_camp/core/secrets.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String url     = Secrets.supabaseUrl;
  static const String anonKey = Secrets.supabaseAnonKey;
}
