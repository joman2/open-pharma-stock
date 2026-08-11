import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:open_pharma_stock/app/backup/app_backup_service.dart';
import 'package:open_pharma_stock/app/settings/app_settings.dart';
import 'package:open_pharma_stock/features/inventory/data/app_database.dart';

AppBackupService createTestBackupService({
  required AppSettingsController settingsController,
}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppBackupService(
    database: AppDatabase.forTesting(NativeDatabase.memory()),
    settingsController: settingsController,
  );
}
