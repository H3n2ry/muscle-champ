# USER_FLOWS.md — Fluxos do Usuário
## Muscle Champ

---

## 1. Fluxo de Onboarding / Cadastro

```
Abrir app
    │
    ├── [sem sessão] ──→ /login
    │                       │
    │              ┌────────┴──────────┐
    │              │ Tem conta?        │ Não
    │              │ Sim ↓             ↓
    │              │ Login         /register
    │              │                   │
    │              │         ┌─────────┴─────────────────┐
    │              │         │ Preencher:                 │
    │              │         │ • Nome completo            │
    │              │         │ • E-mail                   │
    │              │         │ • Senha                    │
    │              │         │ • Objetivo (ganhar/        │
    │              │         │   perder/manter)           │
    │              │         │ • Peso atual               │
    │              │         │ • Peso alvo                │
    │              │         │ • Altura                   │
    │              │         └─────────────────────────────┘
    │              │                   │
    │              │         E-mail de confirmação enviado
    │              │                   │
    │              │         /confirm-email (aguardar clique)
    │              │                   │
    │              └─────────── /dashboard ←──────────────┘
    │
    └── [com sessão] ──→ /dashboard
```

---

## 2. Fluxo Principal — Dashboard

```
/dashboard
    │
    ├── Pontos totais + Rank global + Rank amigos
    │
    ├── Status do dia:
    │   ├── [✗] Treino pendente ──→ tap → /workout
    │   └── [✓] Treino concluído (verde)
    │
    ├── [✗] Meta de dieta pendente ──→ tap → /diet
    │   └── [✓] Meta atingida (verde)
    │
    ├── Meta semanal de treinos (barra de progresso)
    │
    └── Histórico de pontos (gráfico fl_chart)
```

---

## 3. Fluxo de Treino

```
/workout
    │
    ├── Histórico dos últimos 30 treinos (lista)
    │
    └── Botão "Novo Treino"
            │
            Selecionar grupo muscular
            (Peito / Costas / Pernas / Ombros / Bíceps / Tríceps / etc.)
            │
            "Gerar Treino com IA" → spinner (~5-10s)
            │
            Lista de 5-8 exercícios:
            ┌─────────────────────────┐
            │ Supino Reto             │
            │ 4 séries × 12 reps      │
            │ Dica: mantenha...       │
            │ Peso: [___] kg          │
            └─────────────────────────┘
            │
            Preencher peso em cada exercício
            │
            "Concluir Treino"
            │
            ├── Treino salvo
            ├── Pontos creditados
            └── Dashboard atualizado
```

---

## 4. Fluxo de Dieta — Modo Texto

```
/diet → aba "Texto"
    │
    Campo de descrição livre:
    "2 ovos mexidos com 30g de queijo"
    │
    Botão "Calcular Macros" → spinner (~3-5s)
    │
    Card com resultado:
    ┌──────────────────────────────┐
    │ 2 Ovos Mexidos c/ Queijo     │
    │ 180g · 320 kcal              │
    │ Prot: 22g Carb: 2g Fat: 24g │
    └──────────────────────────────┘
    │
    "Adicionar" → salvo em diet_logs
    │
    Resumo do dia atualizado
```

---

## 5. Fluxo de Dieta — Modo Foto

```
/diet → aba "Foto"
    │
    [Opcional] Selecionar porção: PEQUENA / MÉDIA / GRANDE / PRATO
    │
    Dica: "Coloque um garfo ou prato perto para melhor precisão"
    │
    ┌──────────────┬────────────────┐
    │ 📷 Câmera    │ 🖼️ Galeria      │
    └──────────────┴────────────────┘
    │
    Imagem selecionada/tirada
    → _optimizeImage() (resize ≤768px, JPEG 80%)
    → GroqService.analyzeFoodPhoto() → spinner (~10-20s)
    │
    ┌── Identificado ──────────────────────────────────┐
    │   Card com resultado:                            │
    │   Nome + peso estimado + macros                  │
    │                                                  │
    │   Slider: [20g ──────●─────── 800g]             │
    │           Ajustar peso → recalcula macros        │
    │                                                  │
    │   Botão "Adicionar"                              │
    └──────────────────────────────────────────────────┘
    │
    └── Não identificado ──→ "Não foi possível identificar"
                              Opção de tentar novamente
```

---

## 6. Fluxo de Ranking e Amizades

```
/ranking
    │
    ├── Aba "Global" → lista todos os usuários ordenados por pontos
    │
    ├── Aba "Amigos" → lista amigos aceitos por pontos
    │
    └── Aba "Buscar"
            │
            Campo de busca → digitar nome
            │
            Lista de resultados:
            ┌─────────────────────────────────┐
            │ João Silva · 450pts             │
            │ [Adicionar amigo]               │
            ├─────────────────────────────────┤
            │ Maria Costa · 380pts · Amiga ✓  │
            └─────────────────────────────────┘
            │
            "Adicionar" → solicitação enviada
            │
            João vê em Notificações:
            "Maria quer ser sua amiga"
            → Aceitar / Recusar
            │
            Aceito → ambos aparecem no ranking de amigos
```

---

## 7. Fluxo do Tutorial Interativo (Novo Usuário)

```
Login com nova conta → /dashboard
    │
    TutorialOverlay aparece (overlay escura com spotlight)
    │
    Passo 1/12 — INÍCIO
    │   Spotlight na aba INÍCIO
    │   Card: "Bem-vindo ao Muscle Champ!"
    │   → [PRÓXIMO]
    │
    Passo 2/12 — INÍCIO
    │   Spotlight no topo da tela (pontos/rank)
    │   → [PRÓXIMO] → navega para /workout
    │
    Passo 3-4/12 — TREINO
    │   Spotlight na aba TREINO → como gerar treino com IA
    │   → [PRÓXIMO] → navega para /diet
    │
    Passo 5-8/12 — DIETA
    │   Spotlight na aba DIETA → como registrar refeição
    │   → texto, foto, macros, plano IA
    │   → [PRÓXIMO] → navega para /ranking
    │
    Passo 9-10/12 — RANKING
    │   Spotlight na aba RANKING → ranking global + amigos
    │   → [PRÓXIMO] → navega para /profile
    │
    Passo 11-12/12 — PERFIL
    │   Spotlight na aba PERFIL → metas + bioimpedância
    │   → [COMEÇAR!]
    │
    Tutorial concluído → overlay some
    SharedPreferences['tutorial_seen_{userId}'] = true
    Nunca mais aparece para esse usuário
    │
    └── [PULAR] disponível em qualquer passo → mesmo efeito que COMEÇAR
```

---

## 8. Fluxo do Plano de Dieta com IA

```
/diet → rolar para baixo → seção "Plano de Dieta com IA"
    │
    Botão "Gerar Plano"
    → spinner (~10-20s)
    → GroqService.generateDietPlan(metas do usuário)
    │
    Plano gerado e exibido:
    ┌────────────────────────────────────┐
    │ Café da Manhã                      │
    │  • Ovos mexidos 150g — 230 kcal   │
    │  • Pão integral 50g — 130 kcal    │
    ├────────────────────────────────────┤
    │ Almoço                             │
    │  • Arroz 150g — 195 kcal          │
    │  • Frango grelhado 200g — 330 kcal│
    └────────────────────────────────────┘
    Total: 2000 kcal | Prot: 150g | Carb: 210g | Gord: 67g
    │
    Plano salvo no SharedPreferences → persiste após F5
    │
    Substituir alimento (botão ALTERAR):
        → Sheet de busca abre
        → Digitar nome do alimento substituto
        → Selecionar da base local
        → Peso recalculado automaticamente para manter as calorias do alimento original
        → Plano atualizado e salvo
```

---

## 9. Pontos de Fricção Identificados

| Ponto | Fricção | Melhoria Sugerida |
|-------|---------|------------------|
| Cadastro longo | 7 campos na tela de registro | Dividir em steps (1: conta, 2: objetivos) |
| Confirmação de e-mail | Usuário precisa sair do app | Adicionar botão "Reenviar e-mail" |
| Foto de alimento: sem feedback de progresso | Usuário não sabe que a IA está processando | Texto "Analisando sua refeição..." + animação |
| Ranking global com muitos usuários | Lista pode ficar longa | Paginação ou "top 50" |
| Bioimpedância: muitos campos opcionais | Pode confundir | Tooltip em cada campo explicando o que é |
