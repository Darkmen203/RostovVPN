import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rostov_vpn/singbox/service/singbox_service.dart';

part 'singbox_service_provider.g.dart';

@Riverpod(keepAlive: true)
SingboxService singboxService(SingboxServiceRef ref) {
  return SingboxService();
}
