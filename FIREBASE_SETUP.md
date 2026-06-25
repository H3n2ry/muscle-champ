# Configuração Firebase

## 1. Criar projeto Firebase
1. Acesse https://console.firebase.google.com
2. Clique em "Adicionar projeto" → nome: **muscle-champ**
3. Desative Google Analytics (opcional) → Criar projeto

## 2. Ativar Authentication
1. No menu: Authentication → Get started
2. Sign-in method → Email/Password → Ativar → Salvar

## 3. Ativar Firestore
1. No menu: Firestore Database → Criar banco de dados
2. Selecione **production mode** → Região: southamerica-east1 (São Paulo)
3. Regras de segurança — substitua por:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /workout_templates/{docId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
    match /workout_completions/{docId} {
      allow read, write: if request.auth != null;
    }
    match /diet_logs/{docId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
    match /points/{docId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
    match /friendships/{docId} {
      allow read, write: if request.auth != null;
    }
    match /weight_logs/{docId} {
      allow read, write: if request.auth != null;
    }
    match /bioimpedance_logs/{docId} {
      allow read, write: if request.auth != null;
    }
    match /workouts/{docId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
  }
}
```

## 4. Ativar Storage
1. No menu: Storage → Get started
2. Regras:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /avatars/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

## 5. Configurar o app (flutterfire CLI)
Execute dentro da pasta do projeto:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=muscle-champ
```

Isso vai **substituir** `lib/core/firebase/firebase_options.dart` com suas credenciais reais.

## 6. Instalar dependências
```bash
flutter pub get
```

## 7. Índices Firestore necessários
Alguns queries precisam de índices compostos. O Firestore mostrará um link para criar automaticamente quando a query falhar pela primeira vez no console do Firebase.

Principais índices necessários:
- `points`: `userId` ASC + `createdAt` ASC
- `points`: `userId` ASC + `reason` ASC + `createdAt` ASC
- `workout_completions`: `userId` ASC + `completedDate` ASC
- `diet_logs`: `userId` ASC + `date` ASC + `createdAt` ASC
- `friendships`: `friendId` ASC + `status` ASC + `createdAt` DESC
- `friendships`: `userId` ASC + `status` ASC
- `bioimpedance_logs`: `userId` ASC + `measuredAt` DESC
- `users`: `totalPoints` DESC (para ranking)

## 8. Diferenças em relação ao Supabase

| Funcionalidade         | Supabase                        | Firebase                              |
|------------------------|---------------------------------|---------------------------------------|
| Auth                   | `signInWithPassword`            | `signInWithEmailAndPassword`          |
| Confirmação de email   | OTP de 6 dígitos (obrigatório)  | Link de email (opcional, desativado)  |
| Banco de dados         | PostgreSQL + RPC functions      | Firestore (NoSQL, coleções/docs)      |
| Storage                | Buckets com upsert              | Firebase Storage com `putData`        |
| Realtime               | PostgresChanges channels        | Firestore `.snapshots()` streams      |
| Pontos/ranking         | Calculado via RPC no servidor   | Calculado client-side com transaction |

## 9. Schema Firestore (coleções)

### `users/{uid}`
```json
{
  "name": "João Silva",
  "nameLower": "joão silva",
  "email": "joao@exemplo.com",
  "avatarUrl": null,
  "createdAt": Timestamp,
  "goalType": "lose_weight",
  "heightCm": 175.0,
  "currentWeight": 80.0,
  "targetWeight": 70.0,
  "dailyCalories": 1800,
  "weeklyWorkoutGoal": 4,
  "totalPoints": 0
}
```

### `workout_templates/{docId}`
```json
{
  "userId": "uid",
  "name": "Peito e Tríceps",
  "createdAt": Timestamp,
  "exercises": [
    { "id": "...", "name": "Supino", "sets": 4, "reps": 10, "weightKg": 60.0, "orderIndex": 0 }
  ]
}
```

### `workout_completions/{templateId_uid_date}`
```json
{
  "userId": "uid",
  "templateId": "...",
  "completedDate": "2024-01-15",
  "progression": 2,
  "createdAt": Timestamp
}
```

### `diet_logs/{docId}`
```json
{
  "userId": "uid",
  "date": "2024-01-15",
  "mealName": "Frango grelhado",
  "calories": 300,
  "protein": 40.0,
  "carbs": 5.0,
  "fat": 8.0,
  "createdAt": Timestamp
}
```

### `points/{docId}`
```json
{
  "userId": "uid",
  "amount": 10,
  "reason": "workout_completed",
  "referenceId": "templateId",
  "createdAt": Timestamp
}
```

### `friendships/{docId}`
```json
{
  "userId": "uid-solicitante",
  "friendId": "uid-destinatario",
  "status": "pending",
  "createdAt": Timestamp
}
```
