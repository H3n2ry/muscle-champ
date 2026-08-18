import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

// ─── Seleção de modelo ──────────────────────────────────────────────────────
// O app NÃO escolhe o modelo. Ele manda apenas a tarefa ("text" ou "vision") e
// o proxy resolve para o ID atual.
//
// Isso existe porque a Groq aposenta modelos com pouco aviso e o app quebra na
// hora. Com o ID compilado no cliente, um APK já instalado ficaria quebrado até
// o usuário atualizar pela Play Store — dias ou semanas. Aqui, trocar de modelo
// é um redeploy desta função.
//
// Histórico de desligamentos:
//   17/07/2026 — meta-llama/llama-4-scout-17b-16e-instruct (visão)
//   16/08/2026 — llama-3.3-70b-versatile (texto)
type ModelSpec = {
  id: string;
  /// Os dois modelos em uso raciocinam antes de responder, de formas diferentes:
  ///
  /// • gpt-oss-120b — raciocínio em campo separado (`reasoning`). Sem limite ele
  ///   consome todo o max_tokens pensando e devolve `content` VAZIO com
  ///   finish_reason "length": falha silenciosa, não erro. Aceita apenas
  ///   low | medium | high.
  /// • qwen3.6-27b — raciocínio inline, dentro do `content`, entre tags
  ///   <think>. O JSON sai cortado ou nem sai. Aceita "none", que desliga.
  ///
  /// Valor do chamador sempre vence (ver loop principal).
  reasoningEffort?: "none" | "low" | "medium" | "high";
  /// Folga no max_tokens para caber raciocínio + conteúdo. Medido: ~65% do
  /// output do gpt-oss-120b vai para raciocínio em prompts curtos de JSON.
  tokenHeadroom?: number;
};

const MODEL_CHAINS: Record<string, ModelSpec[]> = {
  // gpt-oss-120b é mais barato que o llama-3.3 que substituiu
  // (US$ 0,15/0,60 contra 0,59/0,79 por 1M), mesmo pagando os tokens de
  // raciocínio como saída.
  text: [
    { id: "openai/gpt-oss-120b", reasoningEffort: "low", tokenHeadroom: 2.5 },
    // "none" é indispensável aqui: como fallback de texto ninguém define o
    // parâmetro, e o qwen devolveria <think>...</think> no lugar do JSON.
    { id: "qwen/qwen3.6-27b", reasoningEffort: "none" },
  ],

  // ⚠️ Sem fallback real: qwen3.6-27b é hoje o único multimodal que usamos.
  // Se ele for desligado, o modo FOTO cai até alguém apontar outro aqui.
  vision: [{ id: "qwen/qwen3.6-27b", reasoningEffort: "none" }],
};

// Subiu de 2048 para caber raciocínio + conteúdo do plano de dieta, que é a
// resposta mais longa do app. A 4096 tokens de saída o teto de custo por
// chamada fica em ~US$ 0,0025 — irrelevante.
const MAX_TOKENS_CAP = 4096;
const MAX_BODY_BYTES = 4 * 1024 * 1024; // 4MB (foto 768px em base64 cabe folgado)

/// Teto da espera antes de reprocessar a cadeia. A Edge Function tem orçamento
/// de tempo, e segurar o usuário além disso é pior do que devolver um erro claro
/// para ele tentar de novo.
const MAX_BACKOFF_SECS = 3;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Expose-Headers": "x-model-used, x-model-fallback",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/// Detecta a resposta da Groq para "esse modelo não existe mais".
/// Só esse caso justifica trocar de modelo — erro de payload ou falha de
/// autenticação seriam idênticos em qualquer um.
function isModelUnavailable(status: number, body: string): boolean {
  if (status !== 400 && status !== 404) return false;
  const b = body.toLowerCase();
  return (
    b.includes("does not exist") ||
    b.includes("decommissioned") ||
    b.includes("has been deprecated") ||
    b.includes("model_not_found")
  );
}

/// Lê o `Retry-After` da Groq (segundos). Cai no default quando ausente.
function parseRetryAfter(h: Headers, fallbackSecs: number): number {
  const raw = h.get("retry-after");
  if (!raw) return fallbackSecs;
  const n = Number(raw);
  return Number.isFinite(n) && n > 0 ? n : fallbackSecs;
}

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

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

  const task = payload.task as string | undefined;
  const chain = task ? MODEL_CHAINS[task] : undefined;
  if (!chain) {
    return json(400, {
      error: {
        message:
          `Campo "task" inválido ou ausente. Esperado: ${Object.keys(MODEL_CHAINS).join(" | ")}`,
      },
    });
  }
  // `task` é do protocolo do proxy, não da API da Groq.
  delete payload.task;

  // Guardados ANTES do loop: cada tentativa precisa partir do que o chamador
  // pediu, não do que a tentativa anterior deixou no payload.
  const requestedTokens = typeof payload.max_tokens === "number"
    ? payload.max_tokens
    : 1024;
  const callerReasoning = payload.reasoning_effort;

  let key: string;
  try {
    key = await getGroqKey();
  } catch (e) {
    return json(502, {
      error: { message: `Erro no proxy Groq: ${(e as Error).message}` },
    });
  }

  const retired: string[] = [];
  let sawRateLimit = false;
  let retryAfterSecs = 1;

  // Duas passadas pela cadeia. A primeira tenta cada modelo; se TODOS
  // devolverem 429, espera o backoff e repete uma única vez.
  for (let pass = 0; pass < 2; pass++) {
    sawRateLimit = false;

    for (let i = 0; i < chain.length; i++) {
      const spec = chain[i];
      const model = spec.id;
      payload.model = model;

      // Ajustes específicos do modelo — o app não precisa conhecê-los.
      //
      // Reconstruído a cada tentativa a partir de `callerReasoning`. Sem isso,
      // o valor injetado para um modelo morto vazaria para o fallback: o
      // gpt-oss recebe "low", falha, e o qwen herdaria "low" na volta seguinte
      // — quebrando exatamente o mecanismo que deveria salvar a chamada.
      if (callerReasoning !== undefined) {
        payload.reasoning_effort = callerReasoning; // chamador vence
      } else if (spec.reasoningEffort) {
        payload.reasoning_effort = spec.reasoningEffort;
      } else {
        delete payload.reasoning_effort;
      }

      payload.max_tokens = Math.min(
        Math.ceil(requestedTokens * (spec.tokenHeadroom ?? 1)),
        MAX_TOKENS_CAP,
      );

      let upstream: Response;
      let body: string;
      try {
        upstream = await fetch(GROQ_URL, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${key}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
        });
        body = await upstream.text();
      } catch (e) {
        return json(502, {
          error: { message: `Erro no proxy Groq: ${(e as Error).message}` },
        });
      }

      // ── Modelo aposentado → próximo da cadeia ──────────────────────────
      if (isModelUnavailable(upstream.status, body)) {
        if (!retired.includes(model)) retired.push(model);

        if (i < chain.length - 1) {
          console.error(
            `[groq-proxy] modelo "${model}" indisponivel para task "${task}" — ` +
            `caindo para "${chain[i + 1].id}". ATUALIZAR MODEL_CHAINS.`,
          );
          continue;
        }

        // Se algum modelo estava apenas limitado, o problema é de capacidade,
        // não de modelo aposentado — deixa cair no tratamento de 429.
        if (!sawRateLimit) {
          console.error(
            `[groq-proxy] TODOS os modelos da task "${task}" estao ` +
            `indisponiveis: ${chain.map((m) => m.id).join(", ")}. ` +
            `ATUALIZAR MODEL_CHAINS URGENTE.`,
          );
          return json(503, {
            error: {
              message:
                "O serviço de IA está temporariamente indisponível. " +
                "Tente novamente mais tarde.",
            },
          });
        }
        continue;
      }

      // ── Rate limit (429) ───────────────────────────────────────────────
      // Cada modelo tem balde próprio na Groq, então o próximo da cadeia pode
      // estar livre — tentar ali resolve boa parte dos picos sem espera.
      if (upstream.status === 429) {
        sawRateLimit = true;
        retryAfterSecs = parseRetryAfter(upstream.headers, retryAfterSecs);
        console.warn(
          `[groq-proxy] 429 em "${model}" (task "${task}", passada ${pass + 1}). ` +
          `retry-after=${retryAfterSecs}s`,
        );
        continue;
      }

      // ── Sucesso (ou erro que não vale retentar) ────────────────────────
      return new Response(body, {
        status: upstream.status,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "x-model-used": model,
          ...(retired.length ? { "x-model-fallback": retired.join(",") } : {}),
        },
      });
    }

    // Cadeia inteira esgotada nesta passada. Se foi por 429, espera e repete.
    if (sawRateLimit && pass === 0) {
      const wait = Math.min(retryAfterSecs, MAX_BACKOFF_SECS);
      console.warn(
        `[groq-proxy] cadeia "${task}" toda limitada — aguardando ${wait}s`,
      );
      await sleep(wait * 1000);
      continue;
    }
    break;
  }

  // Rate limit persistente. 429 com mensagem que o usuário entende — o app
  // repassa `error.message` direto para a tela.
  if (sawRateLimit) {
    console.error(
      `[groq-proxy] 429 persistente na task "${task}" apos backoff. ` +
      `Free tier: 30 RPM / 8k TPM / 1k RPD / 200k TPD por organizacao.`,
    );
    return new Response(
      JSON.stringify({
        error: {
          message:
            "Muita gente usando a IA agora. Espere alguns segundos e tente de novo.",
        },
      }),
      {
        status: 429,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
          "Retry-After": String(Math.min(retryAfterSecs, MAX_BACKOFF_SECS)),
        },
      },
    );
  }

  // Inalcançável: o loop sempre retorna ou cai no 429 acima.
  return json(502, { error: { message: "Erro no proxy Groq" } });
});
