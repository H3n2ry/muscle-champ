# ARCHITECTURE.md — Arquitetura Detalhada
## Muscle Champ · v1.0.0+1

---

## 1. Padrão Arquitetural

**Feature-First + Repository Pattern + Riverpod**

O projeto não adota Clean Architecture estritamente (sem entidades de domínio separadas), mas implementa separação clara de responsabilidades por camada dentro de cada feature.

```
lib/
├── core/                    ← Infraestrutura compartilhada
│   ├── groq/                  (GroqService, GroqConfig)
│   ├── router/                (GoRouter com guard de auth)
│   ├── supabase/              (SupabaseConfig)
│   ├── theme/                 (AppColors, AppTypography, AppTheme)
│   └── network/               (DohHttpOverrides)
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/user_model.dart
│   │   │   └── repositories/auth_repository.dart
│   │   └── presentation/
│   │       ├── providers/auth_provider.dart
│   │       └── pages/ (login, register, confirm_email)
│   │
│   ├── dashboard/
│   │   ├── data/
│   │   │   ├── models/dashboard_model.dart
│   │   │   └── repositories/dashboard_repository.dart
│   │   └── presentation/
│   │       ├── providers/dashboard_provider.dart
│   │       └── pages/dashboard_page.dart
│   │
│   ├── workout/
│   │   ├── data/
│   │   │   ├── models/ (workout_model, workout_template_model)
│   │   │   ├── repositories/ (workout_repository, workout_template_repository)
│   │   │   └── datasources/exercise_library.dart   ← dados locais estáticos
│   │   └── presentation/
│   │       ├── providers/ (workout_provider, workout_template_provider)
│   │       └── pages/workout_page.dart
│   │
│   ├── diet/
│   │   ├── data/
│   │   │   ├── models/diet_model.dart
│   │   │   ├── repositories/diet_repository.dart
│   │   │   └── datasources/food_database.dart      ← base de alimentos local
│   │   └── presentation/
│   │       ├── providers/diet_provider.dart
│   │       └── pages/diet_page.dart                ← maior arquivo do projeto
│   │
│   ├── profile/
│   │   ├── data/
│   │   │   ├── models/profile_model.dart
│   │   │   └── repositories/profile_repository.dart
│   │   └── presentation/
│   │       ├── providers/profile_provider.dart
│   │       └── pages/ (profile_page, edit_profile_page)
│   │
│   ├── ranking/
│   │   ├── data/
│   │   │   ├── models/ranking_model.dart
│   │   │   └── repositories/ranking_repository.dart
│   │   └── presentation/
│   │       ├── providers/ranking_provider.dart
│   │       └── pages/ranking_page.dart
│   │
│   └── notifications/
│       └── presentation/
│           ├── providers/notifications_provider.dart
│           └── pages/notifications_page.dart
│
└── shared/
    └── widgets/
        ├── bottom_nav_bar.dart    (MainScaffold + tutorial trigger)
        ├── tutorial_overlay.dart  (TutorialOverlay + TutorialNotifier + tutorialProvider)
        ├── mk_button.dart
        ├── mk_card.dart
        └── mk_text_field.dart
```

---

## 2. Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│  Flutter App                                                    │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Presentation Layer                                      │  │
│  │                                                          │  │
│  │  Pages (ConsumerWidget / ConsumerStatefulWidget)         │  │
│  │    DietPage  WorkoutPage  DashboardPage  RankingPage     │  │
│  │        ↕           ↕           ↕             ↕          │  │
│  │  Providers (Riverpod AsyncNotifier / FutureProvider)     │  │
│  │    DietController  WorkoutController  dashboardProvider  │  │
│  └──────────────────┬───────────────────────────────────────┘  │
│                     ↓                                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Data Layer                                              │  │
│  │                                                          │  │
│  │  Repositories                    GroqService             │  │
│  │    DietRepository                  (static methods)      │  │
│  │    WorkoutRepository                   ↓                 │  │
│  │    DashboardRepository           http.post()             │  │
│  │    ProfileRepository                                     │  │
│  │    RankingRepository                                     │  │
│  │         ↓                                                │  │
│  │  Supabase.instance.client                                │  │
│  └──────────────────┬───────────────────────────────────────┘  │
└─────────────────────┼───────────────────────────────────────────┘
                      │
         ┌────────────┴────────────┐
         ↓                        ↓
  ┌──────────────┐       ┌────────────────┐
  │  Supabase    │       │   Groq API     │
  │  Auth + DB   │       │  LLM + Vision  │
  │  + Storage   │       └────────────────┘
  └──────────────┘
```

---

## 3. Padrões de State Management

### FutureProvider.autoDispose (leitura)
Usado quando a página só precisa carregar dados uma vez e não os mutam:
```dart
final dashboardProvider = FutureProvider.autoDispose<DashboardModel>((ref) {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});
```

### AsyncNotifierProvider.autoDispose (leitura + escrita)
Usado quando a página precisa criar/deletar dados e atualizar a UI:
```dart
class DietController extends AutoDisposeAsyncNotifier<DietSummaryModel?> {
  @override Future<DietSummaryModel?> build() => ...fetch...

  Future<void> addMeal(data) async {
    await repo.addMeal(data);
    state = AsyncData(await repo.getTodaySummary()); // otimista: fetch após write
  }
}
```

### StateNotifierProvider.autoDispose (estado mutable local)
Usado para estado local persistido em SharedPreferences, sem backend:
```dart
// AI diet plan — persiste no SharedPreferences com chave por usuário
final aiDietPlanProvider = StateNotifierProvider.autoDispose<AiDietPlanNotifier, AiDietPlanState>(...)

// Tutorial onboarding — detecta novo usuário via SharedPreferences
final tutorialProvider = StateNotifierProvider.autoDispose<TutorialNotifier, TutorialState>(...)
```

### Provider (repositórios)
```dart
final dietRepositoryProvider = Provider<DietRepository>((_) => DietRepository());
```

---

## 4. Roteamento

GoRouter com `ShellRoute` para a navegação por abas:

```
/login             → LoginPage (sem shell)
/register          → RegisterPage (sem shell)
/confirm-email     → ConfirmEmailPage (sem shell)
/edit-profile      → EditProfilePage (sem shell)
/notifications     → NotificationsPage (sem shell)

ShellRoute → MainScaffold (BottomNavBar com 5 abas)
  /dashboard       → DashboardPage
  /workout         → WorkoutPage
  /diet            → DietPage
  /ranking         → RankingPage
  /profile         → ProfilePage
```

**Guard de auth** síncrono em `GoRouter.redirect`:
- Sem sessão + rota não-auth → `/login`
- Com sessão + rota auth → `/dashboard`

---

## 5. Design System — Obsidian Kinetic

```
Background:   #121413   (quase preto esverdeado)
Surface:      #1B1C1C → #343535 (escala de containers)
Primary:      #7EFC00  (lime green — ações, sucessos, destaque)
Secondary:    #C6C6C6  (texto secundário)
Cyan:         #0EA5E9  (modo foto na DietPage)
Warning:      #FFD700
Error:        #FFB4AB  (container: #93000A)
```

Todos os widgets do projeto usam `AppColors.*` — sem dependência de `Theme.of(context).colorScheme` exceto no `AppTheme.dark()`.

---

## 6. Separação de Responsabilidades

### ✅ Bem feito
- Feature isolation: cada feature é completamente independente
- GroqService encapsula toda a lógica de IA (método estático, sem vazamento para UI)
- `_optimizeImage()` isolada e testável separadamente
- Repositórios são a única camada que fala com Supabase

### ⚠️ Acoplamentos a monitorar
- `Supabase.instance.client` direto nos repositórios dificulta mocking
- `diet_page.dart` concentra muita lógica (poderia extrair controllers de UI)
- ~~`GroqConfig` expõe chaves hardcoded~~ — resolvido: a chave Groq vive no Supabase Vault e é usada só pela Edge Function `groq-proxy`; `GroqConfig`/`GroqService` apontam para o proxy, não para a Groq direta

---

## 7. Pontos de Extensão

| Feature nova | Onde adicionar |
|-------------|---------------|
| Nova aba principal | Novo ShellRoute em `app_router.dart` + ícone em `bottom_nav_bar.dart` |
| Novo endpoint Groq | Novo método estático em `groq_service.dart` |
| Novo modelo de dados | Nova pasta `features/<x>/data/models/` |
| Novo componente UI | `shared/widgets/mk_<nome>.dart` |
| Nova RPC Supabase | Novo método no repositório correspondente |
| Notificações push | `notifications_provider.dart` + integração FCM |

---

## 8. Limitações Conhecidas

| Limitação | Impacto |
|-----------|---------|
| Sem abstração de data source | Testes unitários de repositório requerem Supabase real ou mocking manual |
| Sem isolamento de GroqService | GroqService chama `http` diretamente — sem injeção de dependência |
| Orientação fixada em portrait | `SystemChrome.setPreferredOrientations([portraitUp, portraitDown])` em `main.dart` |
| Web: sem PWA configurado | `flutter build web` não gera service worker por padrão |
| iOS: nunca buildado | Pode haver problemas com permissões de câmera/galeria no iOS |
| `doh_http_overrides.dart` com erros de análise | Arquivo com API obsoleta — flutter analyze retorna 5 erros neste arquivo, ignorados via `build.gradle.kts` (`abortOnError = false`) |
