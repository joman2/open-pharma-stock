import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/core/gs1/gs1_parser.dart';

void main() {
  group('Gs1Parser.extractGtin', () {
    test('extracts GTIN from raw GS1 string', () {
      final parser = Gs1Parser();
      final gtin = parser.extractGtin('010123456789012817250101');
      expect(gtin, '01234567890128');
    });

    test('extracts GTIN with symbology identifier', () {
      final parser = Gs1Parser();
      final gtin = parser.extractGtin(']d2010123456789012817250101');
      expect(gtin, '01234567890128');
    });

    test('extracts GTIN with ASCII 29 separator', () {
      final parser = Gs1Parser();
      const gs = '\u001D';
      final gtin = parser.extractGtin('0101234567890128${gs}17250101');
      expect(gtin, '01234567890128');
    });

    test('returns null when 01 is missing', () {
      final parser = Gs1Parser();
      final gtin = parser.extractGtin('99123456789012');
      expect(gtin, isNull);
    });

    test('returns null when GTIN is too short', () {
      final parser = Gs1Parser();
      final gtin = parser.extractGtin('011234');
      expect(gtin, isNull);
    });
  });

  group('Gs1Parser.parse', () {
    test('extracts GTIN and serial number', () {
      final parser = Gs1Parser();
      final parsed = parser.parse('010123456789012821ABC123');
      expect(parsed.gtin, '01234567890128');
      expect(parsed.serialNumber, 'ABC123');
    });

    test('extracts serial with group separator', () {
      final parser = Gs1Parser();
      const gs = '\u001D';
      final parsed = parser.parse(']d20101234567890128${gs}21SERIAL987');
      expect(parsed.gtin, '01234567890128');
      expect(parsed.serialNumber, 'SERIAL987');
    });

    test('does not match AI(21) inside GTIN', () {
      final parser = Gs1Parser();
      const gs = '\u001D';
      final parsed = parser.parse(
        ']d2010560036021092421XF1MFNA8H4${gs}10KW9E${gs}17270531',
      );
      expect(parsed.gtin, '05600360210924');
      expect(parsed.serialNumber, 'XF1MFNA8H4');
      expect(parsed.lot, 'KW9E');
      expect(parsed.expiry, DateTime.utc(2027, 5, 31));
    });

    test('parses different serials with same GTIN', () {
      final parser = Gs1Parser();
      const gs = '\u001D';
      final parsed = parser.parse(
        ']d2010560036021092421NF66FXF8C3${gs}10KW9E${gs}17270531',
      );
      expect(parsed.gtin, '05600360210924');
      expect(parsed.serialNumber, 'NF66FXF8C3');
      expect(parsed.lot, 'KW9E');
      expect(parsed.expiry, DateTime.utc(2027, 5, 31));
    });
  });
}
