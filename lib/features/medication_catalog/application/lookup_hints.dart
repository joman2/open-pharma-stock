import '../../../core/gs1/gs1_parser.dart';
import '../../../core/gs1/scan_normalizer.dart';
export '../domain/lookup_hint.dart';
import '../domain/lookup_hint.dart';
import '../../inventory/domain/models.dart';

class MedicationCodeKind {
  static const String gtin = CodeType.gtin;
  static const String ean = CodeType.ean;
  static const String raw = CodeType.raw;
  static const String ptReg = 'PT_REG';
  static const String cnpem = 'CNPEM';
}

class LookupHints {
  const LookupHints._();

  static List<LookupHint> fromRaw(
    String raw, {
    String? formatHint,
    String? productCode,
    String? codeType,
  }) {
    final parser = Gs1Parser();
    final parsed = parser.parse(raw);
    final normalized = normalizeScan(raw, formatHint: formatHint);
    final hints = <LookupHint>[];

    void addHint(
      String? code,
      String kind,
      String label, {
      required int priority,
      required String source,
      bool isStrongIdentifier = false,
    }) {
      final normalizedCode = code?.trim();
      if (normalizedCode == null || normalizedCode.isEmpty) {
        return;
      }
      if (hints.any(
        (hint) =>
            hint.normalizedCode == normalizedCode && hint.codeKind == kind,
      )) {
        return;
      }
      hints.add(
        LookupHint(
          normalizedCode: normalizedCode,
          codeKind: kind,
          label: label,
          priority: priority,
          source: source,
          isStrongIdentifier: isStrongIdentifier,
        ),
      );
    }

    final ptReg = parsed.extras['714'];
    if (ptReg != null) {
      addHint(
        _digitsOnly(ptReg),
        MedicationCodeKind.ptReg,
        'AI(714)',
        priority: 1000,
        source: 'parser',
        isStrongIdentifier: true,
      );
    }

    final explicitCode = productCode?.trim();
    final explicitType = codeType?.trim();
    if (explicitCode != null &&
        explicitCode.isNotEmpty &&
        explicitType != null) {
      addHint(
        explicitCode,
        explicitType,
        'código normalizado',
        priority: 950,
        source: 'scan',
        isStrongIdentifier: explicitType != MedicationCodeKind.raw,
      );
    }

    addHint(
      parsed.gtin,
      MedicationCodeKind.gtin,
      'GTIN GS1',
      priority: 900,
      source: 'parser',
      isStrongIdentifier: true,
    );

    if (normalized.codeType == MedicationCodeKind.gtin) {
      addHint(
        normalized.productCode,
        MedicationCodeKind.gtin,
        'GTIN',
        priority: 850,
        source: 'normalizer',
        isStrongIdentifier: true,
      );
    } else if (normalized.codeType == MedicationCodeKind.ean) {
      addHint(
        normalized.productCode,
        MedicationCodeKind.ean,
        'EAN',
        priority: 800,
        source: 'normalizer',
        isStrongIdentifier: true,
      );
    }

    final longNumericCode =
        parsed.gtin ?? _longNumericCandidate(normalized.productCode);
    if (longNumericCode != null) {
      addHint(
        longNumericCode.substring(longNumericCode.length - 7),
        MedicationCodeKind.ptReg,
        'GTIN/EAN → registo candidato',
        priority: 700,
        source: 'derived',
      );
      addHint(
        longNumericCode.substring(longNumericCode.length - 8),
        MedicationCodeKind.cnpem,
        'GTIN/EAN → CNPEM candidato',
        priority: 680,
        source: 'derived',
      );
    }

    final cleaned = raw.trim();
    if (RegExp(r'^\d{8}$').hasMatch(cleaned)) {
      addHint(
        cleaned,
        MedicationCodeKind.cnpem,
        'CNPEM candidato',
        priority: 650,
        source: 'derived',
      );
      addHint(
        cleaned,
        MedicationCodeKind.ean,
        'EAN-8',
        priority: 640,
        source: 'normalizer',
        isStrongIdentifier: true,
      );
    }
    if (RegExp(r'^\d{7}$').hasMatch(cleaned)) {
      addHint(
        cleaned,
        MedicationCodeKind.ptReg,
        'registo candidato',
        priority: 630,
        source: 'derived',
      );
    }
    addHint(
      cleaned,
      MedicationCodeKind.raw,
      'RAW',
      priority: 100,
      source: 'raw',
    );

    hints.sort((a, b) => b.priority.compareTo(a.priority));
    return hints;
  }

  static List<LookupHint> fromScanEvent(ScanEvent event) {
    return fromRaw(
      event.raw,
      productCode: event.productCode,
      codeType: event.codeType,
    );
  }

  static List<LookupHint> fromInventoryItem(InventoryItem item) {
    return fromRaw(
      item.productCode,
      productCode: item.productCode,
      codeType: item.codeType,
    );
  }

  static String? bestRemoteLookupKey(List<LookupHint> hints) {
    final preferred = bestRemoteHint(hints);
    return preferred?.cacheKey;
  }

  static String? bestInfarmedLookupKey(List<LookupHint> hints) {
    return bestRemoteLookupKey(hints);
  }

  static LookupHint? bestInfarmedHint(List<LookupHint> hints) {
    return _bestInfarmedHint(hints);
  }

  static LookupHint? bestRemoteHint(List<LookupHint> hints) {
    if (hints.isEmpty) {
      return null;
    }
    final ordered = [...hints]..sort((a, b) => b.priority.compareTo(a.priority));
    return ordered.first;
  }

  static List<LookupHint> orderedInfarmedHints(List<LookupHint> hints) {
    final ordered = <LookupHint>[];

    void addWhere(String kind) {
      for (final hint in hints) {
        if (hint.codeKind != kind) {
          continue;
        }
        if (ordered.any((existing) => existing.cacheKey == hint.cacheKey)) {
          continue;
        }
        ordered.add(hint);
      }
    }

    addWhere(MedicationCodeKind.ptReg);
    addWhere(MedicationCodeKind.cnpem);
    for (final hint in hints) {
      if (hint.codeKind != MedicationCodeKind.raw) {
        continue;
      }
      if (!RegExp(r'^\d{7,8}$').hasMatch(hint.normalizedCode)) {
        continue;
      }
      if (ordered.any((existing) => existing.cacheKey == hint.cacheKey)) {
        continue;
      }
      ordered.add(hint);
    }

    return ordered;
  }

  static LookupHint? _bestInfarmedHint(List<LookupHint> hints) {
    final ordered = orderedInfarmedHints(hints);
    return ordered.isEmpty ? null : ordered.first;
  }

  static String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  static String? _longNumericCandidate(String code) {
    final digits = _digitsOnly(code);
    if (digits.length < 13) {
      return null;
    }
    return digits;
  }
}
