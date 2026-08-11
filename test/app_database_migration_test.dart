import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/features/inventory/data/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test('migrates a v4 database to include provider-aware enrichment status', () async {
    final tempDir = await Directory.systemTemp.createTemp('ops-db-test');
    final dbPath = p.join(tempDir.path, 'legacy.sqlite');
    final sqlite = sqlite3.open(dbPath);
    sqlite.execute(
      'CREATE TABLE inventory_sessions (id TEXT PRIMARY KEY, name TEXT NOT NULL, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL);',
    );
    sqlite.execute(
      'CREATE TABLE scan_events (id TEXT PRIMARY KEY, session_id TEXT NOT NULL, product_code TEXT NOT NULL, code_type TEXT NOT NULL, raw TEXT NOT NULL, serial_number TEXT, lot TEXT, expiry TEXT, created_at INTEGER NOT NULL, is_deleted INTEGER NOT NULL DEFAULT 0);',
    );
    sqlite.execute(
      'CREATE TABLE medication_catalog_entries (id TEXT PRIMARY KEY, source_name TEXT NOT NULL, source_priority INTEGER NOT NULL, source_record_id TEXT NOT NULL, canonical_code TEXT NOT NULL, display_name TEXT NOT NULL, active_substance TEXT, strength TEXT, pharmaceutical_form TEXT, presentation TEXT, holder TEXT, leaflet_url TEXT, rcm_url TEXT, source_url TEXT, image_url TEXT, updated_at INTEGER NOT NULL);',
    );
    sqlite.execute(
      'CREATE TABLE medication_lookup_codes (id TEXT PRIMARY KEY, medication_id TEXT NOT NULL, normalized_code TEXT NOT NULL, code_kind TEXT NOT NULL, is_primary INTEGER NOT NULL DEFAULT 0);',
    );
    sqlite.execute(
      'CREATE TABLE medication_enrichment_status (id TEXT PRIMARY KEY, normalized_code TEXT NOT NULL, code_kind TEXT NOT NULL, last_attempted_at INTEGER, last_succeeded_at INTEGER, last_failed_at INTEGER, attempt_count INTEGER NOT NULL DEFAULT 0, next_retry_at INTEGER, last_error TEXT);',
    );
    sqlite.execute(
      'CREATE TABLE medication_catalog_state (id TEXT PRIMARY KEY, csv_last_imported_at INTEGER, csv_entry_count INTEGER NOT NULL DEFAULT 0, csv_source_label TEXT);',
    );
    sqlite.execute('PRAGMA user_version = 4;');
    sqlite.dispose();

    final database = AppDatabase.forTesting(NativeDatabase(File(dbPath)));
    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table'",
        )
        .get();
    final names = tables.map((row) => row.read<String>('name')).toSet();

    expect(names, contains('medication_catalog_entries'));
    expect(names, contains('medication_lookup_codes'));
    expect(names, contains('medication_enrichment_status'));
    expect(names, contains('medication_catalog_state'));
    final enrichmentColumns = await database.customSelect(
      "PRAGMA table_info('medication_enrichment_status')",
    ).get();
    final columnNames = enrichmentColumns
        .map((row) => row.read<String>('name'))
        .toSet();
    expect(columnNames, contains('last_provider_name'));

    await database.close();
    await tempDir.delete(recursive: true);
  });
}
