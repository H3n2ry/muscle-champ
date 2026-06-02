# SECURITY.md — Política de Segurança
## Muscle Champ

---

## Como Reportar uma Vulnerabilidade

Se você encontrar uma vulnerabilidade de segurança, **não abra uma issue pública**.

Entre em contato diretamente:
- **E-mail:** [security@contato.com]
- **Assunto:** `[SECURITY] Muscle Champ - <descrição breve>`

**O que incluir no reporte:**
1. Descrição da vulnerabilidade
2. Passos para reproduzir
3. Impacto potencial
4. Sugestão de correção (opcional)

**Prazo de resposta:** Confirmaremos o recebimento em até 72 horas.

---

## Mecanismos de Segurança Implementados

### Autenticação
- ✅ E-mail + senha com hash bcrypt (gerenciado pelo Supabase Auth)
- ✅ JWT com expiração automática
- ✅ Confirmação de e-mail antes do primeiro acesso (configurado no Supabase)
- ✅ `currentSession` verificado em cada navegação via GoRouter redirect

### Autorização (Row Level Security)
- ✅ RLS ativo no Supabase — usuário só acessa seus próprios dados
- ✅ Funções RPC com `p_user_id` explícito (não confiam no JWT implicitamente — verificar policies)
- ✅ Bucket `avatars` com path `{userId}/avatar.*` — usuário só pode escrever no próprio caminho

### Comunicação
- ✅ HTTPS em todos os endpoints (Supabase, Groq, Vercel)
- ✅ Sem comunicação HTTP plaintext

### Dados
- ✅ Fotos de alimentos não são persistidas — processadas e descartadas
- ✅ Senhas nunca passam pelo app (gerenciadas pelo Supabase Auth SDK)

---

## O que Precisa ser Implementado

| Item | Prioridade | Descrição |
|------|-----------|-----------|
| Externalizar chaves de API | 🔴 Alta | `groq_config.dart` e `supabase_config.dart` têm chaves hardcoded |
| Validação de input no app | 🟡 Média | Campos de peso, altura, calorias sem validação de range |
| Rate limiting nas RPCs | 🟡 Média | Sem proteção contra spam de chamadas ao Groq |
| Certificate pinning | 🟢 Baixa | Previne ataques MITM em redes comprometidas |
| Ofuscação do código | 🟢 Baixa | `flutter build apk --obfuscate` não configurado |
| Timeout de sessão | 🟢 Baixa | Sessão Supabase nunca expira explicitamente no app |

---

## Boas Práticas para Contribuidores

1. **Nunca commitar chaves de API ou segredos** — usar `--dart-define` ou arquivo `.env` não versionado
2. **Validar todos os inputs** antes de enviar ao Supabase ou Groq
3. **Não logar dados pessoais** — nenhum `print()` com e-mail, nome ou dados de saúde
4. **Não desativar RLS** em tabelas para "facilitar o desenvolvimento"
5. **Revisar as policies RLS** ao criar novas tabelas
6. **Verificar `flutter analyze`** antes de cada PR — sem warnings ignorados

---

## Versões com Vulnerabilidades Conhecidas

| Versão | Status | Vulnerabilidade |
|--------|--------|----------------|
| Versão atual (1.0.0+1) | Em análise | Chaves de API hardcoded no código-fonte |

Para verificar CVEs em dependências Flutter: https://pub.dev/security
