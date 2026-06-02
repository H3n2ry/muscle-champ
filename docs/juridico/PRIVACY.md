# PRIVACY.md — Política de Privacidade
## Muscle Champ

> **Status:** Rascunho finalizado. Revisar com advogado antes de publicar.
> **URL pública:** `https://musclechamp.com.br/privacidade`

---

# Política de Privacidade — Muscle Champ

**Última atualização:** 15 de junho de 2025

---

## 1. Quem somos

O Muscle Champ é um aplicativo de fitness desenvolvido por **Henry de Araujo Fernandes**, disponível para Android e Web.

Para dúvidas sobre privacidade ou para exercer seus direitos, entre em contato:
**E-mail:** afd3vs@gmail.com
**Endereço:** Rua Abdo Salem, 353 — São Paulo, SP — CEP 03462-070

---

## 2. Quais dados coletamos

### 2.1 Dados que você fornece
- **Cadastro:** nome completo, endereço de e-mail, senha (armazenada com hash pelo Supabase — nunca em texto plano)
- **Perfil físico:** peso atual, peso alvo, altura, tipo de objetivo (ganhar massa / perder peso / manter)
- **Bioimpedância (opcional):** percentual de gordura, massa muscular, gordura visceral, hidratação, massa óssea, taxa metabólica basal — inseridos manualmente pelo usuário
- **Fotos de perfil:** imagem enviada voluntariamente

### 2.2 Dados gerados pelo uso
- **Histórico de treinos:** data, exercícios, séries, repetições, cargas
- **Histórico alimentar:** refeições registradas com nome, macros e calorias
- **Fotos de alimentos:** enviadas temporariamente para análise por IA e **não armazenadas** permanentemente em nossos servidores
- **Pontuação e ranking:** gerados automaticamente pelas atividades no app

### 2.3 Dados técnicos
- Identificador único de usuário (UUID gerado pelo Supabase)
- Data e hora de criação da conta

---

## 3. Como usamos seus dados

| Dado | Finalidade |
|------|-----------|
| E-mail | Autenticação, confirmação de conta |
| Dados físicos | Personalizar metas e recomendações |
| Histórico de treinos | Exibir progresso, calcular pontos |
| Histórico alimentar | Calcular macros diários, verificar meta calórica |
| Fotos de alimentos | Análise nutricional por IA (enviadas à Groq API — **não armazenadas**) |
| Ranking | Exibição de placar global e entre amigos |
| Avatar | Identificação visual no ranking e perfil |

---

## 4. Com quem compartilhamos

| Terceiro | Dado compartilhado | Finalidade | Política de Privacidade |
|---------|-------------------|-----------|------------------------|
| **Supabase** (Brasil/EUA) | Todos os dados do usuário | Armazenamento e autenticação | https://supabase.com/privacy |
| **Groq** (EUA) | Fotos de alimentos (temporário, não armazenado) | Análise nutricional por IA | https://groq.com/privacy |
| **Vercel** (global) | Nenhum dado pessoal | Hospedagem do app web | https://vercel.com/legal/privacy-policy |
| **Outros usuários** | Nome, avatar, pontuação | Ranking e sistema de amizades | — |

**Não vendemos dados pessoais.**

---

## 5. Seus direitos (LGPD — Lei 13.709/2018)

Você tem direito a:

- ✅ **Acessar** seus dados — solicite por e-mail: afd3vs@gmail.com
- ✅ **Corrigir** dados incorretos — disponível diretamente no perfil do app
- ✅ **Excluir** sua conta e todos os dados — disponível no perfil do app ou por e-mail
- ✅ **Portabilidade** — exportar histórico de treinos e dieta mediante solicitação
- ✅ **Revogar consentimento** — ao excluir a conta
- ✅ **Informação** sobre com quem compartilhamos seus dados — neste documento

Para exercer qualquer direito: **afd3vs@gmail.com**
Prazo de resposta: até **15 dias úteis**.

---

## 6. Segurança

- Comunicação criptografada com **TLS/HTTPS** em todas as chamadas
- Senhas nunca armazenadas em texto plano (gerenciadas pelo Supabase Auth)
- Acesso aos dados restrito ao próprio usuário via **Row Level Security (RLS)** no banco de dados
- Fotos de alimentos não são persistidas após análise

---

## 7. Menores de idade

O Muscle Champ **não é destinado a menores de 13 anos**. Se você tiver conhecimento de que um menor forneceu dados sem consentimento dos responsáveis, entre em contato imediatamente pelo e-mail afd3vs@gmail.com para exclusão dos dados.

---

## 8. Retenção de dados

- Dados mantidos enquanto a conta estiver ativa
- Após solicitação de exclusão: dados removidos em até **30 dias**
- O banco de dados utiliza o plano gratuito do Supabase, que **não possui backups automáticos** — os dados são mantidos apenas enquanto a conta estiver ativa no servidor

---

## 9. Transferência internacional de dados

Alguns dados são processados fora do Brasil:

| Destino | Motivo | Garantia |
|---------|--------|----------|
| Supabase (AWS sa-east-1, São Paulo) | Armazenamento principal | Servidor no Brasil |
| Groq (EUA) | Análise de fotos de alimentos por IA | Dado transiente, não armazenado |

---

## 10. Alterações nesta política

Comunicaremos alterações relevantes por **e-mail ou notificação no app** com pelo menos **30 dias de antecedência**.

---

## 11. Contato

**Henry de Araujo Fernandes**
afd3vs@gmail.com
Rua Abdo Salem, 353 — São Paulo, SP — CEP 03462-070
