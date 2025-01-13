// import 'package:fpdart/fpdart.dart';
// import 'package:rostov_vpn/features/geo_asset/data/geo_asset_data_providers.dart';
// import 'package:rostov_vpn/features/geo_asset/model/geo_asset_entity.dart';
// import 'package:rostov_vpn/utils/custom_loggers.dart';
// import 'package:rostov_vpn/utils/riverpod_utils.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';

// part 'geo_asset_notifier.g.dart';

// @riverpod
// class FetchGeoAsset extends _$FetchGeoAsset with AppLogger {
//   @override
//   Future<Unit?> build(String id) async {
//     ref.disposeDelay(const Duration(seconds: 10));
//     return null;
//   }

//   Future<void> fetch(GeoAssetEntity geoAsset) async {
//     state = const AsyncLoading();
//     state = await AsyncValue.guard(
//       () => ref
//           .read(geoAssetRepositoryProvider)
//           .requireValue
//           .update(geoAsset)
//           .getOrElse(
//         (failure) {
//           loggy.warning("error updating geo asset $failure", failure);
//           throw failure;
//         },
//       ).run(),
//     );
//   }
// }
