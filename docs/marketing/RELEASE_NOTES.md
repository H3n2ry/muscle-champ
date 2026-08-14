# RELEASE_NOTES.md — Notas de Versão
## Muscle Champ

> Mantido para usuários finais. Linguagem acessível, foco em benefícios.

---

## Versão 1.0.0 — Lançamento Inicial
**Data:** [a definir]

### 🎉 Novidades
- **Treinos com IA** — Selecione o grupo muscular e receba um treino completo gerado na hora
- **Dieta por foto** — Tire uma foto do seu prato e a IA calcula calorias e macros automaticamente
- **Dieta por texto** — Descreva o alimento e obtenha os valores nutricionais em segundos
- **Plano de dieta com IA** — Gere um cardápio completo para o dia baseado nas suas metas calóricas; substitua alimentos com um toque e a IA recalcula o peso para manter as calorias
- **Tutorial interativo** — Novos usuários são guiados por um tutorial de 12 passos que apresenta todas as funcionalidades do app com navegação automática entre abas
- **Sistema de pontos** — Ganhe pontos completando treinos e batendo metas de dieta
- **Ranking global** — Veja sua posição entre todos os usuários do app
- **Ranking de amigos** — Adicione amigos e compete diretamente com eles
- **Perfil personalizado** — Configure seu peso, altura, objetivo e foto de perfil
- **Dados de bioimpedância** — Registre % gordura corporal, massa muscular e outros indicadores

### ✨ Detalhes Técnicos da v1.0.0
- Plano de dieta persiste localmente (F5 não apaga o plano)
- Cada conta tem seu próprio plano de dieta e estado do tutorial no mesmo dispositivo
- Substituição de alimentos calcula automaticamente o peso para manter as calorias do alimento original

---

## Versão 1.1.0 — Hidratação e precisão nutricional
**Data:** 10/08/2026

### 🎉 Novidades
- **Contador de água** — registre o quanto bebeu com um toque (200ml, 350ml ou
  500ml) e acompanhe o progresso do dia. A meta diária é calculada
  automaticamente pelo seu peso e idade
- **Dieta montada por você** — além do plano gerado pela IA, agora dá para criar
  suas próprias refeições escolhendo os alimentos e as quantidades
- **Data de nascimento** no cadastro e no perfil, usada para calcular a
  hidratação ideal

### ✨ Melhorias
- **Contagem de calorias muito mais precisa.** O app passou a usar a Tabela
  Brasileira de Composição de Alimentos (TACO) com 581 alimentos, além de uma
  tabela própria de pratos prontos e bebidas. Antes a IA exagerava — 30g de
  doce de leite marcava 147 kcal quando o correto é ~92
- **Entenda medidas do dia a dia.** Digite "2 ovos", "1 concha de feijão" ou
  "1 fatia de pizza" — não precisa mais converter para gramas
- **Bebidas incluídas** — refrigerante, suco, café, leite, cerveja, vinho,
  energético e mais
- **Ajuste o peso** no resultado da IA quando a porção for diferente da sua
- O mesmo alimento agora sempre resulta no mesmo valor, tornando o
  acompanhamento semanal confiável

### 🐛 Correções
- Excluir um treino deixava a tela preta
- Editar um treino não permitia adicionar novos exercícios
- Aba Ranking travava ao exibir o pódio
- Cronômetro de descanso ficava cortado em telas menores
- Análise de foto voltou a funcionar (o serviço de IA havia descontinuado o
  modelo anterior)

---

## Template para Versões Futuras

```markdown
## Versão X.Y.Z — [Codinome opcional]
**Data:** DD/MM/AAAA

### 🎉 Novidades
[Novas funcionalidades adicionadas nesta versão]

### ✨ Melhorias
[Funcionalidades existentes que foram aprimoradas]

### 🐛 Correções
[Bugs corrigidos nesta versão]

### ⚠️ Breaking Changes (se houver)
[Mudanças que requerem ação do usuário, ex: re-login necessário]
```

---

## Backlog de Features para Próximas Versões

Planejadas mas não implementadas:

| Feature | Benefício para o usuário |
|---------|------------------------|
| Push notifications | Lembrete diário de treino e meta de dieta |
| Exportar histórico (PDF/CSV) | Compartilhar progresso com personal trainer |
| Modo offline | Registrar treinos sem internet |
| iOS | App nativo para iPhone |
| Recuperação de senha | Redefinir senha esquecida |
| Deletar conta no app | Excluir dados sem precisar contatar suporte |
| Planos de treino semanais | Sequência de treinos montada pela IA para a semana |
| Metas personalizadas de macros | Definir meta de proteína, carboidrato e gordura |
| Foto "antes e depois" | Registro visual do progresso físico |
