import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rostov_vpn/features/settings/data/settings_repository.dart';

part 'settings_data_providers.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  return SettingsRepositoryImpl();
}
