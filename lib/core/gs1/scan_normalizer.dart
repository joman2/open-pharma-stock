import 'gs1_parser.dart';

class CodeType {
  static const String gtin = 'GTIN';
  static const String ean = 'EAN';
  static const String raw = 'RAW';
  static const String ptReg = 'PT_REG';
}

class NormalizedScan {
  const NormalizedScan({required this.productCode, required this.codeType});

  final String productCode;
  final String codeType;
}

NormalizedScan normalizeScan(String raw, {String? formatHint}) {
  final cleaned = raw.trim();
  final parsed = Gs1Parser().parse(cleaned);
  final gtin = parsed.gtin;
  if (gtin != null) {
    return NormalizedScan(productCode: gtin, codeType: CodeType.gtin);
  }

  final ptReg = parsed.extras['714']?.replaceAll(RegExp(r'\D'), '');
  if (ptReg != null && RegExp(r'^\d{7}$').hasMatch(ptReg)) {
    return NormalizedScan(productCode: ptReg, codeType: CodeType.ptReg);
  }

  if (RegExp(r'^\d{13}$').hasMatch(cleaned)) {
    final gtin14 = '0$cleaned';
    return NormalizedScan(productCode: gtin14, codeType: CodeType.gtin);
  }

  if (RegExp(r'^\d{8}$').hasMatch(cleaned)) {
    return NormalizedScan(productCode: cleaned, codeType: CodeType.ean);
  }

  return NormalizedScan(productCode: cleaned, codeType: CodeType.raw);
}
