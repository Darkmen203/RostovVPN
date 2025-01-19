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
