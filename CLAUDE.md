# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

All commands run from `C:\Users\Jean\Desktop\muscle camp\project\app`.

> **Note**: Flutter is installed at `C:\flutter\bin`. If `flutter` is not found in PowerShell, use Git Bash:
> ```bash
> export PATH="/c/flutter/bin:/c/Program Files/nodejs:/c/Users/Jean/AppData/Roaming/npm:$PATH"
> ```

### Environment setup (required for Android builds)
```powershell
$env:ANDROID_HOME = "C:\Users\Jean\AppData\Local\Android\Sdk"
$env:JAVA_HOME    = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH         = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"
```

### Common commands
```powershell
flutter run                          # Run on connected device/emulator
flutter build apk --release          # Release APK → build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release    # AAB for Play Store
flutter build web --release          # Web build → build/web/
flutter clean                        # Clear build cache
flutter pub get                      # Install dependencies
flutter analyze                      # Static analysis (pre-existing errors in doh_http_overrides.dart are known/ignored)
```

### Web deploy to Vercel
```bash
cd build/web
npx vercel --prod --yes --scope "af-dev"   # → https://muscle-champ.vercel.app
```

### Build + deploy completo
```bash
flutter pub get
flutter build web --release
cd build/web && npx vercel --prod --yes --scope "af-dev"
```

### If build fails with path errors
```powershell
flutter clean
Remove-Item -Recurse -Force .dart_tool, build, android/.gradle -ErrorAction SilentlyContinue
flutter pub get
```

## Architecture

Feature-first structure under `lib/`:

```
lib/
├── main.dart                    # Supabase init, orientation lock, ProviderScope
├── app.dart                     # MaterialApp.router with AppTheme.dark()
├── core/
│   ├── router/app_router.dart   # GoRouter with auth redirect guard
│   ├── supabase/supabase_config.dart
│   ├── groq/
│   │   ├── groq_config.dart     # API key + model names
│   │   └── groq_service.dart    # All Groq API calls (static methods)
│   ├── theme/
│   │   ├── app_colors.dart      # Obsidian Kinetic palette
│   │   ├── app_typography.dart
│   │   └── app_theme.dart
│   └── network/doh_http_overrides.dart
├── features/
│   ├── auth/                    # Login, register (3-step), confirm email
│   ├── dashboard/               # Home — points, rank, weekly goal, weight evolution
│   ├── workout/                 # Workout templates + AI generation + exercise library + logging
│   ├── diet/                    # 3-mode meal entry (BANCO/IA/FOTO) + AI diet plan
│   ├── profile/                 # User profile + avatar + goals + bioimpedance
│   ├── ranking/                 # Global + friends leaderboard + friend system
│   └── notifications/           # In-app notifications
└── shared/widgets/
    ├── bottom_nav_bar.dart      # MainScaffold + tutorial trigger
    ├── tutorial_overlay.dart    # Interactive onboarding tutorial (see below)
    ├── mk_button.dart
    ├── mk_card.dart
    └── mk_text_field.dart
```

Each feature follows `data/models/`, `data/repositories/`, `presentation/providers/`, `presentation/pages/` layers.

## Key Patterns

**State management**: Riverpod `AsyncNotifierProvider.autoDispose` for mutable state; `FutureProvider.autoDispose` for read-only data; `StateNotifierProvider.autoDispose` for complex mutable state (AI diet plan, tutorial). Repositories are exposed via `Provider<XRepository>`.

**Routing**: ShellRoute wraps the 5 main tabs (dashboard/workout/diet/ranking/profile) inside `MainScaffold` (bottom nav). Auth redirect is synchronous in `GoRouter.redirect`. Non-shell routes: `/login`, `/register`, `/confirm-email`, `/edit-profile`, `/notifications`.

**Supabase**: Direct `Supabase.instance.client` calls in repositories — no abstraction layer. Ranking uses RPC functions (`get_global_ranking`, `get_friends_ranking`, `search_users`, `get_pending_requests`).

**Gamification points**:
- +10 pts → completar qualquer treino (uma vez por dia por template)
- +5 pts → por exercício cujo peso aumentou em relação à última sessão (progressão)
- +10 pts → bater a meta calórica diária (consumo dentro de ±10% da meta)

**SharedPreferences**: All keys are user-scoped: `'<key>_${userId}'` to prevent data bleed between accounts on the same device/browser.

## Workout Templates (`workout/`)

The workout system is template-based. Users create reusable workout templates (named, with a list of exercises), then execute them with "FAZER HOJE".

**Workflow**:
1. Create template (manual) or generate with AI → saved to `workout_templates` + `template_exercises`
2. Tap template card → "FAZER HOJE" → `_DoWorkoutSheet` opens
3. User updates weights if needed + uses rest timer
4. "CONCLUIR TREINO" → `completeTemplate()` → saves to `workout_completions`, awards points

**AI generation** (`_showAiSheet` → `GroqService.generateWorkout(group)`): returns exercises as `List<Map>`, saved immediately as a new template. Groups: Peito, Costas, Ombros, Bíceps, Tríceps, Pernas, Glúteos, Core, Full Body.

**Exercise library** (`exercise_library.dart`): local predefined exercises by muscle group. Used in `_ExerciseLibrarySheet` when creating/editing a template manually. `ExerciseLibrary.search(q)` and `ExerciseLibrary.byGroup`.

**Rest timer** (`_WorkoutTimer`): runs inside `_DoWorkoutSheet`. Start/pause/reset + presets (30/60/90/120s).

**Progression detection**: `completeTemplate()` in `workout_template_repository.dart` compares current exercise weights against last session weights. Returns `{'already_done': bool, 'progression': int}` (progression = count of exercises that increased weight).

**Template card** shows `doneToday` state — turns green and shows "FEITO HOJE" button when completed today.

## Diet — 3-Mode Meal Entry (`diet/`)

The meal entry sheet (`_SmartMealSheet`) has 3 modes selectable via tab:

| Mode | Source | How it works |
|------|--------|-------------|
| **BANCO** | `food_database.dart` | Search local food DB → select item → enter weight (g) → macros calculated |
| **IA** | Groq text | Describe freely ("200g frango grelhado") → `calculateFoodMacros()` → macro card |
| **FOTO** | Groq vision | Camera or gallery → `analyzeFoodPhoto()` → result with weight slider |

**Food database** (`FoodDatabase`): local static food database in `food_database.dart`. `FoodDatabase.search(query)` returns `List<FoodItem>`. Each `FoodItem` has `kcalPer100g`, `proteinPer100g`, `carbsPer100g`, `fatPer100g` and `calculate(weightG)` → `NutritionResult`.

**FOTO mode**: image picked → bytes encoded as base64 → `GroqService.analyzeFoodPhoto(b64, portionHint: hint)` → result shown with slider (20–600g range) to adjust weight; macros scale proportionally.

**Macro rings**: Diet page shows animated circular progress rings per macro (Proteína/Carboidrato/Gordura) using `TweenAnimationBuilder` + `CustomPainter`.

**+LOG button**: Foods in the AI Diet Plan section have a "+LOG" button to add them directly to `diet_logs` without reopening the meal sheet.

## AI Diet Plan (`diet_provider.dart` + `diet_model.dart`)

`aiDietPlanProvider` is a `StateNotifierProvider.autoDispose<AiDietPlanNotifier>`.

**Persistence**: plan saved to `SharedPreferences` under `'ai_diet_plan_v1_${userId}'`. Loaded on init. Survives F5/reload on web.

**Food swap** (`swapFood(mealIdx, foodIdx, newFood)`): replaces a food item and auto-recalculates weight to maintain original calorie count:
```dart
newWeight = (originalFood.calories / newFood.kcalPer100g) * 100
```

**`DietPlan` / `DietPlanMeal` / `DietPlanFood`** all implement `toJson()` / `fromJson()`.

## Registration — 3-Step Flow (`register_page.dart`)

```
Step 0 — Conta:  nome, e-mail, senha
Step 1 — Corpo:  altura, peso atual, peso alvo + IMC calculado ao vivo
Step 2 — Missão: objetivo inferido automaticamente (perder/ganhar/manter) + meta semanal de treinos + resumo do perfil
```

**Live BMI** (`_bmi` getter): `peso / (altura_metros²)`. Shown visually while user types in Step 1.

**Goal inference**: `_goalType` compares `currWeight` vs `targetWeight` → `'lose_weight'` / `'gain_weight'` / `'maintain'`.

## Dashboard (`dashboard/`)

`DashboardModel` fields: `totalPoints`, `globalRank`, `friendsRank`, `workoutDoneToday`, `dietGoalMetToday`, `currentWeight`, `targetWeight`, `weeklyWorkouts`, `weeklyWorkoutGoal`, `pointHistory`.

**Monday weight prompt**: `initState()` in `DashboardPage` calls `_checkMondayWeightPrompt()` via `postFrameCallback`. On Mondays (if not already shown today), shows a dialog asking user to record their weekly weight. Saved with key `'last_weight_prompt_monday'` (not user-scoped — one per device per Monday).

Dashboard data comes from Supabase RPC `get_dashboard_data`.

## Groq API (`groq_service.dart`)

Four static methods, all calling `https://api.groq.com/openai/v1/chat/completions`:

| Method | Model | Temp | Returns |
|--------|-------|------|---------|
| `generateWorkout(muscleGroup)` | text | 0.7 | `List<Map>` — each map has `name`, `sets`, `reps`, `tip` |
| `calculateFoodMacros(description)` | text | 0.2 | map: `name`, `weight_g`, `calories`, `protein`, `carbs`, `fat` |
| `generateDietPlan(calories, goalType, {goalProtein?, goalCarbs?, goalFat?})` | text | 0.3 | full `DietPlan` JSON |
| `analyzeFoodPhoto(base64Input, {portionHint?})` | vision | 0.2 | map: `name`, `weight_g`, `calories`, `protein`, `carbs`, `fat` |

**`generateDietPlan`**: strict "não ultrapassar" macro rules. Falls back to 30/40/30 split if targets omitted. Temperature 0.3 is intentional to enforce caloric accuracy.

**Image optimization** (`_optimizeImage()`): detects PNG via magic bytes; resizes to max 768px; encodes as JPEG 80%. Returns `(String b64, String mime)`. Never reduce `_maxImagePx` below 768.

**Models**: text → `llama-3.3-70b-versatile`, vision → `meta-llama/llama-4-scout-17b-16e-instruct`

## Interactive Tutorial (`tutorial_overlay.dart`)

Shown to new users on first login. Stored in SharedPreferences as `'tutorial_seen_${userId}'`.

**12 steps across 5 sections** (INÍCIO → TREINO → DIETA → RANKING → PERFIL):

| Steps | Route | What it covers |
|-------|-------|----------------|
| 0–1 | /dashboard | Welcome + Points/Rank/Streak |
| 2–3 | /workout | Template creation + AI workout + FAZER HOJE |
| 4–7 | /diet | Meal entry (3 modes) + macro summary + AI diet plan |
| 8–9 | /ranking | Global ranking + friends |
| 10–11 | /profile | Profile setup + goals + bioimpedance |

**Auto-navigation**: `context.go(route)` via `postFrameCallback`. ShellRoute keeps `MainScaffold` alive.

**Spotlight**: `CustomPainter` with `canvas.saveLayer` + `BlendMode.clear`. Pulsing lime glow via `AnimationController`. Targets: `SpotTarget.nav0-4` (nav bar icons) and `SpotTarget.pageTop/Middle/Bottom` (22/50/75% body height).

**Integration**: `bottom_nav_bar.dart` wraps `Scaffold` in a `Stack` with `Positioned.fill(TutorialOverlay(...))` when `show == true`.

## Design System — Obsidian Kinetic

Dark theme only. Full spec in `../obsidian_kinetic/DESIGN.md`. Key colors:
- Background: `#121413`
- Primary accent: `#7EFC00` (lime green)
- AI/workout accent: `#7C3AED` (purple — used in AI buttons/chips)
- Photo mode accent: `#0EA5E9` (cyan)
- Surface containers: `#1B1C1C` → `#343535`

UI mockups: `../dashboard_de_progresso_v3/` and `../perfil_e_evolu_o_v3/` (HTML + screenshot).

## External Services

| Service | Purpose | Config |
|---------|---------|--------|
| Supabase | Auth + PostgreSQL + Storage | `supabase_config.dart` |
| Groq | LLM inference | `groq_config.dart` (key starts `gsk_`) |
| Vercel | Web hosting | Project: `muscle-champ`, scope: `af-dev` |

## Supabase Tables

All tables have RLS enabled. Full list:

| Table | Description |
|-------|-------------|
| `profiles` | User profile data + avatar URL |
| `goals` | Daily calorie target, weight goal, body objective, weekly workout goal |
| `workouts` | Workout sessions (legacy) |
| `exercises` | Individual exercises within a workout (legacy) |
| `workout_templates` | Reusable named workout templates |
| `template_exercises` | Exercises belonging to a template (name, sets, reps, weight_kg) |
| `workout_completions` | Log of completed template workouts (date, template_id, progression_count) |
| `diet_logs` | Individual meal entries (macros, calories) |
| `weight_logs` | Historical body weight entries |
| `bioimpedance_logs` | Body composition measurements |
| `points` | Gamification points log |
| `friendships` | Friend relationships + pending requests |
| `notifications` | In-app notifications |

## Project-Level Docs

Files in `../` (parent of `app/`):

| File | Contents |
|------|----------|
| `GUIA_DO_USUARIO.md` | End-user guide: registration, workouts, diet, ranking, points |
| `DIVULGACAO.md` | Marketing material: taglines, features, CTAs, brand identity |

## Docs Folder (`app/docs/`)

| Folder | Contents |
|--------|----------|
| `docs/juridico/` | LEGAL.md, PRIVACY.md, LICENSES.md |
| `docs/tecnico/` | ARCHITECTURE.md, API.md, SDD.md, DEPENDENCIES.md |
| `docs/marketing/` | BRAND_VOICE.md, MARKETING.md, RELEASE_NOTES.md |
| `docs/qa/` | TEST_PLAN.md, TEST_CASES.md, BUG_REPORT_TEMPLATE.md |
| `docs/seguranca/` | SECURITY.md, THREAT_MODEL.md, CHECKLIST_SEGURANCA.md |
| `docs/suporte/` | FAQ.md, ONBOARDING.md, TROUBLESHOOTING.md |
| `docs/ux/` | UX_GUIDELINES.md, USER_FLOWS.md, ACCESSIBILITY.md |

**Rule**: before implementing any feature with legal implications (payments, health data, minors, geolocation, data sharing), check `docs/juridico/LEGAL.md` and update it if needed.

## Pre-Play Store Checklist

From `docs/juridico/LEGAL.md` — pending before publishing:
- [ ] Change `applicationId` from `com.example.muscle_camp` (in `android/app/build.gradle.kts`)
- [ ] Generate release keystore (currently debug-signed)
- [ ] Host `docs/juridico/PRIVACY.md` at `https://musclechamp.com.br/privacidade`
- [ ] Add consent checkbox for health data in registration screen
- [ ] Add "Excluir minha conta" button in profile
- [ ] Add Privacy Policy link inside the app
- [ ] Fill Play Console Data Safety form (declares health data + Groq photo sharing)
