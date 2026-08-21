import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../core/legal/legal_documents.dart';
import '../../core/legal/legal_texts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Popup com o texto integral de um documento legal.
///
/// Retorna `true` quando o usuário toca em "LI E ACEITO" — o chamador usa isso
/// para marcar o checkbox correspondente. Fechar sem aceitar retorna `null`.
///
/// O aceite fica no fim do texto de propósito: o usuário precisa rolar até lá,
/// o que sustenta o argumento de que o conteúdo foi apresentado antes do
/// consentimento (LGPD Art. 9 / GDPR Art. 13).
class LegalDocumentSheet extends StatefulWidget {
  final LegalDocument document;

  /// Quando falso, o popup é só leitura (uso na tela de privacidade, onde o
  /// consentimento já foi dado).
  final bool showAcceptButton;

  const LegalDocumentSheet({
    super.key,
    required this.document,
    this.showAcceptButton = true,
  });

  /// Abre o documento e devolve `true` se o usuário aceitou.
  static Future<bool?> show(
    BuildContext context,
    LegalDocument document, {
    bool showAcceptButton = true,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LegalDocumentSheet(
        document: document,
        showAcceptButton: showAcceptButton,
      ),
    );
  }

  @override
  State<LegalDocumentSheet> createState() => _LegalDocumentSheetState();
}

class _LegalDocumentSheetState extends State<LegalDocumentSheet> {
  final _scrollCtrl = ScrollController();
  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // Documento curto o bastante para não rolar → libera o aceite de imediato.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      if (_scrollCtrl.position.maxScrollExtent <= 0) {
        setState(() => _reachedEnd = true);
      }
    });
  }

  void _onScroll() {
    if (_reachedEnd) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 40) {
      setState(() => _reachedEnd = true);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Puxador
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Cabeçalho
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.document.title,
                          style: AppTypography.headlineSm),
                      const SizedBox(height: 2),
                      Text(L.of(context).doc_versao(LegalTexts.documentVersion),
                          style: AppTypography.bodySm.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.onSurfaceVariant,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.surfaceContainerHigh),

          // Corpo
          Flexible(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              itemCount: widget.document.sections.length,
              itemBuilder: (_, i) {
                final s = widget.document.sections[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.heading,
                          style: AppTypography.labelMd
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Text(s.body,
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.onSurface)),
                    ],
                  ),
                );
              },
            ),
          ),

          if (widget.showAcceptButton) ...[
            Divider(height: 1, color: AppColors.surfaceContainerHigh),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 14, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                children: [
                  if (!_reachedEnd)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.keyboard_double_arrow_down,
                              size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(L.of(context).doc_roleAteOFim,
                              style: AppTypography.bodySm
                                  .copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _reachedEnd
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        disabledBackgroundColor:
                            AppColors.surfaceContainerHigh,
                        disabledForegroundColor: AppColors.onSurfaceVariant,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text('LI E ACEITO',
                          style: AppTypography.labelMd.copyWith(
                            color: _reachedEnd
                                ? AppColors.onPrimary
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}
