import 'package:firebase_auth/firebase_auth.dart';

class GroqConfig {
  GroqConfig._();

  // As chamadas de IA passam pela Cloud Function `groqProxy` (Callable),
  // que valida o Firebase Auth e guarda a chave Groq no Secret Manager.
  // O cliente nunca vê a chave. A URL é descoberta automaticamente pelo
  // SDK via firebase_options.dart — só a região precisa bater com o deploy.
  static const String region = 'southamerica-east1';

  static const String textModel  = 'llama-3.3-70b-versatile';
  static const String visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  // IA disponível somente para usuários autenticados.
  static bool get isConfigured =>
      FirebaseAuth.instance.currentUser != null;
}
