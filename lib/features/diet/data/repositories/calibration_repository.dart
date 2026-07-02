import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calibração da mão do usuário (medidas em cm), usada como régua de escala
/// na análise de foto de comida. Persistida em `goals` (RLS owner-scoped).
class HandCalibration {
  final double? lengthCm;
  final double? widthCm;
  const HandCalibration({this.lengthCm, this.widthCm});

  bool get isCalibrated => lengthCm != null && widthCm != null;

  factory HandCalibration.fromRow(Map<String, dynamic>? r) => HandCalibration(
        lengthCm: (r?['hand_length_cm'] as num?)?.toDouble(),
        widthCm: (r?['hand_width_cm'] as num?)?.toDouble(),
      );
}

class CalibrationRepository {
  final _client = Supabase.instance.client;

  Future<HandCalibration> get() async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client
        .from('goals')
        .select('hand_length_cm, hand_width_cm')
        .eq('user_id', userId)
        .maybeSingle();
    return HandCalibration.fromRow(row);
  }

  Future<void> save(double lengthCm, double widthCm) async {
    await _client.from('goals').update({
      'hand_length_cm': lengthCm,
      'hand_width_cm': widthCm,
      'hand_calibrated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', _client.auth.currentUser!.id);
  }

  Future<void> clear() async {
    await _client.from('goals').update({
      'hand_length_cm': null,
      'hand_width_cm': null,
      'hand_calibrated_at': null,
    }).eq('user_id', _client.auth.currentUser!.id);
  }
}

final calibrationRepositoryProvider =
    Provider<CalibrationRepository>((_) => CalibrationRepository());

/// Lê a calibração atual do usuário. Invalidado após calibrar/limpar.
final handCalibrationProvider = FutureProvider.autoDispose<HandCalibration>(
  (ref) => ref.watch(calibrationRepositoryProvider).get(),
);
