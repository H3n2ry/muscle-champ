import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';

final profileProvider = FutureProvider.autoDispose<ProfileModel>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});
