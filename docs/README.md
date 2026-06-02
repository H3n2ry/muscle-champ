# 📚 Documentação — Muscle Champ

> Documentação gerada por engenharia reversa com metodologia SDD (IEEE 1016).
> Revisar e atualizar conforme o projeto evolui.

**Gerado em:** 2026-05-28
**Versão analisada:** 1.0.0+1
**Status:** Rascunho — aguarda revisão

---

## 🗂️ Estrutura da Documentação

### 🔧 Técnico
| Arquivo | Descrição |
|---------|-----------|
| [SDD.md](./tecnico/SDD.md) | Software Design Document completo (IEEE 1016) — 5 visões |
| [ARCHITECTURE.md](./tecnico/ARCHITECTURE.md) | Arquitetura feature-first, diagramas, padrões Riverpod |
| [API.md](./tecnico/API.md) | Tabelas Supabase, RPCs, contratos Groq com exemplos |
| [DEPENDENCIES.md](./tecnico/DEPENDENCIES.md) | Dependências, versões, riscos e licenças |
| [MEMORY.md](./tecnico/MEMORY.md) | → Aponta para `../MEMORY.md` (raiz do projeto) |

### ⚖️ Jurídico
| Arquivo | Descrição |
|---------|-----------|
| [LEGAL.md](./juridico/LEGAL.md) | LGPD, checklist pré-publicação Play Store, transferência internacional |
| [PRIVACY.md](./juridico/PRIVACY.md) | Rascunho de Política de Privacidade para hospedar |
| [LICENSES.md](./juridico/LICENSES.md) | Licenças MIT/BSD/Apache das dependências |

### 🔒 Segurança
| Arquivo | Descrição |
|---------|-----------|
| [SECURITY.md](./seguranca/SECURITY.md) | Como reportar vulnerabilidades, mecanismos implementados |
| [THREAT_MODEL.md](./seguranca/THREAT_MODEL.md) | Análise STRIDE — 6 categorias de ameaças priorizadas |
| [CHECKLIST_SEGURANCA.md](./seguranca/CHECKLIST_SEGURANCA.md) | Checklist obrigatório antes de cada deploy |

### 🧪 QA
| Arquivo | Descrição |
|---------|-----------|
| [TEST_PLAN.md](./qa/TEST_PLAN.md) | Plano de testes (cobertura atual: 0%) + roadmap |
| [TEST_CASES.md](./qa/TEST_CASES.md) | 30+ casos de teste por funcionalidade |
| [BUG_REPORT_TEMPLATE.md](./qa/BUG_REPORT_TEMPLATE.md) | Template de bug report + bugs históricos resolvidos |

### 🎨 UX
| Arquivo | Descrição |
|---------|-----------|
| [UX_GUIDELINES.md](./ux/UX_GUIDELINES.md) | Design system Obsidian Kinetic — cores, tipografia, componentes |
| [USER_FLOWS.md](./ux/USER_FLOWS.md) | 7 fluxos mapeados em ASCII + pontos de fricção |
| [ACCESSIBILITY.md](./ux/ACCESSIBILITY.md) | Nível WCAG atual, correções necessárias, checklist |

### 🎧 Suporte
| Arquivo | Descrição |
|---------|-----------|
| [FAQ.md](./suporte/FAQ.md) | 15 perguntas frequentes de usuários |
| [TROUBLESHOOTING.md](./suporte/TROUBLESHOOTING.md) | Problemas comuns de usuários + troubleshooting de devs |
| [ONBOARDING.md](./suporte/ONBOARDING.md) | Setup do ambiente, estrutura, armadilhas, glossário |

### 📣 Marketing
| Arquivo | Descrição |
|---------|-----------|
| [MARKETING.md](./marketing/MARKETING.md) | Elevator pitches, posts prontos, ASO Play Store |
| [BRAND_VOICE.md](./marketing/BRAND_VOICE.md) | Tom de voz, vocabulário, exemplos alinhados/desalinhados |
| [RELEASE_NOTES.md](./marketing/RELEASE_NOTES.md) | v1.0.0 + template + backlog de features futuras |

---

## 📊 Resumo da Análise

| Métrica | Valor |
|---------|-------|
| Arquivos Dart analisados | 46 |
| Features mapeadas | 7 (auth, dashboard, workout, diet, profile, ranking, notifications) |
| Tabelas Supabase | 10 |
| RPCs Supabase | 7 |
| Dependências de produção | 13 |
| Cobertura de testes | 0% (zero testes automatizados) |
| Riscos de segurança identificados | 6 (Alta: 2, Média: 3, Baixa: 1) |
| Casos de teste documentados | 35+ |
| Plataformas suportadas | Android ✅ · Web ✅ · iOS ❌ (nunca buildado) |

---

## ⚠️ Sobre esta Documentação

Esta documentação foi gerada automaticamente por análise estática do código-fonte usando engenharia reversa. Algumas seções podem conter imprecisões onde a intenção original do desenvolvedor não era inferível apenas pelo código.

**Recomenda-se revisão humana antes de usar como documentação oficial.**

---

## 🔄 Como Manter Atualizada

- `MEMORY.md` (raiz) → atualizar ao final de cada sessão de desenvolvimento
- `RELEASE_NOTES.md` → atualizar a cada versão publicada
- `CHECKLIST_SEGURANCA.md` → executar antes de cada deploy
- `TEST_CASES.md` → adicionar novos casos ao implementar features
- `API.md` → atualizar ao criar novas tabelas ou RPCs no Supabase
