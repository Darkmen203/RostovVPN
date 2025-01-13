// // lib/core/login/login_manager_provider.dart

// import 'package:rostov_vpn/features/profile/data/profile_data_providers.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:rostov_vpn/core/login/login_manager.dart';
// import 'package:rostov_vpn/features/profile/data/profile_repository.dart';

// part 'login_manager_provider.g.dart';

// // Аннотация генерирует loginManagerProvider
// @riverpod
// LoginManager loginManager(LoginManagerRef ref) {
//   // Берём ProfileRepository из провайдера, например profileRepositoryProvider
//   final profileRepo = ref.watch(profileRepositoryProvider).requireValue;

//   final manager = LoginManager(profileRepo);
//   // Возвращаем готовый manager

//   Future.microtask(() => manager.init());

//   return manager;
// }
import 'package:rostov_vpn/core/login/login_manager_notifier.dart';
import 'package:rostov_vpn/core/login/login_state.dart';
import 'package:rostov_vpn/features/profile/data/profile_data_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final loginManagerProvider = 
    StateNotifierProvider<LoginManagerNotifier, LoginState?>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider).requireValue;
  final notifier = LoginManagerNotifier(profileRepo);
  // при желании вызвать init
  notifier.init();
  return notifier;
});
