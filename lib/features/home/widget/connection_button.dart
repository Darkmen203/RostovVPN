import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/core/model/failures.dart';
import 'package:rostov_vpn/core/theme/theme_extensions.dart';
import 'package:rostov_vpn/core/widget/animated_text.dart';
import 'package:rostov_vpn/features/config_option/data/config_option_repository.dart';
import 'package:rostov_vpn/features/config_option/notifier/config_option_notifier.dart';
import 'package:rostov_vpn/features/connection/model/connection_status.dart';
import 'package:rostov_vpn/features/connection/notifier/connection_notifier.dart';
import 'package:rostov_vpn/features/connection/widget/experimental_feature_notice.dart';
import 'package:rostov_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:rostov_vpn/features/proxy/active/active_proxy_notifier.dart';
import 'package:rostov_vpn/gen/assets.gen.dart';
import 'package:rostov_vpn/utils/alerts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:developer';

// TODO: rewrite
class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;

    final requiresReconnect =
        ref.watch(configOptionNotifierProvider).valueOrNull;
    final today = DateTime.now();

    ref.listen(
      connectionNotifierProvider,
      (_, next) {
        if (next case AsyncError(:final error)) {
          CustomAlertDialog.fromErr(t.presentError(error)).show(context);
        }
        if (next
            case AsyncData(value: Disconnected(:final connectionFailure?))) {
          CustomAlertDialog.fromErr(t.presentError(connectionFailure))
              .show(context);
        }
      },
    );

    final buttonTheme = Theme.of(context).extension<ConnectionButtonTheme>()!;

    Future<bool> showExperimentalNotice() async {
      final hasExperimental = ref.read(ConfigOptions.hasExperimentalFeatures);
      final canShowNotice = !ref.read(disableExperimentalFeatureNoticeProvider);
      if (hasExperimental && canShowNotice && context.mounted) {
        return await const ExperimentalFeatureNoticeDialog().show(context) ??
            false;
      }
      return true;
    }

    return _ConnectionButton(
      onTap: switch (connectionStatus) {
        AsyncData(value: Disconnected()) || AsyncError() => () async {
            if (await showExperimentalNotice()) {
              return await ref
                  .read(connectionNotifierProvider.notifier)
                  .toggleConnection();
            }
          },
        AsyncData(value: Connected()) => () async {
            if (requiresReconnect == true && await showExperimentalNotice()) {
              return await ref
                  .read(connectionNotifierProvider.notifier)
                  .reconnect(await ref.read(activeProfileProvider.future));
            }
            return await ref
                .read(connectionNotifierProvider.notifier)
                .toggleConnection();
          },
        _ => () {},
      },
      enabled: switch (connectionStatus) {
        AsyncData(value: Connected()) ||
        AsyncData(value: Disconnected()) ||
        AsyncError() =>
          true,
        _ => false,
      },
      label: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true =>
          t.connection.reconnect,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 =>
          t.connection.connecting,
        AsyncData(value: final status) => status.present(t),
        _ => "",
      },
      buttonColor: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true =>
          Colors.teal,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 =>
          const Color.fromARGB(255, 185, 176, 103),
        AsyncData(value: Connected()) => buttonTheme.connectedColor!,
        AsyncData(value: _) => buttonTheme.idleColor!,
        _ => Colors.red,
      },
      image: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true =>
          Assets.images.disconnectNorouz,
        AsyncData(value: Connected()) => Assets.images.connectNorouz,
        AsyncData(value: _) => Assets.images.disconnectNorouz,
        _ => Assets.images.disconnectNorouz,
        AsyncData(value: Disconnected()) ||
        AsyncError() =>
          Assets.images.disconnectNorouz,
        AsyncData(value: Connected()) => Assets.images.connectNorouz,
        _ => Assets.images.disconnectNorouz,
      },
      useImage: false,//today.day >= 19 && today.day <= 23 && today.month == 3,
    );
  }
}

// class _ConnectionButton extends StatelessWidget {
//   const _ConnectionButton({
//     required this.onTap,
//     required this.enabled,
//     required this.label,
//     required this.buttonColor,
//     required this.image,
//     required this.useImage,
//   });

//   final VoidCallback onTap;
//   final bool enabled;
//   final String label;
//   final Color buttonColor;
//   final AssetGenImage image;
//   final bool useImage;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Semantics(
//           button: true,
//           enabled: enabled,
//           label: label,
//           child: Container(
//             clipBehavior: Clip.antiAlias,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   blurRadius: 16,
//                   color: buttonColor.withAlpha(100),
//                 ),
//               ],
//             ),
//             width: 300,
//             height: 300,
//             child: Material(
//               key: const ValueKey("home_connection_button"),
//               shape: const CircleBorder(),
//               color: const Color.fromARGB(30, 204, 204, 204),
//               child: InkWell(
//                 onTap: onTap,
//                 child: TweenAnimationBuilder(
//                   tween: ColorTween(end: buttonColor),
//                   duration: const Duration(milliseconds: 250),
//                   builder: (context, value, child) {
//                     if (useImage) {
//                       return image.image(filterQuality: FilterQuality.medium, fit: BoxFit.fill);
//                     } else {
//                       return Assets.images.logo.svg(
//                         fit: BoxFit.cover
//                       );
//                     }
//                   },
//                 ),
//               ),
//             ).animate(target: enabled ? 0 : 1).blurXY(end: 1),
//           )
//               .animate(target: enabled ? 0 : 1)
//               .scaleXY(end: .88, curve: Curves.easeIn),
//         ),
//         const Gap(16),
//         ExcludeSemantics(
//           child: AnimatedText(
//             label,
//             style: Theme.of(context).textTheme.titleMedium,
//           ),
//         ),
//       ],
//     );
//   }
// }

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.buttonColor,
    required this.image,
    required this.useImage,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final Color buttonColor;
  final AssetGenImage image;
  final bool useImage;

  @override
  Widget build(BuildContext context) {
    // Проверим, запущен ли VPN (Connected) — пусть glow будет только тогда
    // (Можно передавать флаг извне или по-другому определять)
    final bool isConnectedGlow = enabled;
    log('isConnectedGlow $isConnectedGlow');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Обернём всё в Stack, чтобы "glow" был позади основной кнопки
        Stack(
          alignment: Alignment.center,
          children: [
            // 1) Наш "glow" круг (показываем только если Connected).
            if (isConnectedGlow) ...[
              _GlowCircle(color: buttonColor, delay: 0.seconds),
              _GlowCircle(color: buttonColor, delay: 1.seconds),
            ],
            // 2) Основная кнопка
            Semantics(
              button: true,
              enabled: enabled,
              label: label,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  // boxShadow: [
                  //   BoxShadow(
                  //     blurRadius: 16,
                  //     color: buttonColor.withAlpha(255),
                  //   ),
                  // ],
                ),
                width: 300,
                height: 300,
                child: Material(
                  key: const ValueKey("home_connection_button"),
                  shape: const CircleBorder(),
                  color: const Color.fromARGB(30, 204, 204, 204),
                  child: InkWell(
                    onTap: onTap,
                    child: TweenAnimationBuilder(
                      tween: ColorTween(end: buttonColor),
                      duration: const Duration(milliseconds: 250),
                      builder: (context, value, child) {
                        if (useImage) {
                          return image.image(
                            filterQuality: FilterQuality.medium,
                            fit: BoxFit.fill,
                          );
                        } else {
                          return Assets.images.logo.svg(fit: BoxFit.cover);
                        }
                      },
                    ),
                  ),
                ).animate(target: enabled ? 0 : 1).blurXY(end: 1),
              )
                  .animate(target: enabled ? 0 : 1)
                  .scaleXY(end: .88, curve: Curves.easeIn),
            ),
          ],
        ),
        const Gap(16),
        ExcludeSemantics(
          child: AnimatedText(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

/// Анимированный «пульсирующий» круг,
/// с зацикленной анимацией на 3 секунды, начиная через [delay].
class _GlowCircle extends StatelessWidget {
  final Color color;
  final Duration delay;

  const _GlowCircle({
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Слегка полупрозрачный
        color: color.withAlpha(240),
      ),
    )
        .animate(
          // Задержка перед запуском
          delay: delay,
          // Повторять анимацию бесконечно
          onPlay: (controller) => controller.repeat(),
        )
        // "Fade"
        .fade(
          begin: 1, // начальная непрозрачность
          end: 0.2, // конечная
          curve: Curves.linear,
          duration: 3.seconds,
        )
        // "Scale"
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.2, 1.2),
          curve: Curves.easeIn,
          duration: 3.seconds,
        );
  }
}
