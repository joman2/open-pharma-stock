import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/core/gs1/scan_normalizer.dart';
import 'package:open_pharma_stock/features/medication_catalog/application/lookup_hints.dart';

void main() {
  group('normalizeScan', () {
    test('returns GTIN when GS1 data includes AI(01)', () {
      final result = normalizeScan('010123456789012817250101');
      expect(result.productCode, '01234567890128');
      expect(result.codeType, CodeType.gtin);
    });

    test('normalizes EAN-13 to GTIN-14', () {
      final result = normalizeScan('7891234567890');
      expect(result.productCode, '07891234567890');
      expect(result.codeType, CodeType.gtin);
    });

    test('returns EAN for 8 digit codes', () {
      final result = normalizeScan('12345670');
      expect(result.productCode, '12345670');
      expect(result.codeType, CodeType.ean);
    });

    test('returns RAW for other inputs', () {
      final result = normalizeScan('ABC-123');
      expect(result.productCode, 'ABC-123');
      expect(result.codeType, CodeType.raw);
    });

    test('adds PT_REG as a lookup hint when GS1 data includes AI(714)', () {
      final hints = LookupHints.fromRaw(
        '0105601234567890\u001d7141234567\u001d17250101',
      );
      expect(
        hints.any(
          (hint) =>
              hint.normalizedCode == '1234567' &&
              hint.codeKind == CodeType.ptReg,
        ),
        isTrue,
      );
    });
  });
}
