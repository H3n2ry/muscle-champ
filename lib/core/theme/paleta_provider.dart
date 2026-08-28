import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_colors.dart';
import 'paleta.dart';

/// Cor de acento escolhida, guardada na CONTA.
///
/// Segue o usuário entre aparelhos: quem escolhe rosa no celular abre o PC em
/// rosa. O cache local existe só para o app já pintar certo no primeiro frame —
/// esperar a rede para saber a cor faria a tela abrir verde e piscar.
final paletaProvider =
    NotifierProvider<PaletaNotifier, Paleta>(PaletaNotifier.new);

class PaletaNotifier extends Notifier<Paleta> {
  @override
  Paleta build() {
    // Quem já aplicou a cor foi o `main()`, antes do primeiro frame.
    _ouvirSessao();
    return AppColors.paleta;
  }

  /// Troca a cor: pinta agora, salva depois.
  ///
  /// A ordem importa. Gravar primeiro e pintar no retorno deixaria o toque sem
  /// resposta pelo tempo de uma ida ao servidor.
  Future<void> trocar(Paleta nova) async {
    if (nova.id == state.id) return;

    AppColors.paleta = nova;
    state = nova;
    repintarTudo();

    await PaletaStore.salvar(nova);
  }

  void _ouvirSessao() {
    final auth = Supabase.instance.client.auth;

    final inscricao = auth.onAuthStateChange.listen((evento) async {
      switch (evento.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.initialSession:
          await _puxarDaConta();
        case AuthChangeEvent.signedOut:
          // Volta ao padrão: sem isto a próxima conta a entrar neste aparelho
          // herdaria a cor da anterior até a primeira leitura terminar.
          _aplicar(Paleta.limao);
        default:
          break;
      }
    });

    ref.onDispose(inscricao.cancel);
  }

  Future<void> _puxarDaConta() async {
    final daConta = await PaletaStore.daConta();
    if (daConta != null) _aplicar(daConta);
  }

  void _aplicar(Paleta p) {
    if (p.id == AppColors.paleta.id) return;
    AppColors.paleta = p;
    state = p;
    repintarTudo();
  }
}

/// Onde a cor mora: `profiles.tema` é a verdade, SharedPreferences é o cache.
class PaletaStore {
  PaletaStore._();

  /// Por usuário, como todas as chaves locais do app — senão duas contas no
  /// mesmo navegador pintariam uma a cor da outra.
  static String _chave(String uid) => 'tema_app_$uid';

  static SupabaseClient get _sb => Supabase.instance.client;

  /// Lê o cache e aplica, antes do primeiro frame. Chamada pelo `main()`.
  ///
  /// Silenciosa em qualquer falha: um app sem cor salva é um app na cor
  /// padrão, não um app que não abre.
  static Future<void> aplicarDoCache() async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null) return;
      final prefs = await SharedPreferences.getInstance();
      AppColors.paleta = Paleta.doId(prefs.getString(_chave(uid)));
    } catch (_) {}
  }

  /// Cor gravada na conta, ou `null` se não deu para ler.
  static Future<Paleta?> daConta() async {
    try {
      final uid = _sb.auth.currentUser?.id;
      if (uid == null) return null;

      final linha = await _sb
          .from('profiles')
          .select('tema')
          .eq('id', uid)
          .maybeSingle();
      if (linha == null) return null;

      final p = Paleta.doId(linha['tema'] as String?);
      // Reescreve o cache: é aqui que o aparelho aprende a escolha feita no
      // outro.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chave(uid), p.id);
      return p;
    } catch (_) {
      return null;
    }
  }

  /// Grava nos dois lugares. O cache primeiro: ele é o que salva a próxima
  /// abertura do app se a rede estiver fora.
  static Future<void> salvar(Paleta p) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chave(uid), p.id);
    } catch (_) {}

    try {
      await _sb.from('profiles').update({'tema': p.id}).eq('id', uid);
    } catch (_) {
      // Fica só no aparelho até a próxima troca. Preferir isso a mostrar erro:
      // a cor já mudou na tela e o usuário conseguiu o que queria.
    }
  }
}

/// Manda a árvore inteira reconstruir, preservando estado.
///
/// As cores são um `static` em [AppColors] — nenhum widget "assiste" a elas,
/// então trocar o valor não repinta nada sozinho. Só reconstruir o
/// `MaterialApp` também não resolve: as páginas vivem dentro de `Route`s que o
/// `Navigator` segura, e elas não reconstroem por causa de um pai novo.
///
/// A alternativa óbvia — trocar a `key` do app e remontar — apagaria o estado
/// de todo mundo, e a troca de cor acontece no fim da página de perfil: o
/// usuário voltaria para o topo a cada cor experimentada.
///
/// Marcar cada elemento como sujo reconstrói tudo e mantém `State`, rolagem e
/// controladores de texto no lugar.
void repintarTudo() {
  void marcar(Element el) {
    el.markNeedsBuild();
    el.visitChildren(marcar);
  }

  final raiz = WidgetsBinding.instance.rootElement;
  if (raiz != null) marcar(raiz);
}
