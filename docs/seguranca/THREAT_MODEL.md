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
| Vazamento da chave Groq via engenharia reversa do APK | `strings` no APK / decompilação | **Alta** | **Crítico** | 🔴 Chave hardcoded no código |
| Vazamento da anonKey Supabase | Idem | **Alta** | Alto | 🔴 Chave hardcoded (anonKey é pública por design, mas confirmar RLS) |
| Dados de saúde visíveis para outros usuários | Bug em RPC de ranking | Baixa | Alto | ⚠️ RPCs devem ser auditadas |
| Fotos de avatar de outros usuários | URLs públicas previsíveis | Baixa | Médio | ⚠️ `{userId}/avatar.ext` é previsível se UUID for descoberto |

### D — Denial of Service (Negação de Serviço)

| Ameaça | Vetor | Probabilidade | Impacto | Status |
|--------|-------|--------------|---------|--------|
| Esgotar cota Groq free tier | Enviar muitas fotos rapidamente | Média | Alto | 🔴 Sem rate limiting no app |
| Esgotar cota Supabase free tier | Spam de cadastros / requests | Baixa | Alto | ⚠️ Sem proteção adicional |
| Timeout em cascata | Groq lento → app trava | Baixa | Médio | ✅ `.timeout(Duration(seconds: 30))` |

### E — Elevation of Privilege (Elevação de Privilégio)

| Ameaça | Vetor | Probabilidade | Impacto | Status |
|--------|-------|--------------|---------|--------|
| Acessar dados de outro usuário via RPC | Bug na lógica SQL da RPC | Baixa | Alto | ⚠️ RPCs precisam ser auditadas |
| Manipular ranking global | Criar muitos pontos artificialmente | Baixa | Médio | ⚠️ Pontos inseridos pelo cliente (sem validação server-side?) |

---

## 3. Priorização de Riscos

| # | Risco | Severidade | Facilidade | Prioridade |
|---|-------|-----------|-----------|-----------|
| 1 | Chave Groq hardcoded → exfiltração via APK | Crítico | Fácil | 🔴 Imediato |
| 2 | Sem rate limiting → abuso da cota Groq | Alto | Média | 🔴 Antes do lançamento |
| 3 | Pontos criados pelo cliente sem validação | Médio | Difícil | 🟡 Sprint seguinte |
| 4 | RPCs não auditadas → possível data leak | Alto | Média | 🟡 Auditar antes do lançamento |
| 5 | Sem audit log de operações sensíveis | Baixo | Fácil | 🟢 Backlog |
| 6 | URLs de avatar previsíveis | Baixo | Fácil | 🟢 Backlog |

---

## 4. Mitigações Recomendadas por Prioridade

### 🔴 Antes do lançamento

**1. Externalizar chaves de API**
```dart
// Em vez de hardcoded:
static const String apiKey = 'gsk_...';

// Usar dart-define no build:
static const String apiKey = String.fromEnvironment('GROQ_API_KEY');
// Build: flutter build apk --dart-define=GROQ_API_KEY=gsk_...
```

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
