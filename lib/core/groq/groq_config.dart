import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:muscle_camp/core/secrets.dart';

class GroqConfig {
  GroqConfig._();

  // As chamadas de IA passam pela Edge Function groq-proxy (autenticada por JWT).
  // A chave Groq vive no Supabase Vault — nunca no app.
  static const String baseUrl =
      '${Secrets.supabaseUrl}/functions/v1/groq-proxy';

  // ⚠️ O app NÃO conhece mais o ID do modelo. Ele envia apenas `task` —
  // 'text' ou 'vision' — e o proxy resolve para o modelo atual.
  //
  // Motivo: a Groq aposenta modelos com pouco aviso (duas vezes em 30 dias) e
  // o app quebra na hora. Com o ID compilado aqui, um APK já instalado ficaria
  // quebrado até o usuário atualizar pela Play Store — dias ou semanas. Do jeito
  // atual, trocar de modelo é um redeploy da Edge Function.
  //
  // Para mudar de modelo, editar MODEL_CHAINS em
  // supabase/functions/groq-proxy/index.ts e redeployar. Nada aqui muda.
  static const Set<String> tasks = {'text', 'vision'};

  static bool get isConfigured =>
      Supabase.instance.client.auth.currentSession != null;
}
