import 'package:rostov_vpn/features/profile/data/profile_data_providers.dart';
import 'package:rostov_vpn/features/profile/model/profile_entity.dart';
import 'package:rostov_vpn/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_profile_notifier.g.dart';

@Riverpod(keepAlive: true)
class ActiveProfile extends _$ActiveProfile with AppLogger {
  @override
  Stream<ProfileEntity?> build() {
    loggy.debug("watching active profile");
    return ref
        .watch(profileRepositoryProvider)
        .requireValue
        .watchActiveProfile()
        .map((event) => event.getOrElse((l) => throw l));
  }
}

// TODO: move to specific feature
@Riverpod(keepAlive: true)
Stream<bool> hasAnyProfile(
  HasAnyProfileRef ref,
) {
  return ref
      .watch(profileRepositoryProvider)
      .requireValue
      .watchHasAnyProfile()
      .map((event) => event.getOrElse((l) => throw l));
}
