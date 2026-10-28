# Fluxo de correção sem tocar produção

Produção = o domínio musclechamp.com.br **e** o projeto Supabase
`jryetjysjiyuuoznaejc` (muscle-camp): banco, Edge Functions, secrets, Vault.

Toda correção, feita por pessoa ou por Claude, segue:

1. **Branch + PR.** Nunca commit direto no `master`. Uma branch por problema.
2. **Testar fora de produção**: web no endereço de preview, banco e funções no
   Supabase de teste.
3. **PR para o Henry revisar**, com o link do preview e o que foi testado.
4. **Só depois do merge, e com o "pode publicar" do Henry**, publicar em
   produção.

Sem esse "pode publicar" não se roda: `bash tool/publicar_web.sh`,
`wrangler pages deploy ... --branch=main`, migration ou SQL de escrita no
projeto `jryetjysjiyuuoznaejc`, deploy de Edge Function nele, nem mudança em
secrets/Vault de produção. Ler produção (logs, `select`) para diagnosticar
pode.

O `publicar_web.sh` recusa rodar fora do `master` sincronizado com o GitHub.

## Ambiente de teste

| | Produção | Teste |
|---|---|---|
| Web | musclechamp.com.br | `https://<branch>.muscle-champ.pages.dev` |
| Supabase | `jryetjysjiyuuoznaejc` | `cqnuthoovekdrwzbsltx` (muscle-camp-teste) |
| Publicar web | `tool/publicar_web.sh` (só master) | `tool/publicar_preview.sh [nome]` |

- `tool/publicar_preview.sh` compila com `--dart-define` apontando para o
  Supabase de teste (`tool/ambiente_de_teste.env`) e confere que o bundle
  aponta para o teste antes de subir. Sem os defines, o app usa
  `lib/core/secrets.dart` (produção) como sempre.
- O banco de teste tem só a estrutura, nenhum dado real.
- Migrations e Edge Functions: primeiro no `cqnuthoovekdrwzbsltx`; produção só
  depois do merge e do "pode publicar".
- O plano grátis pausa o projeto de teste após 7 dias sem uso; é só reativar.
- IA no teste precisa dos secrets da Edge Function e da chave no Vault, que
  não são copiados de produção.

## Recriar o banco de teste

Rode no projeto **de teste**: `supabase/espelhar_no_banco_de_teste.sql`
(trocando `COMMIT` pelo commit desejado) e depois
`supabase/espelhar_no_banco_de_teste_extras.sql`. Para conferir, rode
`supabase/gerar_schema.sql` nos dois projetos e compare o MD5.

## Código

- URL/chave do Supabase no código: use `SupabaseConfig`, nunca `Secrets`
  direto, senão o build de teste falaria com produção.
- Modelos de IA: só na `MODEL_CHAINS` do `groq-proxy`. O workflow
  `groq-desligamentos.yml` abre issue quando a Groq marca um deles para sair.
