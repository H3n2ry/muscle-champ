import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:muscle_camp/core/secrets.dart';

class GroqConfig {
  GroqConfig._();

  // As chamadas de IA passam pela Edge Function groq-proxy (autenticada por JWT).
  // A chave Groq vive no Supabase Vault — nunca no app.
  static const String baseUrl =
      '${Secrets.supabaseUrl}/functions/v1/groq-proxy';

  static const String textModel  = 'llama-3.3-70b-versatile';
  static const String visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static bool get isConfigured =>
      Supabase.instance.client.auth.currentSession != null;
}
