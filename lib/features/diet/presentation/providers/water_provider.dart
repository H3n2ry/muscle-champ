import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/water_model.dart';
import '../../data/repositories/water_repository.dart';

final waterControllerProvider =
    AsyncNotifierProvider.autoDispose<WaterController, WaterSummary>(
        WaterController.new);

class WaterController extends AutoDisposeAsyncNotifier<WaterSummary> {
  @override
  Future<WaterSummary> build() {
    return ref.watch(waterRepositoryProvider).getTodaySummary();
  }

  Future<void> add(int ml) async {
    await ref.read(waterRepositoryProvider).addWater(ml);
    state = AsyncData(
        await ref.read(waterRepositoryProvider).getTodaySummary());
  }

  Future<void> undo() async {
    await ref.read(waterRepositoryProvider).undoLast();
    state = AsyncData(
        await ref.read(waterRepositoryProvider).getTodaySummary());
  }
}
