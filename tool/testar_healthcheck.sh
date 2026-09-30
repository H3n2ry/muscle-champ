#!/usr/bin/env bash
#
# Testa o script de .github/workflows/ai-healthcheck.yml sem chamar a rede.
#
#   bash tool/testar_healthcheck.sh
#
# ## Por que isto existe
#
# O healthcheck falhou 34 vezes seguidas, todo dia, desde o dia em que nasceu
# (27/08 a 30/09/2026) — e ninguém percebeu que o problema era ELE, porque um
# monitor que falha parece estar fazendo o trabalho dele.
#
# A causa: o GitHub roda todo `run:` com `bash -e`, e `grep` retorna 1 quando
# não acha. Numa resposta SAUDÁVEL o cabeçalho `x-model-fallback` não existe,
# então o grep dele derrubava o script antes do primeiro `echo`. Resposta boa
# morria numa linha, resposta ruim na outra — não havia caminho que passasse.
#
# Nada disso exigia rede para ser descoberto. Exigia rodar o script uma vez.
#
# ## Como funciona
#
# Extrai o bloco `run:` do YAML e o executa sob `bash -e`, o mesmo shell do
# runner, com dublês no lugar do `curl` e do `jq`. Cada cenário fixa os
# cabeçalhos, o corpo e o código HTTP, e cobra o código de saída esperado.

set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
YML="$RAIZ/.github/workflows/ai-healthcheck.yml"
BLOCO="$(mktemp)"
trap 'rm -f "$BLOCO"' EXIT

# Tira o conteúdo de `run: |` e desindenta os 10 espaços do YAML.
python -c '
import io, sys
y = io.open(sys.argv[1], encoding="utf-8").read()
b = y.split("        run: |\n", 1)[1]
io.open(sys.argv[2], "w", encoding="utf-8", newline="\n").write(
    "\n".join(l[10:] if l.startswith(" " * 10) else l for l in b.split("\n")))
' "$YML" "$BLOCO"

# Dublê do curl: escreve o cenário nos arquivos que o script espera.
curl() {
  local h="" b=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -D) h="$2"; shift 2 ;;
      -o) b="$2"; shift 2 ;;
      *)  shift ;;
    esac
  done
  [ -n "$h" ] && printf '%s' "$CENARIO_HEADERS" > "$h"
  [ -n "$b" ] && printf '%s' "$CENARIO_BODY" > "$b"
  printf '%s' "$CENARIO_CODE"
}

# Dublê do jq: cobre só os dois filtros que o workflow usa. O runner do GitHub
# tem jq; a máquina de quem desenvolve normalmente não.
jq() {
  local filtro="" arquivo=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -r) shift ;;
      *)  if [ -z "$filtro" ]; then filtro="$1"; else arquivo="$1"; fi; shift ;;
    esac
  done
  python -c 'import json,sys
try:
    c = json.load(open(sys.argv[1]))["choices"][0]
    print(c["message"]["content"] if "content" in sys.argv[2] else c["finish_reason"])
except Exception:
    print("")' "$arquivo" "$filtro"
}

FALHOU=0

cenario() {
  local nome="$1" esperado="$2" saida rc
  saida=$(bash -e -c "$(declare -f curl jq); source '$BLOCO'" 2>&1)
  rc=$?
  if [ "$rc" = "$esperado" ]; then
    printf '  ok    %-38s (saiu %s)\n' "$nome" "$rc"
  else
    printf '  FALHA %-38s (esperado %s, saiu %s)\n' "$nome" "$esperado" "$rc"
    printf '%s\n' "$saida" | sed 's/^/          /'
    FALHOU=1
  fi
}

corpo_ok='{"choices":[{"message":{"content":"OK"},"finish_reason":"stop"}]}'

echo "cenários:"

# ⚠️ O caso que derrubava tudo: saudável, e portanto SEM x-model-fallback.
CENARIO_CODE=200 CENARIO_BODY="$corpo_ok" \
CENARIO_HEADERS=$'HTTP/2 200\r\nx-model-used: gpt-oss-120b\r\nx-model-primary: gpt-oss-120b\r\n' \
cenario "saudável (sem cabeçalho de fallback)" 0

# Respondeu o reserva por causa de 429 — é aviso, não falha: o fallback fez o
# trabalho dele, e falhar aqui viraria alarme falso em pico de uso.
CENARIO_CODE=200 CENARIO_BODY="$corpo_ok" \
CENARIO_HEADERS=$'HTTP/2 200\r\nx-model-used: qwen3.6-27b\r\nx-model-primary: gpt-oss-120b\r\n' \
cenario "reserva por 429 (só avisa)" 0

# Fallback ativo: o primário morreu de verdade. É o alarme que importa.
CENARIO_CODE=200 CENARIO_BODY="$corpo_ok" \
CENARIO_HEADERS=$'HTTP/2 200\r\nx-model-used: qwen3.6-27b\r\nx-model-fallback: gpt-oss-120b\r\nx-model-primary: gpt-oss-120b\r\n' \
cenario "fallback ativo" 1

# 200 com content vazio: a falha SILENCIOSA que motivou o workflow existir.
CENARIO_CODE=200 \
CENARIO_BODY='{"choices":[{"message":{"content":""},"finish_reason":"length"}]}' \
CENARIO_HEADERS=$'HTTP/2 200\r\nx-model-used: gpt-oss-120b\r\nx-model-primary: gpt-oss-120b\r\n' \
cenario "200 com content vazio" 1

CENARIO_CODE=500 CENARIO_BODY='{"error":"boom"}' \
CENARIO_HEADERS=$'HTTP/2 500\r\n' \
cenario "HTTP 500" 1

# curl não respondeu nada: rede, DNS, ou projeto Supabase pausado.
CENARIO_CODE="" CENARIO_BODY="" CENARIO_HEADERS="" \
cenario "sem resposta HTTP" 1

echo
if [ "$FALHOU" = 0 ]; then
  echo "todos os cenários passaram"
else
  echo "HÁ CENÁRIO FALHANDO"
fi
exit "$FALHOU"
