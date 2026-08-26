# Redirecionamento do Vercel aposentado

O que está publicado em `muscle-champ.vercel.app`: nada além de um **307** para
`muscle-champ.pages.dev`.

Fica versionado porque, quando o Vercel voltar a 404 (já aconteceu uma vez),
não dá para lembrar de cabeça o que estava lá.

```bash
cd tools/vercel-retirado
cp ../../build/web/.vercel/project.json .vercel/project.json   # aponta para o projeto certo
npx vercel --prod --yes --scope "af-dev"
```

> ⚠️ Sem copiar o `project.json`, o Vercel cria um projeto NOVO com o nome da
> pasta em vez de publicar no `muscle-champ`.

## Por que ele quebrou em 26/08

O projeto do Vercel estava **conectado ao GitHub**. Um `git push` para o
`master` disparou deploy automático da raiz do repositório — que não é um site
estático — e o 404 substituiu o redirecionamento.

A integração foi desligada com `npx vercel git disconnect`. Se alguém religar,
todo push volta a quebrar isto.

## Por que 307 e não 308

Redirecionamento permanente fica em cache no navegador e seria difícil de
desfazer se o Vercel voltar a ser necessário.
