import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/groq/groq_config.dart';
import '../../../../core/groq/groq_service.dart';
import '../../../../shared/widgets/mk_error_banner.dart';
import '../../../../shared/widgets/mk_snack.dart';
import '../../data/repositories/calibration_repository.dart';

// Moedas brasileiras com diâmetro real (mm) — referência de escala.
const _coins = <({String label, double mm})>[
  (label: 'R\$ 1,00', mm: 27),
  (label: 'R\$ 0,50', mm: 23),
  (label: 'R\$ 0,25', mm: 25),
];

const _accent = Color(0xFF0EA5E9); // cyan — mesmo do modo foto

class CalibrationPage extends ConsumerStatefulWidget {
  const CalibrationPage({super.key});

  @override
  ConsumerState<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends ConsumerState<CalibrationPage> {
  int _coinIdx = 0;
  Uint8List? _photo;
  bool _loading = false;
  String? _error;
  double? _lengthCm;
  double? _widthCm;
  bool _saving = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile =
        await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1024);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    if (!GroqConfig.isConfigured) {
      setState(() => _error = 'Sessão expirada. Faça login novamente.');
      return;
    }
    setState(() {
      _photo = bytes;
      _loading = true;
      _error = null;
      _lengthCm = null;
      _widthCm = null;
    });
    try {
      final result =
          await GroqService.calibrateHand(base64Encode(bytes), _coins[_coinIdx].mm);
      if (!mounted) return;
      if (result.containsKey('error')) {
        setState(() => _error =
            'Não consegui ver a moeda e a mão claramente. Tente de novo com boa luz, moeda bem no centro da palma.');
      } else {
        setState(() {
          _lengthCm = (result['hand_length_cm'] as num?)?.toDouble();
          _widthCm = (result['hand_width_cm'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        setState(() => _error =
            msg.length > 120 ? 'Não foi possível calibrar. Tente novamente.' : msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_lengthCm == null || _widthCm == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(calibrationRepositoryProvider)
          .save(_lengthCm!, _widthCm!);
      ref.invalidate(handCalibrationProvider);
      if (mounted) {
        MkSnack.success(context, 'IA calibrada! As análises de foto ficarão mais precisas.');
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Não foi possível salvar. Tente novamente.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _lengthCm != null && _widthCm != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('CALIBRAR IA',
            style: AppTypography.labelMd.copyWith(letterSpacing: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Explicação ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accent.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: _accent, size: 18),
                        const SizedBox(width: 8),
                        Text('Como funciona',
                            style: AppTypography.labelMd
                                .copyWith(color: _accent, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'A IA aprende o tamanho da sua mão usando uma moeda como régua. '
                      'Depois, ela usa sua mão como referência para estimar as porções com mais precisão. '
                      'É só uma vez.',
                      style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Passos ─────────────────────────────────────────────
              _StepLine(n: '1', text: 'Escolha a moeda que você vai usar'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_coins.length, (i) {
                  final sel = i == _coinIdx;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: i < _coins.length - 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _coinIdx = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: sel
                                ? _accent.withOpacity(0.15)
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel
                                  ? _accent
                                  : AppColors.surfaceContainerHigh,
                              width: sel ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(_coins[i].label,
                                  style: AppTypography.labelMd.copyWith(
                                    fontSize: 13,
                                    color: sel
                                        ? _accent
                                        : AppColors.onSurface,
                                  )),
                              const SizedBox(height: 2),
                              Text('${_coins[i].mm.toStringAsFixed(0)} mm',
                                  style: AppTypography.labelSm.copyWith(
                                      fontSize: 9,
                                      color: AppColors.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),
              _StepLine(
                  n: '2',
                  text:
                      'Abra a palma e coloque a moeda no centro. Boa luz, foto de cima.'),
              const SizedBox(height: 12),

              // ── Foto / preview ────────────────────────────────────
              if (_photo == null)
                Row(
                  children: [
                    Expanded(
                      child: _PhotoBtn(
                        icon: Icons.camera_alt_outlined,
                        label: 'CÂMERA',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PhotoBtn(
                        icon: Icons.photo_library_outlined,
                        label: 'GALERIA',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                )
              else
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(_photo!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover),
                    ),
                    if (!_loading)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _photo = null;
                            _lengthCm = null;
                            _widthCm = null;
                            _error = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    if (_loading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: _accent, strokeWidth: 2),
                              SizedBox(height: 10),
                              Text('Medindo sua mão...',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

              MkErrorBanner(
                message: _error,
                onDismiss: () => setState(() => _error = null),
              ),

              // ── Resultado ─────────────────────────────────────────
              if (hasResult) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Text('Mão medida',
                              style: AppTypography.labelMd.copyWith(
                                  color: AppColors.primary, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _Measure(
                                label: 'COMPRIMENTO',
                                value: '${_lengthCm!.toStringAsFixed(1)} cm'),
                          ),
                          Expanded(
                            child: _Measure(
                                label: 'LARGURA DA PALMA',
                                value: '${_widthCm!.toStringAsFixed(1)} cm'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Confira se faz sentido. Se estiver estranho, refaça a foto.',
                        style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: AppColors.onPrimary))
                        : Text('SALVAR CALIBRAÇÃO',
                            style: AppTypography.labelMd.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 14,
                                letterSpacing: 1.5)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _StepLine extends StatelessWidget {
  final String n;
  final String text;
  const _StepLine({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: Text(n,
                style: AppTypography.labelSm
                    .copyWith(color: _accent, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(text,
                style: AppTypography.bodyMd.copyWith(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

class _PhotoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PhotoBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _accent, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: AppTypography.labelSm
                    .copyWith(letterSpacing: 1.5, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Measure extends StatelessWidget {
  final String label;
  final String value;
  const _Measure({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSm.copyWith(
                fontSize: 9,
                letterSpacing: 1.5,
                color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.headlineSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 20)),
      ],
    );
  }
}
