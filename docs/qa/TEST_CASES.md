# TEST_CASES.md — Casos de Teste por Funcionalidade
## Muscle Champ · v1.0.0+1

---

## 1. Autenticação

### TC-AUTH-01: Login com credenciais válidas
- **Pré-condição:** Usuário cadastrado com e-mail confirmado
- **Passos:** Abrir app → inserir e-mail e senha válidos → tocar "Entrar"
- **Esperado:** Redirecionado para `/dashboard` com nome do usuário visível
- **Borda:** Espaços em branco no e-mail devem ser ignorados (trim)

### TC-AUTH-02: Login com senha errada
- **Passos:** Inserir e-mail válido + senha incorreta → tocar "Entrar"
- **Esperado:** Mensagem de erro clara; usuário permanece na tela de login

### TC-AUTH-03: Cadastro completo
- **Passos:** Ir para /register → preencher nome, e-mail, senha, objetivo, peso, altura → confirmar
- **Esperado:** Tela de confirmação de e-mail exibida; perfil criado no Supabase

### TC-AUTH-04: E-mail já cadastrado
- **Passos:** Tentar cadastrar com e-mail já existente
- **Esperado:** Mensagem de erro; não cria conta duplicada

### TC-AUTH-05: Logout
- **Passos:** Perfil → Sair
- **Esperado:** Redirecionado para `/login`; próxima abertura do app vai para `/login`

---

## 2. Dashboard

### TC-DASH-01: Carregamento inicial
- **Esperado:** Pontos, rank global, rank amigos, meta semanal e status do dia carregam em < 3s
- **Borda:** Usuário novo com 0 pontos — exibir "0" e não crash

### TC-DASH-02: Meta de treino do dia
- **Cenário A:** Sem treino hoje → indicador "Treino" em estado pendente
- **Cenário B:** Após completar treino → indicador "Treino" em estado concluído sem reload manual

### TC-DASH-03: Meta de dieta do dia
- **Cenário A:** Sem refeições → indicador "Dieta" pendente
- **Cenário B:** Calorias dentro de ±10% da meta → indicador concluído

---

## 3. Treinos

### TC-WRK-01: Gerar treino por grupo muscular
- **Passos:** Workout → selecionar "Peito" → "Gerar Treino com IA"
- **Esperado:** Lista de 5-8 exercícios em português com sets, reps e dica dentro de 30s
- **Borda:** Sem conexão → mensagem de timeout; não crash

### TC-WRK-02: Registrar exercício com peso
- **Passos:** Na lista de exercícios gerados → inserir peso no campo → salvar
- **Esperado:** Exercício salvo com peso informado; `previous_weight` igual ao peso da sessão anterior (se houver)

### TC-WRK-03: Completar treino
- **Passos:** Após registrar todos os exercícios → "Concluir Treino"
- **Esperado:** Treino marcado como `completed = true`; pontos creditados; meta do dia atualizada

### TC-WRK-04: Histórico de treinos
- **Esperado:** Últimos 30 treinos exibidos em ordem decrescente; completados e não completados diferenciados visualmente

---

## 4. Dieta — Modo Texto

### TC-DIET-TXT-01: Calcular macros por descrição
- **Input:** "2 ovos mexidos com queijo"
- **Esperado:** Nome, calorias, proteína, carboidratos e gordura retornados em < 10s
- **Borda:** Input vazio → não enviar para a API; exibir validação

### TC-DIET-TXT-02: Adicionar refeição calculada
- **Passos:** Após cálculo → "Adicionar"
- **Esperado:** Refeição aparece na lista do dia; totais diários atualizados

### TC-DIET-TXT-03: Deletar refeição
- **Passos:** Swipe ou botão deletar em uma refeição
- **Esperado:** Refeição removida; totais recalculados imediatamente

---

## 5. Dieta — Modo Foto

### TC-DIET-FOTO-01: Foto por câmera — alimento simples
- **Input:** Foto de uma banana
- **Esperado:** Nome "banana" identificado com peso estimado; macros calculados

### TC-DIET-FOTO-02: Foto de galeria — prato complexo
- **Input:** Foto de arroz, feijão, frango e salada
- **Esperado:** Nome descritivo do prato; peso estimado razoável (>200g); macros totais somados

### TC-DIET-FOTO-03: Imagem PNG da galeria
- **Input:** Screenshot PNG de um alimento
- **Esperado:** MIME `image/png` detectado via magic bytes; análise não falha

### TC-DIET-FOTO-04: Porção selecionada afeta contexto
- **Passos:** Selecionar "PRATO" antes de tirar foto de uma refeição pequena
- **Esperado:** Peso estimado maior do que sem a dica de porção

### TC-DIET-FOTO-05: Slider de ajuste de peso
- **Passos:** Após análise → arrastar slider de 300g para 450g
- **Esperado:** Calorias e macros recalculados proporcionalmente em tempo real

### TC-DIET-FOTO-06: Alimento não identificado
- **Input:** Foto de um objeto não-alimentar (ex: chave)
- **Esperado:** Mensagem "não identificado" exibida; sem crash; campos zerados

### TC-DIET-FOTO-07: Imagem muito grande (>768px)
- **Input:** Foto de 4032x3024px da câmera
- **Esperado:** Imagem redimensionada automaticamente para ≤768px antes do envio; análise funciona normalmente

---

## 6. Ranking e Amizades

### TC-RANK-01: Ranking global
- **Esperado:** Lista ordenada por pontos; posição do usuário logado destacada

### TC-RANK-02: Buscar usuário
- **Input:** Nome parcial de um usuário existente
- **Esperado:** Resultados com nome, pontos e status de amizade

### TC-RANK-03: Enviar solicitação de amizade
- **Passos:** Buscar → "Adicionar" → confirmar
- **Esperado:** Status muda para "Pendente"; destinatário vê solicitação em Notificações

### TC-RANK-04: Aceitar solicitação
- **Passos:** Notificações → solicitação pendente → "Aceitar"
- **Esperado:** Amizade criada; usuário aparece no ranking de amigos de ambos

### TC-RANK-05: Ranking de amigos vazio
- **Cenário:** Usuário sem amigos aceitos
- **Esperado:** Lista vazia com mensagem explicativa; sem crash

---

## 7. Plano de Dieta com IA

### TC-AIPLAN-01: Gerar plano completo
- **Pré-condição:** Usuário com goals configuradas (calorias, objetivo, macros)
- **Passos:** Diet → seção "Plano de Dieta com IA" → "Gerar Plano"
- **Esperado:** Cardápio gerado em < 30s com refeições cobrindo ~100% das calorias meta; macros não ultrapassam metas definidas

### TC-AIPLAN-02: Persistência após F5 (web)
- **Passos:** Gerar plano → recarregar a página (F5)
- **Esperado:** Plano continua exibido; não é regnerado automaticamente

### TC-AIPLAN-03: Plano isolado por conta
- **Passos:** Gerar plano com conta A → logout → login com conta B
- **Esperado:** Conta B não vê o plano da conta A

### TC-AIPLAN-04: Substituir alimento
- **Passos:** Tocar em ALTERAR num alimento → buscar substituto → selecionar
- **Esperado:** Peso do substituto recalculado para manter as calorias do alimento original (± 5%); totais da refeição atualizados

### TC-AIPLAN-05: Substituição salva após F5
- **Passos:** Substituir um alimento → F5
- **Esperado:** Substituição persistida; alimento original não volta

---

## 8. Tutorial Interativo

### TC-TUT-01: Tutorial exibido para novo usuário
- **Pré-condição:** Conta sem `tutorial_seen_{userId}` no SharedPreferences
- **Passos:** Fazer login com nova conta
- **Esperado:** Overlay do tutorial aparece automaticamente sobre o /dashboard

### TC-TUT-02: Navegação automática entre seções
- **Passos:** No tutorial, avançar até o passo 3 (TREINO)
- **Esperado:** App navega automaticamente para /workout; spotlight aparece na aba TREINO

### TC-TUT-03: Tutorial completo não reaparece
- **Passos:** Completar o tutorial (passo 12 → "COMEÇAR!") → logout → login
- **Esperado:** Tutorial não aparece na segunda sessão

### TC-TUT-04: Pular tutorial
- **Passos:** Tocar "PULAR" no passo 1
- **Esperado:** Overlay some; `tutorial_seen_{userId} = true` salvo; não reaparece

### TC-TUT-05: Tutorial isolado por conta
- **Passos:** Completar tutorial com conta A → login com conta B (nova)
- **Esperado:** Tutorial exibido para conta B normalmente

---

## 9. Perfil

### TC-PROF-01: Atualizar peso
- **Passos:** Perfil → editar → novo peso → salvar
- **Esperado:** `goals.current_weight` e `weight_logs` atualizados

### TC-PROF-02: Upload de avatar
- **Passos:** Foto de perfil → selecionar da galeria → confirmar
- **Esperado:** Imagem aparece no perfil e no ranking; URL com cache busting

### TC-PROF-03: Dados de bioimpedância
- **Passos:** Inserir % gordura corporal e massa muscular → salvar
- **Esperado:** Dados visíveis no perfil; `bioimpedance_logs` atualizado com data de hoje

---

## 10. Casos de Borda Globais

| Caso | Comportamento Esperado |
|------|----------------------|
| Sem conexão com internet | Mensagem de erro; sem crash; botão de tentar novamente |
| Timeout Groq (>30s) | `TimeoutException` capturado; mensagem ao usuário |
| Supabase retorna erro 5xx | Mensagem genérica de erro; dados anteriores mantidos |
| JWT expirado | GoRouter redirect para /login automaticamente |
| App em segundo plano por longo período | Dados recarregados ao voltar (autoDispose reconstrói) |
| Modo portrait forçado | App não rotaciona em nenhum dispositivo |
