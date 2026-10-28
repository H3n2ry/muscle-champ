#!/usr/bin/env bash
#
# Build + versionamento da fonte + deploy + conferência, nessa ordem, e para no
# primeiro passo que falhar.
#
#   bash tool/publicar_web.sh
#
# ## Por que existe
#
# O `wrangler pages deploy` publica o que estiver em `build/web`, compilado
# agora ou não. Um build que falha deixa lá o anterior (ou um pela metade), e o
# deploy sobe isso sem reclamar.
#
# Em 06/10/2026 o build falhou num passo depois de compilar, e o deploy subiu
# mesmo assim: a checagem era `flutter build ... | grep -E "Built build|Error"`,
# e o grep devolve SUCESSO quando acha a linha de erro. Produção ficou certa por
# sorte — o main.dart.js já tinha sido escrito. Aqui o build é julgado pelo
# código de saída do próprio flutter, não por texto filtrado.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

passo() { printf '\n── %s\n' "$1"; }

# ## Só o master, e só o que já está no GitHub
#
# Desde 28/10/2026 produção reflete apenas o master revisado (PR aceito).
# Testar mudança é com tool/publicar_preview.sh, que vai para um endereço de
# teste e para o Supabase de teste.
passo "conferir origem"
branch="$(git rev-parse --abbrev-ref HEAD)"
[ "$branch" = "master" ] || { echo "está em '$branch'. Produção só sai do master (para testar: tool/publicar_preview.sh)."; exit 1; }
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "há mudanças não commitadas — não publico."; exit 1; }
git fetch -q origin master
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/master)" ] || { echo "master local difere do origin/master — faça pull/push antes."; exit 1; }

passo "build"
# Sem pipe: com `| grep`, o código de saída seria o do grep, não o do flutter.
flutter build web --release

for f in main.dart.js flutter_bootstrap.js index.html assets/FontManifest.json; do
  [ -s "build/web/$f" ] || { echo "faltando build/web/$f — não publico"; exit 1; }
done

passo "versionar a fonte de ícones"
dart run tool/versionar_fonte_de_icones.dart

passo "deploy"
npx wrangler pages deploy build/web --project-name=muscle-champ --branch=main --commit-dirty=true

passo "conferência no domínio final"
servido="$(mktemp)"
trap 'rm -f "$servido"' EXIT
local_h="$(sha256sum build/web/main.dart.js | cut -c1-16)"
echo "local : $local_h"
# Logo depois do deploy o domínio ainda pode servir o bundle anterior por
# alguns segundos — em 06/10/2026 a primeira leitura divergiu e a seguinte já
# batia. Por isso tenta algumas vezes antes de acusar.
for tentativa in 1 2 3 4 5 6; do
  curl -sS -o "$servido" https://musclechamp.com.br/main.dart.js
  no_ar_h="$(sha256sum "$servido" | cut -c1-16)"
  echo "no ar : $no_ar_h (tentativa $tentativa)"
  if [ "$local_h" = "$no_ar_h" ]; then
    echo "publicado e conferido."
    exit 0
  fi
  sleep 5
done
echo "DIVERGE — passados 30s, o domínio ainda serve outro bundle (cache de borda?)."
exit 1
