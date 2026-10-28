"""Confere se algum modelo usado pelo groq-proxy está na lista de desligamentos
da Groq. Usado pelo workflow .github/workflows/groq-desligamentos.yml.

    python3 tool/desligamentos_groq.py <pagina.html> <groq-proxy/index.ts>

Imprime um JSON com uma entrada por modelo em uso que aparece como
"Deprecated Model" na página: {"modelo", "desligamento", "substituto"}.

Falha (código 2) quando não reconhece NENHUMA linha de desligamento na página:
significa que o formato mudou, e um monitor que passa calado nesse caso é pior
do que nenhum (foi o que aconteceu com o qwen3.6-27b, descoberto por 503).
"""

import html
import json
import re
import sys
from datetime import datetime

DATA = re.compile(r"\b(\d{2})/(\d{2})/(\d{2})\b")


def modelos_em_uso(fonte_ts: str) -> list[str]:
    bloco = fonte_ts[fonte_ts.index("const MODEL_CHAINS"):]
    bloco = bloco[: bloco.index("\n};") + 3]
    # Só ids de código, não os citados em comentário.
    linhas = [l for l in bloco.splitlines() if not l.strip().startswith("//")]
    return sorted(set(re.findall(r'\bid:\s*"([^"]+)"', "\n".join(linhas))))


def _texto(celula: str) -> str:
    return html.unescape(re.sub(r"<[^>]+>", "", celula)).strip().strip("`").strip()


def linhas_de_desligamento(pagina: str) -> list[tuple[str, str, str]]:
    """(modelo, data MM/DD/YY, substituto), de tabela HTML ou Markdown."""
    linhas = []
    for tr in re.findall(r"<tr[^>]*>(.*?)</tr>", pagina, flags=re.S | re.I):
        cel = [_texto(c) for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", tr, flags=re.S | re.I)]
        if len(cel) >= 2 and DATA.fullmatch(cel[1]):
            linhas.append((cel[0], cel[1], cel[2] if len(cel) > 2 else ""))
    # A página também pode vir em Markdown (ou com o Markdown dentro do payload
    # do Next.js, com \n e \" escapados).
    md = pagina.replace("\\n", "\n").replace('\\"', '"')
    for l in md.splitlines():
        cel = [c.strip().strip("`").strip() for c in l.strip().strip("|").split("|")]
        if len(cel) >= 2 and DATA.fullmatch(cel[1]):
            linhas.append((cel[0], cel[1], cel[2] if len(cel) > 2 else ""))
    return list(dict.fromkeys(linhas))


def main() -> int:
    pagina = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    em_uso = modelos_em_uso(open(sys.argv[2], encoding="utf-8").read())
    linhas = linhas_de_desligamento(pagina)
    if not linhas:
        print("nenhuma linha de desligamento reconhecida — o formato da página mudou?", file=sys.stderr)
        return 2
    print(f"{len(linhas)} desligamentos na página; em uso: {', '.join(em_uso)}", file=sys.stderr)

    achados = []
    for modelo, data, substituto in linhas:
        if modelo in em_uso:
            m, d, a = DATA.fullmatch(data).groups()
            quando = datetime(2000 + int(a), int(m), int(d)).date().isoformat()
            achados.append({"modelo": modelo, "desligamento": quando,
                            "substituto": substituto.replace("`", "") or "(não indicado)"})
    print(json.dumps(achados, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
