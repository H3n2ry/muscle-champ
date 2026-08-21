import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Idiomas suportados pelo app.
///
/// Português é a origem: os textos são escritos nele e os outros derivam.
enum AppLocale {
  pt(Locale('pt'), 'Português', 'PT'),
  en(Locale('en'), 'English', 'EN'),
  es(Locale('es'), 'Español', 'ES');

  const AppLocale(this.locale, this.nome, this.sigla);

  final Locale locale;

  /// Nome no próprio idioma — quem procura "Español" não lê "Espanhol".
  final String nome;

  /// Sigla curta, para o seletor compacto.
  final String sigla;

  static AppLocale doCodigo(String? codigo) => AppLocale.values.firstWhere(
        (l) => l.locale.languageCode == codigo,
        orElse: () => AppLocale.pt,
      );

  static List<Locale> get suportados =>
      AppLocale.values.map((l) => l.locale).toList();
}

/// Idioma escolhido, persistido entre sessões.
///
/// A chave NÃO é por usuário: o idioma precisa valer já na tela de login e no
/// cadastro, antes de existir sessão. Trocar de conta no mesmo aparelho mantém
/// o idioma — o que é o comportamento esperado, já que é preferência do
/// aparelho e não do perfil.
final localeProvider =
    NotifierProvider<LocaleNotifier, AppLocale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<AppLocale> {
  static const _chave = 'app_locale';

  @override
  AppLocale build() {
    _carregar();
    // Padrão: idioma do sistema, se for um dos suportados; senão português.
    final doSistema = PlatformDispatcher.instance.locale.languageCode;
    return AppLocale.values.any((l) => l.locale.languageCode == doSistema)
        ? AppLocale.doCodigo(doSistema)
        : AppLocale.pt;
  }

  Future<void> _carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvo = prefs.getString(_chave);
      if (salvo != null) state = AppLocale.doCodigo(salvo);
    } catch (_) {
      // Sem preferência salva o app segue no padrão; não é motivo para falhar.
    }
  }

  Future<void> trocar(AppLocale novo) async {
    state = novo;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chave, novo.locale.languageCode);
    } catch (_) {}
  }
}

/// Idioma corrente para a IA, sem depender de `ref`.
///
/// O GroqService é todo estático e é chamado de dentro de sheets que não têm
/// acesso ao provider. Este espelho é atualizado sempre que o idioma muda,
/// para os prompts pedirem resposta no idioma certo.
class AiLocale {
  AiLocale._();

  static AppLocale atual = AppLocale.pt;

  /// Nome do idioma em inglês — é assim que o modelo entende melhor a
  /// instrução "responda em X".
  static String get nomeParaPrompt => switch (atual) {
        AppLocale.pt => 'Brazilian Portuguese',
        AppLocale.en => 'English',
        AppLocale.es => 'Spanish',
      };

  /// Instrução a acrescentar aos prompts.
  static String get instrucao =>
      'Write every human-readable value in $nomeParaPrompt. '
      'Keep all JSON keys exactly as specified, in English.';
}
