/// Checkout — SIMULAÇÃO.
///
/// Os campos de cartão existem só para o layout poder ser avaliado. Eles vêm
/// preenchidos com o número de teste 4111 1111 1111 1111, não saem do
/// aparelho e não são gravados em lugar nenhum.
///
/// ⚠️ Em produção esta tela não existe no Android: assinatura de conteúdo
/// digital tem que passar pelo Google Play Billing, que abre a folha de
/// pagamento do próprio Play. O que sobra daqui é a versão web, e mesmo essa
/// precisa de um gateway com confirmação por webhook no servidor — cliente
/// nunca decide que pagou.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/plano.dart';
import '../providers/assinatura_provider.dart';
import '../widgets/demo_banner.dart';

enum _Forma { cartao, pix }

class PagamentoPage extends ConsumerStatefulWidget {
  final Plano plano;
  const PagamentoPage({super.key, required this.plano});

  @override
  ConsumerState<PagamentoPage> createState() => _PagamentoPageState();
}

class _PagamentoPageState extends ConsumerState<PagamentoPage> {
  _Forma _forma = _Forma.cartao;
  bool _processando = false;

  // Dados de teste, não de ninguém. 4111… é o número de sandbox universal.
  final _numero = TextEditingController(text: '4111 1111 1111 1111');
  final _nome = TextEditingController(text: 'NOME SOBRENOME');
  final _validade = TextEditingController(text: '12/30');
  final _cvv = TextEditingController(text: '123');

  @override
  void dispose() {
    _numero.dispose();
    _nome.dispose();
    _validade.dispose();
    _cvv.dispose();
    super.dispose();
  }

  String get _dataPrimeiraCobranca {
    final d = DateTime.now().add(const Duration(days: Planos.diasDeTrial));
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _confirmar() async {
    setState(() => _processando = true);
    // Espera artificial: sem ela não dá para avaliar o estado de carregamento,
    // que é justamente onde um checkout real passa mais tempo.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await ref
        .read(assinaturaControllerProvider)
        .assinar(widget.plano);
    if (!mounted) return;
    context.pushReplacement('/assinatura/sucesso', extra: widget.plano);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = widget.plano;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const DemoBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    color: AppColors.onSurface,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(l.pag_titulo,
                      style: AppTypography.headlineMd
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Resumo ───────────────────────────────────────
                    _Rotulo(l.pag_resumo),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.surfaceContainerHigh),
                      ),
                      child: Column(
                        children: [
                          _LinhaResumo(
                            rotulo: l.pag_hoje,
                            valor: l.pag_gratis,
                            destaque: true,
                          ),
                          const Divider(
                              height: 22, color: AppColors.surfaceContainerHigh),
                          _LinhaResumo(
                            rotulo: l.pag_depoisDoTrial(_dataPrimeiraCobranca),
                            valor: formatarBRL(p.entrada),
                          ),
                          if (p.precisaAvisarRenovacao) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l.pro_avisoRenovacao(formatarBRL(p.entrada),
                                    formatarBRL(p.renovacao)),
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Forma de pagamento ───────────────────────────
                    _Rotulo(l.pag_forma),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _AbaForma(
                            icone: Icons.credit_card,
                            rotulo: l.pag_cartao,
                            ativa: _forma == _Forma.cartao,
                            onTap: () =>
                                setState(() => _forma = _Forma.cartao),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AbaForma(
                            icone: Icons.qr_code_2,
                            rotulo: l.pag_pix,
                            ativa: _forma == _Forma.pix,
                            onTap: () => setState(() => _forma = _Forma.pix),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    if (_forma == _Forma.cartao)
                      _FormularioDeCartao(
                        numero: _numero,
                        nome: _nome,
                        validade: _validade,
                        cvv: _cvv,
                      )
                    else
                      _PlaceholderPix(texto: l.pag_pixInstrucao),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _processando ? null : _confirmar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          disabledBackgroundColor:
                              AppColors.surfaceContainerHigh,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _processando
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(l.pag_processando,
                                      style: AppTypography.labelMd.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 14,
                                      )),
                                ],
                              )
                            : Text(
                                l.pag_confirmar,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.onPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline,
                              size: 13, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(l.pag_seguro,
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formulário ───────────────────────────────────────────────────────────────

class _FormularioDeCartao extends StatelessWidget {
  final TextEditingController numero;
  final TextEditingController nome;
  final TextEditingController validade;
  final TextEditingController cvv;

  const _FormularioDeCartao({
    required this.numero,
    required this.nome,
    required this.validade,
    required this.cvv,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Campo(
          rotulo: l.pag_numeroCartao,
          controller: numero,
          teclado: TextInputType.number,
          entradas: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _MascaraDeCartao(),
          ],
        ),
        const SizedBox(height: 14),
        _Campo(rotulo: l.pag_nomeNoCartao, controller: nome),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Campo(
                rotulo: l.pag_validade,
                controller: validade,
                teclado: TextInputType.number,
                entradas: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _MascaraDeValidade(),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Campo(
                rotulo: l.pag_cvv,
                controller: cvv,
                teclado: TextInputType.number,
                entradas: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `4111111111111111` → `4111 1111 1111 1111`.
class _MascaraDeCartao extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue antes, TextEditingValue depois) {
    final digitos = depois.text.replaceAll(' ', '');
    final b = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(digitos[i]);
    }
    final t = b.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// `1230` → `12/30`.
class _MascaraDeValidade extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue antes, TextEditingValue depois) {
    final d = depois.text.replaceAll('/', '');
    final t = d.length <= 2 ? d : '${d.substring(0, 2)}/${d.substring(2)}';
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _Campo extends StatelessWidget {
  final String rotulo;
  final TextEditingController controller;
  final TextInputType? teclado;
  final List<TextInputFormatter>? entradas;

  const _Campo({
    required this.rotulo,
    required this.controller,
    this.teclado,
    this.entradas,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo,
            style: AppTypography.labelSm.copyWith(
              fontSize: 9,
              letterSpacing: 1.5,
              color: AppColors.onSurfaceVariant,
            )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: teclado,
          inputFormatters: entradas,
          style: AppTypography.bodyMd,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.surfaceContainerHigh),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _AbaForma extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final bool ativa;
  final VoidCallback onTap;

  const _AbaForma({
    required this.icone,
    required this.rotulo,
    required this.ativa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: ativa
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                ativa ? AppColors.primary : AppColors.surfaceContainerHigh,
            width: ativa ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone,
                size: 17,
                color:
                    ativa ? AppColors.primary : AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(rotulo,
                style: AppTypography.labelMd.copyWith(
                  fontSize: 13,
                  color: ativa
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPix extends StatelessWidget {
  final String texto;
  const _PlaceholderPix({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        children: [
          Icon(Icons.qr_code_2,
              size: 60, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 14),
          Text(texto,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.45,
              )),
        ],
      ),
    );
  }
}

// ── Peças pequenas ───────────────────────────────────────────────────────────

class _Rotulo extends StatelessWidget {
  final String texto;
  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) => Text(
        texto,
        style: AppTypography.labelSm.copyWith(
          letterSpacing: 2,
          fontSize: 10,
          color: AppColors.onSurfaceVariant,
        ),
      );
}

class _LinhaResumo extends StatelessWidget {
  final String rotulo;
  final String valor;
  final bool destaque;

  const _LinhaResumo({
    required this.rotulo,
    required this.valor,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(rotulo,
              style: AppTypography.bodyMd.copyWith(
                color: destaque
                    ? AppColors.onSurface
                    : AppColors.onSurfaceVariant,
              )),
        ),
        const SizedBox(width: 12),
        Text(valor,
            style: destaque
                ? AppTypography.headlineSm.copyWith(color: AppColors.primary)
                : AppTypography.bodyMd
                    .copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
