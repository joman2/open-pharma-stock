class ParsedGs1 {
  const ParsedGs1({
    required this.raw,
    required this.gtin,
    required this.serialNumber,
    required this.lot,
    required this.expiry,
    this.extras = const {},
  });

  final String raw;
  final String? gtin;
  final String? serialNumber;
  final String? lot;
  final DateTime? expiry;
  final Map<String, String> extras;
}

class Gs1Parser {
  static const Map<String, _AiSpec> _knownAiSpecs = {
    '01': _AiSpec.fixed(14),
    '10': _AiSpec.variable(20),
    '17': _AiSpec.fixed(6),
    '21': _AiSpec.variable(20),
    '240': _AiSpec.variable(30),
    '714': _AiSpec.variable(20),
  };

  ParsedGs1 parse(String raw) {
    final cleaned = _stripSymbologyIdentifier(raw.trim());
    String? gtin;
    String? serialNumber;
    String? lot;
    DateTime? expiry;
    final extras = <String, String>{};

    var index = 0;
    while (index < cleaned.length) {
      if (_isGroupSeparator(cleaned.codeUnitAt(index))) {
        index += 1;
        continue;
      }

      final ai = _matchAi(cleaned, index);
      if (ai == null) {
        index += 1;
        continue;
      }

      index += ai.length;
      final spec = _knownAiSpecs[ai]!;
      final value = spec.isFixedLength
          ? _readFixed(cleaned, index, spec.maxLength)
          : _readVariable(cleaned, index, spec.maxLength);
      if (value == null || value.isEmpty) {
        break;
      }
      index += value.length;
      if (!spec.isFixedLength &&
          index < cleaned.length &&
          _isGroupSeparator(cleaned.codeUnitAt(index))) {
        index += 1;
      }
      extras[ai] = value;

      switch (ai) {
        case '01':
          if (_isDigits(value)) {
            gtin = value;
          }
          break;
        case '17':
          expiry = _parseExpiry(value);
          break;
        case '10':
          lot = value;
          break;
        case '21':
          serialNumber = value;
          break;
      }
    }

    return ParsedGs1(
      raw: raw,
      gtin: gtin,
      serialNumber: serialNumber,
      lot: lot,
      expiry: expiry,
      extras: extras,
    );
  }

  String? extractGtin(String raw) {
    return parse(raw).gtin;
  }

  String? extractSerialNumber(String raw) {
    return parse(raw).serialNumber;
  }

  String? _matchAi(String value, int start) {
    for (final length in const [4, 3, 2]) {
      final end = start + length;
      if (end > value.length) {
        continue;
      }
      final candidate = value.substring(start, end);
      if (_knownAiSpecs.containsKey(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  String _stripSymbologyIdentifier(String value) {
    if (value.startsWith(']') && value.length >= 3) {
      return value.substring(3);
    }
    return value;
  }

  bool _isDigits(String value) => RegExp(r'^\d+$').hasMatch(value);

  String? _readFixed(String value, int start, int length) {
    final end = start + length;
    if (end > value.length) {
      return null;
    }
    return value.substring(start, end);
  }

  String? _readVariable(String value, int start, int maxLength) {
    var end = start;
    while (end < value.length &&
        !_isGroupSeparator(value.codeUnitAt(end)) &&
        end - start < maxLength) {
      end += 1;
    }
    if (end <= start) {
      return null;
    }
    return value.substring(start, end);
  }

  bool _isGroupSeparator(int codeUnit) => codeUnit == 29;

  DateTime? _parseExpiry(String value) {
    if (value.length != 6 || !_isDigits(value)) {
      return null;
    }
    final year = 2000 + int.parse(value.substring(0, 2));
    final month = int.parse(value.substring(2, 4));
    final day = int.parse(value.substring(4, 6));
    if (month < 1 || month > 12) {
      return null;
    }
    final normalizedDay = day == 0 ? DateTime.utc(year, month + 1, 0).day : day;
    if (normalizedDay < 1 || normalizedDay > 31) {
      return null;
    }
    final date = DateTime.utc(year, month, normalizedDay);
    if (date.year != year || date.month != month || date.day != normalizedDay) {
      return null;
    }
    return date;
  }
}

class _AiSpec {
  const _AiSpec.fixed(this.maxLength) : isFixedLength = true;
  const _AiSpec.variable(this.maxLength) : isFixedLength = false;

  final int maxLength;
  final bool isFixedLength;
}
