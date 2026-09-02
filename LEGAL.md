# LEGAL.md — Muscle Champ

> Áreas de atenção legal relevantes para este projeto específico. Não é aconselhamento jurídico.

---

## 1. Dados Pessoais e LGPD (Lei 13.709/2018)

O app coleta e processa dados sensíveis de saúde de usuários brasileiros:

| Dado coletado | Onde é armazenado | Base legal sugerida |
|--------------|-------------------|---------------------|
| Nome e e-mail | Supabase Auth (EU) | Consentimento / execução de contrato |
| Peso, altura, IMC | Supabase DB (`goals`, `weight_logs`) | Consentimento explícito |
| Gordura corporal, massa muscular, gordura visceral | Supabase DB (`bioimpedance_logs`) | Consentimento explícito — **dado sensível de saúde** |
| Fotos de alimentos | Enviadas à Groq API e descartadas após análise | Consentimento + minimização |
| Histórico de treinos e dieta | Supabase DB | Consentimento |

**Ações recomendadas antes do lançamento:**
- [ ] Criar tela de Política de Privacidade acessível no app (obrigatório na Play Store)
- [ ] Adicionar checkbox de consentimento explícito no cadastro para dados de saúde
- [ ] Definir política de retenção de dados (ex: excluir conta e dados em até 30 dias após solicitação)
- [ ] Nomear um encarregado de dados (DPO) ou endereço de contato para exercício de direitos

---

## 2. Imagens Enviadas à Groq API

As fotos de comida são convertidas para base64 e enviadas ao endpoint da Groq (`api.groq.com`). A Groq é uma empresa americana — os dados transitam para os EUA.

**Pontos de atenção:**
- A Groq afirma não reter dados de entrada para treinar modelos (verifique os Terms of Service vigentes em https://groq.com/terms)
- As imagens **não são salvas** no Supabase — apenas o JSON de resultado (nome, macros)
- Informar o usuário no app que fotos são enviadas a um serviço externo de IA

---

## 3. Permissões Android

O app solicita as seguintes permissões (declaradas implicitamente pelo `image_picker`):

| Permissão | Uso |
|-----------|-----|
| `CAMERA` | Tirar foto de alimento |
| `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` | Selecionar foto da galeria |
| `INTERNET` | Supabase + Groq API |

**Play Store:** O Google exige justificativa para permissões de câmera e armazenamento no formulário de envio do app. Descreva o uso como "análise nutricional de alimentos por IA".

---

## 4. Play Store — Políticas Relevantes

| Política | Status |
|---------|--------|
| App de saúde/fitness: não pode dar diagnósticos médicos | ✅ O app não diagnostica — apenas estima macros |
| Dados de saúde: exige Política de Privacidade | ⚠️ Criar antes de publicar |
| Dados pessoais de menores: COPPA (EUA) / Marco Civil (BR) | ⚠️ Se não for restrito a maiores de 13 anos, exige tratamento especial |
| Permissões: justificar uso de câmera | ⚠️ Detalhar no formulário do Play Console |
| Seção "Data Safety" no Play Console | ⚠️ Preencher com os dados coletados listados na seção 1 |

---

## 5. Supabase — Localização dos Dados

O projeto Supabase (`jryetjysjiyuuoznaejc`) foi criado na região padrão. Verifique em https://supabase.com/dashboard/project/jryetjysjiyuuoznaejc/settings/general qual região está ativa.

- Para usuários brasileiros, a região **South America (São Paulo)** reduz latência e facilita argumentação de conformidade com LGPD
- A migração de região no Supabase requer criação de novo projeto e migração manual

---

## 6. Termos de Uso dos Serviços Terceiros

| Serviço | URL dos Termos | Ponto crítico |
|---------|---------------|---------------|
| Supabase | https://supabase.com/terms | Dados armazenados em AWS; free tier sem SLA |
| Groq | https://groq.com/terms | Verificar política de dados de entrada (imagens) |
| Cloudflare | https://www.cloudflare.com/terms/ | Free tier sem SLA; tráfego passa pela rede global da Cloudflare (proxy ativo) |
| Google Play | https://play.google.com/about/developer-content-policy/ | Política de conteúdo e dados de saúde |
