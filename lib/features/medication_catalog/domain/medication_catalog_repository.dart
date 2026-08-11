import '../application/lookup_hints.dart';
import 'models.dart';

abstract class MedicationCatalogRepository {
  Future<CatalogImportResult> replaceCsvCatalog({
    required List<CatalogImportMedicationInput> medications,
    required String sourceLabel,
    required int invalidRowCount,
    required List<String> warnings,
  });

  Future<MedicationMatch?> findPreferredMatch(List<LookupHint> hints);

  Future<Map<String, MedicationMatch>> findPreferredMatchesForLookupKeys(
    Iterable<String> lookupKeys,
  );

  Future<void> upsertRemoteEntry(RemoteProviderResult result, List<LookupHint> hints);

  Future<CatalogState?> getCatalogState();

  Future<EnrichmentStatus?> getEnrichmentStatus(
    String normalizedCode,
    String codeKind,
  );

  Future<void> recordEnrichmentAttempt(
    String normalizedCode,
    String codeKind, {
    String? providerName,
  });

  Future<void> recordEnrichmentSuccess(
    String normalizedCode,
    String codeKind, {
    String? providerName,
  });

  Future<void> recordEnrichmentFailure(
    String normalizedCode,
    String codeKind, {
    required String error,
    String? providerName,
  });
}
