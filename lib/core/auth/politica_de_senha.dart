import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

/// Regras de senha do app — fonte única.
///
/// ⚠️ Precisam espelhar EXATAMENTE a política do Supabase Auth
/// (Authentication → Policies): mínimo 8 + minúscula + maiúscula + dígito +
/// símbolo. Qualquer regra a menos aqui deixa o usuário enviar uma senha que o
/// servidor recusa com 422, e ele não descobre o motivo.
///
/// Vive fora das telas porque **duas** definem senha: o cadastro
/// (`register_page.dart`) e a redefinição (`reset_password_page.dart`). Elas
/// nasceram divergentes — a redefinição aceitava 6 caracteres sem exigir
/// classe nenhuma — e o efeito era o pior possível: o GoTrue recusava com 422 e
/// a tela mostrava erro genérico, sem dizer o que faltava. Duplicar as regras
/// numa segunda tela recriaria a divergência na primeira vez que a política
/// mudasse.
///
/// Conjunto de símbolos aceito pelo Supabase:
///   !@#$%^&*()_+-=[]{};':"|<>?,./`~
class PoliticaDeSenha {
  PoliticaDeSenha._();

  static const int minimo = 8;

  static bool temMinimo(String v) => v.length >= minimo;
  static bool temMinuscula(String v) => v.contains(RegExp(r'[a-z]'));
  static bool temMaiuscula(String v) => v.contains(RegExp(r'[A-Z]'));
  static bool temNumero(String v) => v.contains(RegExp(r'[0-9]'));
  static bool temSimbolo(String v) =>
      v.contains(RegExp('[!@#\\\$%^&*()_+\\-=\\[\\]{};\':"|<>?,./`~\\\\]'));

  /// Qual requisito falta, na ordem em que a UI os lista.
  ///
  /// Devolve `null` quando a senha passa. As mensagens ficam com quem chama,
  /// porque dependem do `BuildContext` para traduzir.
  static RequisitoDeSenha? primeiroRequisitoFaltando(String? valor) {
    final s = valor ?? '';
    if (!temMinimo(s)) return RequisitoDeSenha.minimo;
    if (!temMinuscula(s)) return RequisitoDeSenha.minuscula;
    if (!temMaiuscula(s)) return RequisitoDeSenha.maiuscula;
    if (!temNumero(s)) return RequisitoDeSenha.numero;
    if (!temSimbolo(s)) return RequisitoDeSenha.simbolo;
    return null;
  }
}

enum RequisitoDeSenha { minimo, minuscula, maiuscula, numero, simbolo }

/// Validador pronto para `TextFormField.validator`, já traduzido.
///
/// Devolve a mensagem do **primeiro** requisito que falta, para a pessoa
/// corrigir um item por vez em vez de receber uma lista inteira de erros.
String? mensagemDeSenha(BuildContext context, String? valor) {
  final falta = PoliticaDeSenha.primeiroRequisitoFaltando(valor);
  if (falta == null) return null;
  final l = L.of(context);
  switch (falta) {
    case RequisitoDeSenha.minimo:
      return l.senha_errMin8;
    case RequisitoDeSenha.minuscula:
      return l.senha_errMinuscula;
    case RequisitoDeSenha.maiuscula:
      return l.senha_errMaiuscula;
    case RequisitoDeSenha.numero:
      return l.senha_errNumero;
    case RequisitoDeSenha.simbolo:
      return l.senha_errSimbolo;
  }
}
