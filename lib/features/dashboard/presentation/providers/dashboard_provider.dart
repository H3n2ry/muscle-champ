import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/repositories/dashboard_repository.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardModel>((ref) {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});
