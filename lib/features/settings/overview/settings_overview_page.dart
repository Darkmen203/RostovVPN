import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:rostov_vpn/constants/colors.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/features/common/nested_app_bar.dart';
import 'package:rostov_vpn/features/settings/widgets/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsOverviewPage extends HookConsumerWidget {
  const SettingsOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkGray,
      body: CustomScrollView(
        slivers: [
          NestedAppBar(
            title: Text(t.settings.pageTitle),
            automaticallyImplyLeading: false,
          ),
          SliverList.list(
            children: [
              SettingsSection(t.settings.general.sectionTitle),
              const GeneralSettingTiles(),
              const PlatformSettingsTiles(),
              const SettingsDivider(),
              SettingsSection(t.settings.advanced.sectionTitle),
              const AdvancedSettingTiles(),
              const Gap(16),
            ],
          ),
        ],
      ),
    );
  }
}
