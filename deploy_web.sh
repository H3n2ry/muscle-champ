#!/usr/bin/env bash
# Build + deploy do app web no projeto Vercel correto.
#
# Uso (Git Bash):  ./deploy_web.sh
#
# DUAS ARMADILHAS QUE ESTE SCRIPT RESOLVE
#
# 1) Deploy da pasta errada → "404: NOT_FOUND"
#    Se o deploy roda da RAIZ do repo, o Vercel acha o package.json (que existe,
#    por causa do sharp), trata como projeto Node, não encontra script de build,
#    e publica um deployment sem index.html na raiz. O site responde — com 404
#    NOT_FOUND em tudo. O conteúdo publicado tem que ser build/web, e só ele.
#
# 2) Deploy no projeto errado → "404: DEPLOYMENT_NOT_FOUND"
#    O nome do projeto vem do .vercel/project.json que o CLI grava dentro de
#    build/web — e build/ é apagado por flutter clean. Sem esse arquivo o CLI usa
#    o nome do DIRETÓRIO ("web") e cria projeto novo. O `vercel link --project`
#    abaixo é idempotente e refaz o vínculo a cada execução.
set -euo pipefail

PROJECT="muscle-champ"
SCOPE="af-dev"

cd "$(dirname "$0")"

# No Git Bash do Windows o flutter e o node não estão no PATH por padrão —
# é o mesmo export que o CLAUDE.md documenta. Sem isto o script morria na
# primeira linha com "flutter: command not found".
if ! command -v flutter >/dev/null 2>&1; then
  echo "==> flutter não está no PATH, aplicando o PATH do Windows/Git Bash"
  export PATH="/c/flutter/bin:/c/Program Files/nodejs:$HOME/AppData/Roaming/npm:$PATH"
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "ERRO: flutter não encontrado. Ajuste o PATH e rode de novo:" >&2
  echo '  export PATH="/c/flutter/bin:/c/Program Files/nodejs:$PATH"' >&2
  exit 1
fi

echo "==> flutter pub get"
flutter pub get

# --no-web-resources-cdn é OBRIGATÓRIO aqui.
# Por padrão o Flutter web baixa o CanvasKit de www.gstatic.com em tempo de
# boot, mesmo existindo uma cópia em build/web/canvaskit/. Se o gstatic estiver
# inacessível (DNS de operadora, rede corporativa, bloqueador), o app fica
# eternamente em "Carregando" — verificado em navegador real. Com a flag, o
# CanvasKit vem do próprio domínio e o app não depende de CDN de terceiro.
echo "==> flutter build web --release --no-web-resources-cdn"
flutter build web --release --no-web-resources-cdn

# Sanidade: sem index.html aqui, o deploy sobe e o site dá 404 NOT_FOUND.
# Melhor falhar agora, com mensagem clara, do que publicar algo quebrado.
if [ ! -f build/web/index.html ]; then
  echo "ERRO: build/web/index.html não existe — o build não gerou saída." >&2
  exit 1
fi
echo "==> conteúdo a publicar (build/web):"
ls build/web | head -15

cd build/web

echo "==> conta autenticada"
npx vercel whoami --scope "$SCOPE" || true

echo "==> projetos existentes no scope"
npx vercel project ls --scope "$SCOPE" || true

echo "==> vinculando ao projeto '$PROJECT' (scope $SCOPE)"
npx vercel link --yes --scope "$SCOPE" --project "$PROJECT"

echo "==> vínculo gravado:"
cat .vercel/project.json || true

# --prod publica o diretório atual (build/web) como raiz do deployment.
echo "==> deploy de produção"
npx vercel deploy --prod --yes --scope "$SCOPE"

echo
echo "Pronto. Confirme em: https://$PROJECT.vercel.app"
echo "Na primeira visita force Ctrl+Shift+R — o vercel.json já manda no-store"
echo "nos pontos de entrada, mas um service worker antigo pode teimar uma vez."
