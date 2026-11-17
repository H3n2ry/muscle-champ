// Peças comuns às funções do Asaas (assinar, webhook, cancelar).
//
// O Asaas cobra o site. Quem decide que alguém pagou é o webhook, nunca o
// navegador: a página só pede para assinar e depois lê `assinaturas`.
//
// Secrets (Edge Functions → Secrets, um valor por projeto):
//   ASAAS_API_KEY       chave da conta. Começa com `$aact_hmlg_` no sandbox.
//   ASAAS_WEBHOOK_TOKEN o mesmo texto cadastrado no webhook do painel do Asaas.
//   ASAAS_AMBIENTE      "producao" para a conta real; qualquer outra coisa,
//                       ou ausente, usa o sandbox. Errar para o lado do
//                       sandbox nunca cobra ninguém.

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

let adminClient: SupabaseClient | null = null;
export function admin(): SupabaseClient {
  adminClient ??= createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  return adminClient;
}

/// Id do usuário dono do JWT, ou null. A anon key não tem `sub` e é recusada
/// pelo Auth — ver o comentário de `identificar` no groq-proxy.
export async function usuarioDaRequisicao(req: Request): Promise<string | null> {
  const jwt = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!jwt) return null;
  const { data, error } = await admin().auth.getUser(jwt);
  if (error || !data?.user) return null;
  return data.user.id;
}

export function iguaisEmTempoConstante(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a);
  const eb = new TextEncoder().encode(b);
  if (ea.length !== eb.length) return false;
  let diferenca = 0;
  for (let i = 0; i < ea.length; i++) diferenca |= ea[i] ^ eb[i];
  return diferenca === 0;
}

// ─── Planos ─────────────────────────────────────────────────────────────────
//
// Mesmos números de `lib/features/subscription/data/models/plano.dart` e
// `VALORES.md`, em centavos. O preço do site sai DAQUI, não do navegador: o
// cliente manda só o id do plano.

export type PlanoId = "mensal" | "trimestral" | "anual";

export const PLANOS: Record<PlanoId, {
  entrada: number;
  renovacao: number;
  meses: number;
  ciclo: "MONTHLY" | "QUARTERLY" | "YEARLY";
  descricao: string;
}> = {
  mensal: { entrada: 1990, renovacao: 1990, meses: 1, ciclo: "MONTHLY", descricao: "Muscle Champ Pro — mensal" },
  trimestral: { entrada: 4990, renovacao: 4990, meses: 3, ciclo: "QUARTERLY", descricao: "Muscle Champ Pro — trimestral" },
  anual: { entrada: 11990, renovacao: 14990, meses: 12, ciclo: "YEARLY", descricao: "Muscle Champ Pro — anual" },
};

export const DIAS_DE_TRIAL = 14;

/// Folga depois do vencimento antes de cortar o acesso. O Pix cai na hora,
/// mas o cartão pode levar um dia para confirmar e o webhook pode atrasar;
/// sem folga, quem paga em dia perderia o Pro por algumas horas.
export const DIAS_DE_TOLERANCIA = 3;

export function ehPlanoId(v: unknown): v is PlanoId {
  return v === "mensal" || v === "trimestral" || v === "anual";
}

/// `externalReference` da assinatura no Asaas: `<user_id>:<plano>`. É assim
/// que o webhook sabe de quem é o pagamento sem depender da nossa tabela.
export function referencia(userId: string, plano: PlanoId): string {
  return `${userId}:${plano}`;
}

export function lerReferencia(ref: unknown): { userId: string; plano: PlanoId } | null {
  if (typeof ref !== "string") return null;
  const [userId, plano] = ref.split(":");
  if (!/^[0-9a-f-]{36}$/i.test(userId ?? "") || !ehPlanoId(plano)) return null;
  return { userId, plano };
}

// ─── Datas ──────────────────────────────────────────────────────────────────
//
// O Asaas trabalha com datas sem hora (`YYYY-MM-DD`), no horário de Brasília.

export function hojeEmBrasilia(): string {
  return new Date(Date.now() - 3 * 3600_000).toISOString().slice(0, 10);
}

export function somarDias(data: string, dias: number): string {
  const d = new Date(`${data}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() + dias);
  return d.toISOString().slice(0, 10);
}

export function somarMeses(data: string, meses: number): string {
  const d = new Date(`${data}T12:00:00Z`);
  const dia = d.getUTCDate();
  d.setUTCDate(1);
  d.setUTCMonth(d.getUTCMonth() + meses);
  // 31/01 + 1 mês = 28/02 (ou 29), não 03/03.
  const ultimo = new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth() + 1, 0)).getUTCDate();
  d.setUTCDate(Math.min(dia, ultimo));
  return d.toISOString().slice(0, 10);
}

/// Fim do dia em Brasília, como timestamptz. `expira_em` é comparado com
/// now() no banco; meia-noite UTC cortaria o acesso às 21h do dia anterior.
export function fimDoDia(data: string): string {
  return `${data}T23:59:59-03:00`;
}

// ─── CPF ────────────────────────────────────────────────────────────────────

export function apenasDigitos(v: string): string {
  return v.replace(/\D/g, "");
}

export function cpfValido(v: string): boolean {
  const cpf = apenasDigitos(v);
  if (cpf.length !== 11 || /^(\d)\1{10}$/.test(cpf)) return false;
  const dv = (base: string, pesoInicial: number) => {
    let soma = 0;
    for (let i = 0; i < base.length; i++) soma += Number(base[i]) * (pesoInicial - i);
    const resto = (soma * 10) % 11;
    return resto === 10 ? 0 : resto;
  };
  return dv(cpf.slice(0, 9), 10) === Number(cpf[9]) &&
    dv(cpf.slice(0, 10), 11) === Number(cpf[10]);
}

// ─── API do Asaas ───────────────────────────────────────────────────────────

function baseUrl(): string {
  return Deno.env.get("ASAAS_AMBIENTE") === "producao"
    ? "https://api.asaas.com/v3"
    : "https://api-sandbox.asaas.com/v3";
}

export class ErroAsaas extends Error {
  constructor(public status: number, public corpo: unknown) {
    super(`Asaas respondeu ${status}`);
  }
}

export async function asaas<T = Record<string, unknown>>(
  metodo: "GET" | "POST" | "DELETE",
  caminho: string,
  corpo?: unknown,
): Promise<T> {
  const chave = Deno.env.get("ASAAS_API_KEY");
  if (!chave) throw new Error("ASAAS_API_KEY ausente");
  const resp = await fetch(`${baseUrl()}${caminho}`, {
    method: metodo,
    headers: {
      "access_token": chave,
      "Content-Type": "application/json",
      "User-Agent": "muscle-champ",
    },
    body: corpo === undefined ? undefined : JSON.stringify(corpo),
  });
  const texto = await resp.text();
  let dados: unknown = null;
  try {
    dados = texto ? JSON.parse(texto) : null;
  } catch {
    dados = texto;
  }
  if (!resp.ok) throw new ErroAsaas(resp.status, dados);
  return dados as T;
}

/// Reais com duas casas, como o Asaas espera (`19.9`). Centavos inteiros
/// divididos por 100 dão o número exato que o JSON precisa.
export function emReais(centavos: number): number {
  return centavos / 100;
}

export function emCentavos(reais: unknown): number {
  return Math.round(Number(reais) * 100);
}
