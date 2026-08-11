import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/app/backup/app_backup_service.dart';
import 'package:open_pharma_stock/app/settings/app_settings.dart';
import 'package:open_pharma_stock/features/inventory/data/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('backup export/import restores database rows and preferences', () async {
    SharedPreferences.setMockInitialValues({
      'tour.auto_start_enabled': false,
      'export.custom_txt_template': 'Teste {{codigo}}',
    });
    final preferences = await SharedPreferences.getInstance();
    final settings = AppSettingsController(preferences: preferences);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final service = AppBackupService(
      database: database,
      settingsController: settings,
    );

    await database.into(database.inventorySessions).insert(
      InventorySessionsCompanion.insert(
        id: 'session-1',
        name: 'Prateleira A',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
    await database.into(database.scanEvents).insert(
      ScanEventsCompanion.insert(
        id: 'scan-1',
        sessionId: 'session-1',
        productCode: '05601234567890',
        codeType: 'GTIN',
        raw: '0105601234567890',
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    );
    await database.into(database.medicationCatalogEntries).insert(
      MedicationCatalogEntriesCompanion.insert(
        id: 'med-1',
        sourceName: 'csv_manual',
        sourcePriority: 1000,
        sourceRecordId: 'csv-1',
        canonicalCode: '05601234567890',
        displayName: 'Medicamento Teste',
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
    await database.into(database.medicationLookupCodes).insert(
      MedicationLookupCodesCompanion.insert(
        id: 'lookup-1',
        medicationId: 'med-1',
        normalizedCode: '05601234567890',
        codeKind: 'GTIN',
        isPrimary: const Value(true),
      ),
    );

    final tempDir = await Directory.systemTemp.createTemp('ops-backup-test');
    final backupPath = '${tempDir.path}${Platform.pathSeparator}backup.json';

    final exportSummary = await service.exportToPath(backupPath);
    expect(exportSummary.sessionCount, 1);
    expect(exportSummary.scanCount, 1);
    expect(exportSummary.catalogEntryCount, 1);
    expect(File(backupPath).existsSync(), isTrue);

    await database.delete(database.scanEvents).go();
    await database.delete(database.medicationLookupCodes).go();
    await database.delete(database.medicationCatalogEntries).go();
    await database.delete(database.inventorySessions).go();
    await settings.setTourAutoStartEnabled(true);
    await settings.setCustomTxtTemplate('Alterado');

    final importSummary = await service.importFromPath(backupPath);

    expect(importSummary.sessionCount, 1);
    expect(importSummary.scanCount, 1);
    expect(importSummary.catalogEntryCount, 1);
    expect((await database.select(database.inventorySessions).get()).length, 1);
    expect((await database.select(database.scanEvents).get()).length, 1);
    expect(
      (await database.select(database.medicationCatalogEntries).get()).length,
      1,
    );
    expect(settings.value.tourAutoStartEnabled, isFalse);
    expect(settings.value.customTxtTemplate, 'Teste {{codigo}}');

    await database.close();
    await tempDir.delete(recursive: true);
  });
}
