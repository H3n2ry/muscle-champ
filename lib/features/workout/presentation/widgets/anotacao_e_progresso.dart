import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/models/historico_de_exercicio_model.dart';
import '../../data/models/workout_template_model.dart';
import '../../data/repositories/workout_template_repository.dart';

// ── Anotação ────────────────────────────────────────────────────────────────

/// Abre a anotação do exercício. Devolve o texto salvo, ou `null` se a pessoa
/// fechou sem salvar.
Future<String?> mostrarAnotacao(
  BuildContext context,
  WidgetRef ref,
  TemplateExerciseModel exercicio,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FolhaDeAnotacao(exercicio: exercicio, ref: ref),
  );
}

class _FolhaDeAnotacao extends StatefulWidget {
  final TemplateExerciseModel exercicio;
  final WidgetRef ref;
  const _FolhaDeAnotacao({required this.exercicio, required this.ref});

  @override
  State<_FolhaDeAnotacao> createState() => _FolhaDeAnotacaoState();
}

class _FolhaDeAnotacaoState extends State<_FolhaDeAnotacao> {
  late final TextEditingController _texto =
      TextEditingController(text: widget.exercicio.anotacao ?? '');
  bool _salvando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await widget.ref
          .read(workoutTemplateRepositoryProvider)
          .salvarAnotacao(widget.exercicio.id, _texto.text);
      if (mounted) Navigator.pop(context, _texto.text.trim());
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não deu para salvar. Tente de novo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Folha(
      titulo: widget.exercicio.name.toUpperCase(),
      subtitulo: 'Anotação',
      children: [
        TextField(
          controller: _texto,
          autofocus: true,
          maxLines: 5,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.bodyMd,
          decoration: InputDecoration(
            hintText: 'Banco na altura 4 · pegada média · não travar o cotovelo',
            hintStyle: AppTypography.bodySm
                .copyWith(color: AppColors.onSurfaceVariant),
            filled: true,
            fillColor: AppColors.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Fica presa ao exercício e aparece toda vez que você fizer ele.',
          style:
              AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: Text(_salvando ? 'SALVANDO…' : 'SALVAR'),
          ),
        ),
      ],
    );
  }
}

// ── Progressão ──────────────────────────────────────────────────────────────

void mostrarProgresso(
  BuildContext context,
  WidgetRef ref,
  TemplateExerciseModel exercicio,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FolhaDeProgresso(exercicio: exercicio, ref: ref),
  );
}

class _FolhaDeProgresso extends StatelessWidget {
  final TemplateExerciseModel exercicio;
  final WidgetRef ref;
  const _FolhaDeProgresso({required this.exercicio, required this.ref});

  @override
  Widget build(BuildContext context) {
    return _Folha(
      titulo: exercicio.name.toUpperCase(),
      subtitulo: 'Progressão',
      children: [
        FutureBuilder<List<HistoricoDeExercicio>>(
          future: ref
              .read(workoutTemplateRepositoryProvider)
              .historicoDoExercicio(exercicio.id),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return _aviso('Não deu para carregar o histórico.');
            }
            final historico = snap.data ?? const [];
            if (historico.isEmpty) return _vazio();
            return _ComHistorico(historico: historico);
          },
        ),
      ],
    );
  }

  Widget _aviso(String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Text(texto,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant)),
      );

  /// O vazio aqui é o estado NORMAL para quem já treinava antes de 11/09/2026 —
  /// o histórico nunca foi guardado, então não há o que mostrar até a próxima
  /// sessão. Dizer isso evita que pareça defeito.
  Widget _vazio() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.show_chart,
                size: 40, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Ainda sem histórico',
                style: AppTypography.labelMd
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'A evolução começa a ser guardada quando você concluir este '
              'treino. Na segunda vez já dá para comparar.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
}

class _ComHistorico extends StatelessWidget {
  final List<HistoricoDeExercicio> historico;
  const _ComHistorico({required this.historico});

  @override
  Widget build(BuildContext context) {
    final primeiro = historico.first;
    final ultimo = historico.last;
    final delta = ultimo.pesoKg - primeiro.pesoKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (historico.length > 1) _resumo(delta),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: CustomPaint(
            painter: _GraficoDeCarga(historico),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 16),
        Text('SESSÕES',
            style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        // Da mais recente para a mais antiga: é como a pessoa procura.
        ...historico.reversed.map(_linha),
      ],
    );
  }

  Widget _resumo(double delta) {
    final subiu = delta > 0;
    final parado = delta == 0;
    return Row(
      children: [
        Icon(
          parado
              ? Icons.trending_flat
              : subiu
                  ? Icons.trending_up
                  : Icons.trending_down,
          size: 18,
          color: parado
              ? AppColors.onSurfaceVariant
              : subiu
                  ? AppColors.primary
                  : AppColors.warning,
        ),
        const SizedBox(width: 6),
        Text(
          parado
              ? 'Mesma carga em ${historico.length} sessões'
              : '${subiu ? '+' : ''}${_kg(delta)} kg em ${historico.length} sessões',
          style: AppTypography.labelMd.copyWith(
            fontWeight: FontWeight.w700,
            color: parado
                ? AppColors.onSurfaceVariant
                : subiu
                    ? AppColors.primary
                    : AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _linha(HistoricoDeExercicio h) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(_dia(h.data),
                  style: AppTypography.bodySm
                      .copyWith(color: AppColors.onSurfaceVariant)),
            ),
            Text('${_kg(h.pesoKg)} kg',
                style: AppTypography.bodyMd
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Text('${h.series} × ${h.reps}',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ],
        ),
      );

  static String _dia(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  static String _kg(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// Linha da carga ao longo das sessões.
///
/// Deliberadamente simples: sem eixos, sem grade, sem rótulo em cada ponto. A
/// lista logo abaixo já dá os números exatos; o desenho existe só para a forma
/// — subindo, parado ou caindo — ser lida num relance.
class _GraficoDeCarga extends CustomPainter {
  final List<HistoricoDeExercicio> dados;
  _GraficoDeCarga(this.dados);

  @override
  void paint(Canvas canvas, Size size) {
    if (dados.isEmpty) return;

    final pesos = dados.map((d) => d.pesoKg).toList();
    final menor = pesos.reduce((a, b) => a < b ? a : b);
    final maior = pesos.reduce((a, b) => a > b ? a : b);

    // Faixa achatada quando a carga nunca mudou: sem isto a divisão por
    // (maior - menor) seria por zero e a linha sumiria.
    final faixa = (maior - menor) == 0 ? 1.0 : (maior - menor);

    const margem = 10.0;
    final alturaUtil = size.height - margem * 2;

    Offset ponto(int i) {
      final x = dados.length == 1
          ? size.width / 2
          : size.width * (i / (dados.length - 1));
      final norm = (pesos[i] - menor) / faixa;
      return Offset(x, margem + alturaUtil * (1 - norm));
    }

    final caminho = Path()..moveTo(ponto(0).dx, ponto(0).dy);
    for (var i = 1; i < dados.length; i++) {
      caminho.lineTo(ponto(i).dx, ponto(i).dy);
    }

    // Preenchimento até a base, para a linha ter peso visual sobre o fundo
    // quase preto do tema.
    final area = Path.from(caminho)
      ..lineTo(ponto(dados.length - 1).dx, size.height)
      ..lineTo(ponto(0).dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      caminho,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < dados.length; i++) {
      canvas.drawCircle(ponto(i), i == dados.length - 1 ? 5 : 3,
          Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(_GraficoDeCarga old) => old.dados != dados;
}

// ── Moldura comum das duas folhas ───────────────────────────────────────────

class _Folha extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List<Widget> children;
  const _Folha(
      {required this.titulo,
      required this.subtitulo,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sobe junto com o teclado — a folha da anotação abre com o campo em
      // foco, e sem isto o botão SALVAR fica atrás do teclado.
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(subtitulo,
                  style: AppTypography.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(height: 2),
              Text(titulo,
                  style: AppTypography.labelMd
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
