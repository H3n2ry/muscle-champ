import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { Webhook } from "npm:standardwebhooks@1.0.0";

// ─── Por que esta função existe ─────────────────────────────────────────────
//
// O Brevo anexa `List-Unsubscribe` em TUDO que sai pelo SMTP, e não tem como
// desligar: campanha e transacional dividem o mesmo caminho e eles não
// conseguem distinguir. No Gmail isso vira um botão "Unsubscribe" no e-mail de
// confirmação de cadastro.
//
// Num e-mail de autenticação isso é armadilha: quem clicar entra na blocklist
// do Brevo e **para de receber código de recuperação de senha em silêncio** —
// sem erro no app, sem nada nos logs de auth, porque o envio simplesmente não
// acontece. A pessoa perde a conta e ninguém entende por quê.
//
// A API transacional do Brevo NÃO adiciona o cabeçalho. Então o Auth passa a
// chamar esta função em vez de mandar por SMTP.
//
// Ganho secundário: os templates saem do painel e entram no controle de
// versão — mesma razão pela qual a `groq-proxy` foi versionada.
//
// ⚠️ Deploy com `--no-verify-jwt`. O Auth chama isto server-side, sem JWT de
// usuário. É por isso que a verificação de assinatura abaixo não é opcional:
// sem ela, quem descobrisse a URL mandaria e-mail arbitrário pelo domínio.

const BREVO_URL = "https://api.brevo.com/v3/smtp/email";
const REMETENTE = { name: "Muscle Champ", email: "noreply@musclechamp.com.br" };

/// Minutos de validade do código, exibidos no corpo do e-mail.
///
/// Precisa bater com Authentication → Sessions → Email OTP Expiration no
/// painel. Prometer 60 e expirar em 10 gera chamado de suporte.
const VALIDADE_MIN = 60;

type PayloadDeEmail = {
  user: { email: string };
  email_data: {
    token: string;
    email_action_type: string;
  };
};

// ─── Templates ──────────────────────────────────────────────────────────────
//
// Os dois compartilham moldura, cabeçalho e bloco de código de propósito.
// E-mail de autenticação é o que um golpe imita: se a redefinição de senha
// chegasse num visual diferente da confirmação de cadastro, o usuário teria
// motivo para desconfiar do e-mail legítimo.
//
// Tabela e CSS inline não são preferência — Gmail descarta <style> no <head>,
// Outlook quebra flex/grid, e recurso remoto (imagem, fonte) vem bloqueado por
// padrão. O lime da marca (#7EFC00) some no branco, por isso "CHAMP" usa um
// verde mais fechado e o lime fica no bloco de código, que tem fundo escuro.

function moldura(titulo: string, abertura: string, codigo: string, aviso: string): string {
  return `<div style="margin:0;padding:0;background-color:#f4f4f5;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
         style="background-color:#f4f4f5;padding:32px 12px;">
    <tr><td align="center">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0"
             style="max-width:520px;background-color:#ffffff;border-radius:16px;padding:40px 32px;
                    font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
        <tr><td style="padding-bottom:28px;">
          <span style="font-size:20px;font-weight:800;letter-spacing:1px;color:#121413;">MUSCLE</span><span style="font-size:20px;font-weight:800;letter-spacing:1px;color:#5FA700;">CHAMP</span>
        </td></tr>
        <tr><td style="font-size:22px;font-weight:700;color:#121413;padding-bottom:14px;">${titulo}</td></tr>
        <tr><td style="font-size:15px;line-height:1.6;color:#3f3f46;padding-bottom:26px;">${abertura}</td></tr>
        <tr><td align="center" style="padding-bottom:24px;">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%">
            <tr><td align="center" style="background-color:#121413;border-radius:14px;padding:26px 16px;">
              <span style="font-family:'SFMono-Regular',Consolas,'Liberation Mono',Menlo,monospace;
                           font-size:34px;font-weight:700;letter-spacing:8px;color:#7EFC00;">${codigo}</span>
            </td></tr>
          </table>
        </td></tr>
        <tr><td style="font-size:14px;line-height:1.6;color:#52525b;padding-bottom:26px;">
          O código expira em <strong>${VALIDADE_MIN} minutos</strong> e só pode ser usado uma vez.
        </td></tr>
        <tr><td style="border-top:1px solid #e4e4e7;padding-top:22px;">
          <table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%"
                 style="background-color:#fafafa;border-radius:10px;">
            <tr><td style="padding:16px 18px;font-size:13px;line-height:1.6;color:#52525b;">${aviso}</td></tr>
          </table>
        </td></tr>
        <tr><td style="padding-top:26px;font-size:12px;line-height:1.6;color:#a1a1aa;">
          Muscle Champ — treino, dieta e ranking.<br>Este é um e-mail automático; não responda.
        </td></tr>
      </table>
    </td></tr>
  </table>
</div>`;
}

/// O aviso final é a única diferença de conteúdo entre os dois, e ela importa:
/// no cadastro "ignore" basta, mas um pedido de redefinição que a pessoa não
/// fez pode ser alguém tentando entrar na conta dela — aí é preciso dizer que
/// **nada mudou**, senão o e-mail legítimo vira motivo de pânico.
function montarEmail(acao: string, codigo: string): { subject: string; html: string } | null {
  switch (acao) {
    case "signup":
      return {
        subject: "Confirme seu e-mail — Muscle Champ",
        html: moldura(
          "Confirme seu e-mail",
          "Falta um passo para ativar sua conta. Use o código abaixo no app:",
          codigo,
          `<strong style="color:#121413;">Não foi você?</strong><br>Alguém pode ter digitado seu e-mail por engano. Ignore esta mensagem — sem o código, nenhuma conta é criada com o seu endereço.`,
        ),
      };
    case "recovery":
      return {
        subject: "Redefinir sua senha — Muscle Champ",
        html: moldura(
          "Redefinir sua senha",
          "Recebemos um pedido para redefinir a senha da sua conta. Use o código abaixo no app para criar uma senha nova:",
          codigo,
          `<strong style="color:#121413;">Não foi você?</strong><br>Ignore este e-mail — <strong>sua senha continua a mesma</strong> e nada muda na sua conta. Ninguém consegue trocá-la sem este código.`,
        ),
      };
    case "email_change":
      return {
        subject: "Confirme seu novo e-mail — Muscle Champ",
        html: moldura(
          "Confirme seu novo e-mail",
          "Use o código abaixo para confirmar a troca de endereço da sua conta:",
          codigo,
          `<strong style="color:#121413;">Não foi você?</strong><br>Sua conta pode estar comprometida. Ignore este e-mail e troque sua senha imediatamente.`,
        ),
      };
    default:
      // Ação não mapeada (magiclink, invite). Devolver null faz a função
      // responder 200 sem enviar — melhor que mandar um e-mail com o texto
      // errado. Se algum dia esses fluxos existirem, entram aqui.
      return null;
  }
}

// Cache da chave por instância, mesmo padrão da groq-proxy: evita uma consulta
// ao Vault por requisição.
let chaveBrevo: string | null = null;

async function obterChaveBrevo(): Promise<string> {
  if (chaveBrevo) return chaveBrevo;
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data, error } = await admin.rpc("get_brevo_api_key");
  if (error || !data) {
    throw new Error(`Falha ao ler chave do Vault: ${error?.message}`);
  }
  chaveBrevo = data as string;
  return chaveBrevo;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Método não permitido", { status: 405 });
  }

  const bruto = await req.text();

  // Sem JWT gate (o Auth chama server-side), a assinatura é a ÚNICA barreira.
  // Falhar aqui tem que ser 401, nunca "deixa passar".
  const segredo = Deno.env.get("SEND_EMAIL_HOOK_SECRET");
  if (!segredo) {
    console.error("[enviar-email-auth] SEND_EMAIL_HOOK_SECRET nao configurado");
    return new Response("Configuração ausente", { status: 500 });
  }

  let payload: PayloadDeEmail;
  try {
    // O segredo vem do painel no formato `v1,whsec_<base64>`; a lib espera só
    // a parte base64.
    const wh = new Webhook(segredo.replace("v1,whsec_", ""));
    payload = wh.verify(
      bruto,
      Object.fromEntries(req.headers),
    ) as PayloadDeEmail;
  } catch (e) {
    console.error(`[enviar-email-auth] assinatura invalida: ${e}`);
    return new Response("Assinatura inválida", { status: 401 });
  }

  const destino = payload.user?.email;
  const codigo = payload.email_data?.token;
  const acao = payload.email_data?.email_action_type;

  if (!destino || !codigo) {
    console.error(`[enviar-email-auth] payload incompleto (acao: ${acao})`);
    return new Response("Payload incompleto", { status: 400 });
  }

  const email = montarEmail(acao, codigo);
  if (!email) {
    console.warn(`[enviar-email-auth] acao sem template: ${acao} — nada enviado`);
    return new Response(JSON.stringify({}), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const resposta = await fetch(BREVO_URL, {
    method: "POST",
    headers: {
      "api-key": await obterChaveBrevo(),
      "Content-Type": "application/json",
      "Accept": "application/json",
    },
    body: JSON.stringify({
      sender: REMETENTE,
      to: [{ email: destino }],
      subject: email.subject,
      htmlContent: email.html,
    }),
  });

  if (!resposta.ok) {
    const detalhe = await resposta.text();
    console.error(
      `[enviar-email-auth] Brevo recusou (${resposta.status}) na acao "${acao}": ${detalhe}`,
    );
    // Devolver erro faz o Auth reverter a operação — no cadastro isso evita
    // deixar usuário órfão sem confirmação, que travaria o e-mail para sempre
    // com "já cadastrado".
    return new Response(
      JSON.stringify({
        error: { http_code: resposta.status, message: "Falha ao enviar o e-mail" },
      }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  return new Response(JSON.stringify({}), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
