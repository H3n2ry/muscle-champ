# Templates de e-mail do Supabase Auth

Cópias versionadas dos templates que vivem em **Authentication → Emails →
Templates** no painel do Supabase.

## Por que estão aqui

Mesma razão que levou a Edge Function `groq-proxy` para o repositório: eles só
existiam deployados. Um template de e-mail não é enfeite — ele carrega o código
de confirmação e o de redefinição de senha. Se o projeto Supabase for recriado,
ou alguém salvar por cima, não há de onde restaurar e o cadastro quebra sem
deixar rastro no código.

**O painel continua sendo a versão que roda.** Estes arquivos são a referência:
ao alterar o template no painel, replicar aqui no mesmo commit.

## Arquivos

| Arquivo | Template no painel | Estado |
|---------|-------------------|--------|
| `confirm-signup.html` | Confirm signup | **A aplicar** — substitui a versão sem moldura que está no ar |
| `reset-password.html` | Reset Password | **A aplicar** |

Os dois compartilham a mesma moldura, o mesmo cabeçalho de marca e o mesmo bloco
de código — só mudam título, abertura e aviso final. E-mail de autenticação é
justamente o que um golpe imita: se a redefinição de senha chegasse num visual
diferente da confirmação de cadastro, o usuário teria motivo para desconfiar do
e-mail legítimo. Ao editar um, replicar a estrutura no outro.

A diferença que importa está no aviso final. No cadastro basta "ignore". Na
redefinição é preciso dizer que **a senha continua a mesma**, porque um pedido
que a pessoa não fez pode ser alguém tentando entrar na conta dela — e um aviso
mudo transformaria o e-mail legítimo em motivo de pânico.

## Restrições de HTML em e-mail

Não são preferências de estilo, são limitações dos clientes:

- **Layout em tabela**, não flex/grid — Outlook renderiza com um motor antigo
- **CSS inline**, nunca `<style>` no `<head>` — Gmail descarta
- **Sem imagem e sem fonte externa** — recurso remoto vem bloqueado por padrão,
  e um logo que não carrega deixa um retângulo vazio no lugar da marca
- **`#7EFC00` só sobre fundo escuro** — o lime da marca some no branco; por isso
  "CHAMP" no cabeçalho usa `#5FA700` e o lime fica reservado ao bloco do código

## Regra que não pode ser quebrada

Todo template precisa conter **`{{ .Token }}`**, não `{{ .ConfirmationURL }}`.

O app lê código de 8 dígitos, não link: `verifyOtp` na confirmação de cadastro
(`OtpType.signup`) e `resetPassword` na redefinição (`OtpType.recovery`), ambos
em `lib/features/auth/data/repositories/auth_repository.dart`. Um template com
link entrega um e-mail que parece certo e trava a tela esperando um código que
nunca chega.

## Ao testar

O envio passa pelo SMTP do Brevo (ver `CLAUDE.md`, seção "Signup email runs
through Brevo SMTP"). Se o e-mail não chegar, o erro real aparece nos logs de
auth do Supabase — não no app, que só mostra mensagem genérica.
