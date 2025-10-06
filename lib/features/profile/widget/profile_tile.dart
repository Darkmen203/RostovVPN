import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/core/router/router.dart';
import 'package:rostov_vpn/features/profile/model/profile_entity.dart';
import 'package:rostov_vpn/features/profile/overview/profiles_overview_notifier.dart';
import 'package:rostov_vpn/gen/fonts.gen.dart';
import 'package:rostov_vpn/utils/utils.dart';

class ProfileTile extends HookConsumerWidget {
  const ProfileTile({
    super.key,
    required this.profile,
    this.isMain = false,
  });

  final ProfileEntity profile;
  final bool isMain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final remoteProfile = profile is RemoteProfileEntity
        ? profile as RemoteProfileEntity
        : null;
    final subInfo = remoteProfile?.subInfo;
    final isSelecting = useState(false);

    final effectiveMargin = isMain
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : const EdgeInsets.only(left: 12, right: 12, bottom: 12);
    final effectiveElevation = profile.active ? 12.0 : 4.0;
    final effectiveOutlineColor =
        profile.active ? theme.colorScheme.outlineVariant : Colors.transparent;

    Future<void> onTap() async {
      if (isMain) {
        const ProfilesOverviewRoute().go(context);
        return;
      }
      if (profile.active || isSelecting.value) return;

      isSelecting.value = true;
      try {
        await ref
            .read(profilesOverviewNotifierProvider.notifier)
            .selectActiveProfile(profile.id);

        if (context.mounted && context.canPop()) {
          context.pop();
        }
      } catch (error) {
        if (context.mounted) {
          CustomToast.error(error.toString()).show(context);
        }
      } finally {
        isSelecting.value = false;
      }
    }

    return Card(
      margin: effectiveMargin,
      elevation: effectiveElevation,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: effectiveOutlineColor),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      shadowColor: Colors.transparent,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Semantics(
                button: true,
                sortKey: isMain ? const OrdinalSortKey(0) : null,
                focused: isMain,
                liveRegion: isMain,
                namesRoute: isMain,
                label: isMain ? t.profile.activeProfileBtnSemanticLabel : null,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMain)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Material(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.transparent,
                              clipBehavior: Clip.antiAlias,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      profile.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontFamily: FontFamily.emoji,
                                      ),
                                      semanticsLabel: t.profile
                                          .activeProfileNameSemanticLabel(
                                        name: profile.name,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    FluentIcons.caret_down_16_filled,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Text(
                            profile.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                            semanticsLabel: profile.active
                                ? t.profile.activeProfileNameSemanticLabel(
                                    name: profile.name,
                                  )
                                : t.profile.nonActiveProfileBtnSemanticLabel(
                                    name: profile.name,
                                  ),
                          ),
                        if (subInfo != null) ...[
                          const Gap(4),
                          RemainingTrafficIndicator(subInfo.ratio),
                          const Gap(4),
                          ProfileSubscriptionInfo(subInfo),
                          const Gap(4),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSubscriptionInfo extends HookConsumerWidget {
  const ProfileSubscriptionInfo(this.subInfo, {super.key});

  final SubscriptionInfo subInfo;

  (String, Color?) remainingText(TranslationsEn t, ThemeData theme) {
    if (subInfo.isExpired) {
      return (t.profile.subscription.expired, theme.colorScheme.error);
    } else if (subInfo.ratio >= 1) {
      return (t.profile.subscription.noTraffic, theme.colorScheme.error);
    } else if (subInfo.remaining.inDays > 365) {
      return (t.profile.subscription.remainingDuration(duration: "∞"), null);
    } else {
      return (
        t.profile.subscription.remainingDuration(
          duration: subInfo.remaining.inDays,
        ),
        null,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final remaining = remainingText(t, theme);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Flexible(
            child: Text(
              subInfo.total > 10 * 1099511627776 // 10TB
                  ? "∞ GiB"
                  : subInfo.consumption.sizeOf(subInfo.total),
              semanticsLabel:
                  t.profile.subscription.remainingTrafficSemanticLabel(
                consumed: subInfo.consumption.sizeGB(),
                total: subInfo.total.sizeGB(),
              ),
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Flexible(
          child: Text(
            remaining.$1,
            style: theme.textTheme.bodySmall?.copyWith(color: remaining.$2),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class RemainingTrafficIndicator extends StatelessWidget {
  const RemainingTrafficIndicator(this.ratio, {super.key});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final startColor = ratio < 0.25
        ? const Color.fromRGBO(93, 205, 251, 1.0)
        : ratio < 0.65
            ? const Color.fromRGBO(205, 199, 64, 1.0)
            : const Color.fromRGBO(241, 82, 81, 1.0);
    final endColor = ratio < 0.25
        ? const Color.fromRGBO(49, 146, 248, 1.0)
        : ratio < 0.65
            ? const Color.fromRGBO(98, 115, 32, 1.0)
            : const Color.fromRGBO(139, 30, 36, 1.0);

    return LinearPercentIndicator(
      percent: ratio,
      animation: true,
      padding: EdgeInsets.zero,
      lineHeight: 6,
      barRadius: const Radius.circular(16),
      linearGradient: LinearGradient(
        colors: [startColor, endColor],
      ),
    );
  }
}
