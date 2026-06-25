# Setup Firebase — Muscle Camp

O app migrou de Supabase para Firebase. A IA (Groq) agora passa por uma
Cloud Function (`groqProxy`) que mantém a chave fora do cliente.

Estes passos só precisam ser feitos **uma vez**. Tudo que depende de você
(criar projeto, plano de cobrança, login) está marcado com 👤.

## Pré-requisitos (uma vez por máquina)

```bash
# Node já está instalado (v24). Instale as CLIs:
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

## 1. 👤 Criar o projeto no Firebase

1. Acesse https://console.firebase.google.com → **Adicionar projeto**
2. Nome sugerido: `muscle-camp` (o ID gerado pode ser `muscle-camp-xxxxx`)
3. Pode desativar o Google Analytics (opcional)

## 2. 👤 Ativar os serviços

No console do projeto:
- **Authentication** → Sign-in method → ative **E-mail/senha**
- **Firestore Database** → Criar banco → modo produção → região `southamerica-east1`
- **Storage** → Começar → região `southamerica-east1`

## 3. 👤 Ativar o plano Blaze (necessário p/ Cloud Functions)

- Engrenagem ⚙️ → **Uso e faturamento** → **Modifique o plano** → **Blaze**
- Tem cota gratuita generosa; só cobra acima dela. Pode definir um alerta de orçamento.

## 4. Conectar o app ao projeto

```bash
cd "C:\Users\Jean\Desktop\muscle camp\project\app"
firebase login                       # 👤 login na sua conta Google
flutterfire configure                # escolha o projeto criado → preenche firebase_options.dart
```

Isso substitui os `SUBSTITUA` em `lib/core/firebase/firebase_options.dart`.

## 5. Definir a chave Groq no Secret Manager

```bash
firebase functions:secrets:set GROQ_KEY
# cole a chave gsk_... quando pedir (a chave NÃO fica em nenhum arquivo)
```

## 6. Instalar deps e fazer deploy da função

```bash
cd functions && npm install && cd ..
firebase deploy --only functions
```

A função sobe em `southamerica-east1` (mesma região de `GroqConfig.region`).

## 7. Rodar o app

```bash
flutter run
```

A IA (treino, dieta por texto e foto) chama `groqProxy` automaticamente —
o SDK descobre a URL pelo `firebase_options.dart`, sem hardcode.

---

### Como funciona a segurança da chave
- A chave Groq vive no **Secret Manager** do Firebase.
- Só a Cloud Function `groqProxy` a lê (server-side).
- A função exige usuário autenticado (`request.auth`) e só aceita os 2 modelos do app.
- O cliente nunca vê a chave — nem no bundle web, nem no APK.

### Rotacionar a chave depois
```bash
firebase functions:secrets:set GROQ_KEY   # cola a nova
firebase deploy --only functions          # republica usando a nova versão
```
