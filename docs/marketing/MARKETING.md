# MARKETING.md — Material de Divulgação
## Muscle Champ

> Baseado nas funcionalidades reais implementadas.

---

## 1. Elevator Pitch

### Versão Técnica (30 segundos — devs/investidores)
> "Muscle Champ é um app Flutter multiplataforma para fitness com IA integrada. Usa Qwen 3.6 27B Vision para análise nutricional de fotos e LLaMA 3.3 para geração de treinos, com backend serverless no Supabase. Sistema de gamificação com pontos, ranking global e social via grafo de amizades."

### Versão Usuário Final (15 segundos)
> "Gera seu treino na hora com IA, tira foto da refeição e já calcula as calorias, e você ainda compete no ranking com seus amigos."

### Versão Impacto (20 segundos)
> "Muita gente abandona a academia porque não sabe o que treinar ou como comer. O Muscle Champ resolve os dois problemas com IA e ainda te mantém motivado competindo com amigos."

---

## 2. Proposta de Valor

| | |
|-|-|
| **Problema** | Manter consistência no treino e na dieta é difícil sem orientação e motivação contínua |
| **Solução** | IA que gera treinos + calcula nutrição por foto + gamificação que cria hábito via competição |
| **Diferencial** | Combinação única: IA de visão para dieta + geração de treino + ranking social em um só app gratuito |

---

## 3. Público-Alvo

| Segmento | Perfil |
|---------|--------|
| **Primário** | Homens e mulheres 18-35 anos, praticantes de academia, usam smartphone Android |
| **Secundário** | Iniciantes que precisam de orientação de treino e dieta sem contratar personal |
| **Terciário** | Grupos de amigos que competem entre si por motivação |

---

## 4. Posts Prontos

### Twitter/X — Lançamento
> 🏋️ Muscle Champ chegou!
>
> IA que gera seu treino + calcula calorias da foto do prato + ranking com amigos.
>
> Tudo num app Android gratuito.
>
> 📲 muscle-champ.vercel.app
>
> #fitness #musculação #IA #academia

---

### Twitter/X — Feature: Foto de Alimento
> Chega de pesquisar caloria manualmente 📸
>
> No @MuscleChamp você tira uma foto, a IA identifica o prato e calcula:
> ✅ Calorias totais
> ✅ Proteína, carboidrato e gordura
>
> Ainda ajusta o peso com um slider se souber o gramado 🎚️
>
> #dieta #nutrição #IA

---

### Twitter/X — Feature: Ranking
> Por que treinar sozinho quando você pode ganhar?
>
> No Muscle Champ você acumula pontos por treinos e dieta e disputa ranking com seus amigos 🏆
>
> Semana passada perdi 3 posições por não bater a meta de calorias 💀
>
> #gamificação #fitness #motivação

---

### LinkedIn
> Desenvolvi um app que usa LLM de visão para calcular macros de refeições por foto e gera treinos personalizados via LLaMA 3.3 70B.
>
> Stack: Flutter + Supabase + Groq API. Deploy em Android e Web.
>
> O que aprendi:
> • Pré-processar imagens (resize para 768px, JPEG 80%) reduz tokens em ~73% sem perder qualidade de análise
> • max_tokens muito baixo corta respostas JSON no meio — aprendido na prática
> • Supabase RLS + RPCs substituem um backend inteiro para apps deste porte
>
> App gratuito: muscle-champ.vercel.app
>
> #Flutter #AI #Groq #Supabase #MobileApp

---

### Instagram
> 📸 Foto do prato → macros na hora
>
> Sem buscar no banco de dados. Sem digitar nada.
>
> Só tirar a foto, a IA faz o resto ✨
>
> Disponível agora 👉 muscle-champ.vercel.app
> (link na bio)
>
> #musclechamp #fitness #IA #dieta #academia #treino #nutrição #saude

---

## 5. Argumentos para Apresentações

### Para usuários céticos sobre IA
> "A IA serve de guia, não de nutricionista. Os valores são estimativas — você ainda pode ajustar o peso com o slider. É muito melhor do que não registrar nada."

### Para comparação com apps existentes
> "MyFitnessPal tem um banco de dados enorme, mas você precisa buscar cada alimento. Aqui você tira uma foto. Hevy é ótimo para registro de treinos, mas você monta o treino do zero. Aqui a IA sugere."

### Para quem questiona a precisão
> "Estudos mostram que qualquer registro alimentar, mesmo impreciso, já melhora a consciência nutricional. A foto é boa o suficiente para o objetivo de manter consistência."

---

## 6. Canais Recomendados

| Canal | Tipo de Conteúdo | Frequência |
|-------|-----------------|-----------|
| Instagram | Reels mostrando feature de foto de alimento | 3x/semana |
| TikTok | "Esse app calcula caloria pela foto" — vídeo viral | 1x/semana |
| Reddit r/Fitness | Post orgânico mostrando o app em uso real | 1x |
| Reddit r/brasil + r/academia | Idem adaptado para pt-BR | 1x |
| Twitter/X | Tweets técnicos sobre a stack (LinkedIn paralelo) | 2x/semana |
| Play Store ASO | Keywords: treino academia IA, caloria foto, fitness gamificado | Contínuo |

---

## 7. ASO — App Store Optimization

**Palavras-chave sugeridas para Play Store:**
treino, academia, musculação, dieta, calorias, fitness, IA, inteligência artificial, ranking, pontos, macros, nutrição, personal trainer, exercício, proteína, carboidrato, gordura, foto alimento, plano de treino

**Categoria:** Saúde e Fitness

**Screenshots sugeridas (5 obrigatórias):**
1. Dashboard com pontos e ranking
2. Geração de treino pela IA
3. Foto de prato → resultado de macros
4. Ranking de amigos
5. Perfil com streak e pontos
