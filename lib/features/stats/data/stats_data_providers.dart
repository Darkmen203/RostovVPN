import 'package:rostov_vpn/features/stats/data/stats_repository.dart';
import 'package:rostov_vpn/singbox/service/singbox_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stats_data_providers.g.dart';

@Riverpod(keepAlive: true)
StatsRepository statsRepository(StatsRepositoryRef ref) {
  return StatsRepositoryImpl(singbox: ref.watch(singboxServiceProvider));
}
