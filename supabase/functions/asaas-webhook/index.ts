// Recebe os avisos do Asaas e mantém `assinaturas` igual ao que o Asaas diz.
//
// Publicar SEM verificação de JWT (`--no-verify-jwt`): quem chama é o Asaas.
// A autenticidade vem do cabeçalho `asaas-access-token`, que tem de bater com
// o secret ASAAS_WEBHOOK_TOKEN (o mesmo texto cadastrado no painel).
//
// Respostas:
//   200 → processado, ou ignorado de propósito. O Asaas não reenvia.
//   401 → token errado.
//   500 → falhou do nosso lado. O Asaas reenvia, e o registro em
//         `eventos_pagamento` garante que o reenvio não conte duas vezes.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  admin,
  asaas,
  DIAS_DE_TOLERANCIA,
  emCentavos,
  emReais,
  fimDoDia,
  iguaisEmTempoConstante,
  lerReferencia,
  PLANOS,
  somarDias,
  somarMeses,
} from "../_shared/asaas.ts";

type Cobranca = {
  id: string;
  subscription?: string;
  value: number;
  dueDate: string;
  status: string;
};

type AssinaturaAsaas = {
  id: string;
  value: number;
  nextDueDate: string;
  externalReference?: string;
  status: string;
};

const EVENTOS_DE_PAGAMENTO = new Set(["PAYMENT_CONFIRMED", "PAYMENT_RECEIVED"]);
const EVENTOS_DE_ATRASO = new Set(["PAYMENT_OVERDUE"]);
const EVENTOS_DE_ESTORNO = new Set([
  "PAYMENT_REFUNDED",
  "PAYMENT_CHARGEBACK_REQUESTED",
  "PAYMENT_CHARGEBACK_DISPUTE",
]);
const EVENTOS_DE_FIM = new Set(["SUBSCRIPTION_DELETED", "SUBSCRIPTION_INACTIVATED"]);

function ok(): Response {
  return new Response("ok", { status: 200 });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return new Response("metodo", { status: 405 });

  const esperado = Deno.env.get("ASAAS_WEBHOOK_TOKEN");
  const recebido = req.headers.get("asaas-access-token") ?? "";
  if (!esperado || !iguaisEmTempoConstante(esperado, recebido)) {
    return new Response("token", { status: 401 });
  }

  let evento: Record<string, unknown>;
  try {
    evento = await req.json();
  } catch {
    return new Response("corpo", { status: 400 });
  }

  const idEvento = typeof evento.id === "string" ? evento.id : null;
  const tipo = typeof evento.event === "string" ? evento.event : "";
  if (!idEvento || !tipo) return new Response("corpo", { status: 400 });

  const db = admin();

  // Registra antes de processar. Se já existe e foi processado, é reenvio:
  // responde 200 sem fazer nada. Se existe e não foi (falhou da outra vez),
  // processa de novo.
  const { error: erroInsert } = await db.from("eventos_pagamento").insert({
    origem: "asaas",
    id_evento: idEvento,
    tipo,
    payload: evento,
  });
  if (erroInsert && erroInsert.code !== "23505") {
    console.error(`[asaas-webhook] registrar: ${erroInsert.message}`);
    return new Response("erro", { status: 500 });
  }
  if (erroInsert) {
    const { data: anterior } = await db
      .from("eventos_pagamento")
      .select("processado_em")
      .eq("origem", "asaas").eq("id_evento", idEvento)
      .single();
    if (anterior?.processado_em) return ok();
  }

  try {
    const userId = await processar(tipo, evento);
    await db.from("eventos_pagamento")
      .update({ processado_em: new Date().toISOString(), erro: null, user_id: userId })
      .eq("origem", "asaas").eq("id_evento", idEvento);
    return ok();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`[asaas-webhook] ${tipo} ${idEvento}: ${msg}`);
    await db.from("eventos_pagamento")
      .update({ erro: msg })
      .eq("origem", "asaas").eq("id_evento", idEvento);
    return new Response("erro", { status: 500 });
  }
});

/// Aplica o evento. Devolve o user_id afetado, ou null se o evento não é de
/// assinatura nossa (cobrança avulsa, evento que não usamos).
async function processar(tipo: string, evento: Record<string, unknown>): Promise<string | null> {
  const cobranca = evento.payment as Cobranca | undefined;
  const idAssinatura = cobranca?.subscription ??
    (evento.subscription as { id?: string } | undefined)?.id;
  if (!idAssinatura) return null;

  // Sempre lê a assinatura no Asaas em vez de confiar no corpo do aviso: o
  // aviso pode chegar fora de ordem, e o que vale é o estado atual de lá.
  const sub = await asaas<AssinaturaAsaas>("GET", `/subscriptions/${idAssinatura}`);
  const ref = lerReferencia(sub.externalReference);
  if (!ref) return null; // assinatura criada fora do app
  const plano = PLANOS[ref.plano];

  const gravar = (campos: {
    status: string;
    expiraEm: string;
    emTrial: boolean;
    renova: boolean;
  }) =>
    admin().rpc("gravar_assinatura", {
      p_user_id: ref.userId,
      p_origem: "asaas",
      p_id_externo: sub.id,
      p_plano_id: ref.plano,
      p_status: campos.status,
      p_expira_em: campos.expiraEm,
      p_em_trial: campos.emTrial,
      p_proxima_cobranca: emCentavos(sub.value),
      p_renova: campos.renova,
    }).then(({ error }) => {
      if (error) throw new Error(`gravar_assinatura: ${error.message}`);
    });

  if (EVENTOS_DE_PAGAMENTO.has(tipo) && cobranca) {
    // Pago: vale do vencimento desta cobrança até o próximo, mais a folga.
    const ate = somarDias(somarMeses(cobranca.dueDate, plano.meses), DIAS_DE_TOLERANCIA);
    await gravar({ status: "ativa", expiraEm: fimDoDia(ate), emTrial: false, renova: true });

    // Anual: o primeiro ano custa a entrada; a partir da segunda cobrança, o
    // preço de renovação. Só as cobranças futuras mudam.
    if (emCentavos(sub.value) !== plano.renovacao) {
      await asaas("POST", `/subscriptions/${sub.id}`, {
        value: emReais(plano.renovacao),
        updatePendingPayments: true,
      });
    }
    return ref.userId;
  }

  if (EVENTOS_DE_ATRASO.has(tipo) && cobranca) {
    // Atrasou: mantém o acesso até o fim da folga contada do vencimento. Se o
    // pagamento chegar depois, PAYMENT_RECEIVED reativa.
    const ate = somarDias(cobranca.dueDate, DIAS_DE_TOLERANCIA);
    await gravar({ status: "em_atraso", expiraEm: fimDoDia(ate), emTrial: false, renova: true });
    return ref.userId;
  }

  if (EVENTOS_DE_ESTORNO.has(tipo)) {
    // Dinheiro devolvido: o acesso acaba agora.
    await gravar({ status: "expirada", expiraEm: new Date().toISOString(), emTrial: false, renova: false });
    return ref.userId;
  }

  if (EVENTOS_DE_FIM.has(tipo)) {
    // Cancelada no Asaas (pelo nosso botão ou pelo painel). Quem já pagou
    // segue até o fim do período; isso já está em `expira_em`, que não muda.
    const { data: atual } = await admin()
      .from("assinaturas").select("expira_em, id_externo")
      .eq("user_id", ref.userId).maybeSingle();
    if (!atual || atual.id_externo !== sub.id) return ref.userId;
    await gravar({ status: "cancelada", expiraEm: atual.expira_em, emTrial: false, renova: false });
    return ref.userId;
  }

  return ref.userId;
}
