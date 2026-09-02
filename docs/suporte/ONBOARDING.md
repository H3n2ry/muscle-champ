# ONBOARDING.md — Guia para Novos Desenvolvedores
## Muscle Champ

---

## 1. O que ler primeiro

Nesta ordem:
1. Este arquivo (ONBOARDING.md)
2. [`../../CLAUDE.md`](../../CLAUDE.md) — comandos de build e convenções
3. [`../../MEMORY.md`](../../MEMORY.md) — estado atual do projeto e decisões tomadas
4. [`../tecnico/ARCHITECTURE.md`](../tecnico/ARCHITECTURE.md) — arquitetura detalhada
5. [`../tecnico/API.md`](../tecnico/API.md) — contratos com Supabase e Groq

---

## 2. Pré-requisitos

| Ferramenta | Versão | Onde instalar |
|-----------|--------|--------------|
| Flutter SDK | 3.44+ | https://docs.flutter.dev/get-started/install/windows |
| Android Studio | Mais recente | https://developer.android.com/studio |
| Android SDK | API 34 | Android Studio → SDK Manager |
| Android Command-line Tools | Mais recente | SDK Manager → SDK Tools → Android SDK Command-line Tools |
| Node.js | 20+ | Para o Wrangler (CLI do Cloudflare Pages), necessário no deploy web |
| Git | Qualquer | — |

---

## 3. Configuração do Ambiente (Windows)

```powershell
# 1. Verificar instalação do Flutter
flutter doctor

# 2. Se aparecer "Android toolchain" com erros:
$env:ANDROID_HOME = "C:\Users\Jean\AppData\Local\Android\Sdk"
$env:JAVA_HOME    = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH         = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"

# 3. Aceitar licenças Android (se necessário)
# Ou criar manualmente os arquivos em %ANDROID_HOME%\licenses\
# Ver docs/suporte/TROUBLESHOOTING.md para instruções detalhadas

# 4. Ir para a pasta do projeto
cd "C:\Users\Jean\Desktop\muscle camp\project\app"

# 5. Instalar dependências
flutter pub get

# 6. Verificar que tudo está ok
flutter analyze
```

---

## 4. Rodando o Projeto

```powershell
# No emulador ou dispositivo físico conectado
flutter run

# Forçar web
flutter run -d chrome

# Com hot reload ativo: pressionar 'r' no terminal
# Com hot restart: pressionar 'R'
```

---

## 5. Estrutura de Pastas — O Essencial

```
lib/
├── main.dart              ← Entry point; não editar sem necessidade
├── app.dart               ← MaterialApp.router; não editar sem necessidade
├── core/
│   ├── groq/
│   │   ├── groq_config.dart   ← CHAVES DE API AQUI — não commitar com chaves reais
│   │   └── groq_service.dart  ← Toda lógica de IA; editar para mudar comportamento da IA
│   ├── router/app_router.dart ← Adicionar rotas aqui
│   └── theme/app_colors.dart  ← Paleta de cores — não mudar sem aprovação
└── features/
    └── <feature>/
        ├── data/repositories/<feature>_repository.dart  ← Lógica de banco
        ├── presentation/providers/<feature>_provider.dart ← Estado
        └── presentation/pages/<feature>_page.dart         ← UI
```

---

## 6. Primeiras Tarefas Sugeridas

Para se familiarizar com a base de código, tente em ordem:

1. **Fácil:** Mudar um texto na `DietPage` (ex: label de um botão) — entender como widgets funcionam
2. **Fácil:** Adicionar um novo campo de bioimpedância no perfil (ex: metabolismo basal já existe — adicionar "nível de hidratação")
3. **Médio:** Adicionar um filtro de grupo muscular no histórico de treinos
4. **Médio:** Criar o primeiro teste unitário em `test/unit/groq_service_test.dart`
5. **Difícil:** Implementar botão "Excluir conta" que deleta todos os dados do usuário

---

## 7. Como Fazer Mudanças

### Adicionar uma nova feature

1. Criar pasta `lib/features/<nova_feature>/`
2. Criar `data/models/`, `data/repositories/`, `presentation/providers/`, `presentation/pages/`
3. Adicionar rota em `core/router/app_router.dart`
4. Se for uma aba nova: adicionar em `shared/widgets/bottom_nav_bar.dart`

### Modificar o comportamento da IA

Editar `lib/core/groq/groq_service.dart`:
- Prompt do sistema: texto entre aspas triplas no `'content'` do sistema
- Modelo: `GroqConfig.textModel` ou `GroqConfig.visionModel`
- **Nunca** reduzir `max_tokens` abaixo de 300 em `analyzeFoodPhoto`
- **Nunca** reduzir `_maxImagePx` abaixo de 768
- Para o plano de dieta (`generateDietPlan`): temperatura 0.3 é intencional — garante que a IA respeite as metas calóricas

### Modificar o tutorial de onboarding

Editar `lib/shared/widgets/tutorial_overlay.dart`:
- Passos definidos em `_kSteps` (lista const de `_TStep` records)
- Cada passo tem: `route` (para qual aba navegar), `target` (onde iluminar), `title`, `body`
- `SpotTarget.nav0-4`: ilumina ícone da nav bar; `SpotTarget.pageTop/Middle/Bottom`: ilumina área da tela
- Total de passos em `TutorialNotifier.totalSteps`
- Seções: `_sectionOf(step)` mapeia step → seção (0-4)
- Para resetar o tutorial de um usuário: deletar a chave `tutorial_seen_{userId}` do SharedPreferences

### Alterar o banco de dados

1. Fazer a migração diretamente no Supabase Dashboard → SQL Editor
2. Atualizar o model correspondente em `data/models/`
3. Atualizar o repositório em `data/repositories/`
4. Atualizar `docs/tecnico/API.md` com o novo schema

---

## 8. Armadilhas Comuns

| Armadilha | O que acontece | Como evitar |
|-----------|---------------|-------------|
| Fazer build sem definir `ANDROID_HOME` | `flutter build apk` falha com erro de SDK | Sempre definir as 3 variáveis de ambiente antes de builds Android |
| Editar `local.properties` com caminhos errados | Build falha com "SDK not found" | Verificar se o caminho existe antes de salvar |
| Usar `Colors.green` em vez de `AppColors.primary` | UI inconsistente com o design system | Sempre usar `AppColors.*` |
| Esquecer `autoDispose` em novos providers | Memory leak em navegações | Usar `.autoDispose` em todos os novos providers |
| Usar a mesma chave SharedPreferences para todos os usuários | Plano de dieta e tutorial de um usuário vaza para outro | Sempre incluir `_${userId}` na chave — ver padrão em `tutorial_overlay.dart` e `diet_provider.dart` |
| Commitar `groq_config.dart` com chave real | Chave exposta no repositório | Adicionar ao `.gitignore` ou usar `--dart-define` |
| `flutter run` sem executar `flutter pub get` após mudar `pubspec.yaml` | Erro de dependência não resolvida | Sempre `pub get` após mudar dependências |

---

## 9. Glossário

| Termo | Significado |
|-------|-------------|
| "streak" | Dias consecutivos com pelo menos 1 treino concluído |
| "meta de dieta" | Calorias diárias dentro de ±10% do objetivo |
| "porção" | Dica opcional passada à IA (Pequena/Média/Grande/Prato) |
| "Obsidian Kinetic" | Nome do design system do app |
| "gsk_" | Prefixo de chaves da API Groq |
| "autoDispose" | Provider que se destrói quando não há mais listeners |
| "RPC" | Remote Procedure Call — função PostgreSQL chamada via `supabase.rpc()` |

---

## 10. Canais de Comunicação

- **Dúvidas técnicas:** [email do desenvolvedor principal]
- **Bugs:** Abrir issue usando o template em `docs/qa/BUG_REPORT_TEMPLATE.md`
- **Sugestões:** [canal preferido da equipe]
