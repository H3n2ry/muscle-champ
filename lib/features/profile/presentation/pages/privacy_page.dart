import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/legal/legal_documents.dart';
import '../../../../core/legal/legal_texts.dart';
import '../../../../core/legal/privacy_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/legal_document_sheet.dart';
import '../../../../shared/widgets/mk_snack.dart';

/// Central de privacidade — exercício dos direitos do titular.
///
/// LGPD Art. 18 · GDPR Art. 15-22 · Google Play (Data deletion).
class PrivacyPage extends ConsumerStatefulWidget {
  const PrivacyPage({super.key});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  bool _exporting = false;
  bool _deleting  = false;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) MkSnack.error(context, 'Não foi possível abrir $url');
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final json = await ref.read(privacyRepositoryProvider).exportAndShare();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => _ExportResultDialog(json: json),
      );
    } catch (e) {
      if (mounted) MkSnack.error(context, 'Falha ao exportar: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(privacyRepositoryProvider).deleteMyAccount();
      if (!mounted) return;
      context.go('/login');
      MkSnack.success(context, 'Conta e dados excluídos.');
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        MkSnack.error(context, 'Falha ao excluir: $e');
      }
    }
  }

  Future<void> _toggleConsent(String type, bool value) async {
    final repo = ref.read(privacyRepositoryProvider);
    try {
      value ? await repo.grantConsent(type) : await repo.revokeConsent(type);
      ref.invalidate(myConsentsProvider);
    } catch (e) {
      if (mounted) MkSnack.error(context, 'Não foi possível atualizar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final consents = ref.watch(myConsentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacidade e dados'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _Section(
            title: 'DOCUMENTOS',
            children: [
              _LinkTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Política de Privacidade',
                onTap: () => LegalDocumentSheet.show(
                    context, LegalDocuments.privacy,
                    showAcceptButton: false),
              ),
              _LinkTile(
                icon: Icons.description_outlined,
                label: 'Termos de Uso',
                onTap: () => LegalDocumentSheet.show(
                    context, LegalDocuments.terms,
                    showAcceptButton: false),
              ),
              _LinkTile(
                icon: Icons.open_in_browser,
                label: 'Ver no navegador',
                onTap: () => _open(LegalTexts.privacyUrl),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _Section(
            title: 'SEUS CONSENTIMENTOS',
            children: [
              consents.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Não foi possível carregar: $e',
                      style: AppTypography.bodySm),
                ),
                data: (map) => Column(
                  children: [
                    for (final item in LegalTexts.signupConsents)
                      _ConsentTile(
                        item: item,
                        status: map[item.type],
                        onChanged: item.required
                            ? null
                            : (v) => _toggleConsent(item.type, v),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _Section(
            title: 'SEUS DIREITOS',
            children: [
              _ActionTile(
                icon: Icons.download_outlined,
                label: 'Baixar meus dados',
                detail:
                    'Exporta tudo que guardamos sobre você em JSON — perfil, '
                    'treinos, dieta, peso, pontos e consentimentos.',
                busy: _exporting,
                onTap: _export,
              ),
              _ActionTile(
                icon: Icons.delete_forever_outlined,
                label: 'Excluir minha conta',
                detail:
                    'Apaga a conta e todos os dados permanentemente. '
                    'Não há como desfazer.',
                danger: true,
                busy: _deleting,
                onTap: _confirmDelete,
              ),
            ],
          ),

          const SizedBox(height: 24),
          _Section(
            title: 'CONTATO',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Para dúvidas ou pedidos sobre seus dados, fale com o '
                      'encarregado de proteção de dados:',
                      style: AppTypography.bodySm,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      LegalTexts.privacyEmail,
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Text(
            '${LegalTexts.generalHealthDisclaimer}\n\n'
            'Versão dos documentos: ${LegalTexts.documentVersion}',
            style: AppTypography.bodySm,
          ),
        ],
      ),
    );
  }
}

// ── Diálogos ───────────────────────────────────────────────────────────────

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  static const _phrase = 'EXCLUIR';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _controller.text.trim().toUpperCase() == _phrase;

    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLow,
      title: Text('Excluir conta', style: AppTypography.headlineSm),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Isto apaga permanentemente:\n\n'
            '• Perfil, foto e metas\n'
            '• Histórico de peso e bioimpedância\n'
            '• Treinos, modelos e conclusões\n'
            '• Registros de dieta e água\n'
            '• Pontos, ranking e amizades\n\n'
            'Não há backup e não há como desfazer.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: 16),
          Text('Digite $_phrase para confirmar:', style: AppTypography.bodySm),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: _phrase),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: canDelete ? () => Navigator.of(context).pop(true) : null,
          child: Text(
            'Excluir',
            style: TextStyle(
              color: canDelete ? AppColors.error : AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportResultDialog extends StatelessWidget {
  final String json;
  const _ExportResultDialog({required this.json});

  @override
  Widget build(BuildContext context) {
    final sizeKb = (json.length / 1024).toStringAsFixed(1);

    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLow,
      title: Text('Seus dados', style: AppTypography.headlineSm),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Exportação gerada — $sizeKb KB de JSON.',
              style: AppTypography.bodySm),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(json, style: AppTypography.code),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: json));
            Navigator.of(context).pop();
          },
          child: const Text('Copiar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

// ── Blocos de UI ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppTypography.labelSm),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LinkTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurfaceVariant),
      title: Text(label, style: AppTypography.bodyMd),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: onTap,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final bool danger;
  final bool busy;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.busy,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.onSurface;
    return ListTile(
      leading: busy
          ? const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(icon, color: color),
      title: Text(label, style: AppTypography.bodyMd.copyWith(color: color)),
      subtitle: Text(detail, style: AppTypography.bodySm),
      isThreeLine: true,
      onTap: busy ? null : onTap,
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final ConsentItem item;
  final ConsentStatus? status;
  final ValueChanged<bool>? onChanged;

  const _ConsentTile({
    required this.item,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final granted = status?.granted ?? false;

    return SwitchListTile(
      value: granted,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      title: Text(item.label, style: AppTypography.bodyMd),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.detail, style: AppTypography.bodySm),
          if (item.required)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Obrigatório para usar o app — para retirar, exclua a conta.',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          if (status != null && status!.isStale)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Aceito na versão ${status!.documentVersion} — os documentos '
                'mudaram desde então.',
                style: AppTypography.bodySm.copyWith(color: AppColors.warning),
              ),
            ),
        ],
      ),
      isThreeLine: true,
    );
  }
}
