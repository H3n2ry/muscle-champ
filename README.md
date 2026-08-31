# Muscle Champ

App fitness gamificado para Android e Web. Registre treinos, acompanhe sua dieta com IA e dispute rankings com amigos.

**Live:** https://musclechamp.com.br

## Funcionalidades

- **Treinos com IA** — gere treinos personalizados por grupo muscular via Groq LLM
- **Dieta inteligente** — adicione refeições por texto ou foto; a IA calcula macros automaticamente
- **Gamificação** — ganhe pontos por completar treinos e bater metas de dieta
- **Rankings** — placar global e entre amigos
- **Sistema de amizades** — busque usuários, envie/aceite solicitações

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Mobile/Web | Flutter 3.x + Dart 3.x |
| State management | Riverpod 2.x |
| Navegação | GoRouter |
| Backend | Supabase (Auth + PostgreSQL + Storage) |
| IA | Groq API — LLaMA 3.3 70B (texto) + Qwen 3.6 27B (visão) |
| Hospedagem web | Cloudflare Pages → `musclechamp.com.br` |

## Setup

### Pré-requisitos

- Flutter 3.44+
- Android Studio com SDK 34+ e Command-line Tools instalados
- Node.js (para o Wrangler, CLI do Cloudflare Pages)

### Configuração local

1. Clone o repositório e instale dependências:
   ```bash
   flutter pub get
   ```

2. O projeto já possui `local.properties` configurado para `C:\Users\Jean\AppData\Local\Android\Sdk`. Se estiver em outra máquina, atualize:
   ```
   sdk.dir=SEU_CAMINHO\Android\Sdk
   flutter.sdk=SEU_CAMINHO\flutter
   ```

3. As chaves de API estão em:
   - `lib/core/supabase/supabase_config.dart`
   - `lib/core/groq/groq_config.dart`

### Build Android

```powershell
$env:ANDROID_HOME = "C:\Users\Jean\AppData\Local\Android\Sdk"
$env:JAVA_HOME    = "C:\Program Files\Android\Android Studio\jbr"
$env:PATH         = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"

flutter build apk --release
```

O APK é gerado em `build/app/outputs/flutter-apk/app-release.apk`.

### Build Web + Deploy

```bash
flutter build web --release
npx wrangler pages deploy build/web --project-name=muscle-champ --branch=main
```

O deploy vai para `musclechamp.com.br` (alias: `muscle-champ.pages.dev`).
Na primeira vez, `npx wrangler login` abre um OAuth no navegador.

## Estrutura do projeto

```
lib/
├── core/          # Configurações, tema, router, serviços (Groq, Supabase)
├── features/      # auth | dashboard | workout | diet | profile | ranking | notifications
└── shared/        # Widgets reutilizáveis (MkButton, MkCard, MkTextField)
```

Cada feature segue a separação `data/` (models + repositories) e `presentation/` (providers + pages).
