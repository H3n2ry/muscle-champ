// Cancela a assinatura do site.
//
// POST sem corpo, com o JWT do usuário. Cancela no Asaas (que apaga as
// cobranças futuras) e marca a linha como cancelada. O acesso continua até o
// fim do período já pago: `expira_em` não muda.
//
// Assinatura do Google Play não se cancela aqui: o app abre a tela de
// assinaturas da Play Store, como a política do Google exige.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  admin,
  asaas,
  corsHeaders,
  ErroAsaas,
  json,
  usuarioDaRequisicao,
} from "../_shared/asaas.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { erro: "metodo" });

  const uid = await usuarioDaRequisicao(req);
  if (!uid) return json(401, { erro: "nao_autenticado" });

  const db = admin();
  const { data: atual } = await db
    .from("assinaturas")
    .select("*")
    .eq("user_id", uid)
    .maybeSingle();

  if (!atual) return json(404, { erro: "sem_assinatura" });
  if (atual.origem !== "asaas") {
    return json(409, { erro: "cancelar_pelo_canal", origem: atual.origem });
  }
  if (!atual.renova) return json(200, { status: "cancelada", expiraEm: atual.expira_em });

  try {
    await asaas("DELETE", `/subscriptions/${atual.id_externo}`);
  } catch (e) {
    // 404: já não existe no Asaas. Segue e marca como cancelada aqui.
    if (!(e instanceof ErroAsaas && e.status === 404)) {
      console.error(`[asaas-cancelar] ${e}`);
      return json(502, { erro: "asaas_recusou" });
    }
  }

  // Também vale no trial: o acesso vai até o 14º dia, como no Google Play.
  // Não abre brecha, porque quem não cancela e não paga perde o Pro do mesmo
  // jeito no vencimento.
  const expiraEm = atual.expira_em;

  const { error } = await db.rpc("gravar_assinatura", {
    p_user_id: uid,
    p_origem: "asaas",
    p_id_externo: atual.id_externo,
    p_plano_id: atual.plano_id,
    p_status: "cancelada",
    p_expira_em: expiraEm,
    p_em_trial: false,
    p_proxima_cobranca: 0,
    p_renova: false,
  });
  if (error) {
    console.error(`[asaas-cancelar] gravar_assinatura: ${error.message}`);
    return json(500, { erro: "interno" });
  }

  return json(200, { status: "cancelada", expiraEm });
});
