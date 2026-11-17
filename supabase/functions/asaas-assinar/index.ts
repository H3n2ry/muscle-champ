// Assina o Pro pelo site, via Asaas.
//
// POST { plano: "mensal" | "trimestral" | "anual", nome, cpf, forma: "cartao" | "pix" }
// com o JWT do usuário.
//
// Devolve { status: "trial" | "aguardando_pagamento", linkPagamento? }.
//
// O que esta função NÃO faz: dar o Pro a quem não pagou. A única exceção é a
// avaliação gratuita (uma por conta, somando app e site), que começa aqui
// porque não há pagamento a esperar. Fora dela, o Pro só chega pelo webhook.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  admin,
  apenasDigitos,
  asaas,
  corsHeaders,
  cpfValido,
  DIAS_DE_TRIAL,
  ehPlanoId,
  emReais,
  ErroAsaas,
  fimDoDia,
  hojeEmBrasilia,
  json,
  PLANOS,
  referencia,
  somarDias,
  usuarioDaRequisicao,
} from "../_shared/asaas.ts";

type Pagina<T> = { data: T[] };

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { erro: "metodo" });

  const uid = await usuarioDaRequisicao(req);
  if (!uid) return json(401, { erro: "nao_autenticado" });

  let corpo: Record<string, unknown>;
  try {
    corpo = await req.json();
  } catch {
    return json(400, { erro: "corpo_invalido" });
  }

  const plano = corpo.plano;
  const nome = typeof corpo.nome === "string" ? corpo.nome.trim() : "";
  const cpf = typeof corpo.cpf === "string" ? apenasDigitos(corpo.cpf) : "";
  const forma = corpo.forma;
  if (!ehPlanoId(plano)) return json(400, { erro: "plano_invalido" });
  if (nome.length < 3 || nome.length > 120) return json(400, { erro: "nome_invalido" });
  if (!cpfValido(cpf)) return json(400, { erro: "cpf_invalido" });
  if (forma !== "cartao" && forma !== "pix") return json(400, { erro: "forma_invalida" });

  const db = admin();

  // Já paga por algum canal e ainda vale? Não vende de novo: seria cobrar
  // duas vezes pelo mesmo Pro. A demo não conta.
  const { data: atual } = await db
    .from("assinaturas")
    .select("origem, status, expira_em")
    .eq("user_id", uid)
    .maybeSingle();
  if (
    atual && atual.origem !== "demo" &&
    new Date(atual.expira_em) > new Date() &&
    ["trial", "ativa", "em_atraso"].includes(atual.status)
  ) {
    return json(409, { erro: "assinatura_ativa_em_outro_canal", origem: atual.origem });
  }

  const { data: trialUsado } = await db
    .from("trial_usado").select("user_id").eq("user_id", uid).maybeSingle();
  const comTrial = !trialUsado;

  const { data: usuario } = await db.auth.admin.getUserById(uid);
  const email = usuario?.user?.email;

  const p = PLANOS[plano];
  const hoje = hojeEmBrasilia();
  const primeiroVencimento = comTrial ? somarDias(hoje, DIAS_DE_TRIAL) : hoje;

  try {
    // Um cliente no Asaas por conta. Procurar antes de criar evita duplicar
    // quem desiste no meio e tenta de novo.
    const achados = await asaas<Pagina<{ id: string }>>(
      "GET",
      `/customers?externalReference=${encodeURIComponent(uid)}`,
    );
    const clienteId = achados.data[0]?.id ??
      (await asaas<{ id: string }>("POST", "/customers", {
        name: nome,
        cpfCnpj: cpf,
        email,
        externalReference: uid,
        // O Asaas manda e-mail e SMS de cobrança por padrão. Desligado: os
        // avisos vêm do app.
        notificationDisabled: true,
      })).id;

    const assinatura = await asaas<{ id: string }>("POST", "/subscriptions", {
      customer: clienteId,
      // TODO Pix Automático: hoje "PIX" gera uma cobrança Pix por ciclo, que a
      // pessoa paga pelo link. O Pix Automático (débito autorizado uma vez)
      // depende de o Asaas liberar na conta; entra quando for testado.
      billingType: forma === "cartao" ? "CREDIT_CARD" : "PIX",
      value: emReais(p.entrada),
      nextDueDate: primeiroVencimento,
      cycle: p.ciclo,
      description: p.descricao,
      externalReference: referencia(uid, plano),
    });

    if (comTrial) {
      const { error } = await db.rpc("gravar_assinatura", {
        p_user_id: uid,
        p_origem: "asaas",
        p_id_externo: assinatura.id,
        p_plano_id: plano,
        p_status: "trial",
        p_expira_em: fimDoDia(primeiroVencimento),
        p_em_trial: true,
        p_proxima_cobranca: p.entrada,
        p_renova: true,
      });
      if (error) {
        // Não deixa uma assinatura órfã cobrando no Asaas.
        await asaas("DELETE", `/subscriptions/${assinatura.id}`).catch(() => {});
        console.error(`[asaas-assinar] gravar_assinatura: ${error.message}`);
        return json(409, { erro: error.message });
      }
      return json(200, { status: "trial", expiraEm: primeiroVencimento });
    }

    // Sem trial: o Pro só vem quando o webhook confirmar o pagamento. O link é
    // a página do próprio Asaas, onde o cartão é digitado ou o Pix é pago:
    // número de cartão nunca passa por nós.
    const cobrancas = await asaas<Pagina<{ invoiceUrl: string }>>(
      "GET",
      `/subscriptions/${assinatura.id}/payments`,
    );
    return json(200, {
      status: "aguardando_pagamento",
      linkPagamento: cobrancas.data[0]?.invoiceUrl ?? null,
    });
  } catch (e) {
    if (e instanceof ErroAsaas) {
      console.error(`[asaas-assinar] ${e.status}: ${JSON.stringify(e.corpo)}`);
      return json(502, { erro: "asaas_recusou" });
    }
    console.error(`[asaas-assinar] ${e}`);
    return json(500, { erro: "interno" });
  }
});
