import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/i18n/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/paleta_provider.dart';
import 'l10n/app_localizations.dart';

class MuscleCampApp extends ConsumerWidget {
  const MuscleCampApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final appLocale = ref.watch(localeProvider);

    // Observado para o `AppTheme.dark()` abaixo ser remontado com as cores
    // novas. O resto da árvore é repintado pelo `repintarTudo()` do notifier —
    // reconstruir daqui não alcança as páginas, que o Navigator segura.
    ref.watch(paletaProvider);

    // Espelha o idioma para o GroqService, que é estático e não alcança o
    // provider. Sem isso a IA continuaria respondendo em português para quem
    // trocou de idioma.
    AiLocale.atual = appLocale;

    return MaterialApp.router(
      title: 'Muscle Champ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
      locale: appLocale.locale,
      supportedLocales: AppLocale.suportados,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
