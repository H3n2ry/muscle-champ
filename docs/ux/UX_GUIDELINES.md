# UX_GUIDELINES.md — Diretrizes de UX
## Muscle Champ · Design System Obsidian Kinetic

---

## 1. Princípios de Design

| Princípio | Descrição |
|-----------|-----------|
| **Dark-first** | Apenas tema escuro. Nunca introduzir tema claro sem decisão explícita |
| **Competição visível** | Pontos e ranking sempre acessíveis — é a motivação central |
| **IA como assistente** | IA facilita; usuário confirma. Nunca substituir decisão do usuário |
| **Feedback imediato** | Loading states em toda ação assíncrona; nunca tela em branco |
| **Foco no essencial** | Cada tela tem uma ação primária clara |

---

## 2. Paleta de Cores

```
Uso               Cor hex     Token AppColors
─────────────────────────────────────────────
Background        #121413     AppColors.background
Surface nível 1   #1B1C1C     AppColors.surfaceContainerLow
Surface nível 2   #1F2020     AppColors.surfaceContainer
Surface nível 3   #292A2A     AppColors.surfaceContainerHigh
Surface nível 4   #343535     AppColors.surfaceContainerHighest
Borda padrão      #3F4A34     AppColors.outlineVariant
Borda destaque    #88957B     AppColors.outline

Ação primária     #7EFC00     AppColors.primary (lime green)
Hover/press       #6FE000     AppColors.primaryDim
Texto em primary  #173800     AppColors.onPrimary

Texto principal   #E4E2E1     AppColors.onSurface
Texto secundário  #BDCBAE     AppColors.onSurfaceVariant

Modo foto (IA)    #0EA5E9     — (cyan, hardcoded em diet_page)
Aviso             #FFD700     AppColors.warning
Erro              #FFB4AB     AppColors.error
```

**Regras:**
- Nunca usar `Colors.white` — usar `AppColors.onSurface`
- Nunca usar `Colors.black` — usar `AppColors.background`
- Glow verde: `AppColors.primaryGlow` (15% opacity) para efeitos sutis

---

## 3. Tipografia

Fontes definidas em `app_typography.dart`. Hierarquia:

| Estilo | Uso |
|--------|-----|
| `displayLarge` | Títulos de ranking/pontuação grande |
| `headlineMedium` | Cabeçalhos de seção |
| `titleLarge` | Nome do usuário, títulos de card |
| `bodyLarge` | Texto principal |
| `bodyMedium` | Descrições, subtítulos |
| `labelSmall` | Badges, chips, rótulos pequenos |

---

## 4. Componentes Reutilizáveis

### `MkButton`
- Botão primário: fundo `#7EFC00`, texto `#173800`
- Botão secundário: borda `#7EFC00`, fundo transparente
- **Nunca** usar `ElevatedButton` ou `TextButton` direto — sempre `MkButton`
- Estado desabilitado: opacidade 40%

### `MkCard`
- Fundo `surfaceContainerLow`
- Border radius: 16px
- Variante com glow: borda `primary` com shadow verde

### `MkTextField`
- Fundo `surfaceContainerHigh`
- Label flutuante em `primary`
- Border radius: 12px

### `BottomNavBar`
- 5 abas: Dashboard, Treino, Dieta, Ranking, Perfil
- Ícone ativo: cor `primary` (#7EFC00)
- Ícone inativo: cor `onSurfaceVariant`

---

## 5. Padrões de Interação

### Loading States
```
┌──────────────────────┐
│  Shimmer animado     │  ← Usar shimmer package para listas
│  ou CircularProgress │  ← Para ações pontuais (gerar treino, analisar foto)
│  com cor primary     │
└──────────────────────┘
```

- `FutureProvider` → envolver com `.when(data:, loading:, error:)`
- Loading de foto: mostrar spinner + texto "Analisando..." sobre a imagem

### Feedback de Sucesso
- Toast/SnackBar com fundo `surfaceContainerHighest` e texto em `primary`
- Duração: 2-3 segundos, sem ação obrigatória

### Feedback de Erro
- SnackBar vermelho com mensagem clara em português
- Botão "Tentar novamente" quando aplicável
- Nunca mostrar stack trace para o usuário

### Estados Vazios
- Ícone temático + texto descritivo + CTA quando relevante
- Exemplo: lista de treinos vazia → ícone de haltere + "Nenhum treino registrado. Gere seu primeiro treino!"

---

## 6. O que NÃO Fazer

| ❌ Proibido | ✅ Alternativa |
|------------|--------------|
| `Colors.white` | `AppColors.onSurface` |
| `Colors.green` | `AppColors.primary` |
| `Theme.of(context).primaryColor` | `AppColors.primary` diretamente |
| Tela em branco durante loading | Shimmer ou CircularProgressIndicator |
| Mensagens de erro em inglês | Sempre em português |
| Ícones sem label na navegação | BottomNavBar sempre com label |
| Modo landscape | App é portrait-only |
| Alertas que bloqueiam sem opção de fechar | Sempre botão "Cancelar" ou dismiss |

---

## 7. Espaçamentos e Dimensões

```
Padding padrão de página:  EdgeInsets.all(16)
Padding entre cards:       8px vertical
Border radius de cards:    16px
Border radius de botões:   12px
Altura de botões:          48px (mínimo toque 44px)
Tamanho de ícones de nav:  24px
Avatar do usuário:         40px (lista) / 80px (perfil)
```
