# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

All commands run from the repo root (`C:\Users\Henry\Desktop\muscle-champ`).

> **Note**: Flutter is at `C:\Users\Henry\flutter\bin`.

### Environment setup (required for Android builds)

Verified on this machine 2026-08-28 with `flutter doctor -v`. The SDK is **not**
under `AppData\Local\Android` (the usual default) and there is no standalone
JDK — the only Java is the one bundled with Android Studio:

```powershell
$env:ANDROID_HOME = "C:\Users\Henry\Android\Sdk"
$env:JAVA_HOME    = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH         = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"
```

Without `JAVA_HOME` set, `flutter doctor` reports *"No Java Development Kit
(JDK) found"* and every Gradle task fails. Android SDK 36 / build-tools 36.0.0 /
JBR 25.0.2.

⚠️ **From Git Bash, use Windows-style paths and do NOT put `$JAVA_HOME/bin` on
`PATH`.** This works:

```bash
export JAVA_HOME="C:/Program Files/Android/Android Studio/jbr"
export ANDROID_HOME="C:/Users/Henry/Android/Sdk"
export PATH="/c/Users/Henry/flutter/bin:$PATH"
flutter build apk --release
```

Exporting the POSIX form (`/c/Program Files/...`) and prepending `$JAVA_HOME/bin`
to `PATH` corrupts `PATH` for the PowerShell that `flutter.bat` spawns, and the
build dies at startup with a message that names none of this:

```
Set-Content : O fluxo não era legível.
  update_engine_version.ps1:94  Set-Content -Path .../engine.realm -Value ""
Error: Unable to determine engine version...
```

That message sent me hunting a file lock for six builds. The tells that it is
**not** a lock: `flutter build web` succeeds in the same session seconds later,
and writing `engine.realm` by hand works. Gradle reads `JAVA_HOME` directly and
never needs `java` on `PATH`, so there is no reason to add it.

⚠️ **No emulator is installed and no device is usually plugged in.** `flutter
build apk` works; `flutter run` and any on-device verification need either a
phone connected over USB with debugging enabled, or
`sdkmanager "emulator" "system-images;android-36;google_apis;x86_64"` first.

### Android-only paths — exercised on a real phone 2026-08-28

These four exist only on Android (on web they are stubbed or absent), so they
had never run until this date. All four passed on the owner's phone from the
debug-signed release APK:

| Path | Where | Code |
|---|---|---|
| Camera → macros | Dieta → refeição → FOTO | `diet_page.dart:3533` |
| Camera → hand calibration | Dieta → FOTO → calibrar | `calibration_page.dart:223` |
| Data export (LGPD) | Perfil → Privacidade → Exportar | `privacy_repository.dart:57` |
| External legal links | Perfil → Privacidade | `privacy_page.dart:33` |

The APK declares **no `CAMERA` permission**, and that is correct, not an
oversight: `image_picker` hands off to the system camera through an intent, so
declaring it would only add a runtime prompt for nothing. If a build ever starts
asking for camera permission, something changed for the worse.

⚠️ **Gradle warns that `image_picker_android`, `share_plus`,
`shared_preferences_android` and `url_launcher_android` apply the Kotlin Gradle
Plugin the old way, and that future Flutter versions will fail to build.**
Nothing breaks today; it breaks the day the SDK is upgraded. The fix is bumping
those four packages.

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

### Web deploy — Cloudflare Pages (destino final)

```bash
npx wrangler pages deploy build/web --project-name=muscle-champ --branch=main
```

First time only — `wrangler login` opens a browser OAuth flow, so a human has to
do it:

```bash
npx wrangler login
```

**Why Cloudflare and not Vercel.** The app is 48 static files; Vercel executes
nothing for it (the `groq-proxy` runs on Supabase). But Vercel's Hobby plan
**forbids commercial use** — their fair-use policy counts "advertising the sale
of a product or service", so merely announcing the subscription violates it.
Staying would mean Pro at US$20/month ≈ R$1.296/year, which at the projected
Year-1 volume eats the entire revenue. Cloudflare Pages free has no such clause
and no documented bandwidth cap.

Free-tier limits vs this app: 25 MiB per file (largest is `canvaskit.wasm` at
6.9 MB), 20,000 files (we ship 48), 500 builds/month. Comfortable.

No `_redirects` file is needed: the app uses **hash routing** (`/#/register`)
because `usePathUrlStrategy` is not called, so every route resolves through
`index.html` on its own. If someone ever switches to path URLs, a SPA fallback
becomes mandatory or deep links will 404.

### Vercel — RETIRED (2026-08-26)

**Do not deploy the app there.** `muscle-champ.vercel.app` now serves nothing
but a `307` redirect to `muscle-champ.pages.dev`.

Redirecting rather than just abandoning the project was deliberate: stopping
deploys would have left the last build frozen there forever, and anyone with
the URL bookmarked would keep testing a stale app while believing it was
current. The redirect is **temporary (307), not permanent (308)** — a 308 gets
cached by browsers indefinitely and would be painful to undo if Vercel is ever
needed again.

The project still exists in the `af-dev` scope, serving only the redirect. The
files live in `tools/vercel-retirado/` — versioned because the redirect has
already been clobbered once and nobody remembers its contents from memory.

⚠️ **The Vercel project was connected to GitHub.** A `git push` to `master`
triggered an automatic deploy of the repo root — which is not a static site —
and the resulting 404 replaced the redirect fifteen minutes after it was
verified working. Retiring a host without cutting its Git integration is a time
bomb: every future push breaks it again. Turned off with
`npx vercel git disconnect`. If anyone reconnects it, this comes back.

Deleting the project outright is a dashboard action and is yours to take.

### Build + deploy completo
```bash
flutter pub get
flutter build web --release
npx wrangler pages deploy build/web --project-name=muscle-champ --branch=main
```

⚠️ **Never deploy without confirming the build succeeded.** `flutter build`
fails on Windows with `Unable to determine engine version`. The deploy command
happily ships whatever is already in `build/web`, so a failed build silently
republishes the previous version. Check for `✓ Built build\web` first, or
compare hashes afterwards:

```bash
curl -s -o /tmp/served.js https://musclechamp.com.br/main.dart.js && sha256sum /tmp/served.js build/web/main.dart.js
```

Same hash and the deploy is live — **whatever the browser shows**. Compare hashes
before debugging a "deploy that did not go out"; the answer is almost always
caching, and the next section says where.

### ⚠️ The zone's Browser Cache TTL overrides `web/_headers`

`web/_headers` sets `no-cache, must-revalidate` on the entry points
(`index.html`, `main.dart.js`, `flutter_bootstrap.js`, `flutter_service_worker.js`,
`version.json`) precisely so a deploy is visible immediately. **On the custom
domain that file is not the last word.** Traffic to `musclechamp.com.br` goes
through the proxied Cloudflare zone, and the zone's *Browser Cache TTL* setting
rewrites the header on the way out:

```
muscle-champ.pages.dev/main.dart.js → Cache-Control: no-cache, must-revalidate
musclechamp.com.br/main.dart.js     → Cache-Control: max-age=14400, must-revalidate
```

Same file, same project, same deploy. 14400s is **4 hours**, and it appears
nowhere in `_headers` — it is the zone default. Every returning visitor keeps the
previous bundle for up to four hours after any deploy, including a hotfix. Only a
browser that never opened the site sees the new build.

**Fix:** Cloudflare → zone `musclechamp.com.br` → Caching → Configuration →
Browser Cache TTL → **Respect Existing Headers**.

The tell is that `pages.dev` shows the new version and the custom domain does not.
That looks like a broken custom domain and is not: the files are byte-identical,
verified by hash. Check `curl -sI` for the header before touching the deploy.

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

**FOTO mode**: image picked → bytes encoded as base64 → `GroqService.analyzeFoodPhoto(b64, portionHint: hint, handLengthCm:, handWidthCm:)` → result shown with slider (20–600g range) to adjust weight; macros scale proportionally.

**Hand calibration** (`calibration_page.dart` + `calibration_repository.dart`): optional one-time step to improve photo accuracy. User photographs a coin (R$1=27mm / R$0,50=23mm / R$0,25=25mm) on their open palm; `GroqService.calibrateHand(b64, coinMm)` measures the hand using the coin as scale reference. Saved to `goals` (`hand_length_cm`, `hand_width_cm`, `hand_calibrated_at`). The FOTO mode reads `handCalibrationProvider` and passes the measurements to `analyzeFoodPhoto` — if the hand appears next to the food it's a precise ruler, otherwise it gives the model a sense of the user's body scale. Route: `/calibrate`. A badge/invite shows in FOTO mode based on calibration state.

**Macro rings**: Diet page shows animated circular progress rings per macro (Proteína/Carboidrato/Gordura) using `TweenAnimationBuilder` + `CustomPainter`.

**+LOG button**: Foods in the AI Diet Plan section have a "+LOG" button to add them directly to `diet_logs` without reopening the meal sheet.

## Water Tracker (`diet/`)

Card on the Diet tab: +200/+350/+500ml buttons, progress bar, undo (removes the most recent entry of the day).

**Daily goal is computed in Postgres**, same pattern as `daily_calories`: `calc_daily_water(weight, birth_date)` = weight(kg) × age factor — **≤17: 40ml · 18-55: 35ml · 56-65: 30ml · >65: 25ml**. The `trg_goals_recalc` trigger recalculates on insert and whenever weight or birth date changes. Without `birth_date` it assumes the 18-55 bracket.

Files: `water_model.dart`, `water_repository.dart`, `water_provider.dart`. Migration: `supabase/migrations/20260803_water_tracker_and_birthdate.sql`.

**`birth_date`** lives in `goals`, is required at registration (Corpo step) and editable in the profile. `ProfileModel.age` derives the age. Shared widget: `mk_date_field.dart`.

## Manual Diet (`customDietPlanProvider`)

IA/Manual toggle in the "Plano do Dia" section — the AI plan stays untouched. In Manual mode the user creates meals and picks foods from the local `FoodDatabase` by weight; macros are computed by the app. Each food has a **+LOG** button that writes straight to `diet_logs`.

Persisted per user in SharedPreferences under `'custom_diet_plan_v1_${userId}'`, reusing the `DietPlan`/`DietPlanMeal`/`DietPlanFood` models.

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
Step 1 — Corpo:  altura, peso atual, peso alvo, data de nascimento + IMC ao vivo
Step 2 — Missão: objetivo inferido automaticamente (perder/ganhar/manter) + meta semanal de treinos + resumo do perfil
```

Birth date is **required** (feeds the water goal) and validated in `_goNext()` before leaving Step 1.

**Live BMI** (`_bmi` getter): `peso / (altura_metros²)`. Shown visually while user types in Step 1.

**Goal inference**: `_goalType` compares `currWeight` vs `targetWeight` → `'lose_weight'` / `'gain_weight'` / `'maintain'`.

## Dashboard (`dashboard/`)

`DashboardModel` fields: `totalPoints`, `globalRank`, `friendsRank`, `workoutDoneToday`, `dietGoalMetToday`, `currentWeight`, `targetWeight`, `weeklyWorkouts`, `weeklyWorkoutGoal`, `pointHistory`.

**Monday weight prompt**: `initState()` in `DashboardPage` calls `_checkMondayWeightPrompt()` via `postFrameCallback`. On Mondays (if not already shown today), shows a dialog asking user to record their weekly weight. Saved with key `'last_weight_prompt_monday'` (not user-scoped — one per device per Monday).

Dashboard data comes from Supabase RPC `get_dashboard_data`.

## Groq API (`groq_service.dart`)

**The Groq key is NEVER in the client.** All calls go through the Supabase Edge Function `groq-proxy` (`${supabaseUrl}/functions/v1/groq-proxy`), which is JWT-authenticated. The key lives in the Supabase **Vault** (`groq_api_key`) and is read only server-side by the Edge Function. `GroqService._headers()` sends the logged-in user's session `accessToken`; `GroqConfig.isConfigured` checks for an active Supabase session.

To rotate the key: `SELECT vault.update_secret((SELECT id FROM vault.secrets WHERE name='groq_api_key'), 'gsk_...')` then redeploy the `groq-proxy` function (it caches the key per instance).

Four static methods, all POSTing to the proxy (which forwards to `https://api.groq.com/openai/v1/chat/completions`):

| Method | Model | Temp | Returns |
|--------|-------|------|---------|
| `generateWorkout(muscleGroup)` | text | 0.7 | `List<Map>` — each map has `name`, `sets`, `reps`, `tip` |
| `calculateFoodMacros(description)` | text | 0.2 | map: `name`, `weight_g`, `calories`, `protein`, `carbs`, `fat` |
| `generateDietPlan(calories, goalType, {goalProtein?, goalCarbs?, goalFat?})` | text | 0.3 | full `DietPlan` JSON |
| `analyzeFoodPhoto(base64Input, {portionHint?, handLengthCm?, handWidthCm?})` | vision | 0.2 | map: `name`, `weight_g`, `calories`, `protein`, `carbs`, `fat` |
| `calibrateHand(base64Input, coinDiameterMm)` | vision | 0.1 | map: `hand_length_cm`, `hand_width_cm` (or `error`) |

**`generateDietPlan`**: strict "não ultrapassar" macro rules. Falls back to 30/40/30 split if targets omitted. Temperature 0.3 is intentional (keeps "Regenerar" producing varied menus).

### Nutrition calibration — the model does no arithmetic

The LLM used to estimate calories directly and inflated them (up to 2×: "2 ovos" → 286kcal for 100g, double the real value). It also drifted between equivalent phrasings. Fixed by splitting responsibilities:

| Step | Who | Why |
|------|-----|-----|
| Parse "2 ovos cozidos" → food + qty + unit | LLM | language task — it's good at this |
| qty + unit + food → grams | app (`_kMedidas`) | measurement — it's bad at this |
| grams + density → kcal/macros | app (`_kDensity` cascade) | arithmetic — it's bad at this |

`calculateFoodMacros` and `analyzeFoodPhoto` run at `temperature: 0`, `top_p: 1`, `seed: 42` — the same input always yields the same output. **Consistency matters more than absolute accuracy for a tracker**: a stable value makes weekly trends meaningful.

**Density cascade** in `_lookupDensity(name, categoria)`, most to least reliable:
1. `_kDensity` — ~130 hand-calibrated foods (prepared dishes and drinks, which TACO lacks). Substring match, longest key wins.
2. `kTacoTable` — 581 foods from TACO 4th ed. (`taco_table.dart`, generated by `tool/gen_taco.dart`). **Conservative match**: head noun must be identical, every query word must be explained by the key, and leftover key words must be preparation descriptors only (`_kPreparo`). Refuses when unsure — a plausible-but-wrong value is worse than no match.
3. `_kCategoria` — 30 calibrated ranges. The LLM classifies (a task it does well) instead of inventing numbers.
4. AI's raw density — last resort.

Known foods use the **official kcal from the table, not Atwater**: the 4/4/9 formula counts fiber as 4kcal/g when it yields ~2, overestimating fruit/vegetables/grains by ~10% (abacaxi gave 54 instead of 48).

`_normalizeNutrition()` sums **item by item** (the model can't do weighted averages reliably) and enforces physical limits: macros never outweigh the food, nothing exceeds 9kcal/g.

**Weight is editable in text mode** (`_aiAdjustedWeight`): measures like "1 prato de arroz" range from 100g to 250g between people — no table solves that, only whoever ate.

⚠️ When adding foods, put **prepared dishes and drinks** in `_kDensity` (TACO has neither). Regenerate TACO with `dart run tool/gen_taco.dart TACO.json`; validate matching with `dart run tool/test_taco_match.dart`.

**Image optimization** (`_optimizeImage()`): detects PNG via magic bytes; resizes to max 768px; encodes as JPEG 80%. Returns `(String b64, String mime)`. Never reduce `_maxImagePx` below 768.

### Model selection lives in the proxy, not the app

**The app never names a model.** It sends `"task": "text"` or `"task": "vision"`; the
Edge Function resolves that to the current model id via `MODEL_CHAINS`.

This is deliberate. Groq retires models with little notice (twice in 30 days) and the app
breaks instantly with *"The model X does not exist or you do not have access to it"*.
With the id compiled into the client, an installed APK would stay broken until every user
updated through the Play Store — days to weeks. Now a model swap is a function redeploy.

**To change models**: edit `MODEL_CHAINS` in `supabase/functions/groq-proxy/index.ts` and
redeploy. Nothing in Dart changes. Retirements so far:
`meta-llama/llama-4-scout-17b-16e-instruct` (vision, 2026-07-17) and
`llama-3.3-70b-versatile` (text, 2026-08-16).

**Fallback**: each task has an ordered chain. If the primary answers "model does not
exist", the proxy retries the next one and logs `ATUALIZAR MODEL_CHAINS`. Only that error
triggers a retry — a rate limit or bad payload would fail identically on any model. The
response carries `x-model-used`, and `x-model-fallback` when a retry happened.
⚠️ `vision` has a chain of one: qwen3.6-27b is the only multimodal model in use, so the
FOTO mode has no automatic recovery.

**Reasoning models need per-model tuning.** `gpt-oss-120b` spends output tokens *thinking*
before emitting content. Left alone it consumed the entire `max_tokens` budget on
reasoning and returned **empty `content` with `finish_reason: "length"`** — a silent
failure, not an error. The proxy fixes this per model via `ModelSpec`:
`reasoningEffort: "low"` and `tokenHeadroom: 2.5`. Measured: ~65% of output is reasoning
on short JSON prompts, and reasoning tokens are billed as output.
Note `reasoning_effort` accepts only `low|medium|high` on gpt-oss — the `"none"` that
`calibrateHand` sends is valid on qwen, and the proxy only injects when the caller
did not set it.

Determinism survives the swap: `temperature: 0, top_p: 1, seed: 42` still yields identical
output for identical input (verified).

The nutrition calibration below was tuned on Llama 3.3. After a text-model swap, the
parsing half ("2 ovos cozidos" → food + qty + unit) may drift — the arithmetic half is
in Dart and is unaffected. Re-validate before trusting the numbers.

### Nutrition validation battery

`test/nutricao_casos.dart` holds 32 real-world Portuguese food descriptions with
reference kcal bands. Two files consume it:

```bash
GRAVAR_NUTRICAO=1 flutter test test/nutricao_gravar_test.dart   # grava a fixture (rede + tokens)
flutter test test/nutricao_test.dart                            # valida offline
```

The recorder hits the proxy with `GroqService.corpoDaRequisicaoDeMacros` — the
**same body the app sends**, never a copy of the prompt — and writes
`test/fixtures/nutricao_modelo.json`. The validator replays that fixture through
`GroqService.normalizarNutricao` with no network, so it runs in CI. **Re-record
and re-run after every model change**: that is the re-validation ritual.

⚠️ **The recorder must run through PowerShell, not the Bash tool** — the Bash
sandbox blocks the Dart VM's DNS (`Failed host lookup`) while `curl` still works,
which looks like an outage and isn't.

⚠️ **A battery can come out split across two models.** On 429 the proxy advances
to the next model in the chain and answers normally, and `x-model-fallback` is
**not** set (that header only means *retired*). So under rate pressure the text
task silently alternates between `gpt-oss-120b` and `qwen3.6-27b`. The fixture
records the model **per case** and the recorder warns when they differ. The two
disagree on units — for "1 pote de açaí" qwen said `pote`, gpt-oss said
`unidade` — so both have to pass.

**What the first run caught (2026-08-25), all fixed:**

| Sintoma | Causa |
|---|---|
| Pote de açaí registrava **1 kcal** | Unidade fora de `_kMedidas` → item descartado → `clamp(1.0, …)` |
| 3 castanhas do pará = **1701 kcal** | Default `'unidade': 100` aplicado a alimento de 5g |
| `name_pt` faltando em 3 casos | O exemplo JSON do prompt não mostrava o campo — o modelo segue o exemplo |
| Couve refogada 25 kcal (real: 90) | Matcher TACO recusa; caiu na categoria "verdura" crua, sem o óleo |
| Açaí com granola a 58 kcal/100g | Substring casava `'acai'` (polpa pura) |
| Big Mac 100g / 250 kcal | `unidade` sem entrada para sanduíche |

O default `'unidade': 100` é a maior fonte de erro do conversor. Mitigado com
entradas por alimento em `_kMedidas` e, para o que não estiver lá,
`_kUnidadeDaCategoria` (oleaginosa 5g, sanduíche 180g, ovo 50g…). Unidade
desconhecida agora assume `_kPorcaoPadrao` (100g) em vez de zerar o item.

**Limitação conhecida**: dentro de um prato composto ("uma marmita de frango com
arroz, feijão e salada") o modelo manda cada componente como `1 unidade`. O peso
total sai certo (~400g) mas a divisão fica uniforme e o total cai ~15%. Insistir
no prompt não resolveu, e a incerteza do próprio pedido é maior que isso.

## Subscription — DEMO ONLY (`features/subscription/`)

Paywall + fake checkout, landed 2026-08-25. Prices come from `VALORES.md`.

```
/assinatura            → PaywallPage        (escolha de plano)
/assinatura/pagamento  → PagamentoPage      (checkout falso, plano via extra)
/assinatura/sucesso    → AssinaturaSucessoPage
```

Entry point: the ASSINATURA card in the profile.

⚠️ **Nothing here charges anything.** `AssinaturaRepository` writes to
SharedPreferences (`assinatura_demo_v1_<uid>`) so the flow can be walked
end-to-end. A `DemoBanner` sits on all three screens on purpose: a convincing
payment screen that doesn't charge is exactly what leaks to production unnoticed.

### Free-tier AI quota (`cota_ia.dart`)

The free plan gets a **daily quota**, not a block: 1 photo · 3 text macros ·
1 workout · 1 diet plan. Pro is unlimited. Limits live on the `RecursoIa` enum
and are pinned by `test/cota_ia_test.dart`.

Quota is about conversion, not cost — a heavy user burns ~R$ 1,06/month in AI
(`VALORES.md` §2). Someone who never saw a photo turn into macros doesn't know
what they'd be buying. The photo cap is tightest because it alone is ~88% of AI
spend.

Call sites check `podeUsar()` **before** the call and `registrarUso()` **after
success only** — charging the quota on a network failure would burn the day's
single photo with nothing to show. The photo path also skips the charge when
the model answers with `error` (didn't recognize the food).

`_gerarPlanoComCota()` gates the diet plan **in the page, not in
`AiDietPlanNotifier`** — the notifier generates diets and shouldn't know what a
subscription is; otherwise testing the generator would need billing state.

A `SeloDeCota` badge ("2 de 3 hoje") sits in the IA and FOTO mode headers.
Showing the balance before it runs out is what separates a limit from a trap.
The profile carries a **Zerar cota (demo)** shortcut so the limit can be tested
without waiting for midnight; it goes away with the demo mode.

### Subscription and quota live in Postgres, not on the device

Migration `20260825_assinatura_e_cota_no_servidor.sql`. Both started in
SharedPreferences and that was wrong for the same reason: they are **account**
state, not device state. Subscribing on the phone and opening on the PC showed
the free plan again, and the daily photo could be spent once per device.

| Tabela | RLS | Quem escreve |
|---|---|---|
| `assinaturas` | dono lê/escreve — **políticas DEMO** | o cliente, por enquanto |
| `cota_ia_diaria` | dono **só lê** | apenas as RPC `SECURITY DEFINER` |

`cota_ia_diaria` has **no write policy on purpose**: without one, not even the
owner can zero their own counter from outside. Writes go through
`consumir_cota_ia(recurso)`, which is atomic (`on conflict do update`) and takes
the day from `app_today()` — the server's date, closing the "adiantar o relógio"
hole the local counter had. `get_cota_ia()` reads today's map;
`zerar_cota_ia()` exists only for the demo reset button.

⚠️ The resource keys `('foto','texto','treino','dieta')` are a **contract with
the database** — `consumir_cota_ia` rejects anything else. `RecursoIa.chave`
renaming without touching the migration breaks every AI call in the app;
`test/cota_ia_test.dart` pins the exact set.

The subscription providers are `autoDispose` for a reason: cached at the root
they would survive a logout and show the previous account's plan.

**The client cannot write entitlement at all.** Migration
`20260825b_fecha_bypass_de_cota_e_assinatura.sql` dropped every write policy on
`assinaturas`; both tables are now read-only over PostgREST. Writes go through:

| RPC | Quem pode | Teto |
|---|---|---|
| `assinar_demo(plano, valor)` | qualquer autenticado | servidor força trial de 14 dias |
| `cancelar_assinatura()` | qualquer autenticado | só a própria linha |
| `consumir_cota_ia(recurso)` | qualquer autenticado | +1, dia de `app_today()` |
| `zerar_cota_ia()` | **só `contas_de_teste`** | — |

`assinar_demo` stays open because the paywall has to be walkable by whoever is
testing, but the server picks the dates and forces `em_trial` — the abuse
ceiling dropped from "Pro até 2099" to the same 14-day trial the screen already
offers. Plan id is validated against a closed list and the price is clamped.

`contas_de_teste` has **no RLS policy at all**, so PostgREST returns nothing to
anyone — who is on the list can't be discovered from outside. `zerar_cota_ia`
was a full quota bypass before this (any authenticated user could call
`/rest/v1/rpc/zerar_cota_ia`); the profile button now only renders when
`sou_conta_de_teste()` says yes, because a button that always errors is worse
than no button.

⚠️ **`assinar_demo` must be dropped when billing is real** — the name carries
the reminder. Entitlement then comes from the gateway webhook with the service
role, and no client-facing grant function should exist.

**Money is `int` centavos, never `double`.** Twelve `19.90` doubles sum to
238.79999999999998. `formatarBRL()` renders it.

**Price copy has a legal constraint.** `R$ 149,90` is never charged on entry, so
"de R$ 149,90 por R$ 119,90" is an artificial reference price — CDC treats that
as misleading advertising. The screen never strikes through a price; it says
*"primeiro ano por X, renova por Y"* (`Plano.precisaAvisarRenovacao` drives it).
See `VALORES.md` §3.

**The ladder check from `VALORES.md` §1 is a test** — `test/planos_test.dart`.
Higher commitment must always be cheaper per month. Change a price, run it.

Three things change when this goes real, detailed in `VALORES.md` §5: on Android
the screen doesn't exist (Play Billing opens its own sheet), the price comes from
Billing per region rather than from `Planos`, and entitlement moves to Supabase
confirmed by gateway webhook — the client never decides it paid.

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

### Accent colour is user-chosen (`paleta.dart`, 2026-08-27)

Seven closed palettes; the user picks one in the profile. The choice lives in
`profiles.tema` (migration `20260827_tema_do_app_por_conta.sql`), so it follows
the **account** across devices, with SharedPreferences as a first-frame cache —
waiting for the network to learn the colour would open the app green and flip
half a second later.

**A palette is a set, not a value.** The theme's greys are *biased*:
`onSurfaceVariant` was `#BDCBAE`, a greenish grey picked to sit with lime, and
`outline`/`outlineVariant` lean green too. Swapping only `primary` leaves half
the screen green with nobody able to say why. Each `Paleta` therefore carries
its own greys and borders.

`warning` and `error` deliberately do **not** follow the accent: an alert that
changes colour with the theme stops alerting. The streak flame is gold in all
seven.

⚠️ **`AppColors.primary` and friends are getters now, not `const`.** Making them
dynamic broke 163 `const` widget constructors across 23 files, and those `const`
keywords were removed. **Do not put them back** — `dart fix --apply
--code=prefer_const_constructors` will not offer to (the analyzer knows they
can't be const), but a hand-written `const` around anything reading `AppColors`
will fail to compile, which is the good outcome. The bad outcome is someone
"fixing" it by hard-coding a hex.

The cost is real and was accepted: those 163 widgets no longer get skipped on
rebuild, and 61 of them sit in the diet and workout scrolling lists.

**Repainting is explicit** (`repintarTudo()` in `paleta_provider.dart`). The
colours are a static field — nothing observes them, so assignment repaints
nothing, and rebuilding `MaterialApp` doesn't reach pages held inside
`Navigator` routes. The function walks the element tree calling
`markNeedsBuild`. Swapping the app's `key` to force a remount was the
alternative and was rejected: the picker sits at the bottom of the profile page,
so remounting would throw the user back to the top on every colour tried.
`test/paleta_test.dart` pins both halves — it repaints, and `initState` does not
run again.

⚠️ **The palette ids are a contract with the database.** `profiles_tema_valido`
lists the seven; adding a `Paleta` without touching the migration means the app
paints the colour and the server rejects the write, so the choice vanishes on
next launch. `test/paleta_test.dart` keeps the two lists in sync, and also pins
the WCAG contrast that is the reason the list is closed rather than a free
colour picker.

## External Services

| Service | Purpose | Config |
|---------|---------|--------|
| Supabase | Auth + PostgreSQL + Storage + Edge Functions + Vault | `supabase_config.dart` / `secrets.dart` (project `jryetjysjiyuuoznaejc`) |
| Groq | LLM inference (via `groq-proxy` Edge Function) | key in Supabase Vault, never in client |
| Cloudflare Pages | Web hosting (destino) | Project: `muscle-champ` → `musclechamp.com.br` (alias: `muscle-champ.pages.dev`) |
| Vercel | **RETIRED 2026-08-26** — serves only a 307 to the Pages site. Do not deploy. | Archived config in `tools/vercel-retirado/` |
| GitHub Actions | Keepalive, backup, AI healthcheck | `.github/workflows/` |

**Workflows** (all run on GitHub's infra, only once pushed):

| File | What it does |
|------|--------------|
| `supabase-keepalive.yml` | Daily RPC ping so the free tier doesn't pause after ~7 idle days |
| `supabase-backup.yml` | Database backup |
| `ai-healthcheck.yml` | Daily probe of both model chains — fails the run (→ email) if a model died |

`ai-healthcheck.yml` checks five things per task, and the second one is the reason it
exists: HTTP 200 · **`content` non-empty** · `finish_reason == "stop"` · no
`x-model-fallback` header · `x-model-used == x-model-primary`. A retired reasoning
model returns *200 with empty content*, so status-code-only monitoring would report
everything healthy while the app is broken. A present `x-model-fallback` means the
chain already fell to the reserve — working, but `MODEL_CHAINS` needs updating.

**The fifth check catches the silent swap.** On 429 the proxy advances down the chain
and answers normally, and `x-model-fallback` stays absent — that header only means
*retired*. So under load the text task quietly alternates between models, and the two
do not answer identically (the nutrition battery caught them disagreeing on units).
The proxy now sends `x-model-primary` with the chain head and the workflow warns when
`x-model-used` differs. It is a **warning, not a failure**: the fallback doing its job
during a spike is healthy, and failing there would cry wolf — a genuinely dead primary
still fails via `x-model-fallback`. Sending the primary from the proxy avoids the
workflow keeping its own copy of `MODEL_CHAINS`, which would drift on the first swap.

## Signup email runs through Brevo SMTP (resolved 2026-08-28)

Auth used to run on Supabase's **built-in email service**
(`noreply@mail.app.supabase.io`), which Supabase documents as test-only and caps
at ~2 signups/hour. Confirmed in the auth logs on 2026-08-24:

```
error_code: "over_email_send_rate_limit"   path: /signup   status: 429
```

Now on custom SMTP via **Brevo**, sending from `noreply@musclechamp.com.br` on
the owned domain. Email rate limit raised 2/h → 30/h in Auth → Rate Limits.
Verified end to end on 2026-08-28: `/signup` returns 200 and the confirmation
code arrives signed by the domain.

**The config lives in the dashboard, not the repo.** Host `smtp-relay.brevo.com`,
port 587, username = the Brevo account email, password = an SMTP key generated in
Brevo → SMTP & API. That key is a secret and never lands in the repository.
Supabase does not echo it back to the settings page after saving, so a blank
password field means *hidden*, not *lost* — do not re-save the form blank to
"check" whether it stuck.

### Three traps this hit, none of them obvious

**1. A pre-existing SPF that blocked every sender.** The domain carried
`v=spf1 -all`, which Cloudflare writes when a domain is marked as not sending
email. It authorizes *nobody*, so every Brevo send would have failed SPF even
with DKIM and DMARC perfect. Now `v=spf1 include:spf.brevo.com -all`. A domain
may have only **one** SPF record — a second one is a `permerror` — so this had to
be an edit of the existing record, not a new one.

**2. Two DMARC records.** `_dmarc` held both Cloudflare's `p=reject` and Brevo's
`p=none`. Per RFC 7489, a resolver that finds multiple `v=DMARC1` records ignores
all of them: the domain effectively had no DMARC while appearing to have two.
Deleted Cloudflare's, kept Brevo's `p=none` so failures get reported rather than
bounced while the setup settles.

**3. `525 "5.7.1 Unauthorized IP address"` reads like a credential error and is
not.** Brevo refuses SMTP connections from IPs outside its authorized list, and
Supabase sends from its own infrastructure. A wrong key returns
`535 Authentication failed` instead — so a 525 actually proves the credentials
worked. Fixed by lifting the IP restriction in Brevo → Security rather than
allowlisting an address, because Supabase's outbound IPs are neither fixed nor
published; pinning one would break signup again weeks later with no warning.

The two DKIM CNAMEs (`brevo1._domainkey`, `brevo2._domainkey`) must stay **DNS
only** in Cloudflare. Proxied — orange cloud — they resolve to Cloudflare instead
and Brevo cannot validate them.

### Still open

Brevo attaches a `List-Unsubscribe` header, so Gmail renders an "Unsubscribe"
button on the confirmation email. On a transactional auth message that is a
footgun: a user who clicks it lands on Brevo's blocklist and then silently stops
receiving confirmation codes, with nothing in the app to explain why.

**There is no setting for this.** Brevo states it does not strip the header from
anything sent over SMTP, because campaigns and transactional mail share that path
and it cannot tell them apart. The header-free alternative (`list-help`) is
Enterprise-only. Three ways out, in order of cost:

1. **Live with it and watch the blocklist** (Contacts → Blocklist). Tolerable
   today: the only transactional mail is the signup code, and nobody unsubscribes
   from a code they just asked for.
2. **Move to the [Send Email Hook](https://supabase.com/docs/guides/auth/auth-hooks/send-email-hook)**
   — Auth calls an Edge Function, which calls Brevo's *transactional API*, and the
   API does not add the header. Same pattern as `groq-proxy`, and it drags the
   email templates out of the dashboard into version control, which is the exact
   reason that function was committed in the first place. Deploy with
   `--no-verify-jwt`: Auth calls it server-side, with no user JWT.
3. Switch provider — costs redoing the DKIM records.

⚠️ **Password reset now exists** (`/forgot-password` → `/reset-password`), so this
is live, not hypothetical: someone who unsubscribed from an earlier confirmation
email silently cannot recover their account, and nothing in the app or the auth
logs explains why — the send simply never happens. Until option 2 ships, a
support report of "I never get the reset code" means **check Brevo's blocklist
first**.

Good news, verified twice by querying `auth.users`: a failed send rolls the
signup back cleanly — **no orphaned unconfirmed rows**, on both the 429 and the
500. Without that, a retry would hit "email já cadastrado" and lock the person
out permanently.

The client still distinguishes a server-side send failure from a user-caused
rate limit (`cad_limiteEmails` / `conf_limiteEmails`). The old copy said "Muitas
tentativas… espere alguns minutos", which blamed a user who did nothing — the
quota was spent by someone else's signup — and named the wrong window (it was
hourly).

## Security (hardened 2026-06)

**Never put secrets in the client.** The Groq key is in the Vault (see Groq API section). `lib/core/secrets.dart` is gitignored and holds only `supabaseUrl` + `supabaseAnonKey` (the anon key is public by design).

**RLS**: every table is owner-scoped via `auth.uid() = user_id` (or an `EXISTS` join to a parent row the user owns). `profiles` SELECT for the ranking is `TO authenticated USING (true)` — login required, and only `id`/`name`/`avatar_url`/`created_at` are exposed (no sensitive data). The `avatars` storage bucket lists only the owner's folder; public display uses public URLs.

**RPCs**: all the `SECURITY DEFINER` functions enforce `auth.uid()` internally — they do **not** trust the `p_user_id` argument (kept only for signature compatibility). `EXECUTE` is revoked from `PUBLIC`/`anon` on every user-data RPC; only `check_email_exists` stays anon-callable (used pre-login during signup). All functions have a locked `search_path`.

**Keepalive**: the Supabase free tier pauses after ~7 idle days. `.github/workflows/supabase-keepalive.yml` pings a light RPC daily (runs on GitHub's infra) to keep the project active. It only runs once pushed to GitHub.

**Known/accepted advisor warnings** (not real issues): the 12 `authenticated_security_definer` warnings — ranking/workout RPCs plus the four privacy RPCs (`export_my_data`, `delete_my_account`, `grant_consent`, `revoke_consent`); all must be `SECURITY DEFINER` and all enforce `auth.uid()` internally. Also `check_email_exists` being anon-callable (intentional), and leaked-password protection being off (Pro-only; compensated with Auth → Email password requirements: min length 8 + lowercase/uppercase/digits/symbols).

⚠️ **`delete_my_account()` must not touch `storage.objects`.** Postgres blocks direct
`DELETE` there (`storage.protect_delete`), and since the function is one transaction,
attempting it aborts the whole deletion and nothing is removed. The avatar is deleted
client-side via the Storage API in `PrivacyRepository.deleteMyAccount()` before the RPC.

## Banco de dados — `schema.sql` é a fonte da verdade

`supabase/migrations/` **nunca foi um registro completo**: on 2026-08-26 the
database had 27 applied migrations and the repo held 8 files, and the missing
ones included the fixes for the `date - bigint` cast in `get_streak` and the
`storage.objects` guard in `delete_my_account`. Rebuilding from that folder
would have reintroduced solved bugs.

Split from now on:

| Arquivo | O que é |
|---|---|
| `supabase/schema.sql` | como o banco **é** hoje — é o que reproduz produção |
| `supabase/gerar_schema.sql` | a consulta que **regenera** o arquivo acima |
| `supabase/migrations/` | registro do que **mudou**, daqui para frente |

### ⚠️ Ritual obrigatório ao mexer no esquema

Applying a migration is **three steps, not one**. Skipping steps 2–3 has already
happened twice in two days (`copiar_treino_de_outro_atleta` on 25/08 and
`perfil_publico_estado_de_amizade` on 26/08), each time leaving production ahead
of the repo:

1. Apply the migration.
2. **Save the same SQL** as a file in `supabase/migrations/`.
3. **Regenerate `schema.sql`** — run `gerar_schema.sql` in the SQL Editor and
   paste the single `script` column over everything below the header. Then fix
   the policy quoting: the generator emits `create policy '...'` and the name is
   an identifier, so it must become `create policy "..."`.

To check for drift at any time, compare the applied migration list against
`ls supabase/migrations/`. A name in one and not the other means the repo can no
longer rebuild the database.

Two things the generator gets right that are easy to miss:

- **Function grants.** Postgres gives `PUBLIC` EXECUTE on every new function,
  so a rebuild without the `revoke`/`grant` block would leave every RPC
  callable by `anon`. The block is generated from the live ACLs.
- **`create policy %I`, not `%L`.** A policy name is an identifier. The first
  version used `%L` and produced `create policy 'nome'` with single quotes,
  which would have failed on all 29 policies. The comment in `gerar_schema.sql`
  says so, because it is an easy mistake to repeat.

Verification is real, not assumed: the table + RLS + policy portion was applied
to a throwaway `_verif` schema inside a transaction (63 statements, no errors)
and rolled back. What is **not** verified is the whole file applying to an empty
database in one pass — that needs a spare database (Supabase branching would
do it).

## Supabase Tables

All tables have RLS enabled. Full list:

| Table | Description |
|-------|-------------|
| `profiles` | User profile data + avatar URL |
| `goals` | Daily calorie target, weight goal, body objective, weekly workout goal, `birth_date`, `daily_water_ml` |
| `workouts` | Workout sessions (legacy) |
| `exercises` | Individual exercises within a workout (legacy) |
| `workout_templates` | Reusable named workout templates |
| `template_exercises` | Exercises belonging to a template (name, sets, reps, weight_kg) |
| `workout_completions` | Log of completed template workouts (date, template_id, progression_count) |
| `diet_logs` | Individual meal entries (macros, calories) |
| `weight_logs` | Historical body weight entries |
| `bioimpedance_logs` | Body composition measurements |
| `water_logs` | Daily water intake entries (`amount_ml`, one row per tap) |
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

## Legal & Compliance (`lib/core/legal/`)

LGPD + GDPR implementation landed 2026-08-17. Migration:
`supabase/migrations/20260817_lgpd_gdpr_compliance.sql`.

**`LegalTexts`** (`legal_texts.dart`) is the single source of truth: document version,
minimum age, public URLs, disclaimers, and the list of signup consents. Bump
`documentVersion` whenever a legal text changes materially — it is written into
`user_consents.document_version`, and the privacy screen flags stale consents.

**`PrivacyRepository`** (`privacy_repository.dart`) wraps four RPCs:

| RPC | Right |
|-----|-------|
| `export_my_data()` | LGPD 18 II/V · GDPR 15 e 20 — full JSON dump |
| `delete_my_account()` | LGPD 18 VI · GDPR 17 — deletes table by table, avatar in Storage, then the `auth` user |
| `grant_consent()` / `revoke_consent()` | GDPR 7(3) — revoking is as easy as granting |

`user_consents` is **append-only** (no UPDATE/DELETE policy) — revoking writes a new
row. That trail is the accountability evidence (LGPD 6 X / GDPR 5(2)).

**Age gate**: 16 (`LegalTexts.minimumAge`), enforced in `register_page._goNext()` and
re-validated in `AuthRepository.register()`. Covers GDPR Art. 8 and LGPD Art. 14 with
one rule, avoiding a verifiable parental-consent flow.

**Disclaimers** are mandatory (Play health-apps policy + CFN): nutrition shows on every
AI result via `_NutritionPreview(isAi: true)`; workout shows in the AI generation sheet.

**Public legal pages** live in `web/` and ship with the web build:
`privacidade.html`, `termos.html`, `excluir-conta.html`. Play requires the deletion URL
to be reachable without login. Keep them in sync with `docs/juridico/`.

⚠️ Consent flags travel through `signUp()` metadata and are persisted by the
`handle_new_user` trigger. Changing the consent list means changing **both**
`LegalTexts.signupConsents` and that trigger.

## Pre-Play Store Checklist

From `docs/juridico/LEGAL.md` — pending before publishing:
- [ ] Change `applicationId` from `com.example.muscle_camp` (in `android/app/build.gradle.kts`)
- [ ] Generate release keystore (currently debug-signed)
- [x] Legal URLs on the owned domain — `musclechamp.com.br` is attached to the
      Pages project; `LegalTexts` points at `/privacidade`, `/termos`,
      `/excluir-conta` (no `.html` — Pages 308s the extension away, and the URL
      filed with Play should not depend on a redirect staying configured)
- [ ] Fill Play Console Data Safety form (declares health data + Groq photo sharing)
- [ ] Decide on EU distribution — GDPR Art. 27 requires an EU representative, or
      restrict the EEA in Play Console
- [x] Consent checkbox for health data in registration
- [x] "Excluir minha conta" in profile + public deletion URL
- [x] Privacy Policy link inside the app
- [x] Compliance migration applied — verified 2026-08-28 against the live
      database: the four privacy RPCs exist as `SECURITY DEFINER`, and
      `user_consents` has RLS with exactly the two append-only policies and
      real rows in it. This line used to say "not yet applied" and was simply
      wrong; a false "pending" here is worse than no line, because it invites
      re-applying a migration that already ran.
