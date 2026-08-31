# DEPENDENCIES.md — Mapa de Dependências
## Muscle Champ · v1.0.0+1

---

## 1. Dependências de Produção

| Pacote | Versão | Função | Criticidade |
|--------|--------|--------|-------------|
| `supabase_flutter` | ^2.5.0 | Auth, banco de dados, storage — backbone do backend | 🔴 Crítica |
| `flutter_riverpod` | ^2.5.1 | State management em toda a app | 🔴 Crítica |
| `go_router` | ^13.2.1 | Navegação declarativa + guard de autenticação | 🔴 Crítica |
| `http` | ^1.2.1 | Chamadas HTTP para Groq API | 🔴 Crítica |
| `image` | ^4.8.0 | Resize e compressão de imagens antes de enviar à Groq | 🔴 Crítica |
| `image_picker` | ^1.1.2 | Câmera e galeria para foto de alimentos | 🔴 Crítica |
| `google_fonts` | ^6.2.1 | Tipografia do design system Obsidian Kinetic | 🟡 Alta |
| `fl_chart` | ^0.67.0 | Gráficos de pontos/progresso no dashboard | 🟡 Alta |
| `cached_network_image` | ^3.3.1 | Avatares do Supabase Storage com cache | 🟡 Alta |
| `shared_preferences` | ^2.3.2 | Persistência local: plano de dieta IA + estado do tutorial de onboarding (chaves por userId) | 🟡 Alta |
| `intl` | ^0.19.0 | Formatação de datas e números em pt-BR | 🟢 Média |
| `equatable` | ^2.0.5 | Comparação de modelos sem boilerplate | 🟢 Baixa |
| `shimmer` | ^3.0.0 | Skeleton loading nas listas | 🟢 Baixa |

---

## 2. Dependências de Desenvolvimento

| Pacote | Versão | Função |
|--------|--------|--------|
| `flutter_test` | SDK | Framework de testes (zero uso atual) |
| `flutter_lints` | ^3.0.0 | Análise estática — regras de lint |
| `flutter_launcher_icons` | ^0.13.1 | Geração de ícones de app a partir de `assets/images/logo.png` |

---

## 3. Serviços Externos

| Serviço | Plano | Limites relevantes | Risco |
|---------|-------|-------------------|-------|
| **Supabase** | Free | 500MB DB, 1GB Storage, 50.000 MAU/mês, 5GB transferência | Sem SLA; projeto pausado após 1 semana inativo |
| **Groq API** | Free | ~500k tokens/dia estimado | Sem SLA; rate limit sem aviso prévio |
| **Cloudflare Pages** | Free | 25 MiB por arquivo, 20.000 arquivos, 500 builds/mês | Sem SLA comercial. Substituiu o Vercel em 26/08/2026: o plano Hobby proíbe uso comercial, e anunciar a assinatura já violaria a política |
| **Brevo (SMTP)** | Free | 300 e-mails/dia | Entrega dos e-mails de confirmação de cadastro depende dele — se cair ou estourar a cota, ninguém consegue criar conta. IP compartilhado: reputação afetada por outros remetentes |

**Brevo** entrou em 28/08/2026 como SMTP customizado do Supabase Auth, substituindo
o serviço interno de testes que limitava o cadastro a ~2 contas/hora. Envia de
`noreply@musclechamp.com.br` (domínio autenticado por DKIM + DMARC). As credenciais
ficam **só no painel do Supabase** — nunca no repositório. Ver `CLAUDE.md`,
seção "Signup email runs through Brevo SMTP", para as armadilhas de DNS envolvidas.

O limite prático de cadastros é o menor entre a cota do Brevo (300/dia) e o rate
limit do Supabase Auth (30/hora) — não mais o teto de ~2/hora do serviço interno.

---

## 4. Análise de Riscos por Dependência

### 🔴 Riscos Altos

| Pacote | Risco | Mitigação |
|--------|-------|-----------|
| `supabase_flutter` | Mudança de API pode quebrar auth/DB | Pin versão exata em produção; testar upgrades em branch |
| `go_router` | Versões major frequentes com breaking changes | Não atualizar sem testar navegação completa |

### 🟡 Riscos Médios

| Pacote | Risco | Mitigação |
|--------|-------|-----------|
| `image` | API instável entre versões major | Encapsulado em `_optimizeImage()` — fácil de atualizar |
| `fl_chart` | API de charts muda frequentemente | Encapsulado em widgets do dashboard |
| `intl` | Versão deve ser compatível com o SDK Flutter | Atualizar junto com upgrade do Flutter |

### 🟢 Baixo Risco

`equatable`, `shimmer`, `shared_preferences` — APIs estáveis, baixa frequência de breaking changes.

---

## 5. Licenças das Dependências Principais

| Pacote | Licença |
|--------|---------|
| `supabase_flutter` | Apache 2.0 |
| `flutter_riverpod` | MIT |
| `go_router` | BSD 3-Clause |
| `http` | BSD 3-Clause |
| `image` | Apache 2.0 |
| `image_picker` | BSD 3-Clause |
| `google_fonts` | Apache 2.0 |
| `fl_chart` | MIT |
| `cached_network_image` | MIT |
| `intl` | BSD 3-Clause |
| `equatable` | MIT |
| `shimmer` | MIT |
| `shared_preferences` | BSD 3-Clause |

Todas as licenças são permissivas (MIT, BSD, Apache 2.0) — compatíveis com distribuição comercial na Play Store.

---

## 6. Como Verificar Vulnerabilidades

```bash
# Verificar pacotes desatualizados
flutter pub outdated

# Não há equivalente ao npm audit no ecossistema Dart/Flutter
# Verificar manualmente no pub.dev se há CVEs para cada pacote
# Referência: https://pub.dev/security
```

---

## 7. Comandos de Atualização

```bash
# Atualizar para versões compatíveis com as constraints
flutter pub upgrade

# Ver o que seria atualizado sem aplicar
flutter pub upgrade --dry-run

# Atualizar para versões mais recentes (pode quebrar)
# Editar pubspec.yaml manualmente e rodar:
flutter pub get
flutter analyze
flutter test
```
