# BUG_REPORT_TEMPLATE.md — Template para Reportar Bugs
## Muscle Champ

> Copie e preencha este template ao reportar um bug.

---

```markdown
## Descrição do Bug
[Descreva o comportamento incorreto em uma ou duas frases]

## Passos para Reproduzir
1. Abrir o app em [dispositivo/browser]
2. Navegar para [tela]
3. [Ação específica]
4. Observar o comportamento incorreto

## Comportamento Esperado
[O que deveria acontecer]

## Comportamento Atual
[O que está acontecendo de errado]

## Ambiente
- Plataforma: [ ] Android  [ ] Web (Chrome)  [ ] Web (Safari)  [ ] Outro: ___
- Versão do app: 1.0.0+1
- Dispositivo / OS: [ex: Samsung Galaxy A54, Android 14 / iPhone 13, iOS 17]
- Versão do Flutter (se dev): [ex: 3.44.0]

## Frequência
- [ ] Sempre (100%)
- [ ] Frequente (>50%)
- [ ] Ocasional (<50%)
- [ ] Uma vez (não reproduzível)

## Evidências
[Screenshots, vídeo de tela, ou logs do console]

## Logs de Erro (se disponível)
```
Cole aqui o stack trace ou mensagem de erro do console
```

## Severidade
- [ ] 🔴 Crítico — app inutilizável ou perda de dados
- [ ] 🟠 Alto — funcionalidade principal quebrada
- [ ] 🟡 Médio — funcionalidade secundária afetada ou workaround existe
- [ ] 🟢 Baixo — problema cosmético ou de usabilidade menor

## Contexto Adicional
[Qualquer informação extra que possa ajudar — o que você estava fazendo antes, se o bug
apareceu após atualização, etc.]
```

---

## Exemplos de Bugs Reais Já Resolvidos

| Bug | Causa | Solução | Data |
|-----|-------|---------|------|
| IA sempre retornava 150g para qualquer alimento | Placeholders `"weight_g":0` faziam o modelo copiar zeros | Substituir por `PESO_TOTAL_EM_GRAMAS` como descritor | mai/2025 |
| PNG da galeria analisado como JPEG | `_optimizeImage` não detectava MIME de PNG | Detectar via magic bytes `0x89 0x50 0x4E 0x47` | mai/2025 |
| Pratos complexos não identificados | Limite 512px muito pequeno para pratos com muitos itens | Aumentar para 768px + prompt somar todos os itens | mai/2025 |
| Build falhava com caminho `C:\Users\Henry` | Cache `.dart_tool` do dev original | `flutter clean` + deletar `.dart_tool` e `build/` | mai/2025 |
