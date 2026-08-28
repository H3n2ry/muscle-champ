/// Paywall — escolha de plano.
///
/// ⚠️ DEMONSTRAÇÃO. Existe para ajustar layout e, principalmente, COPY: preço
/// é decisão de mão única (subir assinatura com base ativa no Play é caro), e
/// a redação tem regra do CDC em cima. Ver `VALORES.md` §3.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/legal/legal_documents.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/legal_document_sheet.dart';
import '../../data/models/plano.dart';
import '../widgets/demo_banner.dart';

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  Plano _selecionado = Planos.anual;

  String get _dataDaPrimeiraCobranca {
    final d = DateTime.now().add(const Duration(days: Planos.diasDeTrial));
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withOpacity(0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const DemoBanner(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Cabeçalho ────────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.pop(),
                            child: Text(l.pro_agoraNao,
                                style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant)),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.workspace_premium,
                                  color: AppColors.onPrimary, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.pro_titulo,
                                    style: AppTypography.headlineMd
                                        .copyWith(height: 1)),
                                Text(l.pro_pro,
                                    style: AppTypography.display.copyWith(
                                      fontSize: 30,
                                      color: AppColors.primary,
                                      height: 1,
                                    )),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(l.pro_subtitulo,
                            style: AppTypography.bodyLg
                                .copyWith(color: AppColors.onSurfaceVariant)),

                        const SizedBox(height: 28),

                        // ── Benefícios ───────────────────────────────
                        _Rotulo(l.pro_oQueLibera),
                        const SizedBox(height: 12),
                        _Beneficio(
                            icone: Icons.photo_camera_outlined,
                            titulo: l.pro_benefFoto,
                            descricao: l.pro_benefFotoDesc),
                        _Beneficio(
                            icone: Icons.restaurant_menu,
                            titulo: l.pro_benefDieta,
                            descricao: l.pro_benefDietaDesc),
                        _Beneficio(
                            icone: Icons.fitness_center,
                            titulo: l.pro_benefTreino,
                            descricao: l.pro_benefTreinoDesc),
                        _Beneficio(
                            icone: Icons.timeline,
                            titulo: l.pro_benefHistorico,
                            descricao: l.pro_benefHistoricoDesc),

                        const SizedBox(height: 28),

                        // ── Planos ───────────────────────────────────
                        _Rotulo(l.pro_escolhaPlano),
                        const SizedBox(height: 12),
                        for (final p in Planos.todos) ...[
                          _CartaoDePlano(
                            plano: p,
                            selecionado: _selecionado.id == p.id,
                            onTap: () => setState(() => _selecionado = p),
                          ),
                          const SizedBox(height: 10),
                        ],

                        const SizedBox(height: 18),

                        // ── Aviso de cobrança ────────────────────────
                        // A ordem importa: primeiro QUANDO cobra, depois
                        // QUANTO passa a custar, depois COMO cancelar.
                        // É o que o CDC pede que apareça antes do botão,
                        // não escondido depois dele.
                        _AvisoDeCobranca(
                          plano: _selecionado,
                          dataPrimeiraCobranca: _dataDaPrimeiraCobranca,
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => context.push('/assinatura/pagamento',
                                extra: _selecionado),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l.pro_comecarTrial(Planos.diasDeTrial),
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
                          child: TextButton(
                            onPressed: () {},
                            child: Text(l.pro_restaurar,
                                style: AppTypography.bodySm.copyWith(
                                    color: AppColors.onSurfaceVariant)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Aviso de cobrança ────────────────────────────────────────────────────────

class _AvisoDeCobranca extends StatelessWidget {
  final Plano plano;
  final String dataPrimeiraCobranca;
  const _AvisoDeCobranca(
      {required this.plano, required this.dataPrimeiraCobranca});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _linha(
            Icons.event_available_outlined,
            l.pro_avisoTrial(
              Planos.diasDeTrial,
              formatarBRL(plano.entrada),
              dataPrimeiraCobranca,
            ),
          ),
          const SizedBox(height: 8),
          _linha(
            Icons.autorenew,
            // Nunca "de R$ 149,90 por R$ 119,90": o preço cheio jamais é
            // cobrado na entrada, e anunciar assim é preço de referência
            // artificial — propaganda enganosa pelo CDC. Dizer os dois
            // valores no papel que cada um tem resolve.
            plano.precisaAvisarRenovacao
                ? l.pro_avisoRenovacao(
                    formatarBRL(plano.entrada), formatarBRL(plano.renovacao))
                : l.pro_avisoRenovacaoSimples(formatarBRL(plano.renovacao)),
          ),
          const SizedBox(height: 8),
          _linha(Icons.cancel_outlined, l.pro_avisoCancelar),
          const SizedBox(height: 10),
          // Termos e Privacidade no ponto da compra, não escondidos no perfil.
          // A seção 5 dos Termos é a que descreve renovação, cancelamento e o
          // direito de arrependimento — é aqui que ela precisa estar à mão.
          const _LinksLegais(),
        ],
      ),
    );
  }

  Widget _linha(IconData i, String texto) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, size: 15, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant, height: 1.45)),
          ),
        ],
      );
}

/// "Ao assinar você aceita os Termos e a Privacidade", com os dois abrindo o
/// documento de verdade — o mesmo `LegalDocumentSheet` do cadastro, em modo
/// leitura (sem botão de aceite: aceitar acontece ao confirmar a assinatura).
class _LinksLegais extends StatelessWidget {
  const _LinksLegais();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final base = AppTypography.bodySm.copyWith(
      color: AppColors.onSurfaceVariant,
      fontSize: 11,
      height: 1.45,
    );
    final link = base.copyWith(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
    );

    // A frase traduzida tem os dois links no meio, e a ordem muda entre
    // idiomas. Substituo cada um por uma sentinela que não aparece em texto
    // e corto por ela — assim cada língua mantém a própria gramática, em vez
    // de eu concatenar pedaços numa ordem fixa que só serve ao português.
    const marcaTermos = '\u0001';
    const marcaPrivacidade = '\u0002';
    final modelo = l.pro_aoAssinarAceita(marcaTermos, marcaPrivacidade);

    final spans = <InlineSpan>[];
    final buffer = StringBuffer();

    void despejar() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(text: buffer.toString()));
      buffer.clear();
    }

    for (final ch in modelo.split('')) {
      final ehTermos = ch == marcaTermos;
      if (!ehTermos && ch != marcaPrivacidade) {
        buffer.write(ch);
        continue;
      }
      despejar();
      spans.add(TextSpan(
        text: ehTermos
            ? l.privacidade_termosUso
            : l.privacidade_politicaPrivacidade,
        style: link,
        recognizer: TapGestureRecognizer()
          ..onTap = () => LegalDocumentSheet.show(
                context,
                ehTermos ? LegalDocuments.terms : LegalDocuments.privacy,
                showAcceptButton: false,
              ),
      ));
    }
    despejar();

    return Text.rich(TextSpan(style: base, children: spans));
  }
}

// ── Cartão de plano ──────────────────────────────────────────────────────────

class _CartaoDePlano extends StatelessWidget {
  final Plano plano;
  final bool selecionado;
  final VoidCallback onTap;

  const _CartaoDePlano({
    required this.plano,
    required this.selecionado,
    required this.onTap,
  });

  String _nome(L l) => switch (plano.periodo) {
        Periodicidade.mensal => l.pro_periodoMensal,
        Periodicidade.trimestral => l.pro_periodoTrimestral,
        Periodicidade.anual => l.pro_periodoAnual,
      };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final economia = plano.economiaAnualContra(Planos.mensal);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selecionado
              ? AppColors.primary.withOpacity(0.10)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selecionado
                ? AppColors.primary
                : AppColors.surfaceContainerHigh,
            width: selecionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _Radio(selecionado: selecionado),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_nome(l),
                          style: AppTypography.labelMd.copyWith(
                            color: selecionado
                                ? AppColors.primary
                                : AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          )),
                      if (plano.destaque) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(l.pro_maisPopular,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(l.pro_porMes(formatarBRL(plano.porMes)),
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  if (economia > 0) ...[
                    const SizedBox(height: 2),
                    Text(l.pro_economia(formatarBRL(economia)),
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.primary,
                          fontSize: 11,
                        )),
                  ],
                ],
              ),
            ),
            Text(formatarBRL(plano.entrada),
                style: AppTypography.headlineSm.copyWith(
                  color:
                      selecionado ? AppColors.primary : AppColors.onSurface,
                )),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selecionado;
  const _Radio({required this.selecionado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selecionado ? AppColors.primary : AppColors.outline,
          width: 2,
        ),
      ),
      child: selecionado
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
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

class _Beneficio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;

  const _Beneficio({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: AppTypography.bodyMd
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(descricao,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
