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
| **CDC** (Lei 8.078/90) | ✅ Assinatura paga — direito de arrependimento de 7 dias (Art. 49) |
| **ECA** (Lei 8.069/90) | ✅ Resolvido com idade mínima de 16 anos no cadastro |
| **CFN** (Conselho Federal de Nutrição) | ✅ Disclaimers de estimativa exibidos em todo resultado de IA |
| **GDPR** (UE 2016/679) | ⚠️ Se distribuir no EEE — exige representante na UE (Art. 27) |
| **UK GDPR** + Data Protection Act 2018 | ⚠️ Mesma lógica do GDPR para o Reino Unido |
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

> **Implementado em 17/08/2026** — migration `20260817_lgpd_gdpr_compliance.sql`
> + `lib/core/legal/` + `lib/features/profile/presentation/pages/privacy_page.dart`.

### Política de Privacidade
- [x] Criar página web com Política de Privacidade — `PRIVACY.md` preenchido (Henry de Araujo Fernandes)
- [x] Páginas públicas geradas: `web/privacidade.html`, `web/termos.html`, `web/excluir-conta.html`
- [x] Exibir link dentro do app — cadastro (passo 3) e Perfil → Privacidade e dados
- [x] Migrar para domínio próprio — ✅ 28/08/2026: `musclechamp.com.br` conectado ao projeto Cloudflare Pages e `LegalTexts` apontando para lá. Os três respondem 200 na forma sem `.html` (`/privacidade`, `/termos`, `/excluir-conta`), que é a canônica — o Pages redireciona a versão com extensão via 308
- [ ] Vincular no Play Console (obrigatório para apps que coletam dados)

### Consentimento
- [x] Checkbox de consentimento explícito no cadastro para **dados de saúde**
- [x] Consentimento granular por finalidade — `LegalTexts.signupConsents`
- [x] Nenhum item pré-marcado (GDPR Art. 4(11) / LGPD Art. 5 XII)
- [x] Registro auditável em `user_consents` (finalidade + versão do documento + data)
- [x] Revogação dos consentimentos opcionais no app (GDPR Art. 7(3))
- [x] Botão "Excluir minha conta" no perfil

### Direitos do Titular (LGPD Art. 18 / GDPR Art. 15-22)
- [x] Acesso e portabilidade: RPC `export_my_data()` → JSON completo, com share/cópia no app
- [x] Correção: edição de perfil já existia
- [x] Exclusão: RPC `delete_my_account()` — apaga tabela por tabela, avatar no Storage e o usuário do `auth`
- [x] Revogação de consentimento: RPCs `grant_consent()` / `revoke_consent()`
- [x] Canal de contato exposto na tela de privacidade (`LegalTexts.privacyEmail`)

### Idade mínima
- [x] Barreira de 16 anos no cadastro (`LegalTexts.minimumAge`), validada na UI e no repositório
- [x] Cobre LGPD Art. 14 (BR) e GDPR Art. 8 (UE) com uma regra só, evitando ter que
      construir fluxo de consentimento parental verificável

### Disclaimers (política de apps de saúde do Google Play + restrição do CFN)
- [x] Nutricional — exibido em todo resultado de IA (`_NutritionPreview` com `isAi: true`)
- [x] Treino — exibido no resultado da geração por IA
- [x] Geral ("não é dispositivo médico") — tela de privacidade e Termos de Uso
- [ ] Bioimpedância — texto pronto em `LegalTexts.bioimpedanceDisclaimer`, ainda não exibido na UI

### Play Store — Data Safety Form
- [ ] Preencher seção "Data Safety" no Play Console
- [ ] Declarar: coleta de dados de saúde, nome, e-mail, fotos (avatar), atividade física
- [ ] Declarar: envio de dados a terceiros (Groq API para análise de fotos)
- [ ] Declarar URL de exclusão de conta: `/excluir-conta.html`
- [x] Criptografia em trânsito (HTTPS)

### GDPR — pendências que exigem decisão comercial
- [ ] **Representante na UE (Art. 27)** — obrigatório para oferecer o app a residentes do
      EEE sem estabelecimento lá. É serviço pago de terceiro. Sem isso, o caminho seguro
      é **não** distribuir o app no EEE (restringir países no Play Console).
- [ ] Registro de operações de tratamento (Art. 30) — exigível acima de 250 funcionários
      ou quando há tratamento de categoria especial não ocasional. Dados de saúde
      contínuos provavelmente enquadram; vale manter um registro simples.
- [ ] Avaliar necessidade de DPIA (Art. 35 / LGPD Art. 38) — tratamento de dado de saúde
      em larga escala é gatilho típico.

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
| Cloudflare (rede global) | Arquivos estáticos do app + **endereço IP e metadados de requisição** de quem acessa | Legítimo interesse (entrega e segurança do site) |

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
