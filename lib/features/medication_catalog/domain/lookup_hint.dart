class LookupHint {
  const LookupHint({
    required this.normalizedCode,
    required this.codeKind,
    required this.label,
    this.priority = 0,
    this.source = 'scan',
    this.isStrongIdentifier = false,
  });

  final String normalizedCode;
  final String codeKind;
  final String label;
  final int priority;
  final String source;
  final bool isStrongIdentifier;

  String get value => normalizedCode;

  String get cacheKey => '$codeKind|$normalizedCode';
}
