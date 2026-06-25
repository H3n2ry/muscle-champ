# SDD — Software Design Document
## Muscle Champ · v1.0.0+1
### Metodologia IEEE 1016 — 5 Visões

> Gerado por engenharia reversa. Revisar antes de usar como documentação oficial.

---

## 1. Visão de Contexto

### 1.1 O que o sistema faz
Muscle Champ é um app fitness gamificado multiplataforma (Android nativo + Web Progressive) que permite ao usuário:
- Gerar treinos personalizados por grupo muscular via IA
- Registrar refeições por foto (análise visual de macronutrientes por IA) ou por descrição de texto
- Acumular pontos por atividades concluídas e disputar rankings globais e entre amigos
- Acompanhar evolução de peso, composição corporal e streaks de treino

### 1.2 Para quem
Usuários brasileiros interessados em fitness que querem rastreamento simples e motivação por competição social.

### 1.3 Atores e casos de uso

| Ator | Casos de uso |
|------|-------------|
| Usuário não autenticado | Criar conta, fazer login, confirmar e-mail |
| Usuário autenticado | Gerar treino, registrar exercício, adicionar refeição (foto/texto), ver ranking, gerenciar amigos, editar perfil, ver dashboard |
| Sistema (Supabase triggers) | Criar profile após cadastro, registrar pontos, atualizar streaks |
| IA Groq (LLaMA 3.3 70B) | Gerar lista de exercícios, calcular macros por texto |
| IA Groq (LLaMA 4 Scout Vision) | Identificar alimentos em fotos e retornar macros |

### 1.4 Escopo do sistema
```
[Usuário] ←──── Flutter App ────→ [Supabase: Auth + DB + Storage]
                    │
                    └────────────→ [Groq API: LLM + Vision]
```

Não há servidor próprio. Toda lógica server-side vive em funções RPC PostgreSQL no Supabase.

---

## 2. Visão de Composição

### 2.1 Camadas da aplicação

```
┌─────────────────────────────────────────────────────────────┐
│  PRESENTATION                                               │
│  Pages (ConsumerWidget) ← Providers (Riverpod) ← State     │
├─────────────────────────────────────────────────────────────┤
│  DOMAIN / APPLICATION                                       │
│  Providers orquestram chamadas a repositórios               │
├─────────────────────────────────────────────────────────────┤
│  DATA                                                       │
│  Repositories → Supabase client / GroqService (HTTP)        │
├─────────────────────────────────────────────────────────────┤
│  INFRAESTRUTURA                                             │
│  supabase_flutter · http · image · image_picker             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Módulos e responsabilidades

| Módulo | Localização | Responsabilidade |
|--------|-------------|-----------------|
| Auth | `features/auth/` | Login, cadastro, confirmação de e-mail, logout |
| Dashboard | `features/dashboard/` | Pontos totais, rank, metas do dia, histórico semanal |
| Workout | `features/workout/` | Geração de treino por IA, registro de exercícios, histórico |
| Diet | `features/diet/` | Adição de refeições (texto/foto), cálculo de macros, metas calóricas |
| Profile | `features/profile/` | Dados pessoais, bioimpedância, avatar, metas físicas |
| Ranking | `features/ranking/` | Placar global/amigos, busca de usuários, sistema de amizades |
| Notifications | `features/notifications/` | Listagem de notificações in-app |
| Core | `core/` | Roteamento, tema, Supabase config, Groq service |
| Shared | `shared/widgets/` | Componentes UI reutilizáveis (MkButton, MkCard, etc.) |

### 2.3 Diagrama de componentes

```
main.dart
  └── MuscleCampApp (ConsumerWidget)
        ├── AppTheme.dark()
        └── GoRouter (appRouterProvider)
              ├── /login → LoginPage
              ├── /register → RegisterPage
              ├── /confirm-email → ConfirmEmailPage
              ├── /edit-profile → EditProfilePage
              ├── /notifications → NotificationsPage
              └── ShellRoute → MainScaffold (BottomNavBar)
                    ├── /dashboard → DashboardPage
                    ├── /workout   → WorkoutPage
                    ├── /diet      → DietPage
                    ├── /ranking   → RankingPage
                    └── /profile   → ProfilePage
```

---

## 3. Visão de Dependências

### 3.1 Dependências externas críticas

| Serviço | Protocolo | Autenticação | Disponibilidade |
|---------|-----------|-------------|-----------------|
| Supabase | HTTPS/WSS | JWT (anonKey + Bearer) | SLA não garantido (free tier; keepalive evita pausa) |
| Groq API | HTTPS (via Edge Function `groq-proxy`) | Chave no Vault, server-side | SLA não garantido (free tier) |
| Vercel | HTTPS | N/A (hosting estático) | Edge Network global |

### 3.2 Grafo de dependências internas

```
DietPage
  ├── DietController (dietControllerProvider)
  │     └── DietRepository (dietRepositoryProvider)
  │           └── Supabase.instance.client
  └── GroqService.analyzeFoodPhoto()
        └── GroqConfig (apiKey, visionModel)

WorkoutPage
  ├── WorkoutController (workoutControllerProvider)
  │     └── WorkoutRepository
  └── GroqService.generateWorkout()

DashboardPage
  └── dashboardProvider
        └── DashboardRepository → RPC get_dashboard_data

RankingPage
  └── rankingControllerProvider
        └── RankingRepository → RPCs (get_global_ranking, get_friends_ranking)
```

### 3.3 Dependências Flutter/Dart

Ver `docs/tecnico/DEPENDENCIES.md` para análise completa.

---

## 4. Visão de Interface

### 4.1 Supabase — Tabelas

| Tabela | Operações usadas |
|--------|-----------------|
| `profiles` | SELECT (id, name, avatar_url, created_at), UPDATE (name, avatar_url) |
| `goals` | SELECT (goal_type, current_weight, target_weight, height_cm, daily_calories, weekly_workout_goal), UPDATE |
| `workouts` | SELECT (últimos 30), INSERT, UPDATE (completed=true) |
| `exercises` | SELECT (nested em workouts), INSERT |
| `workout_templates` | SELECT, INSERT, DELETE |
| `template_exercises` | SELECT (nested em templates), INSERT |
| `workout_completions` | SELECT, INSERT |
| `diet_logs` | SELECT (hoje), INSERT, DELETE |
| `points` | SELECT (amount), INSERT (via trigger/RPC) |
| `friendships` | INSERT (upsert), UPDATE (status), DELETE |
| `notifications` | SELECT |
| `bioimpedance_logs` | SELECT (último), UPSERT |
| `weight_logs` | UPSERT |
| `avatars` (Storage) | UPLOAD (binary), GET public URL |

### 4.2 Supabase — RPC Functions

| Função | Parâmetros | Retorno |
|--------|-----------|---------|
| `get_dashboard_data` | `p_user_id` | `{total_points, global_rank, friends_rank, workout_done_today, diet_goal_met_today, current_weight, target_weight, weekly_workouts, weekly_workout_goal, point_history[]}` |
| `get_global_ranking` | `p_user_id` | `[{user_id, user_name, avatar_url, total_points, rank, is_current_user}]` |
| `get_friends_ranking` | `p_user_id` | igual ao global |
| `search_users` | `p_query, p_current_user_id` | `[{user_id, user_name, avatar_url, total_points, is_friend, is_pending, request_id}]` |
| `get_pending_requests` | `p_user_id` | `[{request_id, requester_id, requester_name, requester_avatar, requester_points, created_at}]` |
| `get_pending_requests_count` | `p_user_id` | `int` |
| `get_streak` | `p_user_id` | `int` |

### 4.3 Groq API

**Endpoint:** `POST https://api.groq.com/openai/v1/chat/completions`

| Método | Modelo | Temperatura | max_tokens | Resposta |
|--------|--------|-------------|-----------|---------|
| `generateWorkout(muscleGroup)` | llama-3.3-70b-versatile | 0.7 | padrão | `{"exercises":[{name, sets, reps, tip}]}` |
| `calculateFoodMacros(description)` | llama-3.3-70b-versatile | 0.2 | padrão | `{name, weight_g, calories, protein, carbs, fat}` |
| `generateDietPlan(calories, goalType, {goalProtein?, goalCarbs?, goalFat?})` | llama-3.3-70b-versatile | 0.3 | padrão | `{target_calories, goal_protein_g, goal_carbs_g, goal_fat_g, meals:[{type, foods:[...]}]}` |
| `analyzeFoodPhoto(base64, portionHint?)` | llama-4-scout-17b-16e-instruct | 0.2 | 300 | `{name, weight_g, calories, protein, carbs, fat}` ou `{error}` |

### 4.4 Variáveis de configuração

| Config | Arquivo | Valor atual |
|--------|---------|------------|
| Supabase URL | `core/supabase/supabase_config.dart` | `https://jryetjysjiyuuoznaejc.supabase.co` |
| Supabase anonKey | `core/secrets.dart` (gitignored) | JWT longo (público por design) |
| Groq apiKey | Supabase Vault (`groq_api_key`) | server-side; NUNCA no cliente |
| Groq proxy | `core/groq/groq_config.dart` | `${supabaseUrl}/functions/v1/groq-proxy` |
| Groq textModel | `core/groq/groq_config.dart` | `llama-3.3-70b-versatile` |
| Groq visionModel | `core/groq/groq_config.dart` | `meta-llama/llama-4-scout-17b-16e-instruct` |

⚠️ **Ambas as chaves estão hardcoded no código-fonte.** Para produção, considerar obfuscação mínima ou variáveis de ambiente via `--dart-define`.

---

## 5. Visão de Comportamento

### 5.1 Fluxo de autenticação

```
Usuário abre o app
  │
  ├─ [sessão ativa] ──→ /dashboard
  └─ [sem sessão] ────→ GoRouter redirect → /login
                              │
                    RegisterPage (nome, email, senha, objetivo, peso, altura)
                              │
                    Supabase.auth.signUp(data: {name, goal_type, ...})
                              │
                    ┌─ session != null ─→ dashboard
                    └─ session == null ─→ /confirm-email (aguarda clique no e-mail)
```

### 5.2 Fluxo de geração de treino

```
WorkoutPage → usuário seleciona grupo muscular
  → GroqService.generateWorkout(muscleGroup)
    → POST /openai/v1/chat/completions (LLaMA 3.3)
    → parse JSON {"exercises": [...]}
  → usuário edita pesos/séries
  → WorkoutController.createWorkout(exercises)
    → INSERT workouts + INSERT exercises (loop)
    → consulta previous_weight para cada exercício
  → Supabase trigger / RPC adiciona pontos
  → state = AsyncData([newWorkout, ...oldWorkouts])
```

### 5.3 Fluxo de foto de alimento

```
DietPage (foto mode)
  → image_picker.pickImage(camera | gallery)
  → readAsBytes() → base64Encode()
  → GroqService._optimizeImage(base64)
    → decode image → resize ≤768px → encode JPEG 80%
    → detect MIME (PNG magic bytes vs JPEG)
  → GroqService.analyzeFoodPhoto(optimized, portionHint?)
    → POST /openai/v1/chat/completions (LLaMA 4 Scout Vision)
    → extract JSON via RegExp (\\{[\\s\\S]*\\})
  → show result + weight slider
    → _adjustedWeight altera calorias/macros proporcionalmente
  → DietController.addMeal(data)
    → INSERT diet_logs
  → se calorias ≥ 90% && ≤ 110% da meta → ponto "diet_goal_met"
```

### 5.4 Fluxo de plano de dieta com IA

```
DietPage → botão "Gerar Plano de Dieta"
  → lê goals.daily_calories + goal_type + macro targets (protein/carbs/fat)
  → GroqService.generateDietPlan(calories, goalType, goalProtein, goalCarbs, goalFat)
    → POST /openai/v1/chat/completions (LLaMA 3.3, temperature 0.3)
    → prompt com regras estritas "não ultrapassar" por macro
  → parse → DietPlan(meals: [...])
  → AiDietPlanNotifier.generate() salva em SharedPreferences['ai_diet_plan_v1_{userId}']

Usuário troca alimento (botão ALTERAR):
  → busca food_database local por nome/categoria
  → ao selecionar substituto: newWeight = (originalCalories / newFood.kcalPer100g) × 100
  → swapFood(mealIdx, foodIdx, newFood) → DietPlanFood recriado com peso recalculado
  → plano salvo novamente no SharedPreferences

Persistência:
  → F5 / reload → AiDietPlanNotifier._loadFromStorage() restaura o plano
  → Logout / novo usuário → provider autoDispose → na próxima sessão carrega plano do novo usuário
```

---

### 5.5 Fluxo do tutorial interativo

```
Usuário novo faz login → /dashboard
  → MainScaffold monta → ref.watch(tutorialProvider)
  → TutorialNotifier._init()
    → SharedPreferences['tutorial_seen_{userId}'] == false → state.show = true
  → MainScaffold retorna Stack(Scaffold, Positioned.fill(TutorialOverlay))

Tutorial (12 passos em 5 seções):
  INÍCIO(0-1) → TREINO(2-3) → DIETA(4-7) → RANKING(8-9) → PERFIL(10-11)

  Cada passo:
    → SpotTarget determina posição do spotlight (nav bar ou posição % na tela)
    → _SpotlightPainter: saveLayer + BlendMode.clear cria "buraco" na overlay escura
    → Card posiciona-se acima ou abaixo do spotlight conforme metade da tela
    → Ao mudar de seção: context.go(novaRota) navega a aba correspondente

  Ao completar ou pular:
    → SharedPreferences['tutorial_seen_{userId}'] = true
    → state.show = false → MainScaffold retorna apenas o Scaffold
```

---

### 5.6 Tratamento de erros

| Camada | Como é tratado |
|--------|----------------|
| Groq API erro HTTP | `_assertOk()` lança `Exception('Groq ${statusCode}: ${body}')` |
| Groq JSON inválido | `RegExp(r'\{[\s\S]*\}')` extrai bloco JSON; se falhar → `jsonDecode` lança |
| Groq não identifica alimento | Retorna `{"error":"não identificado"}` → UI exibe mensagem |
| Supabase erro | Exceção não tratada propagada ao Riverpod → `AsyncError` |
| Timeout Groq | `.timeout(Duration(seconds: 30))` lança `TimeoutException` |
| Email não confirmado | `EmailConfirmationPendingException` capturado na `RegisterPage` |

---

## 6. SharedPreferences — Chaves utilizadas

| Chave | Tipo | Usado em |
|-------|------|---------|
| `ai_diet_plan_v1_{userId}` | String (JSON) | Plano de dieta gerado por IA — persiste entre sessões |
| `tutorial_seen_{userId}` | bool | Tutorial de onboarding — não mostrar novamente |

> **Padrão:** todas as chaves incluem `_{userId}` para evitar vazamento de dados entre contas no mesmo dispositivo/browser.

---

## 7. Débitos Técnicos e Riscos

| Item | Severidade | Descrição |
|------|-----------|-----------|
| Chaves de API hardcoded | 🔴 Alto | `groq_config.dart` e `supabase_config.dart` expõem credenciais no código-fonte |
| Zero cobertura de testes | 🔴 Alto | Nenhum arquivo `*_test.dart` encontrado |
| Sem tratamento global de erros | 🟡 Médio | Exceções Supabase não são normalizadas — UX de erro inconsistente |
| `Supabase.instance.client` direto | 🟡 Médio | Dificulta mocking em testes; sem abstração de data source |
| Free tier Supabase/Groq | 🟡 Médio | Sem SLA; limites podem ser atingidos com crescimento |
| Sem CI/CD | 🟡 Médio | Build e deploy são manuais via PowerShell + Vercel CLI |
| iOS não testado | 🟡 Médio | Projeto nunca foi buildado para iOS |
| Sem modo offline | 🟢 Baixo | App inutilizável sem internet |

---

## 8. Checklist de Qualidade

- [ ] Implementar `--dart-define` para externalizar chaves de API
- [ ] Criar pelo menos 1 teste de unidade por repositório
- [ ] Adicionar `ErrorWidget.builder` global para capturar erros de render
- [ ] Configurar GitHub Actions para `flutter analyze` + `flutter test` em cada PR
- [ ] Implementar tratamento de `AsyncError` em todas as páginas
- [ ] Testar build iOS
- [ ] Configurar `flutter_launcher_icons` para ícones corretos no web
