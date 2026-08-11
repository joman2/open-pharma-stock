import 'package:open_pharma_stock/features/medication_catalog/application/lookup_hints.dart';
import 'package:open_pharma_stock/features/medication_catalog/data/catalog_csv_importer.dart';
import 'package:open_pharma_stock/features/medication_catalog/data/providers/medication_remote_provider.dart';
import 'package:open_pharma_stock/features/medication_catalog/domain/medication_catalog_repository.dart';
import 'package:open_pharma_stock/features/medication_catalog/domain/medication_enrichment_service.dart';
import 'package:open_pharma_stock/features/medication_catalog/domain/models.dart';

class TestMedicationCatalogRepository implements MedicationCatalogRepository {
  final Map<String, MedicationMatch> _matchesByLookupKey = {};
  final Map<String, EnrichmentStatus> _statusByLookupKey = {};
  CatalogState? catalogState;

  @override
  Future<MedicationMatch?> findPreferredMatch(List<LookupHint> hints) async {
    for (final hint in hints) {
      final match = _matchesByLookupKey[hint.cacheKey];
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  @override
  Future<Map<String, MedicationMatch>> findPreferredMatchesForLookupKeys(
    Iterable<String> lookupKeys,
  ) async {
    return {
      for (final key in lookupKeys)
        if (_matchesByLookupKey.containsKey(key))
          key: _matchesByLookupKey[key]!,
    };
  }

  @override
  Future<CatalogState?> getCatalogState() async => catalogState;

  @override
  Future<EnrichmentStatus?> getEnrichmentStatus(
    String normalizedCode,
    String codeKind,
  ) async {
    return _statusByLookupKey['$codeKind|$normalizedCode'];
  }

  @override
  Future<void> recordEnrichmentAttempt(
    String normalizedCode,
    String codeKind, {
    String? providerName,
  }
  ) async {
    final current = _statusByLookupKey['$codeKind|$normalizedCode'];
    _statusByLookupKey['$codeKind|$normalizedCode'] = EnrichmentStatus(
      id: '$codeKind|$normalizedCode',
      normalizedCode: normalizedCode,
      codeKind: codeKind,
      lastAttemptedAt: DateTime.now(),
      lastSucceededAt: current?.lastSucceededAt,
      lastFailedAt: current?.lastFailedAt,
      attemptCount: (current?.attemptCount ?? 0) + 1,
      nextRetryAt: current?.nextRetryAt,
      lastError: current?.lastError,
      lastProviderName: providerName ?? current?.lastProviderName,
    );
  }

  @override
  Future<void> recordEnrichmentFailure(
    String normalizedCode,
    String codeKind, {
    required String error,
    String? providerName,
  }) async {
    _statusByLookupKey['$codeKind|$normalizedCode'] = EnrichmentStatus(
      id: '$codeKind|$normalizedCode',
      normalizedCode: normalizedCode,
      codeKind: codeKind,
      lastAttemptedAt: DateTime.now(),
      lastSucceededAt: null,
      lastFailedAt: DateTime.now(),
      attemptCount:
          (_statusByLookupKey['$codeKind|$normalizedCode']?.attemptCount ?? 0) +
          1,
      nextRetryAt: DateTime.now().add(const Duration(hours: 1)),
      lastError: error,
      lastProviderName: providerName,
    );
  }

  @override
  Future<void> recordEnrichmentSuccess(
    String normalizedCode,
    String codeKind, {
    String? providerName,
  }
  ) async {
    _statusByLookupKey['$codeKind|$normalizedCode'] = EnrichmentStatus(
      id: '$codeKind|$normalizedCode',
      normalizedCode: normalizedCode,
      codeKind: codeKind,
      lastAttemptedAt: DateTime.now(),
      lastSucceededAt: DateTime.now(),
      lastFailedAt: null,
      attemptCount:
          (_statusByLookupKey['$codeKind|$normalizedCode']?.attemptCount ?? 0) +
          1,
      nextRetryAt: null,
      lastError: null,
      lastProviderName: providerName,
    );
  }

  @override
  Future<CatalogImportResult> replaceCsvCatalog({
    required List<CatalogImportMedicationInput> medications,
    required String sourceLabel,
    required int invalidRowCount,
    required List<String> warnings,
  }) async {
    for (final medication in medications) {
      final entry = MedicationCatalogEntry(
        id: '${medication.sourceName}::${medication.sourceRecordId}',
        sourceName: medication.sourceName,
        sourcePriority: medication.sourcePriority,
        sourceRecordId: medication.sourceRecordId,
        canonicalCode: medication.canonicalCode,
        displayName: medication.displayName,
        activeSubstance: medication.activeSubstance,
        strength: medication.strength,
        pharmaceuticalForm: medication.pharmaceuticalForm,
        presentation: medication.presentation,
        holder: medication.holder,
        leafletUrl: medication.leafletUrl,
        rcmUrl: medication.rcmUrl,
        sourceUrl: medication.sourceUrl,
        imageUrl: medication.imageUrl,
        updatedAt: DateTime.now(),
      );
      for (final lookup in medication.lookupCodes) {
        _matchesByLookupKey['${lookup.codeKind}|${lookup.normalizedCode}'] =
            MedicationMatch(
              entry: entry,
              matchedCode: lookup.normalizedCode,
              matchedCodeKind: lookup.codeKind,
              sourceName: medication.sourceName,
              sourcePriority: medication.sourcePriority,
            );
      }
    }

    catalogState = CatalogState(
      csvLastImportedAt: DateTime.now(),
      csvEntryCount: medications.length,
      csvSourceLabel: sourceLabel,
    );

    return CatalogImportResult(
      importedMedicationCount: medications.length,
      importedLookupCount: medications.fold(
        0,
        (sum, medication) => sum + medication.lookupCodes.length,
      ),
      replacedMedicationCount: 0,
      invalidRowCount: invalidRowCount,
      warnings: warnings,
    );
  }

  @override
  Future<void> upsertRemoteEntry(
    RemoteProviderResult result,
    List<LookupHint> hints,
  ) async {
    final remoteEntry = result.entry!;
    final storedEntry = MedicationCatalogEntry(
      id: '${remoteEntry.sourceName}::${remoteEntry.sourceRecordId}',
      sourceName: remoteEntry.sourceName,
      sourcePriority: remoteEntry.sourcePriority,
      sourceRecordId: remoteEntry.sourceRecordId,
      canonicalCode: remoteEntry.canonicalCode,
      displayName: remoteEntry.displayName,
      activeSubstance: remoteEntry.activeSubstance,
      strength: remoteEntry.strength,
      pharmaceuticalForm: remoteEntry.pharmaceuticalForm,
      presentation: remoteEntry.presentation,
      holder: remoteEntry.holder,
      leafletUrl: remoteEntry.leafletUrl,
      rcmUrl: remoteEntry.rcmUrl,
      sourceUrl: remoteEntry.sourceUrl,
      imageUrl: remoteEntry.imageUrl,
      updatedAt: DateTime.now(),
    );
    for (final hint in hints) {
      _matchesByLookupKey[hint.cacheKey] = MedicationMatch(
        entry: storedEntry,
        matchedCode: hint.normalizedCode,
        matchedCodeKind: hint.codeKind,
        sourceName: storedEntry.sourceName,
        sourcePriority: storedEntry.sourcePriority,
      );
    }
  }
}

class TestRemoteProvider implements MedicationRemoteProvider {
  @override
  String get providerName => MedicationSource.infarmed;

  @override
  int get providerPriority => MedicationSourcePriority.infarmed;

  @override
  Future<RemoteProviderResult> resolve(List<LookupHint> hints) async {
    return const RemoteProviderResult(
      status: RemoteProviderStatus.notFound,
      providerName: MedicationSource.infarmed,
      entry: null,
      lookupCodes: [],
      errorMessage: 'Sem resultado de teste.',
    );
  }
}

MedicationEnrichmentService createTestEnrichmentService({
  TestMedicationCatalogRepository? repository,
}) {
  return MedicationEnrichmentService(
    repository: repository ?? TestMedicationCatalogRepository(),
    remoteProviders: [TestRemoteProvider()],
  );
}

CatalogCsvImporter createTestCatalogImporter({
  TestMedicationCatalogRepository? repository,
}) {
  return CatalogCsvImporter(
    repository: repository ?? TestMedicationCatalogRepository(),
  );
}
