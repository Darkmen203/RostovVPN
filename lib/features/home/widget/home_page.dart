import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/core/app_info/app_info_provider.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/core/login/login_manager_provider.dart';
import 'package:rostov_vpn/core/model/failures.dart';
import 'package:rostov_vpn/core/router/router.dart';
import 'package:rostov_vpn/core/providers/animations_provider.dart';
import 'package:rostov_vpn/features/home/widget/connection_button.dart';
import 'package:rostov_vpn/features/home/widget/empty_profiles_home_body.dart';
import 'package:rostov_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:rostov_vpn/features/profile/widget/profile_tile.dart';
import 'package:rostov_vpn/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:rostov_vpn/features/proxy/active/active_proxy_footer.dart';
import 'package:rostov_vpn/utils/utils.dart';
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

    useEffect(() {
      final notifier = ref.read(animationsEnabledProvider.notifier);
      notifier.state = true;
      return () {
        notifier.state = false;
      };
    }, const []);
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
