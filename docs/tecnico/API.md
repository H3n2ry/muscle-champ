# API.md — Contratos de Interface
## Muscle Champ · v1.0.0+1

> Toda a API é servida pelo Supabase (tabelas + RPC) e pela Groq. Não há servidor HTTP próprio.

---

## 1. Supabase — Auth

### POST `/auth/v1/signup`
Disparado por `Supabase.auth.signUp()`.

**Request body (via SDK):**
```json
{
  "email": "usuario@exemplo.com",
  "password": "senha123",
  "data": {
    "name": "João Silva",
    "goal_type": "gain_muscle",
    "height_cm": 175.0,
    "current_weight": 80.0,
    "target_weight": 85.0
  }
}
```

**Comportamentos:**
- Se confirmação de e-mail habilitada: retorna `session = null` → app lança `EmailConfirmationPendingException`
- Se desabilitada: retorna `session` com JWT → app vai para `/dashboard`
- Trigger Supabase cria `profiles` e `goals` automaticamente com os dados do `data`

---

### POST `/auth/v1/token?grant_type=password`
Disparado por `Supabase.auth.signInWithPassword()`.

**Retorno:** JWT de sessão armazenado automaticamente pelo SDK.

---

## 2. Supabase — Tabelas (via PostgREST)

Todas as operações são feitas via `supabase_flutter` SDK com Row Level Security (RLS) ativa.

### `profiles`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid (PK) | Igual ao `auth.users.id` |
| `name` | text | Nome do usuário |
| `avatar_url` | text? | URL pública no Supabase Storage |
| `created_at` | timestamptz | Data de criação |

**Operações:**
```dart
// Leitura
.from('profiles').select().eq('id', userId).single()

// Atualização de nome
.from('profiles').update({'name': name}).eq('id', userId)

// Atualização de avatar
.from('profiles').update({'avatar_url': url}).eq('id', userId)
```

---

### `goals`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `user_id` | uuid (FK → profiles) | |
| `goal_type` | text | `'gain_muscle'` \| `'lose_weight'` \| `'maintain'` |
| `current_weight` | numeric | kg |
| `target_weight` | numeric | kg |
| `height_cm` | numeric | cm |
| `daily_calories` | int | Meta calórica diária (recalculada por trigger) |
| `weekly_workout_goal` | int | Número de treinos por semana |
| `birth_date` | date? | Data de nascimento — usada na meta de água |
| `daily_water_ml` | int? | Meta diária de água (recalculada por trigger) |
| `updated_at` | timestamptz | |

**Triggers:** `trg_goals_recalc` recalcula `daily_calories` e `daily_water_ml`
no INSERT e sempre que `current_weight`, `height_cm`, `goal_type` ou
`birth_date` mudarem. Fórmulas em `calc_daily_calories()` e `calc_daily_water()`.

---

### `workouts`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid (PK) | |
| `user_id` | uuid (FK) | |
| `date` | date | YYYY-MM-DD |
| `completed` | boolean | `false` ao criar, `true` ao concluir |
| `notes` | text? | Observações opcionais |

**Operações:**
```dart
// Listar últimos 30
.from('workouts').select('*, exercises(*)')
  .eq('user_id', userId).order('date', ascending: false).limit(30)

// Criar
.from('workouts').insert({'user_id': userId, 'date': today, 'notes': notes}).select().single()

// Concluir
.from('workouts').update({'completed': true}).eq('id', workoutId).select('*, exercises(*)').single()
```

---

### `exercises`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid (PK) | |
| `workout_id` | uuid (FK → workouts) | |
| `name` | text | Nome do exercício |
| `sets` | int | Número de séries |
| `reps` | int | Repetições por série |
| `weight` | numeric | Carga em kg |
| `previous_weight` | numeric? | Carga da última sessão deste exercício |

---

### `diet_logs`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid (PK) | |
| `user_id` | uuid (FK) | |
| `date` | date | YYYY-MM-DD |
| `name` | text | Nome do alimento/refeição |
| `weight_g` | int | Quantidade em gramas |
| `calories` | int | Kcal totais |
| `protein` | numeric | g |
| `carbs` | numeric | g |
| `fat` | numeric | g |
| `created_at` | timestamptz | |

---

### `points`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid (PK) | |
| `user_id` | uuid (FK) | |
| `amount` | int | Valor do ponto (geralmente 10, 20, etc.) |
| `reason` | text | `'workout_completed'` \| `'diet_goal_met'` |
| `created_at` | timestamptz | |

---

### `friendships`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid (PK) | |
| `user_id` | uuid (FK) | Quem enviou a solicitação |
| `friend_id` | uuid (FK) | Quem recebeu |
| `status` | text | `'pending'` \| `'accepted'` |

**Constraint único:** `(user_id, friend_id)` — evita solicitações duplicadas via `upsert`.

---

### `workout_templates`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid (PK) | |
| `user_id` | uuid (FK) | |
| `name` | text | Nome do template (ex: "Peito e Tríceps") |
| `muscle_group` | text | Grupo muscular alvo |
| `created_at` | timestamptz | |

---

### `template_exercises`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid (PK) | |
| `template_id` | uuid (FK → workout_templates) | |
| `name` | text | Nome do exercício |
| `sets` | int | |
| `reps` | int | |
| `tip` | text? | Dica de execução |

---

### `workout_completions`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid (PK) | |
| `user_id` | uuid (FK) | |
| `template_id` | uuid (FK → workout_templates) | |
| `completed_at` | timestamptz | |

---

### `weight_logs`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `user_id` | uuid (FK) | |
| `weight_kg` | numeric | Peso em kg |
| `measured_at` | date | Constraint único: `(user_id, measured_at)` |

---

### `water_logs`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid (PK) | |
| `user_id` | uuid (FK → auth.users, ON DELETE CASCADE) | |
| `date` | date | Padrão `CURRENT_DATE` |
| `amount_ml` | int | Quantidade em ml (CHECK > 0) — uma linha por registro |
| `created_at` | timestamptz | Usado para o "desfazer" (remove o mais recente) |

Índice: `(user_id, date)`. RLS owner-scoped em SELECT, INSERT e DELETE.

---

### `bioimpedance_logs`

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `user_id` | uuid (FK) | |
| `body_fat_pct` | numeric? | % gordura corporal |
| `muscle_mass_kg` | numeric? | kg massa muscular |
| `visceral_fat` | int? | Nível de gordura visceral |
| `hydration_pct` | numeric? | % hidratação |
| `bone_mass_kg` | numeric? | kg massa óssea |
| `bmr_kcal` | int? | Taxa metabólica basal (kcal) |
| `measured_at` | date | Constraint único: `(user_id, measured_at)` |

---

## 3. Supabase — RPC Functions

### `get_dashboard_data(p_user_id uuid)`

**Retorno:**
```json
{
  "total_points": 450,
  "global_rank": 12,
  "friends_rank": 3,
  "workout_done_today": true,
  "diet_goal_met_today": false,
  "current_weight": 80.5,
  "target_weight": 85.0,
  "weekly_workouts": 3,
  "weekly_workout_goal": 4,
  "point_history": [
    {"date": "2026-05-22", "points": 50},
    {"date": "2026-05-23", "points": 30}
  ]
}
```

---

### `get_global_ranking(p_user_id uuid)` / `get_friends_ranking(p_user_id uuid)`

**Retorno:** array de
```json
{
  "user_id": "uuid",
  "user_name": "João",
  "avatar_url": "https://...",
  "total_points": 450,
  "rank": 1,
  "is_current_user": false
}
```

---

### `search_users(p_query text, p_current_user_id uuid)`

**Retorno:** array de
```json
{
  "user_id": "uuid",
  "user_name": "Maria",
  "avatar_url": null,
  "total_points": 200,
  "is_friend": false,
  "is_pending": true,
  "request_id": "uuid-da-solicitacao"
}
```

---

### `get_pending_requests(p_user_id uuid)`

**Retorno:** array de
```json
{
  "request_id": "uuid",
  "requester_id": "uuid",
  "requester_name": "Carlos",
  "requester_avatar": null,
  "requester_points": 150,
  "created_at": "2026-05-28T10:00:00Z"
}
```

---

### `get_streak(p_user_id uuid)`

**Retorno:** `int` — número de dias consecutivos com treino concluído.

---

## 4. Groq API

⚠️ O app **não** chama a Groq diretamente. Todas as chamadas passam pela Edge Function `groq-proxy` do Supabase, que injeta a chave (guardada no Vault) server-side. O cliente nunca tem a chave `gsk_`.

**Base URL (proxy):** `${supabaseUrl}/functions/v1/groq-proxy`
**Upstream (dentro do proxy):** `https://api.groq.com/openai/v1/chat/completions`

**Headers obrigatórios (cliente → proxy):**
```
Authorization: Bearer <JWT da sessão Supabase do usuário>
Content-Type: application/json
```
O corpo (modelos, mensagens) segue o formato OpenAI/Groq abaixo; o proxy repassa e devolve a resposta da Groq.

---

### Gerar treino (`generateWorkout`)

**Request:**
```json
{
  "model": "llama-3.3-70b-versatile",
  "temperature": 0.7,
  "response_format": {"type": "json_object"},
  "messages": [
    {"role": "system", "content": "...prompt de personal trainer..."},
    {"role": "user", "content": "Gere um treino para: Peito"}
  ]
}
```

**Response esperada (dentro de `choices[0].message.content`):**
```json
{
  "exercises": [
    {"name": "Supino Reto", "sets": 4, "reps": 12, "tip": "Mantenha os cotovelos a 45°"}
  ]
}
```

---

### Calcular macros por texto (`calculateFoodMacros`)

**Response esperada:**
```json
{
  "name": "Frango grelhado 200g",
  "weight_g": 200,
  "calories": 330,
  "protein": 62.0,
  "carbs": 0.0,
  "fat": 7.2
}
```

---

### Gerar plano de dieta (`generateDietPlan`)

**Request:**
```json
{
  "model": "llama-3.3-70b-versatile",
  "temperature": 0.3,
  "response_format": {"type": "json_object"},
  "messages": [
    {"role": "system", "content": "...nutricionista com regras estritas de não ultrapassar metas..."},
    {"role": "user", "content": "Meta: 2000 kcal | Proteína: 150g | Carboidrato: 210g | Gordura: 67g | Objetivo: gain_muscle"}
  ]
}
```

**Response esperada:**
```json
{
  "target_calories": 2000,
  "goal_protein_g": 150,
  "goal_carbs_g": 210,
  "goal_fat_g": 67,
  "meals": [
    {
      "type": "Café da Manhã",
      "foods": [
        {"name": "Ovos mexidos", "weight_g": 150, "calories": 230, "protein": 18.0, "carbs": 1.0, "fat": 16.0}
      ]
    }
  ]
}
```

**Parâmetros opcionais:** `goalProtein`, `goalCarbs`, `goalFat` em gramas. Se omitidos, usa split 30/40/30.
**Temperatura 0.3** para maior consistência nos valores numéricos (não ultrapassar metas).

---

### Analisar foto de alimento (`analyzeFoodPhoto`)

**Request:** multimodal — imagem base64 + texto no mesmo `content` array.

**Response esperada:**
```json
{
  "name": "Arroz com feijão e frango",
  "weight_g": 450,
  "calories": 620,
  "protein": 45.0,
  "carbs": 78.0,
  "fat": 12.5
}
```

**Response de erro (alimento não identificado):**
```json
{"error": "não identificado"}
```

---

## 5. Supabase Storage

**Bucket:** `avatars`

**Caminho:** `{userId}/avatar.{ext}`

**Acesso:** público (URL pública gerada via `.getPublicUrl()` com cache busting `?t={timestamp}`)

**Tipos aceitos:** jpg, jpeg, png, webp, heic
