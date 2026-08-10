import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

// Somente os modelos que o app usa — impede abuso do proxy para outros fins.
// meta-llama/llama-4-scout-17b-16e-instruct foi desligado pela Groq em
// 17/07/2026; substituído por qwen/qwen3.6-27b (visão).
const ALLOWED_MODELS = new Set([
  "llama-3.3-70b-versatile",
  "qwen/qwen3.6-27b",
]);

const MAX_TOKENS_CAP = 2048;
const MAX_BODY_BYTES = 4 * 1024 * 1024; // 4MB (foto 768px em base64 cabe folgado)

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// Cache da chave por instância (evita 1 query por request)
let cachedKey: string | null = null;

async function getGroqKey(): Promise<string> {
  if (cachedKey) return cachedKey;
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data, error } = await admin.rpc("get_groq_api_key");
  if (error || !data) {
    throw new Error(`Falha ao ler chave do Vault: ${error?.message}`);
  }
  cachedKey = data as string;
  return cachedKey;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json(405, { error: { message: "Método não permitido" } });
  }

  const len = parseInt(req.headers.get("content-length") ?? "0", 10);
  if (len > MAX_BODY_BYTES) {
    return json(413, { error: { message: "Payload muito grande" } });
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return json(400, { error: { message: "JSON inválido" } });
  }

  if (!ALLOWED_MODELS.has(payload.model as string)) {
    return json(400, { error: { message: "Modelo não permitido" } });
  }

  // Limita tokens de saída para conter custo/abuso
  const requested = typeof payload.max_tokens === "number" ? payload.max_tokens : 1024;
  payload.max_tokens = Math.min(requested, MAX_TOKENS_CAP);

  try {
    const key = await getGroqKey();
    const upstream = await fetch(GROQ_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });
    const text = await upstream.text();
    return new Response(text, {
      status: upstream.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return json(502, {
      error: { message: `Erro no proxy Groq: ${(e as Error).message}` },
    });
  }
});
