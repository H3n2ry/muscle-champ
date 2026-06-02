# TEST_PLAN.md — Plano de Testes
## Muscle Champ · v1.0.0+1

---

## 1. Estado Atual

**Cobertura de testes:** 0% — nenhum arquivo `*_test.dart` encontrado no projeto.

Todos os testes realizados até agora foram manuais (dispositivo físico + browser).

---

## 2. Escopo

### Dentro do escopo
- Testes unitários de repositórios e lógica de negócio
- Testes de widget para componentes compartilhados
- Testes de integração dos fluxos principais
- Testes manuais de UI/UX

### Fora do escopo (por enquanto)
- Testes de performance (app é simples o suficiente)
- Testes de carga (free tier Supabase/Groq não suporta carga alta)
- Testes de acessibilidade automatizados
- Testes iOS (plataforma nunca buildada)

---

## 3. Tipos de Teste e Ferramentas

| Tipo | Ferramenta | Localização | Status |
|------|-----------|-------------|--------|
| Unitário | `flutter_test` (SDK) | `test/unit/` | 🔴 A criar |
| Widget | `flutter_test` + `flutter_driver` | `test/widget/` | 🔴 A criar |
| Integração | `integration_test` package | `integration_test/` | 🔴 A criar |
| Manual | Dispositivo físico + Chrome | — | ✅ Único ativo |

---

## 4. Ambientes de Teste

| Ambiente | Configuração | Status |
|---------|-------------|--------|
| Local — Android | Emulador AVD ou dispositivo físico via USB | ✅ Disponível |
| Local — Web | `flutter run -d chrome` | ✅ Disponível |
| CI/CD | GitHub Actions (a configurar) | 🔴 Inexistente |

---

## 5. Critérios de Aceite para Deploy

**Versão atual (sem testes automatizados):**

Antes de cada release, validar manualmente:

| Funcionalidade | Critério |
|--------------|---------|
| Login | Usuário consegue fazer login com credenciais válidas |
| Cadastro | Novo usuário consegue se cadastrar e recebe e-mail de confirmação |
| Dashboard | Pontos, rank e metas carregam sem erro |
| Gerar treino | Treino é gerado pela IA em menos de 10s |
| Registrar treino | Exercícios são salvos e aparecem no histórico |
| Foto de alimento | IA identifica alimento e retorna macros em menos de 30s |
| Texto de alimento | Cálculo de macros retorna em menos de 10s |
| Adicionar refeição | Refeição aparece no resumo diário com macros corretos |
| Ranking | Lista global e de amigos carregam |
| Adicionar amigo | Solicitação é enviada e aparece para o destinatário |
| Editar perfil | Nome, peso e avatar são atualizados |
| Logout | Usuário é deslogado e redirecionado para /login |

---

## 6. Plano de Implementação de Testes

### Fase 1 — Unitários (prioridade alta)

```bash
# Criar estrutura
mkdir -p test/unit/repositories
mkdir -p test/unit/services
```

Prioridade de testes a criar:
1. `test/unit/services/groq_service_test.dart` — mock HTTP, testar `_optimizeImage`, parsing JSON
2. `test/unit/repositories/diet_repository_test.dart` — mock Supabase, testar `getTodaySummary`
3. `test/unit/repositories/workout_repository_test.dart` — testar criação com `previous_weight`

### Fase 2 — Widgets (prioridade média)

1. `test/widget/mk_button_test.dart`
2. `test/widget/mk_card_test.dart`
3. `test/widget/diet_page_test.dart` — testar estados de loading/error/data

### Fase 3 — Integração (prioridade baixa)

1. Fluxo completo: login → dashboard → gerar treino → salvar
2. Fluxo de dieta: foto → macros → salvar refeição

---

## 7. Comandos

```bash
# Rodar todos os testes
flutter test

# Rodar um arquivo específico
flutter test test/unit/services/groq_service_test.dart

# Com cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
# Abrir coverage/html/index.html no browser

# Integração (requer dispositivo/emulador)
flutter test integration_test/app_test.dart -d <device-id>
```
