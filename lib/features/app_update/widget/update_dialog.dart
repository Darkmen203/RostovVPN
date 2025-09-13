import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/features/app_update/model/remote_version_entity.dart';
import 'package:rostov_vpn/features/app_update/notifier/app_update_notifier.dart';

Future<void> showUpdateDialog(
  BuildContext context,
  RemoteVersionEntity remote, {
  required String currentVersion,
  bool canIgnore = true,
}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final t = ref.watch(translationsProvider);
          final theme = Theme.of(ctx);

          return AlertDialog(
            title: Text(t.appUpdate.dialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.appUpdate.updateMsg),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '${t.appUpdate.currentVersionLbl}: ',
                      style: theme.textTheme.bodySmall,
                    ),
                    TextSpan(
                      text: currentVersion,
                      style: theme.textTheme.labelMedium,
                    ),
                  ]),
                ),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '${t.appUpdate.newVersionLbl}: ',
                      style: theme.textTheme.bodySmall,
                    ),
                    TextSpan(
                      text: remote.presentVersion, // см. getter в entity
                      style: theme.textTheme.labelMedium,
                    ),
                  ]),
                ),
              ],
            ),
            actions: [
              // 1) Просто закрыть (без игнора) — "Позже"
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(t.appUpdate.laterBtnTxt),
              ),

              // 2) Игнорировать эту версию (не показывать снова)
              if (canIgnore)
                TextButton(
                  onPressed: () {
                    ref
                        .read(appUpdateNotifierProvider.notifier)
                        .ignoreRelease(remote);
                    Navigator.of(ctx).pop();
                  },
                  child: Text(t.appUpdate.ignoreBtnTxt),
                ),

              // 3) Обновить (открыть ссылку)
              TextButton(
                onPressed: () async {
                  final uri = Uri.parse(remote.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(t.appUpdate.updateNowBtnTxt),
              ),
            ],
          );
        },
      );
    },
  );
}
