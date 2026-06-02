# ACCESSIBILITY.md — Acessibilidade
## Muscle Champ

---

## 1. Nível WCAG Atual (Estimado)

**Nível estimado: A parcial** — requisitos mínimos atendidos por padrão do Flutter, mas sem implementação explícita de acessibilidade.

---

## 2. O que está Implementado

### Pelo Flutter automaticamente
- ✅ Suporte nativo a screen readers (TalkBack Android, VoiceOver iOS) via Semantics tree
- ✅ Tamanho de fonte escalonável (respeita configurações do sistema se usado `TextStyle` sem `textScaleFactor` fixo)
- ✅ Foco de teclado em campos de formulário (login, cadastro)
- ✅ Botões com área de toque mínima (Material Design: 48x48dp)

### Pelo design
- ✅ Contraste alto: texto `#E4E2E1` sobre fundo `#121413` → ratio ~14:1 (passa AAA)
- ✅ Texto de ação em botão primário `#173800` sobre `#7EFC00` → ratio ~7:1 (passa AA)
- ✅ Sem informação transmitida apenas por cor (status usa ícone + cor)

---

## 3. O que Precisa ser Corrigido para WCAG 2.1 AA

### Prioridade Alta

| Item | Problema | Solução |
|------|---------|---------|
| Ícones sem label de acessibilidade | `Icon(Icons.fitness_center)` sem `Semantics(label:)` | Adicionar `Tooltip` ou `Semantics(label: 'Treino')` |
| Imagens sem descrição | Avatares e fotos de alimento sem `semanticLabel` | `Image(..., semanticLabel: 'Foto do usuário')` |
| Campos de formulário | Verificar se `TextFormField` tem `decoration.labelText` em todos | Garantir label visível e `hint` descritivo |
| Bottom nav sem label de estado | Aba selecionada não anuncia "selecionado" | Verificar `NavigationDestination` com `semanticsLabel` |

### Prioridade Média

| Item | Problema | Solução |
|------|---------|---------|
| Slider de peso | `Slider` precisa de label descritivo | `Slider(label: '${value.round()}g', semanticFormatterCallback:...)` |
| Gráfico de pontos | `fl_chart` não é acessível por padrão | Adicionar tabela alternativa oculta com os dados |
| Loading states | Shimmer não anuncia "carregando" para leitores | Envolver com `Semantics(liveRegion: true, label: 'Carregando...')` |
| Mensagens de erro | Verificar se erros são anunciados pelo TalkBack | Usar `Semantics(liveRegion: true)` no SnackBar |

### Prioridade Baixa

| Item | Problema | Solução |
|------|---------|---------|
| Tamanho de texto | Alguns labels podem ser pequenos em telas grandes | Verificar `textScaleFactor` nos widgets críticos |
| Animações | Shimmer e transições podem causar desconforto | Respeitar `MediaQuery.disableAnimations` |

---

## 4. Como Testar Acessibilidade no Flutter

```bash
# Verificar tree de semantics no DevTools
flutter run --debug
# DevTools → Widget Inspector → Toggle Semantics

# Testar no Android com TalkBack
# Configurações → Acessibilidade → TalkBack → Ativar
# Navegar pelo app usando gestos do TalkBack

# Verificar contraste
# https://webaim.org/resources/contrastchecker/
# Foreground: #E4E2E1, Background: #121413 → ratio: 14.08:1 ✅ AAA
# Foreground: #173800, Background: #7EFC00 → ratio: 7.2:1 ✅ AA
```

---

## 5. Checklist de Acessibilidade Pré-Lançamento

- [ ] Navegar todo o app com TalkBack ativado sem travar
- [ ] Todos os botões têm descrição audível
- [ ] Todos os campos de formulário têm label
- [ ] Imagens decorativas marcadas como `excludeFromSemantics: true`
- [ ] Imagens informativas têm `semanticLabel`
- [ ] Contraste de cores verificado nas combinações principais
- [ ] App funciona com fonte 200% (configurar no dispositivo)
- [ ] Nenhuma ação requer precisão motora fina (ex: targets muito pequenos)
- [ ] Mensagens de erro são anunciadas pelo leitor de tela
- [ ] Fluxo de login completo acessível via teclado (web)
