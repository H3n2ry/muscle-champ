# LEGAL.md — Conformidade Legal
## Muscle Champ · v1.0.0+1

> **Disclaimer:** Este documento não substitui consultoria jurídica. É uma análise técnica das implicações legais identificadas no código. Consulte um advogado antes de publicar o app.

> **Regra geral para o Claude Code:** Antes de implementar qualquer feature com implicação legal (pagamentos, dados de saúde, menores, geolocalização, compartilhamento de dados), pesquisar a legislação vigente e atualizar este documento.

---

## 1. Legislação Aplicável

| Lei | Aplicabilidade |
|-----|---------------|
| **LGPD** (Lei 13.709/2018) | ✅ Dados pessoais de usuários brasileiros |
| **Marco Civil da Internet** (Lei 12.965/2014) | ✅ App web + app mobile com dados de brasileiros |
| **ECA** (Lei 8.069/90) | ⚠️ Se app for usado por menores — verificar restrição de idade |
| **CFN** (Conselho Federal de Nutrição) | ⚠️ App não pode dar diagnóstico nutricional — apenas estimativas |
| **Google Play Policies** | ✅ Obrigatório para publicação |

---

## 2. Dados Pessoais Coletados

| Dado | Classificação LGPD | Base Legal | Onde armazenado |
|------|--------------------|-----------|-----------------|
| Nome | Dado pessoal | Consentimento / Contrato | Supabase `profiles` |
| E-mail | Dado pessoal | Consentimento / Contrato | Supabase Auth |
| Peso atual e histórico | **Dado de saúde (sensível)** | Consentimento explícito | `goals`, `weight_logs` |
| Altura | **Dado de saúde (sensível)** | Consentimento explícito | `goals` |
| Meta de peso | Dado pessoal | Consentimento | `goals` |
| Tipo de objetivo (ganhar/perder/manter) | Dado de saúde | Consentimento explícito | `goals` |
| Gordura corporal, massa muscular, gordura visceral | **Dado de saúde (altamente sensível)** | Consentimento explícito | `bioimpedance_logs` |
| Histórico de treinos | Dado pessoal de comportamento | Consentimento | `workouts`, `exercises` |
| Histórico alimentar + fotos de alimentos | **Dado de saúde** | Consentimento explícito | `diet_logs` (fotos não salvas) |
| Avatar (foto do usuário) | Dado pessoal (imagem) | Consentimento | Supabase Storage `avatars` |
| Pontos e ranking | Dado derivado | Contrato | `points`, RPCs |
| Friendships | Dado de relacionamento | Consentimento | `friendships` |

---

## 3. Checklist Jurídico Pré-Publicação Play Store

### Política de Privacidade
- [x] Criar página web com Política de Privacidade — `PRIVACY.md` preenchido (Henry de Araujo Fernandes)
- [ ] Hospedar em URL permanente: `https://musclechamp.com.br/privacidade` (aguarda compra do domínio)
- [ ] Vincular no Play Console (obrigatório para apps que coletam dados)
- [ ] Exibir link dentro do app (tela de cadastro ou configurações)

### Consentimento
- [ ] Adicionar checkbox de consentimento explícito no cadastro para **dados de saúde**
- [ ] Consentimento deve ser granular: treino, dieta, bioimpedância separados (ou agrupado com linguagem clara)
- [ ] Implementar botão "Excluir minha conta e dados" no perfil

### Direitos do Titular (LGPD Art. 18)
- [ ] Direito de acesso: exportar dados do usuário
- [ ] Direito de correção: edição de perfil já existe ✅
- [ ] Direito de exclusão: implementar `DELETE CASCADE` em todas as tabelas por `user_id`
- [ ] Direito de portabilidade: exportar histórico de treinos/dieta em JSON ou CSV
- [ ] Canal de contato: e-mail para exercício de direitos (informar na Privacy Policy)

### Play Store — Data Safety Form
- [ ] Preencher seção "Data Safety" no Play Console
- [ ] Declarar: coleta de dados de saúde, nome, e-mail, fotos (avatar), atividade física
- [ ] Declarar: envio de dados a terceiros (Groq API para análise de fotos)
- [ ] Declarar: criptografia em trânsito (HTTPS) ✅

---

## 4. Restrições de Conteúdo

### O app NÃO pode
- Dar diagnósticos nutricionais ou de saúde (apenas estimativas)
- Recomendar dietas muito restritivas sem disclaimers
- Tratar dados de menores de 13 anos sem consentimento dos responsáveis

### Disclaimers recomendados
Exibir no onboarding ou nas funcionalidades relevantes:
> "Os valores nutricionais são estimativas geradas por inteligência artificial e podem não refletir a composição exata dos alimentos. Consulte um nutricionista para orientação personalizada."

> "As sugestões de treino são geradas por IA e têm fins educativos. Consulte um profissional de educação física antes de iniciar qualquer programa de exercícios."

---

## 5. Transferência Internacional de Dados

| Destino | Dado enviado | Base legal |
|---------|-------------|-----------|
| Supabase (AWS us-east-1 ou sa-east-1) | Todos os dados do usuário | Cláusulas contratuais padrão |
| Groq (EUA) | Fotos de alimentos (transiente, não armazenado) | Consentimento específico |
| Vercel (Edge Network global) | Dados do app (estático) | Apenas código — sem dados pessoais |

**Ação recomendada:** Verificar região do projeto Supabase em Settings → General. Migrar para `sa-east-1` (São Paulo) se possível para minimizar transferência internacional.

---

## 6. Retenção de Dados

Definir e implementar política de retenção:

| Dado | Retenção sugerida |
|------|------------------|
| Conta ativa | Indefinido enquanto ativo |
| Conta inativa (sem login há 1 ano) | Notificar + deletar após 90 dias |
| Histórico de treinos e dieta | Manter enquanto conta ativa |
| Logs de acesso | 90 dias |
| Fotos de avatar deletadas | Remover do Storage imediatamente |
