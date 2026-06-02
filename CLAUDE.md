# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

> **Importante:** Flutter, Android Studio e Node.js estão instalados na **máquina de desenvolvimento (Jean)**.
> Esta máquina (User Implacil) não tem essas ferramentas no PATH — use-a apenas para editar código e commitar.

All commands run from `C:\Users\Jean\Desktop\muscle camp\project\app` (máquina Jean).

### Environment setup (required for Android builds — set in same PowerShell session)
```powershell
$env:ANDROID_HOME = "C:\Users\Jean\AppData\Local\Android\Sdk"
$env:JAVA_HOME    = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH         = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"
```

> **Note**: Flutter is installed at `C:\flutter\bin`. If `flutter` is not found in PowerShell, use Git Bash instead:
> ```bash
> export PATH="/c/flutter/bin:$PATH"
> ```

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
vercel --prod --yes --scope "af-dev"  # Links to muscle-champ project automatically → https://muscle-champ.vercel.app
```

### Build + deploy completo (sequência recomendada)
```bash
# Na máquina Jean, dentro de C:\Users\Jean\Desktop\muscle camp\project\app
flutter pub get
flutter build web --release
cd build/web
vercel --prod --yes --scope "af-dev"
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
│   ├── auth/                    # Login, register, confirm email
│   ├── dashboard/               # Home screen — points, rank, streak, weekly summary
│   ├── workout/                 # AI-generated workouts + exercise logging + templates
│   ├── diet/                    # Meal tracking (text + photo AI) + AI diet plan
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

**Gamification**: Points awarded server-side via Supabase. Dashboard reads `total_points`, `global_rank`, `friends_rank`. Diet goal met = within ±10% of `goals.daily_calories`.

**SharedPreferences**: Used for client-side persistence. All keys are user-scoped: `'<key>_${userId}'` to prevent data bleed between accounts on the same device/browser.

## Groq API (`groq_service.dart`)

Four static methods, all calling `https://api.groq.com/openai/v1/chat/completions`:

| Method | Model | Temp | Returns |
|--------|-------|------|---------|
| `generateWorkout(muscleGroup)` | text | 0.7 | `List<Map>` of exercises |
| `calculateFoodMacros(description)` | text | 0.2 | macro map |
| `generateDietPlan(calories, goalType, {goalProtein?, goalCarbs?, goalFat?})` | text | 0.3 | full `DietPlan` JSON |
| `analyzeFoodPhoto(base64Input, {portionHint?})` | vision | 0.2 | macro map |

**`generateDietPlan`**: accepts exact macro targets in grams; the prompt instructs the model with strict "não ultrapassar" rules. Falls back to 30/40/30 split if targets not provided.

**Image optimization** (`_optimizeImage()`): returns `(String b64, String mime)`. Detects PNG via magic bytes; resizes to max 768px; always encodes as JPEG 80%.

**Models**: text → `llama-3.3-70b-versatile`, vision → `meta-llama/llama-4-scout-17b-16e-instruct`

## AI Diet Plan (`diet_provider.dart` + `diet_model.dart`)

`aiDietPlanProvider` is a `StateNotifierProvider.autoDispose<AiDietPlanNotifier>`.

**Persistence**: plan is saved to `SharedPreferences` under `'ai_diet_plan_v1_${userId}'` on every generate/swap. Loaded back on notifier init. Survives F5 / page reload on web.

**Food swap** (`swapFood(mealIdx, foodIdx, newFood)`): replaces a food item, automatically recalculating its weight to maintain the original food's calorie count:
```dart
newWeight = (originalFood.calories / newFood.kcalPer100g) * 100
```
Saves the updated plan to SharedPreferences after swap.

**`DietPlan` / `DietPlanMeal` / `DietPlanFood`** all implement `toJson()` / `fromJson()` for serialization.

## Interactive Tutorial (`tutorial_overlay.dart`)

Shown to new users on first login. Never shown again after completion (stored in SharedPreferences as `'tutorial_seen_${userId}'`). Uses `StateNotifierProvider.autoDispose` — resets correctly on account switch.

**12 steps across 5 sections** (INÍCIO → TREINO → DIETA → RANKING → PERFIL):

| Steps | Route | What it covers |
|-------|-------|----------------|
| 0–1 | /dashboard | Welcome + Points/Rank/Streak |
| 2–3 | /workout | AI workout generation + logging |
| 4–7 | /diet | Meal text log + photo analysis + macro summary + AI diet plan |
| 8–9 | /ranking | Global ranking + friends |
| 10–11 | /profile | Profile setup + goals + bioimpedance |

**Auto-navigation**: when advancing to a new section, the overlay calls `context.go(route)` via `postFrameCallback`. The ShellRoute keeps `MainScaffold` alive during tab changes.

**Spotlight**: `CustomPainter` with `canvas.saveLayer` + `BlendMode.clear` to cut a hole in the dark overlay. Pulsing lime-green glow ring via `AnimationController`. Two spotlight targets:
- `SpotTarget.nav0-4`: bottom nav bar icons (radius 38px)
- `SpotTarget.pageTop/Middle/Bottom`: positioned at 22/50/75% of page body height (radius 52px)

**Card positioning**: card appears below spotlight when spot is in upper 45% of screen (arrow points up), above spotlight otherwise (arrow points down).

**Integration in `MainScaffold`**: `bottom_nav_bar.dart` watches `tutorialProvider` and wraps the `Scaffold` in a `Stack` with `Positioned.fill(TutorialOverlay(...))` when `show == true`.

## Design System — Obsidian Kinetic

Dark theme only. Key colors from `AppColors`:
- Background: `#121413`
- Primary accent: `#7EFC00` (lime green)
- Surface containers: `#1B1C1C` → `#343535` (gradient of greys)
- Photo/AI mode uses cyan `#0EA5E9` as accent

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
| `goals` | Daily calorie target, weight goal, body objective |
| `workouts` | Workout sessions |
| `exercises` | Individual exercises within a workout |
| `workout_templates` | Saved AI-generated workout templates |
| `template_exercises` | Exercises belonging to a template |
| `workout_completions` | Log of completed template workouts |
| `diet_logs` | Individual meal entries (macros, calories) |
| `weight_logs` | Historical body weight entries |
| `bioimpedance_logs` | Body composition measurements |
| `points` | Gamification points log |
| `friendships` | Friend relationships + pending requests |
| `notifications` | In-app notifications |

Dashboard data comes from `dashboard_repository.dart` via Supabase RPC `get_dashboard_data`.

## Pre-Play Store Checklist

From `docs/juridico/LEGAL.md` — pending before publishing:
- [ ] Change `applicationId` from `com.example.muscle_camp` (in `android/app/build.gradle.kts`)
- [ ] Generate release keystore (currently debug-signed)
- [ ] Host `docs/juridico/PRIVACY.md` at `https://musclechamp.com.br/privacidade`
- [ ] Add consent checkbox for health data in registration screen
- [ ] Add "Excluir minha conta" button in profile
- [ ] Add Privacy Policy link inside the app
- [ ] Fill Play Console Data Safety form (declares health data + Groq photo sharing)

## Docs Folder

`docs/` contains supporting documentation organized by area:

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
