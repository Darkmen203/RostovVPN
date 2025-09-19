import 'package:dartx/dartx.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rostov_vpn/core/model/optional_range.dart';
import 'package:rostov_vpn/core/model/region.dart';

import 'package:rostov_vpn/core/utils/exception_handler.dart';
import 'package:rostov_vpn/core/utils/json_converters.dart';
import 'package:rostov_vpn/core/utils/preferences_utils.dart';
import 'package:rostov_vpn/features/config_option/model/config_option_failure.dart';

import 'package:rostov_vpn/features/log/model/log_level.dart';
import 'package:rostov_vpn/singbox/model/singbox_config_enum.dart';
import 'package:rostov_vpn/singbox/model/singbox_config_option.dart';
import 'package:rostov_vpn/singbox/model/singbox_rule.dart';
import 'package:rostov_vpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ConfigOptions {
  static final serviceMode = PreferencesNotifier.create<ServiceMode, String>(
    "service-mode",
    ServiceMode.defaultMode,
    mapFrom: (value) => ServiceMode.choices.firstWhere((e) => e.key == value),
    mapTo: (value) => value.key,
  );

  static final region = PreferencesNotifier.create<Region, String>(
    "region",
    Region.other,
    mapFrom: Region.values.byName,
    mapTo: (value) => value.name,
  );
  static final useXrayCoreWhenPossible = PreferencesNotifier.create<bool, bool>(
    "use-xray-core-when-possible",
    false,
  );
  static final blockAds = PreferencesNotifier.create<bool, bool>(
    "block-ads",
    false,
  );
  static final logLevel = PreferencesNotifier.create<LogLevel, String>(
    "log-level",
    LogLevel.warn,
    mapFrom: LogLevel.values.byName,
    mapTo: (value) => value.name,
  );

  static final resolveDestination = PreferencesNotifier.create<bool, bool>(
    "resolve-destination",
    false,
  );

  static final ipv6Mode = PreferencesNotifier.create<IPv6Mode, String>(
    "ipv6-mode",
    IPv6Mode.disable,
    mapFrom: (value) => IPv6Mode.values.firstWhere((e) => e.key == value),
    mapTo: (value) => value.key,
  );

  static final remoteDnsAddress = PreferencesNotifier.create<String, String>(
    "remote-dns-address",
    "udp://8.8.8.8",
    possibleValues: List.of([
      "local",
      "udp://223.5.5.5",
      "udp://1.1.1.1",
      "udp://8.8.8.8",
      "tcp://8.8.8.8",
      "udp://1.1.1.2",
      "tcp://1.1.1.1",
      "https://1.1.1.1/dns-query",
      "https://sky.rethinkdns.com/dns-query",
      "4.4.2.2",
      "8.8.8.8",
    ]),
    validator: (value) => value.isNotBlank,
  );

  static final remoteDnsDomainStrategy = PreferencesNotifier.create<DomainStrategy, String>(
    "remote-dns-domain-strategy",
    DomainStrategy.auto,
    mapFrom: (value) => DomainStrategy.values.firstWhere((e) => e.key == value),
    mapTo: (value) => value.key,
  );

  static final directDnsAddress = PreferencesNotifier.create<String, String>(
    "direct-dns-address",
    "8.8.8.8",
    possibleValues: List.of([
      "local",
      "udp://223.5.5.5",
      "udp://1.1.1.1",
      "udp://1.1.1.2",
      "tcp://1.1.1.1",
      "https://1.1.1.1/dns-query",
      "https://sky.rethinkdns.com/dns-query",
      "4.4.2.2",
      "8.8.8.8",
    ]),
    defaultValueFunction: (ref) => ref.read(region) == Region.cn ? "223.5.5.5" : "8.8.8.8",
    validator: (value) => value.isNotBlank,
  );

  static final directDnsDomainStrategy = PreferencesNotifier.create<DomainStrategy, String>(
    "direct-dns-domain-strategy",
    DomainStrategy.auto,
    mapFrom: (value) => DomainStrategy.values.firstWhere((e) => e.key == value),
    mapTo: (value) => value.key,
  );

  static final mixedPort = PreferencesNotifier.create<int, int>(
    "mixed-port",
    12334,
    validator: (value) => isPort(value.toString()),
  );

  static final tproxyPort = PreferencesNotifier.create<int, int>(
    "tproxy-port",
    12335,
    validator: (value) => isPort(value.toString()),
  );

  static final localDnsPort = PreferencesNotifier.create<int, int>(
    "local-dns-port",
    16450,
    validator: (value) => isPort(value.toString()),
  );

  static final tunImplementation = PreferencesNotifier.create<TunImplementation, String>(
    "tun-implementation",
    TunImplementation.gvisor,
    mapFrom: TunImplementation.values.byName,
    mapTo: (value) => value.name,
  );

  static final mtu = PreferencesNotifier.create<int, int>("mtu", 9000);

  static final strictRoute = PreferencesNotifier.create<bool, bool>("strict-route", true);

  static final connectionTestUrl = PreferencesNotifier.create<String, String>(
    "connection-test-url",
    "http://cp.cloudflare.com",
    possibleValues: List.of([
      "http://connectivitycheck.gstatic.com/generate_204",
      "http://www.gstatic.com/generate_204",
      "https://www.gstatic.com/generate_204",
      "http://cp.cloudflare.com",
      "http://kernel.org",
      "http://detectportal.firefox.com",
      "http://captive.apple.com/hotspot-detect.html",
      "https://1.1.1.1",
      "http://1.1.1.1",
    ]),
    validator: (value) => value.isNotBlank && isUrl(value),
  );

  static final urlTestInterval = PreferencesNotifier.create<Duration, int>(
    "url-test-interval",
    const Duration(minutes: 10),
    mapFrom: const IntervalInSecondsConverter().fromJson,
    mapTo: const IntervalInSecondsConverter().toJson,
  );

  static final enableClashApi = PreferencesNotifier.create<bool, bool>(
    "enable-clash-api",
    true,
  );

  static final clashApiPort = PreferencesNotifier.create<int, int>(
    "clash-api-port",
    16756,
    validator: (value) => isPort(value.toString()),
  );

  static final bypassLan = PreferencesNotifier.create<bool, bool>("bypass-lan", false);

  static final allowConnectionFromLan = PreferencesNotifier.create<bool, bool>(
    "allow-connection-from-lan",
    false,
  );

  static final enableFakeDns = PreferencesNotifier.create<bool, bool>(
    "enable-fake-dns",
    false,
  );

  static final enableDnsRouting = PreferencesNotifier.create<bool, bool>(
    "enable-dns-routing",
    true,
  );

  static final independentDnsCache = PreferencesNotifier.create<bool, bool>(
    "independent-dns-cache",
    true,
  );

  static final enableTlsFragment = PreferencesNotifier.create<bool, bool>(
    "enable-tls-fragment",
    false,
  );

  static final tlsFragmentSize = PreferencesNotifier.create<OptionalRange, String>(
    "tls-fragment-size",
    const OptionalRange(min: 10, max: 30),
    mapFrom: OptionalRange.parse,
    mapTo: const OptionalRangeJsonConverter().toJson,
  );

  static final tlsFragmentSleep = PreferencesNotifier.create<OptionalRange, String>(
    "tls-fragment-sleep",
    const OptionalRange(min: 2, max: 8),
    mapFrom: OptionalRange.parse,
    mapTo: const OptionalRangeJsonConverter().toJson,
  );

  static final enableTlsMixedSniCase = PreferencesNotifier.create<bool, bool>(
    "enable-tls-mixed-sni-case",
    false,
  );

  static final enableTlsPadding = PreferencesNotifier.create<bool, bool>(
    "enable-tls-padding",
    false,
  );

  static final tlsPaddingSize = PreferencesNotifier.create<OptionalRange, String>(
    "tls-padding-size",
    const OptionalRange(min: 1, max: 1500),
    mapFrom: OptionalRange.parse,
    mapTo: const OptionalRangeJsonConverter().toJson,
  );

  static final enableMux = PreferencesNotifier.create<bool, bool>(
    "enable-mux",
    false,
  );

  static final muxPadding = PreferencesNotifier.create<bool, bool>(
    "mux-padding",
    false,
  );

  static final muxMaxStreams = PreferencesNotifier.create<int, int>(
    "mux-max-streams",
    8,
    validator: (value) => value > 0,
  );

  static final muxProtocol = PreferencesNotifier.create<MuxProtocol, String>(
    "mux-protocol",
    MuxProtocol.h2mux,
    mapFrom: MuxProtocol.values.byName,
    mapTo: (value) => value.name,
  );

  static final hasExperimentalFeatures = Provider.autoDispose<bool>(
    (ref) {
      final mode = ref.watch(serviceMode);
      if (PlatformUtils.isDesktop && mode == ServiceMode.tun) {
        return true;
      }
      if (ref.watch(enableTlsFragment) || ref.watch(enableTlsMixedSniCase) || ref.watch(enableTlsPadding) || ref.watch(enableMux) || ref.watch(bypassLan) || ref.watch(allowConnectionFromLan)) {
        return true;
      }

      return false;
    },
  );

  /// preferences to exclude from share and export
  static final privatePreferencesKeys = {
  };

  static final Map<String, StateNotifierProvider<PreferencesNotifier, dynamic>> preferences = {
    "region": region,
    "block-ads": blockAds,
    "use-xray-core-when-possible": useXrayCoreWhenPossible,
    "service-mode": serviceMode,
    "log-level": logLevel,
    "resolve-destination": resolveDestination,
    "ipv6-mode": ipv6Mode,
    "remote-dns-address": remoteDnsAddress,
    "remote-dns-domain-strategy": remoteDnsDomainStrategy,
    "direct-dns-address": directDnsAddress,
    "direct-dns-domain-strategy": directDnsDomainStrategy,
    "mixed-port": mixedPort,
    "tproxy-port": tproxyPort,
    "local-dns-port": localDnsPort,
    "tun-implementation": tunImplementation,
    "mtu": mtu,
    "strict-route": strictRoute,
    "connection-test-url": connectionTestUrl,
    "url-test-interval": urlTestInterval,
    "clash-api-port": clashApiPort,
    "bypass-lan": bypassLan,
    "allow-connection-from-lan": allowConnectionFromLan,
    "enable-dns-routing": enableDnsRouting,

    // mux
    "mux.enable": enableMux,
    "mux.padding": muxPadding,
    "mux.max-streams": muxMaxStreams,
    "mux.protocol": muxProtocol,

    // tls-tricks
    "tls-tricks.enable-fragment": enableTlsFragment,
    "tls-tricks.fragment-size": tlsFragmentSize,
    "tls-tricks.fragment-sleep": tlsFragmentSleep,
    "tls-tricks.mixed-sni-case": enableTlsMixedSniCase,
    "tls-tricks.enable-padding": enableTlsPadding,
    "tls-tricks.padding-size": tlsPaddingSize,
  };

  static final singboxConfigOptions = FutureProvider<SingboxConfigOption>(
    (ref) async {
      // final region = ref.watch(Preferences.region);
      final rules = <SingboxRule>[];
      // final rules = switch (region) {
      //   Region.ir => [
      //       const SingboxRule(
      //         domains: "domain:.ir,geosite:ir",
      //         ip: "geoip:ir",
      //         outbound: RuleOutbound.bypass,
      //       ),
      //     ],
      //   Region.cn => [
      //       const SingboxRule(
      //         domains: "domain:.cn,geosite:cn",
      //         ip: "geoip:cn",
      //         outbound: RuleOutbound.bypass,
      //       ),
      //     ],
      //   Region.ru => [
      //       const SingboxRule(
      //         domains: "domain:.ru",
      //         ip: "geoip:ru",
      //         outbound: RuleOutbound.bypass,
      //       ),
      //     ],
      //   Region.af => [
      //       const SingboxRule(
      //         domains: "domain:.af,geosite:af",
      //         ip: "geoip:af",
      //         outbound: RuleOutbound.bypass,
      //       ),
      //     ],
      //   Region.id => [
      //       const SingboxRule(
      //         domains: "domain:.id,geosite:id",
      //         ip: "geoip:id",
      //         outbound: RuleOutbound.bypass,
      //       ),
      //     ],
      //   _ => <SingboxRule>[],
      // };

      final mode = ref.watch(serviceMode);
      // final reg = ref.watch(Preferences.region.notifier).raw();

      return SingboxConfigOption(
        region: ref.watch(region).name,
        blockAds: ref.watch(blockAds),
        useXrayCoreWhenPossible: ref.watch(useXrayCoreWhenPossible),
        executeConfigAsIs: false,
        logLevel: ref.watch(logLevel),
        resolveDestination: ref.watch(resolveDestination),
        ipv6Mode: ref.watch(ipv6Mode),
        remoteDnsAddress: ref.watch(remoteDnsAddress),
        remoteDnsDomainStrategy: ref.watch(remoteDnsDomainStrategy),
        directDnsAddress: ref.watch(directDnsAddress),
        directDnsDomainStrategy: ref.watch(directDnsDomainStrategy),
        mixedPort: ref.watch(mixedPort),
        tproxyPort: ref.watch(tproxyPort),
        localDnsPort: ref.watch(localDnsPort),
        tunImplementation: ref.watch(tunImplementation),
        mtu: ref.watch(mtu),
        strictRoute: ref.watch(strictRoute),
        connectionTestUrl: ref.watch(connectionTestUrl),
        urlTestInterval: ref.watch(urlTestInterval),
        enableClashApi: ref.watch(enableClashApi),
        clashApiPort: ref.watch(clashApiPort),
        enableTun: mode == ServiceMode.tun,
        enableTunService: mode == ServiceMode.tunService,
        setSystemProxy: mode == ServiceMode.systemProxy,
        bypassLan: ref.watch(bypassLan),
        allowConnectionFromLan: ref.watch(allowConnectionFromLan),
        enableFakeDns: ref.watch(enableFakeDns),
        enableDnsRouting: ref.watch(enableDnsRouting),
        independentDnsCache: ref.watch(independentDnsCache),
        mux: SingboxMuxOption(
          enable: ref.watch(enableMux),
          padding: ref.watch(muxPadding),
          maxStreams: ref.watch(muxMaxStreams),
          protocol: ref.watch(muxProtocol),
        ),
        tlsTricks: SingboxTlsTricks(
          enableFragment: ref.watch(enableTlsFragment),
          fragmentSize: ref.watch(tlsFragmentSize),
          fragmentSleep: ref.watch(tlsFragmentSleep),
          mixedSniCase: ref.watch(enableTlsMixedSniCase),
          enablePadding: ref.watch(enableTlsPadding),
          paddingSize: ref.watch(tlsPaddingSize),
        ),
        // geoipPath: ref.watch(geoAssetPathResolverProvider).relativePath(
        //       geoAssets.geoip.providerName,
        //       geoAssets.geoip.fileName,
        //     ),
        // geositePath: ref.watch(geoAssetPathResolverProvider).relativePath(
        //       geoAssets.geosite.providerName,
        //       geoAssets.geosite.fileName,
        //     ),
        rules: rules,
      );
    },
  );
}

class ConfigOptionRepository with ExceptionHandler, InfraLogger {
  ConfigOptionRepository({
    required this.preferences,
    required this.getConfigOptions,
  });

  final SharedPreferences preferences;
  final Future<SingboxConfigOption> Function() getConfigOptions;

  TaskEither<ConfigOptionFailure, SingboxConfigOption> getFullSingboxConfigOption() {
    return exceptionHandler(
      () async {
        return right(await getConfigOptions());
      },
      ConfigOptionUnexpectedFailure.new,
    );
  }
}
