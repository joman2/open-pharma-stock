import '../application/lookup_hints.dart';
import '../data/providers/medication_remote_provider.dart';
import 'medication_catalog_repository.dart';
import 'models.dart';

class MedicationEnrichmentService {
  MedicationEnrichmentService({
    required MedicationCatalogRepository repository,
    required List<MedicationRemoteProvider> remoteProviders,
    bool Function()? remoteLookupEnabled,
    Duration requestTimeout = const Duration(seconds: 8),
  }) : _repository = repository,
       _remoteProviders = List.unmodifiable(remoteProviders),
       _remoteLookupEnabled = remoteLookupEnabled ?? _disabledByDefault,
       _requestTimeout = requestTimeout;

  static bool _disabledByDefault() => false;

  final MedicationCatalogRepository _repository;
  final List<MedicationRemoteProvider> _remoteProviders;
  final bool Function() _remoteLookupEnabled;
  final Duration _requestTimeout;
  final Map<String, Future<void>> _inFlight = {};

  Future<MedicationResolution> resolveNow(List<LookupHint> hints) async {
    if (hints.isEmpty) {
      return const MedicationResolution(
        productCode: '',
        codeType: '',
        medication: null,
        resolutionReason: MedicationResolutionReason.unresolved,
        preferredSourceName: null,
        hasCsvMatch: false,
        hasInfarmedMatch: false,
        resolvedSourcePriority: null,
        matchedCode: null,
        matchedCodeKind: null,
      );
    }

    final match = await _repository.findPreferredMatch(hints);
    final hasCsvMatch = match?.sourceName == MedicationSource.csvManual;
    final hasInfarmedMatch = match?.sourceName == MedicationSource.infarmed;
    return MedicationResolution(
      productCode: hints.first.normalizedCode,
      codeType: hints.first.codeKind,
      medication: match,
      resolutionReason: match == null
          ? MedicationResolutionReason.unresolved
          : MedicationResolutionReason.resolvedLocally,
      preferredSourceName: match?.sourceName,
      hasCsvMatch: hasCsvMatch,
      hasInfarmedMatch: hasInfarmedMatch,
      resolvedSourcePriority: match?.sourcePriority,
      matchedCode: match?.matchedCode,
      matchedCodeKind: match?.matchedCodeKind,
    );
  }

  Future<void> ensureEnrichedInBackground(List<LookupHint> hints) async {
    if (hints.isEmpty || !_remoteLookupEnabled()) {
      return;
    }

    final localMatch = await _repository.findPreferredMatch(hints);
    if (localMatch != null) {
      return;
    }

    final lookupHint = LookupHints.bestRemoteHint(hints);
    if (lookupHint == null) {
      return;
    }

    final key = lookupHint.cacheKey;
    if (_inFlight.containsKey(key)) {
      await _inFlight[key];
      return;
    }

    final status = await _repository.getEnrichmentStatus(
      lookupHint.normalizedCode,
      lookupHint.codeKind,
    );
    final now = DateTime.now();
    if (status?.nextRetryAt != null && status!.nextRetryAt!.isAfter(now)) {
      return;
    }

    final future = _runEnrichment(lookupHint, hints);
    _inFlight[key] = future;
    try {
      await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<void> _runEnrichment(
    LookupHint lookupHint,
    List<LookupHint> hints,
  ) async {
    String? lastProviderName;
    String? lastError;
    for (final provider in _remoteProviders) {
      lastProviderName = provider.providerName;
      await _repository.recordEnrichmentAttempt(
        lookupHint.normalizedCode,
        lookupHint.codeKind,
        providerName: provider.providerName,
      );
      try {
        final result = await provider.resolve(hints).timeout(_requestTimeout);
        switch (result.status) {
          case RemoteProviderStatus.resolved:
          case RemoteProviderStatus.partial:
            await _repository.upsertRemoteEntry(result, hints);
            await _repository.recordEnrichmentSuccess(
              lookupHint.normalizedCode,
              lookupHint.codeKind,
              providerName: provider.providerName,
            );
            return;
          case RemoteProviderStatus.notFound:
          case RemoteProviderStatus.unsupported:
            lastError = result.errorMessage;
            continue;
          case RemoteProviderStatus.error:
            lastError = result.errorMessage;
            continue;
        }
      } catch (error) {
        lastError = error.toString();
      }
    }
    await _repository.recordEnrichmentFailure(
      lookupHint.normalizedCode,
      lookupHint.codeKind,
      error: lastError ?? 'Sem resultado nas fontes remotas.',
      providerName: lastProviderName,
    );
  }

  Future<Map<String, MedicationResolution>> resolveItemsBatch(
    Map<String, List<LookupHint>> hintsByLookupKey,
  ) async {
    final resolutions = <String, MedicationResolution>{};
    for (final entry in hintsByLookupKey.entries) {
      resolutions[entry.key] = await resolveNow(entry.value);
    }
    return resolutions;
  }
}
