# TROUBLESHOOTING.md — Resolução de Problemas
## Muscle Champ

---

## Para Usuários

### Problema 1: App não abre ou fecha sozinho
**Sintoma:** App trava na tela de carregamento ou fecha inesperadamente.
**Causa provável:** Falha de conexão com o Supabase na inicialização.
**Solução:**
1. Verificar conexão com a internet
2. Fechar completamente o app (remover da lista de recentes)
3. Reabrir
4. Se persistir: desinstalar e reinstalar o app

---

### Problema 2: Tela de login em loop
**Sintoma:** Faz login mas volta para a tela de login.
**Causa provável:** E-mail não confirmado.
**Solução:**
1. Verificar caixa de e-mail (incluindo spam) para e-mail de confirmação
2. Clicar no link de confirmação
3. Tentar fazer login novamente

---

### Problema 3: IA não identifica o alimento na foto
**Sintoma:** Mensagem "não foi possível identificar" ou peso sempre estimado incorretamente.
**Causas e soluções:**
| Causa | Solução |
|-------|---------|
| Foto escura ou desfocada | Melhorar iluminação; focar antes de tirar a foto |
| Alimento muito pequeno na imagem | Aproximar a câmera |
| Prato com muitos itens | Colocar garfo ou colher do lado para dar referência de tamanho |
| Alimento incomum ou muito processado | Usar modo texto para inserir manualmente |
| Ângulo de cima prejudica identificação | Tentar ângulo de 45° |

---

### Problema 4: Treino demorou mais de 30 segundos para gerar
**Sintoma:** Spinner girando por muito tempo ou mensagem de erro de timeout.
**Causa provável:** API Groq sobrecarregada ou conexão lenta.
**Solução:**
1. Verificar conexão com a internet
2. Aguardar 30 segundos e tentar novamente
3. Se persistir, tentar mais tarde

---

### Problema 5: Pontos não foram creditados após completar treino
**Sintoma:** Dashboard ainda mostra pontos antigos após concluir treino.
**Solução:**
1. Puxar para baixo (pull-to-refresh) na tela do dashboard
2. Sair e entrar novamente na aba do dashboard
3. Se os pontos ainda não aparecerem após 5 minutos, entrar em contato com suporte

---

### Problema 6: Foto de perfil não atualiza
**Sintoma:** Avatar antigo ainda aparece após upload de nova foto.
**Causa provável:** Cache de imagem.
**Solução:**
1. Fechar e reabrir o app
2. A nova foto usa cache-busting automático — deve aparecer na reabertura

---

### Problema 7: Ranking não carrega
**Sintoma:** Tela de ranking em loading infinito ou erro.
**Causa provável:** Serviço Supabase temporariamente indisponível.
**Solução:**
1. Verificar conexão com a internet
2. Aguardar 1-2 minutos e tentar novamente
3. Verificar status do Supabase: https://status.supabase.com

---

## Para Desenvolvedores

### Build falha com "C:\Users\Henry" no caminho
```powershell
flutter clean
Remove-Item -Recurse -Force .dart_tool, build, android/.gradle -ErrorAction SilentlyContinue
flutter pub get
flutter build apk --release
```

### `sdkmanager` não encontrado
- Instalar "Android SDK Command-line Tools (latest)" via Android Studio SDK Manager (aba SDK Tools)
- Definir `$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"` antes de usar

### Groq retorna sempre macros zerados ou placeholders
- Verificar se o prompt usa descritores (`PESO_TOTAL_EM_GRAMAS`) e não literais (`0`)
- `max_tokens` deve ser ≥ 300 para não cortar o JSON

### Web build falha com lock no iOS ephemeral
```powershell
Remove-Item -Recurse -Force "ios/Flutter/ephemeral" -ErrorAction SilentlyContinue
flutter build web --release
```

### Deploy web: subiu mas a tela não muda
Quase sempre é cache, não deploy. Compare o hash antes de investigar qualquer outra coisa:
```bash
curl -sL https://musclechamp.com.br/main.dart.js | sha256sum
sha256sum build/web/main.dart.js
```
Hash igual = está no ar. Aí o problema é do lado do cliente: service worker do Flutter, cache do navegador, ou proxy/VPN. Ver `CLAUDE.md`, seção sobre Browser Cache TTL.

> O deploy hoje é `npx wrangler pages deploy build/web --project-name=muscle-champ --branch=main`. **Não usar Vercel** — aposentado em 26/08/2026.

### PNG da galeria não é identificado pela IA
- Verificar se `_optimizeImage()` está detectando magic bytes `0x89 0x50 0x4E 0x47`
- O método deve retornar `'image/png'` para PNGs que falham no `img.decodeImage()`
