# Memória de Contexto — Muscle Champ

> Este arquivo é lido automaticamente pelo Claude Code no início de cada sessão. Ele garante continuidade de contexto entre conversas diferentes. **Atualize este arquivo sempre que houver decisões importantes, mudanças de direção ou contexto novo relevante.**

---

## Identidade do Projeto

- **Nome:** Muscle Champ (package: `muscle_camp`)
- **Versão atual:** 1.0.0+1
- **Status:** Em desenvolvimento (pré-lançamento Play Store)
- **Objetivo principal:** App fitness gamificado para Android e Web — treinos com IA, dieta por foto e ranking entre amigos
- **Stack:** Flutter 3.44 · Dart 3.12 · Riverpod · GoRouter · Supabase · Groq API · Vercel
- **Repositório:** local (`C:\Users\Jean\Desktop\muscle camp\project\app`)
- **Deploy atual:** https://muscle-champ.vercel.app (web) · APK distribuído via Google Drive

---

## Estado Atual do Desenvolvimento

### O que está funcionando
- Autenticação completa: login, cadastro com metadados (objetivo, peso, altura), confirmação de email
- Dashboard: pontos totais, rank global, rank amigos, meta semanal de treinos, meta de dieta do dia
- Treinos: geração por IA (Groq LLaMA 3.3 70B) por grupo muscular, registro de exercícios com peso, histórico dos últimos 30 treinos
- Dieta — modo texto: calcular macros por descrição livre (IA)
- Dieta — modo foto: selecionar porção (P/M/G/Prato), tirar foto ou escolher da galeria, IA analisa e retorna macros, slider para ajustar o peso (recalcula macros proporcionalmente)
- Perfil: editar nome, peso atual, altura, meta, tipo de objetivo; upload de avatar para Supabase Storage; dados de bioimpedância (gordura corporal, massa muscular, etc.)
- Ranking: placar global e entre amigos, streak de dias consecutivos
- Amizades: buscar usuários por nome, enviar/aceitar/rejeitar/remover amigos
- Notificações: página de notificações in-app
- Build Android (APK) e web funcionando; deploy automático via Vercel CLI

### O que está em progresso
- Play Store: publicação pendente (precisa gerar keystore, assinar AAB, criar conta Play Console)
- Notificações push (push notifications via Supabase não implementadas — só in-app)

### O que ainda não foi feito
- Publicação na Play Store (keystore + AAB assinado + Play Console)
- Notificações push reais (FCM)
- iOS build (nunca foi testado)
- Testes automatizados (zero cobertura atual)
- Modo offline / cache local
- Exportação de histórico (PDF/CSV)

---

## Decisões Tomadas (e Por Quê)

| Decisão | Motivo | Data |
|---------|--------|------|
| Groq no lugar de OpenAI | Cota gratuita generosa (~500k tokens/dia), latência baixa, modelos LLaMA top de linha | mai/2025 |
| `image` package para pré-processar fotos | Reduz tokens da visão em ~73% (resize 768px + JPEG 80%) antes de enviar à Groq | mai/2025 |
| `GroqService` com métodos estáticos | Não há estado interno; evita instância desnecessária no Riverpod | mai/2025 |
| `max_tokens: 300` na análise de foto | Valor menor (120) cortava o JSON no meio; 300 é suficiente para a resposta estruturada | mai/2025 |
| Imagens redimensionadas para máx 768px | 512px rejeitava pratos complexos com muitos itens; 768px é o equilíbrio qualidade/tokens | mai/2025 |
| Supabase como único backend | Auth + DB + Storage + RPC em um só serviço, sem servidor próprio | início do projeto |
| RLS + RPC no Supabase | Segurança e lógica de ranking no banco, sem expor lógica no cliente | início do projeto |
| Dart Records `(String, String)` no `_optimizeImage` | Retornar b64 + mime type sem criar classe auxiliar; Dart 3+ | mai/2025 |
| `autoDispose` em todos os providers | Libera memória ao sair da página; evita dados stale entre navegações | início do projeto |
| Confirmação de email obrigatória | `EmailConfirmationPendingException` lançado no register quando `session == null` | início do projeto |
| Cores hard-coded em `AppColors` | Design system Obsidian Kinetic é fixo — não há tema claro, sem necessidade de `ThemeData` dinâmico | início do projeto |

---

## Convenções Estabelecidas

- **Nomenclatura de arquivos:** `snake_case` para tudo; páginas terminam em `_page.dart`, providers em `_provider.dart`, repositórios em `_repository.dart`, modelos em `_model.dart`
- **Estrutura de features:** `data/models/` + `data/repositories/` + `data/datasources/` + `presentation/providers/` + `presentation/pages/`
- **Providers:** `XRepositoryProvider` expõe o repositório; `XControllerProvider` (AsyncNotifier) é o provider mutável; `XSummaryProvider` / `XProvider` (FutureProvider) é só leitura
- **Supabase:** sempre `Supabase.instance.client` direto nos repositórios — sem wrapper
- **Idioma:** app e prompts da IA 100% em português; código e comentários em português
- **Groq prompts:** instrução no `system` para texto; instrução inline no `content` para visão (vision model não suporta `system` role separado)
- **Commits:** não há padrão definido ainda

---

## Contexto de Negócio

- **Usuário:** público brasileiro interessado em fitness; usa o app para acompanhar treinos e dieta de forma gamificada
- **Prazo:** sem prazo fixo — projeto pessoal em evolução
- **Restrições importantes:** Groq free tier (~500k tokens/dia) — não escalar para muitos usuários sem revisar plano; Supabase free tier (500MB DB, 1GB Storage, 50k MAU)
- **Integrações obrigatórias:** Supabase (auth + dados), Groq API (IA), Vercel (web deploy)

---

## Problemas Resolvidos Anteriormente

| Problema | Solução aplicada |
|----------|-----------------|
| Build falha com `C:\Users\Henry` (caminho do dev original) | `flutter clean` + deletar `.dart_tool`, `build`, `android/.gradle` |
| Android SDK licenses não aceitas interativamente | Escrever hashes SHA-1 diretamente em `%ANDROID_HOME%\licenses\` com LF (não CRLF) |
| `sdkmanager` não encontrado | Instalar "Android SDK Command-line Tools (latest)" pelo Android Studio SDK Manager (aba SDK Tools) |
| IA retornava sempre 150g para qualquer foto | Placeholders como `"weight_g":0` faziam o modelo copiar zeros; substituídos por `PESO_TOTAL_EM_GRAMAS` como descritores |
| `max_tokens: 120` cortava JSON no meio | Aumentado para 300 |
| PNG da galeria enviado como `image/jpeg` | Detectar PNG via magic bytes (`0x89 0x50 0x4E 0x47`) em `_optimizeImage()` e retornar MIME correto |
| Pratos complexos/grandes não identificados pela IA | Limite de 512px era insuficiente; aumentado para 768px + prompt atualizado para somar todos os itens do prato |
| Web build falhava com lock no iOS ephemeral | `Remove-Item -Recurse -Force ios/Flutter/ephemeral` |
| Vercel `list_projects` retornava vazio | Usar `vercel --prod --yes --scope "af-dev"` que autovincula ao projeto existente `muscle-champ` |
| `JAVA_HOME` não definido ao rodar `sdkmanager` | Definir `$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"` no mesmo terminal |

---

## Instruções Permanentes para o Claude

1. Ler este arquivo e o `CLAUDE.md` no início de cada sessão antes de qualquer alteração
2. Atualizar a seção "O que está funcionando" quando uma feature for concluída
3. Registrar em "Decisões Tomadas" qualquer escolha técnica nova com data e motivo
4. Registrar em "Problemas Resolvidos" qualquer bug difícil que for corrigido
5. Não mudar a stack, os modelos Groq ou a estrutura de features sem perguntar explicitamente
6. Manter Supabase como único backend — não introduzir Firebase, servidor Node/Python ou outro BaaS
7. Todo texto exibido ao usuário deve estar em português brasileiro
8. Ao fazer builds Android, sempre definir `ANDROID_HOME`, `JAVA_HOME` e `PATH` no mesmo PowerShell antes de rodar `flutter build`
9. Para deploy web, rodar `vercel --prod --yes --scope "af-dev"` dentro de `build/web/`
10. Nunca reduzir `_maxImagePx` abaixo de 768 nem `max_tokens` abaixo de 300 em `analyzeFoodPhoto`

---

## Glossário do Projeto

| Termo | Significado no contexto deste projeto |
|-------|---------------------------------------|
| "pontos" | Moeda de gamificação creditada na tabela `points` por treinos/metas |
| "streak" | Dias consecutivos com pelo menos um treino concluído (calculado pela RPC `get_streak`) |
| "meta de dieta" | Consumir calorias dentro de ±10% do `goals.daily_calories` |
| "meta semanal" | Número de treinos completos na semana vs `goals.weekly_workout_goal` |
| "modo foto" | Aba de análise de alimento por imagem na DietPage (usa visão Groq) |
| "modo texto" | Aba de cálculo de macros por descrição na DietPage (usa texto Groq) |
| "porção" | Dica opcional (P/M/G/Prato) passada como `portionHint` ao `analyzeFoodPhoto` |
| "bioimpedância" | Dados opcionais de composição corporal (gordura, músculo, etc.) na tabela `bioimpedance_logs` |
| "Obsidian Kinetic" | Nome do design system do app — dark, accent lime green `#7EFC00` |

---

## Última Atualização

- **Atualizado em:** 2026-05-28
- **Por:** Claude Code
- **O que mudou:** Primeira versão do arquivo criada com base em toda a sessão de desenvolvimento. Registra o estado completo após implementação de foto de alimentos com IA, otimização de tokens, builds Android e web, e deploy Vercel.
