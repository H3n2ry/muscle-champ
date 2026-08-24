# VALORES.md — Estratégia de Preços

> **Status:** proposta consolidada em 17/08/2026. Desde 25/08/2026 existe um paywall de
> **demonstração** (`lib/features/subscription/`) com estes valores, para ajustar layout e
> copy. Não existe billing nem entitlement real. Ver "Implementação" no final.
>
> A escada de coerência da §1 virou teste: `test/planos_test.dart`. Mudou preço, roda.

## 1. Tabela de preços

Referência para todos os cálculos de economia: mensal × 12 = **R$ 238,80/ano**.

### Anual — três degraus

| Fase | Preço | R$/mês | Economia vs mensal | Quando se aplica |
|------|-------|--------|--------------------|------------------|
| **Lançamento** | R$ 89,90 | 7,49 | ~7,5 meses grátis | Apenas nos 6 primeiros meses de vida do app |
| **Primeira assinatura** | R$ 119,90 | 9,99 | ~6 meses grátis | Sempre — todo usuário novo, permanente |
| **Renovação** | R$ 149,90 | 12,49 | ~4,5 meses grátis | 2º ano em diante |

### Demais planos

| Plano | Preço | R$/mês |
|-------|-------|--------|
| Mensal | R$ 19,90 | 19,90 |
| Trimestral | R$ 49,90 | 16,63 |

### Avaliação gratuita

**14 dias** de trial.

### Coerência da escada

Verificação que precisa continuar valendo a cada mudança de preço:

```
4 × trimestral (R$ 199,60)  >  renovação anual (R$ 149,90)   ✓
12 × mensal   (R$ 238,80)  >  4 × trimestral (R$ 199,60)     ✓
```

O plano de maior compromisso tem que ser sempre o mais barato por mês. Na versão
anterior da tabela isso estava quebrado: 4 trimestrais a R$ 34,90 davam R$ 139,60,
menos que os R$ 149,90 da renovação anual — quem fizesse a conta abandonaria o anual.

## 2. Por que estes valores

### O custo de IA é irrelevante

Esta é a premissa que sustenta tudo. Preços da Groq (atualizado em 17/08/2026):

- `openai/gpt-oss-120b` (texto) — US$ 0,15/M entrada · US$ 0,60/M saída
- `qwen/qwen3.6-27b` (visão) — US$ 0,60/M entrada · US$ 3,00/M saída

> O modelo de texto anterior (`llama-3.3-70b-versatile`, US$ 0,59/0,79) foi
> descontinuado pela Groq em **16/08/2026**. O substituto é mais barato, então
> os custos abaixo caíram em relação à primeira versão deste documento.

Custo por chamada, convertido a R$ 5,40/USD:

O `gpt-oss-120b` é modelo de raciocínio: gasta tokens "pensando" antes do conteúdo,
e esses tokens são **cobrados como saída**. Medido em prompts curtos de JSON: ~65% da
saída é raciocínio. Os números abaixo já incluem isso.

| Chamada | Tokens aprox. | Custo |
|---------|---------------|-------|
| Foto de refeição (visão, 768px) | ~1.800 in + 100 out | R$ 0,0075 |
| Macros por texto | ~600 in + 80 out (51 de raciocínio) | R$ 0,0007 |
| Gerar treino | ~400 in + 1.000 out | R$ 0,0037 |
| Gerar plano de dieta | ~500 in + 2.500 out | R$ 0,0084 |

Usuário **pesado** (4 fotos/dia, 2 textos/dia, 8 treinos e 10 planos/mês): **~R$ 1,06/mês**.
Usuário médio: ~R$ 0,35/mês.

Com 1.000 usuários — Groq ~R$ 400/mês + Supabase Pro (US$ 25) R$ 135/mês — o custo fica em
**~R$ 0,54 por usuário/mês** contra ~R$ 9,88 de receita líquida. **Margem ~95%.**

O modo FOTO responde por ~88% do custo de IA. Trocar o modelo de texto mudou pouco
justamente por isso — quem manda na conta é a visão.

Conclusão: o preço não é definido por custo. É definido por valor percebido e por mercado.

### Âncora de mercado

MyFitnessPal Premium no Brasil: ~R$ 31,99/mês e ~R$ 147,99/ano (~R$ 12,33/mês).
⚠️ Conferir direto na Play Store — a fonte encontrada pode estar desatualizada.

O Muscle Champ entrega mais que o núcleo do MFP (foto por IA, geração de treino, plano de
dieta, gamificação, ranking social), mas não tem marca nem base de alimentos comparável.
Desconto se justifica; 53% abaixo, como estava, não.

### O trial de 14 dias

Um trialista custa ~R$ 0,25 em IA. Abuso de trial é financeiramente irrelevante.
14 dias dão tempo de completar duas semanas de treino e ver a gamificação enganchar —
que é onde o app retém. O custo de dobrar o trial é ruído; o efeito em conversão não é.

## 3. Decisões em aberto

**R$ 149,90 nunca é pago na entrada.** Se toda primeira assinatura sai por R$ 119,90, o
valor "normal" é só o preço de renovação. Anunciar *"de R$ 149,90 por R$ 119,90"* configura
preço de referência artificial e o CDC trata isso como propaganda enganosa.
**Enquadramento seguro:** *"primeiro ano por R$ 119,90, renova por R$ 149,90"*.
→ Ver `docs/juridico/LEGAL.md` antes de escrever qualquer copy de preço.

**A renovação é o momento de churn.** Todo usuário leva +25% no 2º ano. O Google Play
obriga a notificar mudança de preço, então ele vê chegando. Decidir se:
- (a) aceita o churn, ou
- (b) segura os compradores de lançamento em R$ 119,90 na renovação como fidelidade —
  reter sai mais barato que readquirir.

**Preço é decisão de mão única.** Assinatura no Google Play é difícil de subir depois que
existe base ativa. Diferente do resto do app, isso não dá para testar e corrigir depois.

**Volume é o gargalo real, não preço.** 1.000 usuários no Ano 10 gera ~R$ 110 mil de lucro
anual (~R$ 9,2 mil/mês). A escada acima adiciona talvez 25% a isso; dobrar a base adiciona
100%. Vale girar o botão do preço porque é fácil — sem confundir com a alavanca principal.

## 4. Premissas herdadas do planejamento

- **Gateway:** Google Play, taxa de 15% (correta — vale até US$ 1M/ano, teto inalcançável nesta escala)
- **Mix de assinaturas:** 60% anual · 30% mensal · 10% trimestral
- **Crescimento:** 10 usuários no Ano 1 → 1.000 no Ano 10
- **Câmbio:** R$ 5,40/USD
- **Infra:** free tier até ~50 usuários; depois Supabase Pro (US$ 25/mês) + tokens Groq pagos

## 5. Implementação

- [x] Paywall e telas de assinatura — **em modo demonstração**
- [ ] Integração com Google Play Billing
- [ ] **Introductory offer** para a promo de primeira assinatura (recurso nativo do Play — desconto automático na 1ª compra)
- [ ] Base price temporário ou promo codes para a janela de lançamento de 6 meses
- [ ] Controle de entitlement (quem é assinante, quando expira) — **no servidor**
- [ ] Trial de 14 dias (hoje só a data é simulada)
- [ ] Notificação de mudança de preço na renovação
- [ ] **Decidir o que é grátis e o que é Pro** — a tela lista os quatro recursos de IA
      como pagos, mas isso foi escolha de rascunho, não decisão tomada

### O que o modo demonstração faz e não faz

`/assinatura` → `/assinatura/pagamento` → `/assinatura/sucesso`, com entrada pelo perfil.
Grava a "assinatura" em `SharedPreferences` com escopo de usuário, só para dar para
percorrer o fluxo inteiro e ver o estado no perfil. **Nenhuma função do app está
bloqueada** — não há gate em lugar nenhum.

Os campos de cartão vêm com o número de sandbox `4111 1111 1111 1111`, não saem do
aparelho e não são gravados. Uma faixa `MODO DEMONSTRAÇÃO` fica visível nas três telas:
uma tela de pagamento convincente que não cobra nada é exatamente o tipo de coisa que
vaza para produção sem ninguém notar.

### Três coisas que mudam quando virar real

1. **No Android esta tela não existe.** Assinatura de conteúdo digital tem que passar
   pelo Google Play Billing, que abre a folha de pagamento do próprio Play. O que sobra
   do checkout é a versão web.
2. **O preço não sai do cliente.** No Play ele é definido por região no Console e o app
   exibe o que o Billing devolver. `Planos` no código é vitrine de demonstração — deixar
   valor fixo faria o usuário de outro país ver R$ e ser cobrado em outra moeda.
3. **O entitlement mora no servidor.** `SharedPreferences` é do aparelho e o usuário
   edita. Quem decide se alguém é assinante é o Supabase, confirmado por webhook do
   gateway — cliente nunca decide que pagou.

Os dois primeiros itens são mecanismos distintos no Play Billing — a promo permanente de
primeira assinatura é *introductory offer*; a janela de lançamento não é.

---

## Fontes

- [Groq Pricing In 2026 — CloudZero](https://www.cloudzero.com/blog/groq-pricing/)
- [Groq API Pricing (June 2026) — AI Pricing Guru](https://www.aipricing.guru/groq-pricing/)
- [Qwen3.6 27B — API Pricing & Benchmarks (OpenRouter)](https://openrouter.ai/qwen/qwen3.6-27b)
- [MyFitnessPal lança versão Premium no Brasil — Sport Life](https://sportlife.com.br/myfitnesspal-lanca-versao-premium-no-brasil/)
