import 'package:drift/drift.dart';

import '../application/lookup_hints.dart';
import '../domain/medication_catalog_repository.dart';
import '../domain/models.dart';
import '../../inventory/data/app_database.dart';

class DriftMedicationCatalogRepository implements MedicationCatalogRepository {
  DriftMedicationCatalogRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  @override
  Future<CatalogImportResult> replaceCsvCatalog({
    required List<CatalogImportMedicationInput> medications,
    required String sourceLabel,
    required int invalidRowCount,
    required List<String> warnings,
  }) async {
    return _db.transaction(() async {
      final existingCsvRows =
          await (_db.select(_db.medicationCatalogEntries)..where(
                (tbl) => tbl.sourceName.equals(MedicationSource.csvManual),
              ))
              .get();
      final existingIds = existingCsvRows.map((row) => row.id).toList();
      if (existingIds.isNotEmpty) {
        await (_db.delete(
          _db.medicationLookupCodes,
        )..where((tbl) => tbl.medicationId.isIn(existingIds))).go();
        await (_db.delete(
          _db.medicationCatalogEntries,
        )..where((tbl) => tbl.id.isIn(existingIds))).go();
      }

      var importedLookupCount = 0;
      final now = DateTime.now();
      for (final medication in medications) {
        final entryId = _entryId(
          medication.sourceName,
          medication.sourceRecordId,
        );
        await _db
            .into(_db.medicationCatalogEntries)
            .insert(
              MedicationCatalogEntriesCompanion.insert(
                id: entryId,
                sourceName: medication.sourceName,
                sourcePriority: medication.sourcePriority,
                sourceRecordId: medication.sourceRecordId,
                canonicalCode: medication.canonicalCode,
                displayName: medication.displayName,
                activeSubstance: Value(medication.activeSubstance),
                strength: Value(medication.strength),
                pharmaceuticalForm: Value(medication.pharmaceuticalForm),
                presentation: Value(medication.presentation),
                holder: Value(medication.holder),
                leafletUrl: Value(medication.leafletUrl),
                rcmUrl: Value(medication.rcmUrl),
                sourceUrl: Value(medication.sourceUrl),
                imageUrl: Value(medication.imageUrl),
                updatedAt: now,
              ),
            );

        for (final lookup in medication.lookupCodes) {
          importedLookupCount += 1;
          await _db
              .into(_db.medicationLookupCodes)
              .insert(
                MedicationLookupCodesCompanion.insert(
                  id: _lookupId(
                    entryId,
                    lookup.codeKind,
                    lookup.normalizedCode,
                  ),
                  medicationId: entryId,
                  normalizedCode: lookup.normalizedCode,
                  codeKind: lookup.codeKind,
                  isPrimary: Value(lookup.isPrimary),
                ),
              );
        }
      }

      await _db
          .into(_db.medicationCatalogStateTable)
          .insertOnConflictUpdate(
            MedicationCatalogStateTableCompanion.insert(
              id: _catalogStateId,
              csvLastImportedAt: Value(now),
              csvEntryCount: Value(medications.length),
              csvSourceLabel: Value(sourceLabel),
            ),
          );

      return CatalogImportResult(
        importedMedicationCount: medications.length,
        importedLookupCount: importedLookupCount,
        replacedMedicationCount: existingIds.length,
        invalidRowCount: invalidRowCount,
        warnings: warnings,
      );
    });
  }

  @override
  Future<MedicationMatch?> findPreferredMatch(List<LookupHint> hints) async {
    if (hints.isEmpty) {
      return null;
    }

    Expression<bool> predicate = const Constant(false);
    for (final hint in hints) {
      predicate =
          predicate |
          (_db.medicationLookupCodes.normalizedCode.equals(
                hint.normalizedCode,
              ) &
              _db.medicationLookupCodes.codeKind.equals(hint.codeKind));
    }

    final rows = await (_db.select(_db.medicationLookupCodes).join([
      innerJoin(
        _db.medicationCatalogEntries,
        _db.medicationCatalogEntries.id.equalsExp(
          _db.medicationLookupCodes.medicationId,
        ),
      ),
    ])..where(predicate)).get();

    final matches = rows.map((row) {
      final lookup = row.readTable(_db.medicationLookupCodes);
      final entry = row.readTable(_db.medicationCatalogEntries);
      return MedicationMatch(
        entry: _mapEntry(entry),
        matchedCode: lookup.normalizedCode,
        matchedCodeKind: lookup.codeKind,
        sourceName: entry.sourceName,
        sourcePriority: entry.sourcePriority,
      );
    }).toList()..sort(_compareMatches);

    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<Map<String, MedicationMatch>> findPreferredMatchesForLookupKeys(
    Iterable<String> lookupKeys,
  ) async {
    final result = <String, MedicationMatch>{};
    for (final key in lookupKeys) {
      final parts = key.split('|');
      if (parts.length != 2) {
        continue;
      }
      final match = await findPreferredMatch([
        LookupHint(
          normalizedCode: parts[1],
          codeKind: parts[0],
          label: 'lookup',
        ),
      ]);
      if (match != null) {
        result[key] = match;
      }
    }
    return result;
  }

  @override
  Future<void> upsertRemoteEntry(
    RemoteProviderResult result,
    List<LookupHint> hints,
  ) async {
    final entry = result.entry;
    if (entry == null) {
      return;
    }
    final entryId = _entryId(entry.sourceName, entry.sourceRecordId);
    final dedupedLookups = <String, CatalogImportLookupInput>{};
    for (final lookup in result.lookupCodes) {
      dedupedLookups['${lookup.codeKind}|${lookup.normalizedCode}'] =
          CatalogImportLookupInput(
            normalizedCode: lookup.normalizedCode,
            codeKind: lookup.codeKind,
            isPrimary: lookup.isPrimary,
          );
    }
    for (final hint in hints) {
      dedupedLookups.putIfAbsent(
        '${hint.codeKind}|${hint.normalizedCode}',
        () => CatalogImportLookupInput(
          normalizedCode: hint.normalizedCode,
          codeKind: hint.codeKind,
          isPrimary: false,
        ),
      );
    }

    await _db.transaction(() async {
      await (_db.delete(
        _db.medicationLookupCodes,
      )..where((tbl) => tbl.medicationId.equals(entryId))).go();

      await _db
          .into(_db.medicationCatalogEntries)
          .insertOnConflictUpdate(
            MedicationCatalogEntriesCompanion.insert(
              id: entryId,
              sourceName: entry.sourceName,
              sourcePriority: entry.sourcePriority,
              sourceRecordId: entry.sourceRecordId,
              canonicalCode: entry.canonicalCode,
              displayName: entry.displayName,
              activeSubstance: Value(entry.activeSubstance),
              strength: Value(entry.strength),
              pharmaceuticalForm: Value(entry.pharmaceuticalForm),
              presentation: Value(entry.presentation),
              holder: Value(entry.holder),
              leafletUrl: Value(entry.leafletUrl),
              rcmUrl: Value(entry.rcmUrl),
              sourceUrl: Value(entry.sourceUrl),
              imageUrl: Value(entry.imageUrl),
              updatedAt: DateTime.now(),
            ),
          );

      for (final lookup in dedupedLookups.values) {
        await _db
            .into(_db.medicationLookupCodes)
            .insert(
              MedicationLookupCodesCompanion.insert(
                id: _lookupId(entryId, lookup.codeKind, lookup.normalizedCode),
                medicationId: entryId,
                normalizedCode: lookup.normalizedCode,
                codeKind: lookup.codeKind,
                isPrimary: Value(lookup.isPrimary),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  @override
  Future<CatalogState?> getCatalogState() async {
    final row = await (_db.select(
      _db.medicationCatalogStateTable,
    )..where((tbl) => tbl.id.equals(_catalogStateId))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return CatalogState(
      csvLastImportedAt: row.csvLastImportedAt,
      csvEntryCount: row.csvEntryCount,
      csvSourceLabel: row.csvSourceLabel,
    );
  }

  @override
  Future<EnrichmentStatus?> getEnrichmentStatus(
    String normalizedCode,
    String codeKind,
  ) async {
    final row =
        await (_db.select(_db.medicationEnrichmentStatuses)..where(
              (tbl) =>
                  tbl.normalizedCode.equals(normalizedCode) &
                  tbl.codeKind.equals(codeKind),
            ))
            .getSingleOrNull();
    return row == null ? null : _mapStatus(row);
  }

  @override
  Future<void> recordEnrichmentAttempt(
    String normalizedCode,
    String codeKind, {
    String? providerName,
  }
  ) async {
    final current = await getEnrichmentStatus(normalizedCode, codeKind);
    await _db
        .into(_db.medicationEnrichmentStatuses)
        .insertOnConflictUpdate(
          MedicationEnrichmentStatusesCompanion.insert(
            id: _statusId(normalizedCode, codeKind),
            normalizedCode: normalizedCode,
            codeKind: codeKind,
            lastAttemptedAt: Value(DateTime.now()),
            lastSucceededAt: Value(current?.lastSucceededAt),
            lastFailedAt: Value(current?.lastFailedAt),
            attemptCount: Value((current?.attemptCount ?? 0) + 1),
            nextRetryAt: Value(current?.nextRetryAt),
            lastError: Value(current?.lastError),
            lastProviderName: Value(providerName ?? current?.lastProviderName),
          ),
        );
  }

  @override
  Future<void> recordEnrichmentSuccess(
    String normalizedCode,
    String codeKind, {
    String? providerName,
  }
  ) async {
    final current = await getEnrichmentStatus(normalizedCode, codeKind);
    await _db
        .into(_db.medicationEnrichmentStatuses)
        .insertOnConflictUpdate(
          MedicationEnrichmentStatusesCompanion.insert(
            id: _statusId(normalizedCode, codeKind),
            normalizedCode: normalizedCode,
            codeKind: codeKind,
            lastAttemptedAt: Value(current?.lastAttemptedAt ?? DateTime.now()),
            lastSucceededAt: Value(DateTime.now()),
            lastFailedAt: Value(current?.lastFailedAt),
            attemptCount: Value(current?.attemptCount ?? 1),
            nextRetryAt: const Value(null),
            lastError: const Value(null),
            lastProviderName: Value(providerName ?? current?.lastProviderName),
          ),
        );
  }

  @override
  Future<void> recordEnrichmentFailure(
    String normalizedCode,
    String codeKind, {
    required String error,
    String? providerName,
  }) async {
    final current = await getEnrichmentStatus(normalizedCode, codeKind);
    final attempts = current?.attemptCount ?? 1;
    final retryDelay = switch (attempts) {
      <= 1 => const Duration(hours: 1),
      2 => const Duration(hours: 6),
      _ => const Duration(hours: 24),
    };
    await _db
        .into(_db.medicationEnrichmentStatuses)
        .insertOnConflictUpdate(
          MedicationEnrichmentStatusesCompanion.insert(
            id: _statusId(normalizedCode, codeKind),
            normalizedCode: normalizedCode,
            codeKind: codeKind,
            lastAttemptedAt: Value(current?.lastAttemptedAt ?? DateTime.now()),
            lastSucceededAt: Value(current?.lastSucceededAt),
            lastFailedAt: Value(DateTime.now()),
            attemptCount: Value(attempts),
            nextRetryAt: Value(DateTime.now().add(retryDelay)),
            lastError: Value(error),
            lastProviderName: Value(providerName ?? current?.lastProviderName),
          ),
        );
  }

  MedicationCatalogEntry _mapEntry(MedicationCatalogEntryRow row) {
    return MedicationCatalogEntry(
      id: row.id,
      sourceName: row.sourceName,
      sourcePriority: row.sourcePriority,
      sourceRecordId: row.sourceRecordId,
      canonicalCode: row.canonicalCode,
      displayName: row.displayName,
      activeSubstance: row.activeSubstance,
      strength: row.strength,
      pharmaceuticalForm: row.pharmaceuticalForm,
      presentation: row.presentation,
      holder: row.holder,
      leafletUrl: row.leafletUrl,
      rcmUrl: row.rcmUrl,
      sourceUrl: row.sourceUrl,
      imageUrl: row.imageUrl,
      updatedAt: row.updatedAt,
    );
  }

  EnrichmentStatus _mapStatus(MedicationEnrichmentStatusRow row) {
    return EnrichmentStatus(
      id: row.id,
      normalizedCode: row.normalizedCode,
      codeKind: row.codeKind,
      lastAttemptedAt: row.lastAttemptedAt,
      lastSucceededAt: row.lastSucceededAt,
      lastFailedAt: row.lastFailedAt,
      attemptCount: row.attemptCount,
      nextRetryAt: row.nextRetryAt,
      lastError: row.lastError,
      lastProviderName: row.lastProviderName,
    );
  }

  int _compareMatches(MedicationMatch a, MedicationMatch b) {
    final byPriority = b.sourcePriority.compareTo(a.sourcePriority);
    if (byPriority != 0) {
      return byPriority;
    }
    final byUpdated = b.entry.updatedAt.compareTo(a.entry.updatedAt);
    if (byUpdated != 0) {
      return byUpdated;
    }
    return a.entry.id.compareTo(b.entry.id);
  }

  String _entryId(String sourceName, String sourceRecordId) {
    return '$sourceName::$sourceRecordId';
  }

  String _lookupId(
    String medicationId,
    String codeKind,
    String normalizedCode,
  ) {
    return '$medicationId::$codeKind::$normalizedCode';
  }

  String _statusId(String normalizedCode, String codeKind) {
    return '$codeKind::$normalizedCode';
  }

  static const String _catalogStateId = 'csv_manual';
}
