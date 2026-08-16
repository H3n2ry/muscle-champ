#!/usr/bin/env bash
# Build + deploy do app web sempre no MESMO projeto Vercel.
#
# POR QUE ESTE SCRIPT EXISTE
# O fluxo antigo era `cd build/web && npx vercel --prod`. O nome do projeto
# Vercel vinha do `.vercel/project.json` que o CLI grava dentro de build/web —
# e build/ é apagado por `flutter clean` e recriado por cada build. Sem esse
# arquivo, o CLI trata o diretório como projeto novo e usa o nome da PASTA
# ("web"), então o deploy vai para outro projeto e muscle-champ.vercel.app
# fica órfão (404 DEPLOYMENT_NOT_FOUND).
#
# O `vercel link --project` abaixo é idempotente e refaz esse vínculo a cada
# execução, então o destino nunca depende de um arquivo dentro de build/.
#
# Uso (Git Bash):  ./deploy_web.sh
set -euo pipefail

PROJECT="muscle-champ"
SCOPE="af-dev"

cd "$(dirname "$0")"

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

cd build/web

echo "==> vinculando ao projeto '$PROJECT' (scope $SCOPE)"
npx vercel link --yes --scope "$SCOPE" --project "$PROJECT"

echo "==> deploy de produção"
npx vercel deploy --prod --yes --scope "$SCOPE"

echo
echo "Pronto. Confirme em: https://$PROJECT.vercel.app"
echo "Se abrir versão antiga, force com Ctrl+Shift+R (o vercel.json já manda"
echo "no-store nos pontos de entrada, mas o service worker antigo pode teimar)."
