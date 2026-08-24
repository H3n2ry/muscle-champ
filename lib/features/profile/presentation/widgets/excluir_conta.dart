/// Exclusão de conta — caminho único, usado pelo perfil e pela tela de
/// privacidade.
///
/// Fica num arquivo só de propósito. É a ação mais destrutiva do app (LGPD
/// Art. 18 VI / GDPR Art. 17, sem volta e sem backup); duas implementações
/// significariam duas chances de uma delas divergir e apagar errado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/mk_snack.dart';
import '../../../../core/legal/privacy_repository.dart';

/// Pede confirmação e, se confirmada, apaga a conta e volta para o login.
///
/// Devolve `true` quando a exclusão aconteceu — quem chamou pode precisar
/// parar de mexer no próprio estado (a tela vai embora junto com a conta).
Future<bool> excluirContaComConfirmacao(
  BuildContext context,
  WidgetRef ref,
) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (_) => const DialogoExcluirConta(),
  );
  if (confirmou != true || !context.mounted) return false;

  try {
    await ref.read(privacyRepositoryProvider).deleteMyAccount();
    if (!context.mounted) return true;
    // Sai da área logada ANTES do aviso: a sessão já não existe, e qualquer
    // tela que ainda tente ler o perfil quebraria.
    context.go('/login');
    MkSnack.success(context, L.of(context).priv_contaExcluida);
    return true;
  } catch (e) {
    if (context.mounted) {
      MkSnack.error(context, '${L.of(context).priv_falhaExcluir}: $e');
    }
    return false;
  }
}

/// Confirmação por digitação.
///
/// Pedir a palavra escrita, e não um "tem certeza?", é proposital: o toque
/// errado num diálogo de dois botões é fácil demais para algo irreversível.
class DialogoExcluirConta extends StatefulWidget {
  const DialogoExcluirConta({super.key});

  @override
  State<DialogoExcluirConta> createState() => _DialogoExcluirContaState();
}

class _DialogoExcluirContaState extends State<DialogoExcluirConta> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    // A palavra é traduzida: mandar quem usa o app em inglês digitar
    // "EXCLUIR" seria uma barreira acidental num fluxo que já é tenso.
    final palavra = l.priv_palavraConfirmacao;
    final podeExcluir =
        _controller.text.trim().toUpperCase() == palavra.toUpperCase();

    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLow,
      title: Text(l.priv_excluirConta, style: AppTypography.headlineSm),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.priv_apagaPermanentemente +
                l.priv_itemPerfil +
                l.priv_itemPesoBio +
                l.priv_itemTreinos +
                l.priv_itemDieta +
                l.priv_itemPontos +
                l.priv_semBackup,
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: 16),
          Text(l.priv_digiteParaConfirmar(palavra),
              style: AppTypography.bodySm),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: palavra),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.comum_cancelar),
        ),
        TextButton(
          onPressed: podeExcluir ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            l.priv_excluir,
            style: TextStyle(
              color: podeExcluir ? AppColors.error : AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bloco "zona de perigo" para o fim de uma página.
///
/// Separado visualmente e no fim da rolagem: a exclusão precisa ser
/// encontrável — o Google Play exige — sem ficar ao alcance de um toque
/// distraído.
class BlocoExcluirConta extends ConsumerStatefulWidget {
  const BlocoExcluirConta({super.key});

  @override
  ConsumerState<BlocoExcluirConta> createState() => _BlocoExcluirContaState();
}

class _BlocoExcluirContaState extends ConsumerState<BlocoExcluirConta> {
  bool _excluindo = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.priv_apagaConta,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              )),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _excluindo
                  ? null
                  : () async {
                      setState(() => _excluindo = true);
                      await excluirContaComConfirmacao(context, ref);
                      // Se a conta foi apagada esta tela já saiu de cena;
                      // o mounted protege o caso de cancelamento ou falha.
                      if (mounted) setState(() => _excluindo = false);
                    },
              icon: _excluindo
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.error),
                    )
                  : const Icon(Icons.delete_forever_outlined, size: 18),
              label: Text(
                _excluindo ? l.perfil_excluindo : l.perfil_excluirMinhaConta,
                style: AppTypography.labelMd.copyWith(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
