# Architecture — Muscle Champ

## Overview

Flutter app (Android + Web) com backend 100% Supabase e inferência de IA via Groq. Nenhum servidor próprio — toda lógica server-side vive em funções RPC do PostgreSQL/Supabase.

```
┌──────────────────────────────────────────────────────┐
│                Flutter App (Dart)                    │
│  Presentation  ←→  Providers (Riverpod)  ←→  Repos  │
└─────────────────────┬────────────────────────────────┘
                      │ HTTP
          ┌───────────┴───────────┐
          │                       │
   ┌──────▼──────┐       ┌────────▼────────┐
   │  Supabase   │       │    Groq API     │
   │  Auth + DB  │       │  LLM inference  │
   │  + Storage  │       │  (text+vision)  │
   └─────────────┘       └─────────────────┘
```

## Layer Breakdown

### Core (`lib/core/`)

| Módulo | Responsabilidade |
|--------|-----------------|
| `router/app_router.dart` | GoRouter com ShellRoute para as 5 abas + guard de auth síncrono |
| `supabase/supabase_config.dart` | URL e anonKey do Supabase |
| `groq/groq_service.dart` | Todas as chamadas à Groq API (métodos estáticos) |
| `groq/groq_config.dart` | API key, baseUrl, nomes dos modelos |
| `theme/app_colors.dart` | Paleta Obsidian Kinetic (`#121413` bg, `#7EFC00` primary) |
| `network/doh_http_overrides.dart` | DNS-over-HTTPS para contornar bloqueios de rede |

### Feature Layer (`lib/features/<feature>/`)

Cada feature segue exatamente esta estrutura:

```
<feature>/
├── data/
│   ├── models/          # Plain Dart classes com fromJson/toJson
│   ├── repositories/    # Acesso ao Supabase; expostos via Provider<Repo>
│   └── datasources/     # Dados locais estáticos (exercise_library, food_database)
└── presentation/
    ├── providers/        # AsyncNotifierProvider / FutureProvider
    └── pages/            # Widgets (StatelessWidget / ConsumerWidget)
```

### Shared (`lib/shared/widgets/`)

- `MkButton` — botão primário/secundário no estilo Obsidian Kinetic
- `MkCard` — card com glow verde opcional
- `MkTextField` — input estilizado
- `BottomNavBar` / `MainScaffold` — navegação entre as 5 abas via ShellRoute

## Data Flow

### Treino gerado por IA

```
WorkoutPage → GroqService.generateWorkout(muscleGroup)
           → Groq llama-3.3-70b-versatile
           → List<Map> de exercícios
           → WorkoutController.createWorkout()
           → Supabase: INSERT workouts + exercises
           → Points awarded (Supabase trigger/RPC)
```

### Foto de alimento

```
DietPage (photo mode)
  → image_picker (câmera ou galeria)
  → base64 encode
  → GroqService._optimizeImage()   ← resize ≤768px, JPEG 80%
  → GroqService.analyzeFoodPhoto()
  → Groq llama-4-scout-17b (vision)
  → JSON {name, weight_g, calories, protein, carbs, fat}
  → User ajusta peso via slider (recalcula macros proporcionalmente)
  → DietController.addMeal()
  → Supabase: INSERT diet_logs
```

### Ranking

```
RankingPage → RankingRepository.getGlobalRanking()
           → Supabase RPC: get_global_ranking(p_user_id)
           → PostgreSQL function (calcula posição em tempo real)
```

## Supabase Schema (tabelas principais)

| Tabela | Colunas chave |
|--------|--------------|
| `profiles` | id, user_name, avatar_url, current_weight, target_weight, weekly_workout_goal |
| `goals` | user_id, daily_calories |
| `workouts` | id, user_id, date, completed, notes |
| `exercises` | id, workout_id, name, sets, reps, weight, previous_weight |
| `diet_logs` | id, user_id, date, name, weight_g, calories, protein, carbs, fat |
| `points` | id, user_id, amount, reason, created_at |
| `friendships` | id, user_id, friend_id, status (pending/accepted) |
| `notifications` | id, user_id, title, body, read, created_at |

### RPC Functions

- `get_dashboard_data(p_user_id)` — agrega pontos, rank, metas do dia
- `get_global_ranking(p_user_id)` — ranking geral com posição do usuário destacada
- `get_friends_ranking(p_user_id)` — ranking restrito aos amigos
- `search_users(p_query, p_current_user_id)` — busca por nome, retorna status de amizade
- `get_pending_requests(p_user_id)` — solicitações de amizade recebidas
- `get_pending_requests_count(p_user_id)` — badge do sino de notificações

## Gamification

Pontos são creditados na tabela `points` com `reason` descritivo:

| Evento | `reason` |
|--------|---------|
| Treino concluído | `workout_completed` |
| Meta calórica atingida (±10%) | `diet_goal_met` |

O `DietRepository` verifica diariamente se já existe uma linha `diet_goal_met` para hoje antes de recompensar (evita duplicatas).

## Groq API — Token Budget

| Chamada | Modelo | Tokens estimados |
|---------|--------|-----------------|
| `generateWorkout` | llama-3.3-70b | ~400 tokens |
| `calculateFoodMacros` | llama-3.3-70b | ~200 tokens |
| `analyzeFoodPhoto` | llama-4-scout | ~590 tokens (imagem 768px JPEG 80%) |

Com 10 usuários × 4 fotos/dia ≈ 23.600 tokens/dia (~5% da cota gratuita Groq de ~500k tokens/dia).

## Build Targets

| Target | Comando | Saída |
|--------|---------|-------|
| Android APK | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| Android AAB | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |
| Web | `flutter build web --release` | `build/web/` → deploy via Vercel |

## Dependências notáveis

- `supabase_flutter ^2.5.0` — auth + realtime + storage
- `flutter_riverpod ^2.5.1` — state management
- `go_router ^13.2.1` — navegação declarativa
- `image ^4.8.0` — resize/compressão de imagens antes de enviar à Groq
- `image_picker ^1.1.2` — câmera e galeria
- `shared_preferences ^2.3.2` — controle de popups semanais
- `fl_chart ^0.67.0` — gráficos de progresso
- `cached_network_image ^3.3.1` — avatares do Supabase Storage
