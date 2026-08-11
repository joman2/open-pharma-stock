class InfarmedMedicationPayload {
  const InfarmedMedicationPayload({
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
  final List<InfarmedLookupCode> lookupCodes;
}

class InfarmedLookupCode {
  const InfarmedLookupCode({
    required this.normalizedCode,
    required this.codeKind,
    this.isPrimary = false,
  });

  final String normalizedCode;
  final String codeKind;
  final bool isPrimary;
}
