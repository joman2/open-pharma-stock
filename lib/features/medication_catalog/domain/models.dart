class MedicationSource {
  static const String csvManual = 'csv_manual';
  static const String infarmed = 'infarmed';
  static const String ema = 'ema';
  static const String gepir = 'gepir';
}

class MedicationSourcePriority {
  static const int csvManual = 1000;
  static const int infarmed = 700;
  static const int ema = 600;
  static const int gepir = 550;
}

class MedicationCatalogEntry {
  const MedicationCatalogEntry({
    required this.id,
    required this.sourceName,
    required this.sourcePriority,
    required this.sourceRecordId,
    required this.canonicalCode,
    required this.displayName,
    required this.activeSubstance,
    required this.strength,
    required this.pharmaceuticalForm,
    required this.presentation,
    required this.holder,
    required this.leafletUrl,
    required this.rcmUrl,
    required this.sourceUrl,
    required this.imageUrl,
    required this.updatedAt,
  });

  final String id;
  final String sourceName;
  final int sourcePriority;
  final String sourceRecordId;
  final String canonicalCode;
  final String displayName;
  final String? activeSubstance;
  final String? strength;
  final String? pharmaceuticalForm;
  final String? presentation;
  final String? holder;
  final String? leafletUrl;
  final String? rcmUrl;
  final String? sourceUrl;
  final String? imageUrl;
  final DateTime updatedAt;
}

class MedicationLookupCode {
  const MedicationLookupCode({
    required this.id,
    required this.medicationId,
    required this.normalizedCode,
    required this.codeKind,
    required this.isPrimary,
  });

  final String id;
  final String medicationId;
  final String normalizedCode;
  final String codeKind;
  final bool isPrimary;
}

class MedicationMatch {
  const MedicationMatch({
    required this.entry,
    required this.matchedCode,
    required this.matchedCodeKind,
    required this.sourceName,
    required this.sourcePriority,
  });

  final MedicationCatalogEntry entry;
  final String matchedCode;
  final String matchedCodeKind;
  final String sourceName;
  final int sourcePriority;
}

enum MedicationResolutionReason {
  resolvedLocally,
  unresolved,
  enrichmentNotSupported,
  enrichmentFailed,
}

class MedicationResolution {
  const MedicationResolution({
    required this.productCode,
    required this.codeType,
    required this.medication,
    required this.resolutionReason,
    required this.preferredSourceName,
    required this.hasCsvMatch,
    required this.hasInfarmedMatch,
    this.resolvedSourcePriority,
    this.matchedCode,
    this.matchedCodeKind,
  });

  final String productCode;
  final String codeType;
  final MedicationMatch? medication;
  final MedicationResolutionReason resolutionReason;
  final String? preferredSourceName;
  final bool hasCsvMatch;
  final bool hasInfarmedMatch;
  final int? resolvedSourcePriority;
  final String? matchedCode;
  final String? matchedCodeKind;

  bool get isResolved => medication != null;
}

enum RemoteProviderStatus {
  resolved,
  notFound,
  unsupported,
  error,
  partial,
}

class RemoteProviderResult {
  const RemoteProviderResult({
    required this.status,
    required this.providerName,
    required this.entry,
    required this.lookupCodes,
    this.errorMessage,
  });

  final RemoteProviderStatus status;
  final String providerName;
  final MedicationCatalogEntry? entry;
  final List<MedicationLookupCode> lookupCodes;
  final String? errorMessage;

  bool get hasUsableEntry =>
      entry != null &&
      (status == RemoteProviderStatus.resolved ||
          status == RemoteProviderStatus.partial);
}

class CatalogImportResult {
  const CatalogImportResult({
    required this.importedMedicationCount,
    required this.importedLookupCount,
    required this.replacedMedicationCount,
    required this.invalidRowCount,
    required this.warnings,
  });

  final int importedMedicationCount;
  final int importedLookupCount;
  final int replacedMedicationCount;
  final int invalidRowCount;
  final List<String> warnings;
}

class EnrichmentStatus {
  const EnrichmentStatus({
    required this.id,
    required this.normalizedCode,
    required this.codeKind,
    required this.lastAttemptedAt,
    required this.lastSucceededAt,
    required this.lastFailedAt,
    required this.attemptCount,
    required this.nextRetryAt,
    required this.lastError,
    required this.lastProviderName,
  });

  final String id;
  final String normalizedCode;
  final String codeKind;
  final DateTime? lastAttemptedAt;
  final DateTime? lastSucceededAt;
  final DateTime? lastFailedAt;
  final int attemptCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final String? lastProviderName;
}

class CatalogState {
  const CatalogState({
    required this.csvLastImportedAt,
    required this.csvEntryCount,
    required this.csvSourceLabel,
  });

  final DateTime? csvLastImportedAt;
  final int csvEntryCount;
  final String? csvSourceLabel;
}

class CatalogImportMedicationInput {
  const CatalogImportMedicationInput({
    required this.sourceName,
    required this.sourcePriority,
    required this.sourceRecordId,
    required this.canonicalCode,
    required this.displayName,
    required this.activeSubstance,
    required this.strength,
    required this.pharmaceuticalForm,
    required this.presentation,
    required this.holder,
    required this.leafletUrl,
    required this.rcmUrl,
    required this.sourceUrl,
    required this.imageUrl,
    required this.lookupCodes,
  });

  final String sourceName;
  final int sourcePriority;
  final String sourceRecordId;
  final String canonicalCode;
  final String displayName;
  final String? activeSubstance;
  final String? strength;
  final String? pharmaceuticalForm;
  final String? presentation;
  final String? holder;
  final String? leafletUrl;
  final String? rcmUrl;
  final String? sourceUrl;
  final String? imageUrl;
  final List<CatalogImportLookupInput> lookupCodes;
}

class CatalogImportLookupInput {
  const CatalogImportLookupInput({
    required this.normalizedCode,
    required this.codeKind,
    required this.isPrimary,
  });

  final String normalizedCode;
  final String codeKind;
  final bool isPrimary;
}
