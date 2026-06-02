# LICENSES.md — Licenças das Dependências
## Muscle Champ · v1.0.0+1

---

## Resumo

Todas as dependências de produção usam licenças permissivas **compatíveis com distribuição comercial** na Play Store e App Store.

| Licença | Contagem | Obrigações |
|---------|----------|-----------|
| MIT | 6 | Manter aviso de copyright no distribuível |
| BSD 3-Clause | 6 | Manter aviso de copyright; não usar nome dos autores para endosso |
| Apache 2.0 | 3 | Manter aviso de copyright + NOTICE se houver; mencionar modificações |

---

## Detalhamento

| Pacote | Versão | Licença | URL |
|--------|--------|---------|-----|
| `supabase_flutter` | ^2.5.0 | Apache 2.0 | https://pub.dev/packages/supabase_flutter/license |
| `flutter_riverpod` | ^2.5.1 | MIT | https://pub.dev/packages/flutter_riverpod/license |
| `go_router` | ^13.2.1 | BSD 3-Clause | https://pub.dev/packages/go_router/license |
| `google_fonts` | ^6.2.1 | Apache 2.0 | https://pub.dev/packages/google_fonts/license |
| `fl_chart` | ^0.67.0 | MIT | https://pub.dev/packages/fl_chart/license |
| `cached_network_image` | ^3.3.1 | MIT | https://pub.dev/packages/cached_network_image/license |
| `image` | ^4.8.0 | Apache 2.0 | https://pub.dev/packages/image/license |
| `shimmer` | ^3.0.0 | MIT | https://pub.dev/packages/shimmer/license |
| `image_picker` | ^1.1.2 | BSD 3-Clause | https://pub.dev/packages/image_picker/license |
| `shared_preferences` | ^2.3.2 | BSD 3-Clause | https://pub.dev/packages/shared_preferences/license |
| `http` | ^1.2.1 | BSD 3-Clause | https://pub.dev/packages/http/license |
| `intl` | ^0.19.0 | BSD 3-Clause | https://pub.dev/packages/intl/license |
| `equatable` | ^2.0.5 | MIT | https://pub.dev/packages/equatable/license |
| Flutter SDK | 3.44+ | BSD 3-Clause | https://github.com/flutter/flutter/blob/master/LICENSE |
| Dart SDK | 3.12+ | BSD 3-Clause | https://github.com/dart-lang/sdk/blob/main/LICENSE |

---

## Fontes (Google Fonts)

O pacote `google_fonts` baixa fontes diretamente do Google Fonts em runtime. As fontes têm licenças individuais — a maioria usa **SIL Open Font License (OFL)** ou **Apache 2.0**.

**Ação recomendada para produção:** Baixar as fontes usadas e incluí-las como assets locais para evitar chamadas externas e garantir disponibilidade offline.

---

## Obrigações Consolidadas

### Para distribuição na Play Store / App Store:
1. Flutter já inclui avisos de copyright nas builds (`--release` não remove obrigações de licença)
2. A Play Store aceita licenças MIT, BSD, Apache 2.0 sem restrições
3. **Apache 2.0 (supabase, image, google_fonts):** Se modificar o código-fonte dessas bibliotecas, indicar as modificações no arquivo NOTICE

### Não há:
- Licenças GPL ou LGPL (que exigiriam open source do app)
- Licenças proprietárias
- Dependências sem manutenção declarada

---

## Como verificar licenças no Flutter

```bash
# Gera arquivo HTML com todas as licenças das dependências
flutter pub deps --style=compact

# Exibir licenças no app (widget nativo do Flutter)
# Adicionar em configurações:
showLicensePage(context: context, applicationName: 'Muscle Champ');
```

**Recomendação:** Adicionar `LicensePage` ou link para ela nas configurações do app — é boa prática e exigida por algumas lojas.
