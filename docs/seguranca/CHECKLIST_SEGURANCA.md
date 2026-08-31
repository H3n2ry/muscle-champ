# CHECKLIST DE SEGURANÇA — Pré-Deploy
## Muscle Champ

> Executar este checklist antes de cada release publicado na Play Store ou no Cloudflare Pages.

---

## 🔴 Crítico — Bloqueia o Deploy

- [x] **Chaves de API fora do código-fonte** — ✅ chave Groq no Supabase Vault (via Edge Function `groq-proxy`); `secrets.dart` só tem URL + anonKey (pública por design)
- [x] **`.env` ou arquivos de secrets não commitados** — ✅ `lib/core/secrets.dart` no `.gitignore`, confirmado
- [x] **RLS ativa em todas as tabelas** — ✅ auditado 2026-06; todas as tabelas com políticas owner-scoped (`auth.uid()`)
- [x] **Confirmação de e-mail habilitada** — ✅ verificado 28/08/2026: cadastro dispara código de confirmação e `/signup` retorna 200
- [x] **Credenciais SMTP fora do repositório** — ✅ a chave SMTP do Brevo existe só no painel do Supabase (Authentication → Emails); nunca em arquivo versionado. O Supabase não reexibe o campo depois de salvar — campo em branco significa oculto, não perdido

---

## 🟡 Alto — Deve ser Verificado

- [ ] **`flutter analyze` sem erros** — `cd app && flutter analyze` retorna 0 issues
- [ ] **Sem `print()` com dados pessoais** — `grep -r "print(" lib/ | grep -v "//"`
- [ ] **Inputs de formulário validados** — campos de peso (0-500kg), altura (50-250cm), calorias (0-10000) com limites
- [ ] **Timeout configurado nas chamadas Groq** — `.timeout(Duration(seconds: 30))` ✅ já implementado
- [ ] **HTTPS em todos os endpoints** — nenhuma URL `http://` no código
- [ ] **Versão do SDK Flutter atualizada** — `flutter upgrade` e verificar release notes de segurança

---

## 🟢 Recomendado

- [ ] **`flutter build apk --obfuscate --split-debug-info=./debug-info`** — dificulta engenharia reversa
- [ ] **Verificar dependências desatualizadas** — `flutter pub outdated`
- [ ] **Logs sem stack traces expostos ao usuário** — mensagens de erro amigáveis nas páginas
- [x] **Supabase: revisar políticas RLS** das tabelas `workouts`, `diet_logs`, `points`, `friendships` — ✅ auditadas; `points` INSERT travado em `auth.uid() = user_id`
- [ ] **Groq: verificar se há CVEs no modelo em uso** — acompanhar https://groq.com/security
- [x] **Bucket `avatars`: confirmar que não é listável** — ✅ listagem restrita à pasta do dono; exibição via URL pública
- [ ] **Rate limiting na chamada de foto** — cooldown entre chamadas ao `analyzeFoodPhoto`
- [ ] **Web: verificar Content-Security-Policy** — definir em `web/_headers` (lido pelo Cloudflare Pages). Hoje o site serve só `x-content-type-options` e `referrer-policy`; não há CSP. Nunca houve — o antigo `vercel.json` só tinha regras de cache, então isso é lacuna antiga, não regressão da migração
- [ ] **Link de descadastro no e-mail de confirmação** — o cabeçalho `List-Unsubscribe` faz o Gmail exibir "Unsubscribe"; quem clicar entra na blocklist do Brevo e para de receber códigos sem nenhum aviso. **Não há configuração que desligue isso**: o Brevo não remove o cabeçalho de nada enviado por SMTP, e a alternativa (`list-help`) é só no plano Enterprise. Enquanto não for resolvido, conferir **Contatos → Blocklist** periodicamente. Correção definitiva = Send Email Hook do Supabase chamando a API transacional do Brevo (a API não adiciona o cabeçalho) — ver `CLAUDE.md`. **Obrigatório antes de lançar a recuperação de senha**
- [ ] **DNS de e-mail íntegro** — `musclechamp.com.br` deve ter **um** SPF (`v=spf1 include:spf.brevo.com -all`), **um** `_dmarc`, e os CNAME `brevo1/brevo2._domainkey` como *DNS only* na Cloudflare. Registro duplicado de SPF ou DMARC invalida a autenticação inteira

---

## Deploy Android (APK / AAB)

- [ ] `flutter clean && flutter pub get`
- [ ] `flutter analyze` — sem erros
- [ ] `flutter build apk --release` (ou `appbundle` para Play Store)
- [ ] Testar APK no dispositivo físico antes de distribuir
- [ ] Verificar que o ícone, nome e versão estão corretos no `pubspec.yaml`
- [ ] **Para Play Store:** assinar com keystore de produção (não debug)

---

## Deploy Web (Cloudflare Pages)

- [ ] `flutter build web --release`
- [ ] Confirmar `✓ Built build\web` — o deploy publica o que estiver em `build/web` mesmo se o build falhar, republicando a versão anterior em silêncio
- [ ] Verificar que `build/web/` contém `index.html` e assets
- [ ] `npx wrangler pages deploy build/web --project-name=muscle-champ --branch=main`
- [ ] Conferir que subiu comparando o hash, não olhando a tela:
      `curl -sL https://musclechamp.com.br/main.dart.js | sha256sum` vs `sha256sum build/web/main.dart.js`
- [ ] Acessar https://musclechamp.com.br e testar login + funcionalidade principal
- [ ] Verificar console do browser — sem erros de CORS ou recursos faltando

---

## Pós-Deploy

- [ ] Monitorar Supabase Logs por erros nas primeiras 24h
- [ ] Verificar se rate limits do Groq não foram atingidos
- [ ] Confirmar que não há regressões nas funcionalidades principais
- [ ] Atualizar `RELEASE_NOTES.md` com as mudanças desta versão
- [ ] Atualizar `docs/tecnico/MEMORY.md` com o estado atual

---

## Histórico de Execuções

| Data | Versão | Executado por | Resultado |
|------|--------|--------------|-----------|
| — | 1.0.0+1 | — | Pendente primeiro deploy oficial |
