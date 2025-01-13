import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/core/app_info/app_info_provider.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/core/login/login_manager_provider.dart';
import 'package:rostov_vpn/core/model/failures.dart';
import 'package:rostov_vpn/core/router/router.dart';
import 'package:rostov_vpn/features/home/widget/connection_button.dart';
import 'package:rostov_vpn/features/home/widget/empty_profiles_home_body.dart';
import 'package:rostov_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:rostov_vpn/features/profile/widget/profile_tile.dart';
import 'package:rostov_vpn/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:rostov_vpn/features/proxy/active/active_proxy_footer.dart';
import 'package:rostov_vpn/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    final loginState = ref.watch(loginManagerProvider);
    final isLoading = loginState?.isLoading ?? false;

    return Scaffold(
      backgroundColor: AppColors.darkGray,
      // Шапка с названием и логином
      appBar: AppBar(
        backgroundColor: AppColors.darkPink, // Фиолетово-розоватый цвет
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => const QuickSettingsRoute().push(context),
            icon: const Icon(FluentIcons.options_24_filled),
            tooltip: t.config.quickSettings,
            color: Colors.white,
          ),
          // IconButton(
          //   onPressed: () => const AddProfileRoute().push(context),
          //   icon: const Icon(FluentIcons.add_circle_24_filled),
          //   tooltip: t.profile.add.buttonText,
          //   color: Colors.white,
          // ),
        ],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomScrollView(
            slivers: [
              switch (activeProfile) {
                AsyncData(value: final profile?) => MultiSliver(
                    children: [
                      ProfileTile(profile: profile, isMain: true),
                      const SizedBox(height: 24),
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                // mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ConnectionButton(),
                                  ActiveProxyDelayIndicator(),
                                ],
                              ),
                            ),
                            // if (MediaQuery.sizeOf(context).width < 840)
                            ActiveProxyFooter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                AsyncData() => switch (hasAnyProfile) {
                    AsyncData(value: true) =>
                      const EmptyActiveProfileHomeBody(),
                    _ => const EmptyProfilesHomeBody(),
                  },
                AsyncError(:final error) =>
                  SliverErrorBodyPlaceholder(t.presentShortError(error)),
                _ => const SliverToBoxAdapter(),
              },
            ],
          ),
          // Если isLoading == true, показываем оверлей
          if (isLoading)
            const ColoredBox(
              color: AppColors.darkGray, // полупрозрачный фон
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.about.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 1,
        ),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
// class HomePage extends HookConsumerWidget {
//   const HomePage({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Для примера используем статичные тексты и цвета.
//     // В реальном приложении подставьте свои переводы/цвета/данные.
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       // Тёмная заливка фона
//       backgroundColor: Colors.black,
//       // Шапка с названием и логином
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF8B1679), // Фиолетово-розоватый цвет
//         title: const Text(
//           'Rostov VPN',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: false,
//         actions: [
//           // «Профиль» пользователя — можно заменить на иконку
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: Center(
//               child: Text(
//                 'Darkmen203',
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // «Глобус»
//           Expanded(
//             child: Center(
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   // Это просто пример: в реальном проекте можно использовать
//                   // svg-иконку или картинку глобуса, закрашенную нужным цветом.
//                   Container(
//                     width: 200,
//                     height: 200,
//                     decoration: const BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Color(0xFF8B1679),
//                     ),
//                   ),
//                   // Поверх можем добавить «карта мира» или что-то ещё
//                   const Icon(
//                     Icons.public, // иконка глобуса
//                     size: 100,
//                     color: Colors.black54,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // Текст (имя текущего профиля)
//           const Text(
//             'RostovVPN-DimaPC.json',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//             ),
//           ),
//           const SizedBox(height: 20),
//           // Большая кнопка «Пуск»
//           SizedBox(
//             width: 200,
//             height: 48,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFFFF0080), // Ярко-розовый
//               ),
//               onPressed: () {
//                 // Логика подключения VPN
//               },
//               child: const Text(
//                 'Пуск',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 16),
//           // Кнопка/ссылка «Settings to excluded apps»
//           TextButton(
//             onPressed: () {
//               // Открыть экран настроек
//             },
//             child: const Text(
//               'Settings to excluded apps',
//               style: TextStyle(color: Colors.white70),
//             ),
//           ),
//           const SizedBox(height: 16),
//         ],
//       ),
//       // BottomNavigationBar, стилизуем как на скриншоте
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: const Color(0xFF1C1C1C),
//         selectedItemColor: const Color(0xFFFF0080),
//         unselectedItemColor: Colors.white60,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: '',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: '',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.info_outline),
//             label: '',
//           ),
//         ],
//         // При необходимости обрабатывайте выбранный индекс
//         onTap: (index) {
//           // Переключение страниц
//         },
//       ),
//     );
//   }
// }
