# THREAT_MODEL.md — Modelo de Ameaças
## Muscle Champ · v1.0.0+1

> Metodologia STRIDE aplicada ao contexto de app mobile Flutter + Supabase + Groq.

---

## 1. Ativos a Proteger

| Ativo | Valor | Localização |
|-------|-------|-------------|
| Dados de saúde dos usuários | 🔴 Crítico | Supabase DB |
| Chave de API Groq | 🔴 Crítico | `groq_config.dart` (hardcoded) |
| Chave anonKey Supabase | 🔴 Crítico | `supabase_config.dart` (hardcoded) |
| Sessões JWT dos usuários | 🔴 Crítico | Supabase Auth + device storage |
| Fotos de avatar dos usuários | 🟡 Alto | Supabase Storage |
| Histórico de treinos e dieta | 🟡 Alto | Supabase DB |
| Ranking e pontos | 🟢 Baixo | Supabase DB |

---

## 2. Vetores de Ataque por STRIDE

### S — Spoofing (Falsidade de Identidade)

| Ameaça | Vetor | Probabilidade | Impacto | Status |
|--------|-------|--------------|---------|--------|
| Login com credenciais roubadas | Credential stuffing via API Supabase | Média | Alto | ⚠️ Sem proteção de rate limit |
| Token JWT forjado | Assinar JWT com secret vazado | Baixa | Crítico | ✅ Gerenciado pelo Supabase |
| Registro de e-mail falso | Criar conta com e-mail de terceiro | Alta | Baixo | ✅ Confirmação de e-mail ativa |

### T — Tampering (Adulteração)

| Ameaça | Vetor | Probabilidade | Impacto | Status |
|--------|-------|--------------|---------|--------|
| Modificar pontuação de outro usuário | Chamada direta ao PostgREST sem RLS | Baixa | Médio | ✅ RLS protege |
| Modificar dados de saúde de outro usuário | Idem | Baixa | Alto | ✅ RLS protege |
| Injeção SQL via inputs | Campo de nome/notas sem sanitização | Baixa | Alto | ✅ SDK Supabase usa prepared statements |
| Adulteração de resultados Groq | MITM na chamada HTTP ao Groq | Baixa | Médio | ✅ HTTPS obrigatório |

### R — Repudiation (Repúdio)

| Ameaça | Vetor | Probabilidade | Impacto | Status |
|--------|-------|--------------|---------|--------|
| Usuário nega ter enviado dados de saúde | Sem logs de consentimento | Média | Médio | ⚠️ Sem audit log implementado |
| Ação não rastreável no ranking | Pontos criados sem log de operação | Baixa | Baixo | ⚠️ Tabela `points` tem `created_at` mas sem IP |

### I — Information Disclosure (Vazamento de Informação)

| Ameaça | Vetor | Probabilidade | Impacto | Status |
|--------|-------|--------------|---------|--------|
| Vazamento da chave Groq via engenharia reversa do APK | `strings` no APK / decompilação | **Alta** | **Crítico** | ✅ Resolvido (2026-06) — chave no Supabase Vault, usada só pela Edge Function `groq-proxy`; nunca no cliente |
| Vazamento da anonKey Supabase | Idem | **Alta** | Alto | ✅ anonKey é pública por design; RLS auditado e owner-scoped em todas as tabelas |
| Dados de saúde visíveis para outros usuários | Bug em RPC de ranking | Baixa | Alto | ✅ RPCs auditadas — validam `auth.uid()` internamente |
| Fotos de avatar de outros usuários | URLs públicas previsíveis | Baixa | Médio | ✅ Bucket `avatars` lista só a pasta do dono; exibição via URL pública (nome + avatar não são sensíveis) |

### D — Denial of Service (Negação de Serviço)

| Ameaça | Vetor | Probabilidade | Impacto | Status |
|--------|-------|--------------|---------|--------|
| Esgotar cota Groq free tier | Enviar muitas fotos rapidamente | Média | Alto | 🟡 Parcial — proxy `groq-proxy` exige login, faz allowlist de modelo e cap de `max_tokens`; rate-limit por usuário ainda pendente |
| Esgotar cota Supabase free tier | Spam de cadastros / requests | Baixa | Alto | ⚠️ Sem proteção adicional (free pausa por inatividade é evitado pelo keepalive) |
| Timeout em cascata | Groq lento → app trava | Baixa | Médio | ✅ `.timeout(Duration(seconds: 30))` |

### E — Elevation of Privilege (Elevação de Privilégio)

| Ameaça | Vetor | Probabilidade | Impacto | Status |
|--------|-------|--------------|---------|--------|
| Acessar dados de outro usuário via RPC | Bug na lógica SQL da RPC | Baixa | Alto | ✅ RPCs validam `auth.uid()` (ignoram `p_user_id`); EXECUTE revogado de anon/PUBLIC |
| Manipular ranking global | Criar muitos pontos artificialmente | Baixa | Médio | ✅ Política INSERT de `points` = `WITH CHECK (auth.uid() = user_id)` |

---

## 3. Priorização de Riscos

| # | Risco | Severidade | Facilidade | Prioridade |
|---|-------|-----------|-----------|-----------|
| 1 | Chave Groq hardcoded → exfiltração via APK | Crítico | Fácil | ✅ Resolvido (Vault + proxy) |
| 2 | Sem rate limiting → abuso da cota Groq | Alto | Média | 🟡 Proxy mitiga (login + caps); rate-limit por usuário pendente |
| 3 | Pontos criados pelo cliente sem validação | Médio | Difícil | ✅ Resolvido (RLS `auth.uid() = user_id`) |
| 4 | RPCs não auditadas → possível data leak | Alto | Média | ✅ Resolvido (auditadas, validam `auth.uid()`) |
| 5 | Sem audit log de operações sensíveis | Baixo | Fácil | 🟢 Backlog |
| 6 | URLs de avatar previsíveis | Baixo | Fácil | ✅ Bucket restrito ao dono |

---

## 4. Mitigações Recomendadas por Prioridade

### 🔴 Antes do lançamento

**1. Externalizar chaves de API** ✅ FEITO (2026-06)

A chave Groq foi totalmente removida do cliente. `dart-define` foi descartado porque a chave ainda ficaria embutida no binário (extraível por `strings`). Solução adotada:

- Chave no **Supabase Vault** (`groq_api_key`), criptografada em repouso.
- Edge Function **`groq-proxy`** (`verify_jwt`) lê a chave server-side e encaminha à Groq.
- O app chama o proxy com o JWT da sessão (`GroqService`), nunca vê a chave.
- Rotação: `vault.update_secret(...)` + redeploy da função.

**2. Rate limiting na DietPage**
```dart
// Debounce ou cooldown de 30s entre chamadas ao Groq
DateTime? _lastGroqCall;
bool get _canCallGroq =>
  _lastGroqCall == null ||
  DateTime.now().difference(_lastGroqCall!) > const Duration(seconds: 30);
```

### 🟡 Próximo sprint

**3. Validar que pontos são criados apenas por triggers/RPCs** — não pelo cliente direto.

**4. Auditar cada RPC** para garantir que `p_user_id` é validado contra o JWT (`auth.uid()`).
