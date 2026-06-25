/**
 * Cloud Function: groqProxy (Callable, Firebase Functions v2)
 *
 * Proxy seguro para a API da Groq. A chave vive no Secret Manager
 * (`GROQ_KEY`) e NUNCA chega ao cliente. Só usuários autenticados
 * (Firebase Auth) conseguem chamar — `request.auth` é validado pelo SDK.
 *
 * Deploy:
 *   firebase functions:secrets:set GROQ_KEY    # cola a chave gsk_...
 *   firebase deploy --only functions
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { setGlobalOptions } = require("firebase-functions/v2");

const GROQ_KEY = defineSecret("GROQ_KEY");

// Região São Paulo — precisa bater com GroqConfig.region no app.
setGlobalOptions({ region: "southamerica-east1", maxInstances: 10 });

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

// Só os modelos que o app usa — impede abuso do proxy para outros fins.
const ALLOWED_MODELS = new Set([
  "llama-3.3-70b-versatile",
  "meta-llama/llama-4-scout-17b-16e-instruct",
]);

const MAX_TOKENS_CAP = 2048;

exports.groqProxy = onCall(
  { secrets: [GROQ_KEY] },
  async (request) => {
    // 1. Exige usuário autenticado
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Faça login para usar a IA.");
    }

    const payload = request.data || {};

    // 2. Allowlist de modelo
    if (!ALLOWED_MODELS.has(payload.model)) {
      throw new HttpsError("invalid-argument", "Modelo não permitido.");
    }

    // 3. Teto de tokens (contém custo/abuso)
    if (typeof payload.max_tokens === "number") {
      payload.max_tokens = Math.min(payload.max_tokens, MAX_TOKENS_CAP);
    }

    // 4. Encaminha para a Groq com a chave do Secret Manager
    let upstream;
    try {
      upstream = await fetch(GROQ_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${GROQ_KEY.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });
    } catch (e) {
      throw new HttpsError("unavailable", "Falha ao contatar a IA. Tente novamente.");
    }

    const json = await upstream.json();
    if (!upstream.ok) {
      const msg =
        (json && json.error && json.error.message) ||
        `Groq retornou ${upstream.status}`;
      throw new HttpsError("internal", msg);
    }

    // 5. Devolve o JSON da Groq (formato OpenAI) direto ao app
    return json;
  }
);
