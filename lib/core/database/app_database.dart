import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:rostov_vpn/core/database/connection/database_connection.dart';
import 'package:rostov_vpn/core/database/converters/duration_converter.dart';
import 'package:rostov_vpn/core/database/tables/database_tables.dart';
import 'package:rostov_vpn/features/profile/model/profile_entity.dart';
import 'package:rostov_vpn/utils/custom_loggers.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [ProfileEntries])
class AppDatabase extends _$AppDatabase with InfraLogger {
  AppDatabase({required QueryExecutor connection}) : super(connection);

  AppDatabase.connect() : super(openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.alterTable(
            TableMigration(
              profileEntries,
              columnTransformer: {
                profileEntries.type: const Constant<String>('remote'),
                profileEntries.testUrl: const Constant<String>(''),
              },
              newColumns: [profileEntries.type, profileEntries.testUrl],
            ),
          );
          await m.database.customStatement(
            "UPDATE profile_entries SET test_url = NULL WHERE test_url = '';",
          );
        }

        if (from >= 2 && from < 4) {
          try {
            await m.addColumn(profileEntries, profileEntries.testUrl);
          } on Exception catch (err) {
            loggy.debug(err);
          }
        }

        if (from < 5) {
          await m.database.customStatement(
            'DROP TABLE IF EXISTS geo_asset_entries;',
          );
        }
      },
      beforeOpen: (details) async {
        if (kDebugMode) {
          loggy.debug('database opened with schema version ${details.versionBefore}');
        }
      },
    );
  }
}
