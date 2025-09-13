import 'dart:io' show Platform;
import 'package:fpdart/fpdart.dart';
import 'package:rostov_vpn/core/http_client/dio_http_client.dart';
import 'package:rostov_vpn/core/model/constants.dart';
import 'package:rostov_vpn/core/model/environment.dart';
import 'package:rostov_vpn/core/utils/exception_handler.dart';
import 'package:rostov_vpn/features/app_update/model/app_update_failure.dart';
import 'package:rostov_vpn/features/app_update/model/remote_version_entity.dart';
import 'package:rostov_vpn/utils/utils.dart';
import 'package:version/version.dart';

abstract interface class AppUpdateRepository {
  TaskEither<AppUpdateFailure, RemoteVersionEntity> getLatestVersion({
    bool includePreReleases = false,
    Release release = Release.general,
  });
}

class AppUpdateRepositoryImpl
    with ExceptionHandler, InfraLogger
    implements AppUpdateRepository {
  AppUpdateRepositoryImpl({required this.httpClient});

  final DioHttpClient httpClient;

  @override
  TaskEither<AppUpdateFailure, RemoteVersionEntity> getLatestVersion({
    bool includePreReleases = false, // не используется — один прод-релиз
    Release release = Release.general,
  }) {
    return exceptionHandler(
      () async {
        if (!release.allowCustomUpdateChecker) {
          throw Exception("custom update checkers are not supported");
        }

        final res =
            await httpClient.get<Map<String, dynamic>>(Constants.latestJsonUrl);
        if (res.statusCode != 200 || res.data == null) {
          loggy.warning("failed to fetch latest.json");
          return left(const AppUpdateFailure.unexpected());
        }

        final data = res.data!;
        final versionStr = (data['version'] as String?)?.trim();
        if (versionStr == null || versionStr.isEmpty) {
          loggy.warning("latest.json: empty version");
          return left(const AppUpdateFailure.unexpected());
        }

        final releasedAtStr = data['releasedAt'] as String?;
        DateTime publishedAt;
        try {
          publishedAt = DateTime.parse(releasedAtStr ?? '').toUtc();
        } catch (_) {
          publishedAt = DateTime.now().toUtc();
        }

        final assets = (data['assets'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        final selectedUrl = _pickPreferredAssetUrl(assets);

        final remote = RemoteVersionEntity(
          version: versionStr,
          buildNumber: _computeBuildNumber(versionStr, publishedAt),
          releaseTag: 'v$versionStr',
          preRelease: false,
          url: selectedUrl ?? Constants.websiteMain,
          publishedAt: publishedAt,
          flavor: Environment.prod,
        );

        return right(remote);
      },
      AppUpdateFailure.unexpected,
    );
  }

  // Выбираем «лучший» файл под текущую платформу.
  String? _pickPreferredAssetUrl(List<Map<String, dynamic>> assets) {
    bool match(Map<String, dynamic> a, String plat,
        {String? contains, Pattern? regex,}) {
      final p = (a['platform'] as String? ?? '').toLowerCase();
      final f = (a['filename'] as String? ?? '').toLowerCase();
      if (p != plat.toLowerCase()) return false;
      if (contains != null && !f.contains(contains.toLowerCase())) return false;
      if (regex != null && !RegExp(regex.toString()).hasMatch(f)) {
        return false;
      }
      return true;
    }

    if (Platform.isAndroid) {
      return assets.firstWhere(
              (a) => match(a, 'Android', contains: 'universal'),
              orElse: () => const {},)['url'] as String? ??
          assets.firstWhere((a) => match(a, 'Android'),
              orElse: () => const {},)['url'] as String?;
    }
    if (Platform.isWindows) {
      return assets.firstWhere(
              (a) => match(a, 'Windows', regex: r'setup.*\.exe$'),
              orElse: () => const {},)['url'] as String? ??
          assets.firstWhere((a) => match(a, 'Windows'),
              orElse: () => const {},)['url'] as String?;
    }
    if (Platform.isMacOS) {
      return assets.firstWhere((a) => match(a, 'macOS', regex: r'\.dmg$'),
              orElse: () => const {},)['url'] as String? ??
          assets.firstWhere((a) => match(a, 'macOS'),
              orElse: () => const {},)['url'] as String?;
    }
    if (Platform.isLinux) {
      return assets.firstWhere((a) => match(a, 'Linux', contains: 'appimage'),
              orElse: () => const {},)['url'] as String? ??
          assets.firstWhere((a) => match(a, 'Linux'),
              orElse: () => const {},)['url'] as String?;
    }
    return null;
  }

  // Преобразуем semver в монотонный buildNumber.
  String _computeBuildNumber(String version, DateTime publishedAt) {
    try {
      final v = Version.parse(version);
      final num = v.major * 1000000 + v.minor * 1000 + v.patch;
      return num.toString(); // 2.7.6 -> 2007006
    } catch (_) {
      return publishedAt.millisecondsSinceEpoch.toString();
    }
  }
}
