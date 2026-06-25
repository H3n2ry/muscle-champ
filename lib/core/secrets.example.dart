// Modelo de secrets.dart — copie para secrets.dart (que está no .gitignore).
//
// Hoje o app NÃO guarda segredos no cliente:
//   - Credenciais do Firebase → lib/core/firebase/firebase_options.dart
//     (gerado por `flutterfire configure`).
//   - Chave da Groq → Secret Manager do Firebase, usada apenas pela
//     Cloud Function `groqProxy`. Defina com:
//       firebase functions:secrets:set GROQ_KEY
//
// Este arquivo existe só por convenção; mantenha-o sem dados sensíveis.
class Secrets {
  Secrets._();
}
