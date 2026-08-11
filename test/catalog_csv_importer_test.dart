import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/features/medication_catalog/data/catalog_csv_importer.dart';

import 'support/test_medication_catalog.dart';

void main() {
  group('CatalogCsvImporter', () {
    test('groups multiple lookup codes by source_record_id', () {
      final importer = CatalogCsvImporter(
        repository: TestMedicationCatalogRepository(),
      );

      final parsed = importer.parse(
        'source_record_id,lookup_code,lookup_code_kind,canonical_code,display_name,active_substance,is_primary\n'
        'abc,56012345678901,GTIN,56012345678901,Medicamento A,Substância X,true\n'
        'abc,1234567,PT_REG,56012345678901,Medicamento A,Substância X,false\n',
      );

      expect(parsed.medications, hasLength(1));
      expect(parsed.medications.single.lookupCodes, hasLength(2));
      expect(parsed.invalidRowCount, 0);
    });

    test('rejects CSV files missing required headers', () {
      final importer = CatalogCsvImporter(
        repository: TestMedicationCatalogRepository(),
      );

      expect(
        () => importer.parse('lookup_code,display_name\n123,Medicamento'),
        throwsFormatException,
      );
    });

    test('counts invalid rows and keeps valid ones', () {
      final importer = CatalogCsvImporter(
        repository: TestMedicationCatalogRepository(),
      );

      final parsed = importer.parse(
        'source_record_id,lookup_code,lookup_code_kind,canonical_code,display_name\n'
        'ok,56012345678901,GTIN,56012345678901,Medicamento A\n'
        'bad,abc,GTIN,56012345678901,Medicamento B\n',
      );

      expect(parsed.medications, hasLength(1));
      expect(parsed.invalidRowCount, 1);
      expect(parsed.warnings, isNotEmpty);
    });
  });
}
