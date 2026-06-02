# CHECKLIST DE SEGURANÇA — Pré-Deploy
## Muscle Champ

> Executar este checklist antes de cada release publicado na Play Store ou Vercel.

---

## 🔴 Crítico — Bloqueia o Deploy

- [ ] **Chaves de API fora do código-fonte** — `groq_config.dart` e `supabase_config.dart` não devem ter chaves hardcoded em produção
- [ ] **`.env` ou arquivos de secrets não commitados** — verificar `git status` e `.gitignore`
- [ ] **RLS ativa em todas as tabelas** — verificar no Supabase Dashboard → Table Editor → cada tabela tem RLS ativado
- [ ] **Confirmação de e-mail habilitada** — Supabase Auth Settings → Email Confirmations = ON

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
- [ ] **Supabase: revisar políticas RLS** das tabelas `workouts`, `diet_logs`, `points`, `friendships`
- [ ] **Groq: verificar se há CVEs no modelo em uso** — acompanhar https://groq.com/security
- [ ] **Bucket `avatars`: confirmar que não é listável** — Storage → Policies → listar desabilitado
- [ ] **Rate limiting na chamada de foto** — cooldown entre chamadas ao `analyzeFoodPhoto`
- [ ] **Web: verificar Content-Security-Policy** no Vercel (`vercel.json` headers)

---

## Deploy Android (APK / AAB)

- [ ] `flutter clean && flutter pub get`
- [ ] `flutter analyze` — sem erros
- [ ] `flutter build apk --release` (ou `appbundle` para Play Store)
- [ ] Testar APK no dispositivo físico antes de distribuir
- [ ] Verificar que o ícone, nome e versão estão corretos no `pubspec.yaml`
- [ ] **Para Play Store:** assinar com keystore de produção (não debug)

---

## Deploy Web (Vercel)

- [ ] `flutter build web --release`
- [ ] Verificar que `build/web/` contém `index.html` e assets
- [ ] `vercel --prod --yes --scope "af-dev"` dentro de `build/web/`
- [ ] Acessar https://muscle-champ.vercel.app e testar login + funcionalidade principal
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
