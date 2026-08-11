import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('InventorySessionRow')
class InventorySessions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get barcodeQuantityPromptEnabled =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ScanEventRow')
class ScanEvents extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(InventorySessions, #id)();
  TextColumn get productCode => text()();
  TextColumn get codeType => text()();
  TextColumn get raw => text()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get lot => text().nullable()();
  TextColumn get expiry => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MedicationCatalogEntryRow')
class MedicationCatalogEntries extends Table {
  @override
  String get tableName => 'medication_catalog_entries';

  TextColumn get id => text()();
  TextColumn get sourceName => text()();
  IntColumn get sourcePriority => integer()();
  TextColumn get sourceRecordId => text()();
  TextColumn get canonicalCode => text()();
  TextColumn get displayName => text()();
  TextColumn get activeSubstance => text().nullable()();
  TextColumn get strength => text().nullable()();
  TextColumn get pharmaceuticalForm => text().nullable()();
  TextColumn get presentation => text().nullable()();
  TextColumn get holder => text().nullable()();
  TextColumn get leafletUrl => text().nullable()();
  TextColumn get rcmUrl => text().nullable()();
  TextColumn get sourceUrl => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MedicationLookupCodeRow')
class MedicationLookupCodes extends Table {
  @override
  String get tableName => 'medication_lookup_codes';

  TextColumn get id => text()();
  TextColumn get medicationId =>
      text().references(MedicationCatalogEntries, #id)();
  TextColumn get normalizedCode => text()();
  TextColumn get codeKind => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MedicationEnrichmentStatusRow')
class MedicationEnrichmentStatuses extends Table {
  @override
  String get tableName => 'medication_enrichment_status';

  TextColumn get id => text()();
  TextColumn get normalizedCode => text()();
  TextColumn get codeKind => text()();
  DateTimeColumn get lastAttemptedAt => dateTime().nullable()();
  DateTimeColumn get lastSucceededAt => dateTime().nullable()();
  DateTimeColumn get lastFailedAt => dateTime().nullable()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  TextColumn get lastProviderName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MedicationCatalogStateRow')
class MedicationCatalogStateTable extends Table {
  @override
  String get tableName => 'medication_catalog_state';

  TextColumn get id => text()();
  DateTimeColumn get csvLastImportedAt => dateTime().nullable()();
  IntColumn get csvEntryCount => integer().withDefault(const Constant(0))();
  TextColumn get csvSourceLabel => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    InventorySessions,
    ScanEvents,
    MedicationCatalogEntries,
    MedicationLookupCodes,
    MedicationEnrichmentStatuses,
    MedicationCatalogStateTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createIndexes();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await customStatement(
          'ALTER TABLE inventory_sessions '
          'ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'UPDATE inventory_sessions SET updated_at = created_at '
          'WHERE updated_at = 0',
        );
        await customStatement('DROP TABLE IF EXISTS inventory_items');
        await customStatement('DROP TABLE IF EXISTS scanned_serials');
        await migrator.createTable(scanEvents);
        await _createIndexes();
      }
      if (from < 3) {
        if (from >= 2) {
          await customStatement('ALTER TABLE scan_events ADD COLUMN lot TEXT');
          await customStatement(
            'ALTER TABLE scan_events ADD COLUMN expiry TEXT',
          );
        }
      }
      if (from < 4) {
        await migrator.createTable(medicationCatalogEntries);
        await migrator.createTable(medicationLookupCodes);
        await migrator.createTable(medicationEnrichmentStatuses);
        await migrator.createTable(medicationCatalogStateTable);
        await _createMedicationIndexes();
      }
      if (from < 5) {
        await customStatement(
          'ALTER TABLE medication_enrichment_status ADD COLUMN last_provider_name TEXT',
        );
        await _createMedicationIndexes();
      }
      if (from < 6) {
        await customStatement(
          'ALTER TABLE inventory_sessions ADD COLUMN barcode_quantity_prompt_enabled INTEGER NOT NULL DEFAULT 0',
        );
      }
    },
  );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_scan_events_session_product '
      'ON scan_events(session_id, product_code)',
    );
    await _createMedicationIndexes();
  }

  Future<void> _createMedicationIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_medication_lookup_codes_code '
      'ON medication_lookup_codes(normalized_code, code_kind)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_medication_lookup_codes_medication '
      'ON medication_lookup_codes(medication_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_medication_status_code '
      'ON medication_enrichment_status(normalized_code, code_kind)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_medication_entries_priority_updated '
      'ON medication_catalog_entries(source_priority, updated_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_medication_status_retry '
      'ON medication_enrichment_status(normalized_code, code_kind, next_retry_at)',
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(
      '${dbFolder.path}${Platform.pathSeparator}open_pharma_stock.sqlite',
    );
    return NativeDatabase(file);
  });
}
