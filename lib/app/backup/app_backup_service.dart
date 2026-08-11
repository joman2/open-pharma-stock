import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/inventory/data/app_database.dart';
import '../settings/app_settings.dart';
import 'app_backup_platform_bridge.dart';

class AppBackupSummary {
  const AppBackupSummary({
    required this.sessionCount,
    required this.scanCount,
    required this.catalogEntryCount,
    required this.lookupCodeCount,
    required this.preferenceCount,
  });

  final int sessionCount;
  final int scanCount;
  final int catalogEntryCount;
  final int lookupCodeCount;
  final int preferenceCount;
}

class AppBackupExportResult {
  const AppBackupExportResult({required this.path, required this.summary});

  final String path;
  final AppBackupSummary summary;
}

class BackupImportCandidate {
  const BackupImportCandidate({
    required this.path,
    required this.label,
    required this.modifiedAt,
  });

  final String path;
  final String label;
  final DateTime modifiedAt;
}

class AppBackupService {
  AppBackupService({
    required AppDatabase database,
    required AppSettingsController settingsController,
    AppBackupPlatformBridge? platformBridge,
  }) : _database = database,
       _settingsController = settingsController,
       _platformBridge = platformBridge ?? AppBackupPlatformBridge();

  static const backupFormatVersion = 1;

  final AppDatabase _database;
  final AppSettingsController _settingsController;
  final AppBackupPlatformBridge _platformBridge;

  Future<AppBackupSummary> exportToPath(String path) async {
    final payload = await _buildPayload();
    final encoder = const JsonEncoder.withIndent('  ');
    await File(path).writeAsString(encoder.convert(payload));
    return _summaryFromPayload(payload);
  }

  Future<AppBackupExportResult> exportNamedBackup(String fileName) async {
    final payload = await _buildPayload();
    final encoder = const JsonEncoder.withIndent('  ');
    final content = encoder.convert(payload);
    if (Platform.isAndroid) {
      final downloadPath = await _platformBridge.writeBackupToDownloads(
        fileName: fileName,
        content: content,
      );
      if (downloadPath != null && downloadPath.isNotEmpty) {
        return AppBackupExportResult(
          path: downloadPath,
          summary: _summaryFromPayload(payload),
        );
      }
    }

    final path = await defaultExportPath(fileName);
    await File(path).writeAsString(content);
    return AppBackupExportResult(
      path: path,
      summary: _summaryFromPayload(payload),
    );
  }

  Future<String> defaultExportPath(String fileName) async {
    final directory = await _preferredBackupDirectory();
    await directory.create(recursive: true);
    return '${directory.path}${Platform.pathSeparator}$fileName';
  }

  Future<List<BackupImportCandidate>> findImportCandidates() async {
    final directories = <String>{
      '/storage/emulated/0/Download',
      '/sdcard/Download',
      '/storage/emulated/0/Documents',
      '/sdcard/Documents',
      '/storage/emulated/0/Android/data/com.example.open_pharma_stock/files',
      '/sdcard/Android/data/com.example.open_pharma_stock/files',
      '/storage/emulated/0/Android/data/com.open.pharma.stock/files',
      '/sdcard/Android/data/com.open.pharma.stock/files',
    };
    final candidates = <BackupImportCandidate>[];
    for (final path in directories) {
      final directory = Directory(path);
      if (!await directory.exists()) {
        continue;
      }
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) {
          continue;
        }
        final name = entity.uri.pathSegments.isEmpty
            ? entity.path
            : entity.uri.pathSegments.last;
        final lowercase = name.toLowerCase();
        if (!lowercase.endsWith('.opsbackup.json') &&
            !lowercase.contains('open-pharma-stock-backup')) {
          continue;
        }
        final stat = await entity.stat();
        candidates.add(
          BackupImportCandidate(
            path: entity.path,
            label: name,
            modifiedAt: stat.modified,
          ),
        );
      }
    }
    candidates.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return candidates;
  }

  Future<AppBackupSummary> importFromPath(String path) async {
    final raw = jsonDecode(await File(path).readAsString());
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Formato de backup inválido.');
    }
    final version = raw['formatVersion'];
    if (version != backupFormatVersion) {
      throw FormatException('Versão de backup não suportada: $version');
    }

    final preferences = _readSectionMap(raw, 'preferences');
    final sessions = _readSectionList(raw, 'inventorySessions');
    final scans = _readSectionList(raw, 'scanEvents');
    final catalogEntries = _readSectionList(raw, 'medicationCatalogEntries');
    final lookupCodes = _readSectionList(raw, 'medicationLookupCodes');
    final enrichmentStatuses = _readSectionList(
      raw,
      'medicationEnrichmentStatus',
    );
    final catalogState = _readSectionList(raw, 'medicationCatalogState');

    await _database.transaction(() async {
      await _database.delete(_database.scanEvents).go();
      await _database.delete(_database.medicationLookupCodes).go();
      await _database.delete(_database.medicationEnrichmentStatuses).go();
      await _database.delete(_database.medicationCatalogStateTable).go();
      await _database.delete(_database.medicationCatalogEntries).go();
      await _database.delete(_database.inventorySessions).go();

      await _database.batch((batch) {
        batch.insertAll(
          _database.inventorySessions,
          sessions.map(_inventorySessionCompanion).toList(),
        );
        batch.insertAll(
          _database.scanEvents,
          scans.map(_scanEventCompanion).toList(),
        );
        batch.insertAll(
          _database.medicationCatalogEntries,
          catalogEntries.map(_catalogEntryCompanion).toList(),
        );
        batch.insertAll(
          _database.medicationLookupCodes,
          lookupCodes.map(_lookupCodeCompanion).toList(),
        );
        batch.insertAll(
          _database.medicationEnrichmentStatuses,
          enrichmentStatuses.map(_enrichmentStatusCompanion).toList(),
        );
        batch.insertAll(
          _database.medicationCatalogStateTable,
          catalogState.map(_catalogStateCompanion).toList(),
        );
      });
    });

    await _settingsController.restoreAllPreferences(preferences);
    return AppBackupSummary(
      sessionCount: sessions.length,
      scanCount: scans.length,
      catalogEntryCount: catalogEntries.length,
      lookupCodeCount: lookupCodes.length,
      preferenceCount: preferences.length,
    );
  }

  Future<Map<String, Object?>> _buildPayload() async {
    final sessions = await _database.select(_database.inventorySessions).get();
    final scans = await _database.select(_database.scanEvents).get();
    final catalogEntries = await _database
        .select(_database.medicationCatalogEntries)
        .get();
    final lookupCodes = await _database
        .select(_database.medicationLookupCodes)
        .get();
    final enrichmentStatuses = await _database
        .select(_database.medicationEnrichmentStatuses)
        .get();
    final catalogState = await _database
        .select(_database.medicationCatalogStateTable)
        .get();

    return {
      'formatVersion': backupFormatVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'preferences': _settingsController.exportAllPreferences(),
      'inventorySessions': sessions.map(_inventorySessionMap).toList(),
      'scanEvents': scans.map(_scanEventMap).toList(),
      'medicationCatalogEntries': catalogEntries.map(_catalogEntryMap).toList(),
      'medicationLookupCodes': lookupCodes.map(_lookupCodeMap).toList(),
      'medicationEnrichmentStatus': enrichmentStatuses
          .map(_enrichmentStatusMap)
          .toList(),
      'medicationCatalogState': catalogState.map(_catalogStateMap).toList(),
    };
  }

  AppBackupSummary _summaryFromPayload(Map<String, Object?> payload) {
    final preferences = _readSectionMap(payload, 'preferences');
    return AppBackupSummary(
      sessionCount: _readSectionList(payload, 'inventorySessions').length,
      scanCount: _readSectionList(payload, 'scanEvents').length,
      catalogEntryCount:
          _readSectionList(payload, 'medicationCatalogEntries').length,
      lookupCodeCount: _readSectionList(payload, 'medicationLookupCodes').length,
      preferenceCount: preferences.length,
    );
  }

  Map<String, Object?> _inventorySessionMap(InventorySessionRow row) => {
    'id': row.id,
    'name': row.name,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  };

  InventorySessionsCompanion _inventorySessionCompanion(
    Map<String, Object?> row,
  ) => InventorySessionsCompanion.insert(
    id: row['id']! as String,
    name: row['name']! as String,
    createdAt: _readDateTime(row, 'createdAt'),
    updatedAt: _readDateTime(row, 'updatedAt'),
  );

  Map<String, Object?> _scanEventMap(ScanEventRow row) => {
    'id': row.id,
    'sessionId': row.sessionId,
    'productCode': row.productCode,
    'codeType': row.codeType,
    'raw': row.raw,
    'serialNumber': row.serialNumber,
    'lot': row.lot,
    'expiry': row.expiry,
    'createdAt': row.createdAt.toUtc().toIso8601String(),
    'isDeleted': row.isDeleted,
  };

  ScanEventsCompanion _scanEventCompanion(Map<String, Object?> row) =>
      ScanEventsCompanion.insert(
        id: row['id']! as String,
        sessionId: row['sessionId']! as String,
        productCode: row['productCode']! as String,
        codeType: row['codeType']! as String,
        raw: row['raw']! as String,
        serialNumber: Value(_value<String>(row['serialNumber'])),
        lot: Value(_value<String>(row['lot'])),
        expiry: Value(_value<String>(row['expiry'])),
        createdAt: _readDateTime(row, 'createdAt'),
        isDeleted: Value(_value<bool>(row['isDeleted']) ?? false),
      );

  Map<String, Object?> _catalogEntryMap(MedicationCatalogEntryRow row) => {
    'id': row.id,
    'sourceName': row.sourceName,
    'sourcePriority': row.sourcePriority,
    'sourceRecordId': row.sourceRecordId,
    'canonicalCode': row.canonicalCode,
    'displayName': row.displayName,
    'activeSubstance': row.activeSubstance,
    'strength': row.strength,
    'pharmaceuticalForm': row.pharmaceuticalForm,
    'presentation': row.presentation,
    'holder': row.holder,
    'leafletUrl': row.leafletUrl,
    'rcmUrl': row.rcmUrl,
    'sourceUrl': row.sourceUrl,
    'imageUrl': row.imageUrl,
    'updatedAt': row.updatedAt.toUtc().toIso8601String(),
  };

  MedicationCatalogEntriesCompanion _catalogEntryCompanion(
    Map<String, Object?> row,
  ) => MedicationCatalogEntriesCompanion.insert(
    id: row['id']! as String,
    sourceName: row['sourceName']! as String,
    sourcePriority: row['sourcePriority']! as int,
    sourceRecordId: row['sourceRecordId']! as String,
    canonicalCode: row['canonicalCode']! as String,
    displayName: row['displayName']! as String,
    activeSubstance: Value(_value<String>(row['activeSubstance'])),
    strength: Value(_value<String>(row['strength'])),
    pharmaceuticalForm: Value(_value<String>(row['pharmaceuticalForm'])),
    presentation: Value(_value<String>(row['presentation'])),
    holder: Value(_value<String>(row['holder'])),
    leafletUrl: Value(_value<String>(row['leafletUrl'])),
    rcmUrl: Value(_value<String>(row['rcmUrl'])),
    sourceUrl: Value(_value<String>(row['sourceUrl'])),
    imageUrl: Value(_value<String>(row['imageUrl'])),
    updatedAt: _readDateTime(row, 'updatedAt'),
  );

  Map<String, Object?> _lookupCodeMap(MedicationLookupCodeRow row) => {
    'id': row.id,
    'medicationId': row.medicationId,
    'normalizedCode': row.normalizedCode,
    'codeKind': row.codeKind,
    'isPrimary': row.isPrimary,
  };

  MedicationLookupCodesCompanion _lookupCodeCompanion(
    Map<String, Object?> row,
  ) => MedicationLookupCodesCompanion.insert(
    id: row['id']! as String,
    medicationId: row['medicationId']! as String,
    normalizedCode: row['normalizedCode']! as String,
    codeKind: row['codeKind']! as String,
    isPrimary: Value(_value<bool>(row['isPrimary']) ?? false),
  );

  Map<String, Object?> _enrichmentStatusMap(
    MedicationEnrichmentStatusRow row,
  ) => {
    'id': row.id,
    'normalizedCode': row.normalizedCode,
    'codeKind': row.codeKind,
    'lastAttemptedAt': row.lastAttemptedAt?.toUtc().toIso8601String(),
    'lastSucceededAt': row.lastSucceededAt?.toUtc().toIso8601String(),
    'lastFailedAt': row.lastFailedAt?.toUtc().toIso8601String(),
    'attemptCount': row.attemptCount,
    'nextRetryAt': row.nextRetryAt?.toUtc().toIso8601String(),
    'lastError': row.lastError,
    'lastProviderName': row.lastProviderName,
  };

  MedicationEnrichmentStatusesCompanion _enrichmentStatusCompanion(
    Map<String, Object?> row,
  ) => MedicationEnrichmentStatusesCompanion.insert(
    id: row['id']! as String,
    normalizedCode: row['normalizedCode']! as String,
    codeKind: row['codeKind']! as String,
    lastAttemptedAt: Value(_nullableDateTime(row, 'lastAttemptedAt')),
    lastSucceededAt: Value(_nullableDateTime(row, 'lastSucceededAt')),
    lastFailedAt: Value(_nullableDateTime(row, 'lastFailedAt')),
    attemptCount: Value(_value<int>(row['attemptCount']) ?? 0),
    nextRetryAt: Value(_nullableDateTime(row, 'nextRetryAt')),
    lastError: Value(_value<String>(row['lastError'])),
    lastProviderName: Value(_value<String>(row['lastProviderName'])),
  );

  Map<String, Object?> _catalogStateMap(MedicationCatalogStateRow row) => {
    'id': row.id,
    'csvLastImportedAt': row.csvLastImportedAt?.toUtc().toIso8601String(),
    'csvEntryCount': row.csvEntryCount,
    'csvSourceLabel': row.csvSourceLabel,
  };

  MedicationCatalogStateTableCompanion _catalogStateCompanion(
    Map<String, Object?> row,
  ) => MedicationCatalogStateTableCompanion.insert(
    id: row['id']! as String,
    csvLastImportedAt: Value(_nullableDateTime(row, 'csvLastImportedAt')),
    csvEntryCount: Value(_value<int>(row['csvEntryCount']) ?? 0),
    csvSourceLabel: Value(_value<String>(row['csvSourceLabel'])),
  );

  Map<String, Object?> _readSectionMap(
    Map<String, Object?> payload,
    String key,
  ) {
    final raw = payload[key];
    if (raw == null) {
      return <String, Object?>{};
    }
    if (raw is! Map) {
      throw FormatException('Secção inválida: $key');
    }
    return raw.map((mapKey, value) => MapEntry('$mapKey', value as Object?));
  }

  List<Map<String, Object?>> _readSectionList(
    Map<String, Object?> payload,
    String key,
  ) {
    final raw = payload[key];
    if (raw == null) {
      return const [];
    }
    if (raw is! List) {
      throw FormatException('Lista inválida: $key');
    }
    return raw.map((entry) {
      if (entry is! Map) {
        throw FormatException('Entrada inválida em $key');
      }
      return entry.map(
        (mapKey, value) => MapEntry('$mapKey', value as Object?),
      );
    }).toList();
  }

  DateTime _readDateTime(Map<String, Object?> row, String key) {
    final raw = row[key];
    if (raw is! String) {
      throw FormatException('Campo de data inválido: $key');
    }
    return DateTime.parse(raw);
  }

  DateTime? _nullableDateTime(Map<String, Object?> row, String key) {
    final raw = row[key];
    return raw is String ? DateTime.parse(raw) : null;
  }

  T? _value<T>(Object? value) => value is T ? value : null;

  Future<Directory> _preferredBackupDirectory() async {
    if (Platform.isAndroid) {
      final external = await getExternalStorageDirectory();
      if (external != null) {
        return external;
      }
    }
    return getApplicationDocumentsDirectory();
  }
}
