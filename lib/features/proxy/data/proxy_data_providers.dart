import 'package:rostov_vpn/core/http_client/http_client_provider.dart';
import 'package:rostov_vpn/features/proxy/data/proxy_repository.dart';
import 'package:rostov_vpn/singbox/service/singbox_service_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proxy_data_providers.g.dart';

@Riverpod(keepAlive: true)
ProxyRepository proxyRepository(ProxyRepositoryRef ref) {
  return ProxyRepositoryImpl(
    singbox: ref.watch(singboxServiceProvider),
    client: ref.watch(httpClientProvider),
  );
}
