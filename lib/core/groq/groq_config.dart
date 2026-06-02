import 'package:muscle_camp/core/secrets.dart';

class GroqConfig {
  GroqConfig._();

  static const String apiKey = Secrets.groqApiKey;

  static const String baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String textModel  = 'llama-3.3-70b-versatile';
  static const String visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  static bool get isConfigured =>
      apiKey.isNotEmpty && apiKey.startsWith('gsk_');
}
