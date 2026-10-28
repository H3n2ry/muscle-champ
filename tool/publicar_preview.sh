#!/usr/bin/env bash
#
# Publica a web num endereço de TESTE, ligada ao Supabase de TESTE.
# Produção (musclechamp.com.br e o banco jryetjysjiyuuoznaejc) não é tocada.
#
#   bash tool/publicar_preview.sh                # nome = branch atual
#   bash tool/publicar_preview.sh corrige-login  # nome escolhido
#
# Sai em https://<nome>.muscle-champ.pages.dev — o Cloudflare Pages trata
# qualquer --branch diferente de `main` como preview, sem mexer no domínio.
#
# Para publicar em produção o caminho continua sendo tool/publicar_web.sh, e
# ele só roda a partir do master já enviado ao GitHub.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

passo() { printf '\n── %s\n' "$1"; }

# shellcheck disable=SC1091
source tool/ambiente_de_teste.env

bruto="${1:-$(git rev-parse --abbrev-ref HEAD)}"
# Mesma regra do Cloudflare para o apelido: minúsculas, só [a-z0-9-], até 28.
nome="$(printf '%s' "$bruto" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' | cut -c1-28 | sed -E 's/-+$//')"
case "$nome" in
  ""|main|master|production|producao)
    echo "nome de preview inválido: '$nome' (seria produção). Passe outro nome."
    exit 1 ;;
esac

passo "build (Supabase de teste)"
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL_TESTE" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY_TESTE"

for f in main.dart.js flutter_bootstrap.js index.html assets/FontManifest.json; do
  [ -s "build/web/$f" ] || { echo "faltando build/web/$f — não publico"; exit 1; }
done
# Conferência de que o build saiu apontando para o teste, e não para produção.
grep -q "$SUPABASE_REF_TESTE" build/web/main.dart.js \
  || { echo "o bundle não contém o projeto de teste — não publico"; exit 1; }

passo "versionar a fonte de ícones"
dart run tool/versionar_fonte_de_icones.dart

passo "deploy de preview"
npx wrangler pages deploy build/web --project-name=muscle-champ --branch="$nome" --commit-dirty=true

url="https://$nome.muscle-champ.pages.dev"
passo "conferência em $url"
servido="$(mktemp)"
trap 'rm -f "$servido"' EXIT
local_h="$(sha256sum build/web/main.dart.js | cut -c1-16)"
for tentativa in 1 2 3 4 5 6; do
  curl -sS -o "$servido" "$url/main.dart.js" || true
  no_ar_h="$(sha256sum "$servido" | cut -c1-16)"
  if [ "$local_h" = "$no_ar_h" ]; then
    echo "preview no ar: $url"
    exit 0
  fi
  sleep 5
done
echo "DIVERGE — $url ainda não serve o bundle novo depois de 30s."
exit 1
