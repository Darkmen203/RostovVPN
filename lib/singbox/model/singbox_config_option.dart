import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rostov_vpn/core/model/optional_range.dart';
import 'package:rostov_vpn/core/utils/json_converters.dart';
import 'package:rostov_vpn/features/log/model/log_level.dart';
import 'package:rostov_vpn/singbox/model/singbox_config_enum.dart';
import 'package:rostov_vpn/singbox/model/singbox_rule.dart';

part 'singbox_config_option.freezed.dart';
part 'singbox_config_option.g.dart';

@freezed
class SingboxConfigOption with _$SingboxConfigOption {
  const SingboxConfigOption._();

  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxConfigOption({
    required String region,
    required bool blockAds,
    required bool useXrayCoreWhenPossible,
    required bool executeConfigAsIs,
    required LogLevel logLevel,
    required bool resolveDestination,
    required IPv6Mode ipv6Mode,
    required String remoteDnsAddress,
    required DomainStrategy remoteDnsDomainStrategy,
    required String directDnsAddress,
    required DomainStrategy directDnsDomainStrategy,
    required int mixedPort,
    required int tproxyPort,
    required int localDnsPort,
    required TunImplementation tunImplementation,
    required int mtu,
    required bool strictRoute,
    required String connectionTestUrl,
    @IntervalInSecondsConverter() required Duration urlTestInterval,
    required bool enableClashApi,
    required int clashApiPort,
    required bool enableTun,
    required bool enableTunService,
    required bool setSystemProxy,
    required bool bypassLan,
    required bool allowConnectionFromLan,
    required bool enableFakeDns,
    required bool enableDnsRouting,
    required bool independentDnsCache,
    // required String geoipPath,
    // required String geositePath,
    required List<SingboxRule> rules,
    required SingboxMuxOption mux,
    required SingboxTlsTricks tlsTricks,
  }) = _SingboxConfigOption;

  String format() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  factory SingboxConfigOption.fromJson(Map<String, dynamic> json) => _$SingboxConfigOptionFromJson(json);
}

@freezed
class SingboxMuxOption with _$SingboxMuxOption {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxMuxOption({
    required bool enable,
    required bool padding,
    required int maxStreams,
    required MuxProtocol protocol,
  }) = _SingboxMuxOption;

  factory SingboxMuxOption.fromJson(Map<String, dynamic> json) => _$SingboxMuxOptionFromJson(json);
}

@freezed
class SingboxTlsTricks with _$SingboxTlsTricks {
  @JsonSerializable(fieldRename: FieldRename.kebab)
  const factory SingboxTlsTricks({
    required bool enableFragment,
    @OptionalRangeJsonConverter() required OptionalRange fragmentSize,
    @OptionalRangeJsonConverter() required OptionalRange fragmentSleep,
    required bool mixedSniCase,
    required bool enablePadding,
    @OptionalRangeJsonConverter() required OptionalRange paddingSize,
  }) = _SingboxTlsTricks;

  factory SingboxTlsTricks.fromJson(Map<String, dynamic> json) => _$SingboxTlsTricksFromJson(json);
}
