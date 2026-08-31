# PRIVACY.md — Política de Privacidade
## Muscle Champ

> **Status:** Rascunho finalizado. Revisar com advogado antes de publicar.
> **Versão dos documentos:** `2026-08-31` — precisa bater com `LegalTexts.documentVersion`.
> **Mudança nesta versão:** hospedagem migrou do Vercel para o Cloudflare Pages;
> passou a declarar tratamento de endereço IP pelo operador de hospedagem.
> **Publicado em:** `web/privacidade.html` → `https://musclechamp.com.br/privacidade`
> **Sem `.html`:** o Cloudflare Pages responde 308 de `/privacidade.html` para a
> forma sem extensão. A URL publicada no Play Console deve ser a canônica, para
> não depender de um redirect continuar configurado.
>
> ⚠️ **A versão canônica publicada é o HTML.** Ao alterar este arquivo, replicar em
> `web/privacidade.html` e subir `LegalTexts.documentVersion` se a mudança for material.

---

# Política de Privacidade — Muscle Champ

**Última atualização:** 31 de agosto de 2026

Aplicável a usuários no Brasil (LGPD) e no EEE/Reino Unido (GDPR e UK GDPR).

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
| **Cloudflare** (global) | Endereço IP e metadados de requisição | Hospedagem e entrega do app web | https://www.cloudflare.com/privacypolicy/ |
| **Outros usuários** | Nome, avatar, pontuação | Ranking e sistema de amizades | — |

**Não vendemos dados pessoais.**

---

## 5. Seus direitos (LGPD Art. 18 · GDPR Art. 15-22)

### Direto no app — Perfil → ícone de escudo → Privacidade e dados

| Direito | Como | Base |
|---------|------|------|
| **Acesso e portabilidade** | "Baixar meus dados" gera JSON completo | LGPD 18 II/V · GDPR 15 e 20 |
| **Exclusão** | "Excluir minha conta" apaga tudo na hora | LGPD 18 VI · GDPR 17 |
| **Revogar consentimento** | Alternar os consentimentos opcionais | LGPD 8 §5 · GDPR 7(3) |
| **Correção** | Editar perfil e metas | LGPD 18 III · GDPR 16 |

Os consentimentos obrigatórios (Termos, Privacidade, dados de saúde) não são
revogáveis mantendo a conta — sem eles não há base legal para operar o serviço.
O caminho para retirá-los é excluir a conta, o que apaga tudo.

### Por e-mail — afd3vs@gmail.com

- **Oposição e limitação do tratamento** — GDPR Art. 18 e 21
- **Informação sobre compartilhamento** — LGPD Art. 18 VII
- **Revisão de decisões automatizadas** — LGPD Art. 20 · GDPR Art. 22

Prazo de resposta: até **15 dias**.

### Reclamação a autoridade

- **Brasil:** ANPD — https://www.gov.br/anpd
- **EEE:** autoridade de proteção de dados do seu país
- **Reino Unido:** ICO — https://ico.org.uk

## 5.1 Registro de consentimento

Guardamos, para cada finalidade, se você consentiu, em que versão do documento e
quando. Esse registro é append-only — revogar não apaga o histórico, grava uma nova
entrada. É o que a lei chama de responsabilização (LGPD Art. 6 X / GDPR Art. 5(2)).
O registro é apagado junto com a conta.

---

## 6. Segurança

- Comunicação criptografada com **TLS/HTTPS** em todas as chamadas
- Senhas nunca armazenadas em texto plano (gerenciadas pelo Supabase Auth)
- Acesso aos dados restrito ao próprio usuário via **Row Level Security (RLS)** no banco de dados
- Fotos de alimentos não são persistidas após análise

---

## 7. Idade mínima

O Muscle Champ exige **16 anos ou mais**, e a data de nascimento é validada no
cadastro — contas abaixo dessa idade não são criadas.

O limite é 16 porque tratamos dados de saúde: o GDPR Art. 8 fixa 16 anos como piso
para consentimento sem autorização parental (alguns Estados-Membros reduzem para 13,
mas 16 é seguro em todos), e a LGPD Art. 14 exige consentimento de responsável para
menores de 12. Adotar 16 cobre os dois regimes com uma regra só e dispensa construir
um fluxo de consentimento parental verificável.

Se souber de uma conta de menor de 16, escreva para afd3vs@gmail.com e ela será
excluída.

---

## 8. Retenção de dados

- Dados mantidos enquanto a conta estiver ativa
- Após pedido de exclusão: **removidos imediatamente**, não após período de carência
- O banco de dados utiliza o plano gratuito do Supabase, que **não possui backups automáticos** — os dados são mantidos apenas enquanto a conta estiver ativa no servidor
- Fotos de alimentos: nunca armazenadas

---

## 9. Transferência internacional de dados

Alguns dados são processados fora do Brasil:

| Destino | Motivo | Garantia |
|---------|--------|----------|
| Supabase (AWS sa-east-1, São Paulo) | Armazenamento principal | Servidor no Brasil |
| Groq (EUA) | Análise de fotos de alimentos por IA | Dado transiente, não armazenado |
| Cloudflare (rede global) | Hospedagem e entrega do app web | Apenas endereço IP e metadados de requisição; nenhum dado da conta |

---

## 10. Alterações nesta política

Comunicaremos alterações relevantes por **e-mail ou notificação no app** com pelo menos **30 dias de antecedência**.

---

## 11. Contato

**Henry de Araujo Fernandes**
afd3vs@gmail.com
Rua Abdo Salem, 353 — São Paulo, SP — CEP 03462-070
