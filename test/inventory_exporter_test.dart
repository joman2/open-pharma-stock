import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/export/inventory_exporter.dart';
import 'package:open_pharma_stock/features/inventory/data/in_memory_inventory_repository.dart';
import 'package:open_pharma_stock/features/medication_catalog/domain/models.dart';

import 'support/test_medication_catalog.dart';

void main() {
  test('exports enriched medication name from CSV', () async {
    final repository = InMemoryInventoryRepository();
    final session = await repository.createSession('Prateleira A');
    await repository.registerScan(
      sessionId: session.id,
      raw: '010560123456789017250101',
    );

    final catalogRepository = TestMedicationCatalogRepository();
    await catalogRepository.replaceCsvCatalog(
      medications: const [
        CatalogImportMedicationInput(
          sourceName: MedicationSource.csvManual,
          sourcePriority: MedicationSourcePriority.csvManual,
          sourceRecordId: 'csv-1',
          canonicalCode: '05601234567890',
          displayName: 'Bonviva',
          activeSubstance: 'Ácido ibandrónico',
          strength: '150 mg',
          pharmaceuticalForm: 'Comprimido',
          presentation: '1 unidade',
          holder: 'CSV',
          leafletUrl: 'https://example.com/fi',
          rcmUrl: 'https://example.com/rcm',
          sourceUrl: 'https://example.com/source',
          imageUrl: null,
          lookupCodes: [
            CatalogImportLookupInput(
              normalizedCode: '05601234567890',
              codeKind: 'GTIN',
              isPrimary: true,
            ),
          ],
        ),
      ],
      sourceLabel: 'catalog.csv',
      invalidRowCount: 0,
      warnings: const [],
    );

    final exporter = InventoryExporter(
      repository: repository,
      enrichmentService: createTestEnrichmentService(
        repository: catalogRepository,
      ),
    );

    final csv = await exporter.exportCsv(session.id);
    expect(csv, contains('Bonviva'));
    expect(csv, contains('05601234567890'));
  });

  test('custom preview falls back to product code when no catalog exists', () async {
    final repository = InMemoryInventoryRepository();
    final session = await repository.createSession('Prateleira B');
    await repository.registerScan(
      sessionId: session.id,
      raw: '010560123456789017250101',
    );

    final exporter = InventoryExporter(
      repository: repository,
      enrichmentService: createTestEnrichmentService(),
    );

    final preview = await exporter.buildCustomPreview(
      session.id,
      '{{nome}}|{{fonte}}|{{substancia}}',
    );

    expect(preview, contains('05601234567890|Sem catálogo|'));
  });
}
