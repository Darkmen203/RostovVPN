import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rostov_vpn/core/localization/translations.dart';
import 'package:rostov_vpn/features/common/nested_app_bar.dart';
import 'package:rostov_vpn/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:rostov_vpn/features/proxy/widget/proxy_tile.dart';
import 'package:rostov_vpn/utils/utils.dart';

class ProxiesOverviewPage extends HookConsumerWidget with PresLogger {
  const ProxiesOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final asyncProxies = ref.watch(proxiesOverviewNotifierProvider);
    final notifier = ref.watch(proxiesOverviewNotifierProvider.notifier);
    final sortBy = ref.watch(proxiesSortNotifierProvider);
    final isChangingProxy = useState(false);

    Future<void> changeProxy(String groupTag, String proxyTag) async {
      if (isChangingProxy.value) return;
      isChangingProxy.value = true;
      try {
        await notifier.changeProxy(groupTag, proxyTag);
      } catch (error, stackTrace) {
        loggy.warning('change proxy failed', error, stackTrace);
        if (context.mounted) {
          CustomToast.error(error.toString()).show(context);
        }
      } finally {
        isChangingProxy.value = false;
      }
    }

    final appBar = NestedAppBar(
      title: Text(t.proxies.pageTitle),
      actions: [
        PopupMenuButton<ProxiesSort>(
          initialValue: sortBy,
          onSelected: ref.read(proxiesSortNotifierProvider.notifier).update,
          icon: const Icon(FluentIcons.arrow_sort_24_regular),
          tooltip: t.proxies.sortTooltip,
          itemBuilder: (context) {
            return [
              ...ProxiesSort.values.map(
                (e) => PopupMenuItem(
                  value: e,
                  child: Text(e.present(t)),
                ),
              ),
            ];
          },
        ),
      ],
    );

    switch (asyncProxies) {
      case AsyncData(value: final groups):
        if (groups.isEmpty) {
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                appBar,
                SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.proxies.emptyProxiesMsg),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final group = groups.first;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              appBar,
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  if (!PlatformUtils.isDesktop && width < 648) {
                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 86),
                      sliver: SliverList.builder(
                        itemBuilder: (_, index) {
                          final proxy = group.items[index];
                          return ProxyTile(
                            proxy,
                            selected: group.selected == proxy.tag,
                            onSelect: () async => changeProxy(group.tag, proxy.tag),
                          );
                        },
                        itemCount: group.items.length,
                      ),
                    );
                  }

                  return SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (width / 268).floor(),
                      mainAxisExtent: 68,
                    ),
                    itemBuilder: (context, index) {
                      final proxy = group.items[index];
                      return ProxyTile(
                        proxy,
                        selected: group.selected == proxy.tag,
                        onSelect: () async => changeProxy(group.tag, proxy.tag),
                      );
                    },
                    itemCount: group.items.length,
                  );
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async => notifier.urlTest(group.tag),
            tooltip: t.proxies.delayTestTooltip,
            child: const Icon(FluentIcons.flash_24_filled),
          ),
        );

      case AsyncError(:final error):
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              appBar,
              SliverErrorBodyPlaceholder(
                error.toString(),
                icon: null,
              ),
            ],
          ),
        );

      case AsyncLoading():
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              appBar,
              const SliverLoadingBodyPlaceholder(),
            ],
          ),
        );

      default:
        return const Scaffold();
    }
  }
}
