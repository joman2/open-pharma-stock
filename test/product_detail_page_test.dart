import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/app/theme/app_theme.dart';
import 'package:open_pharma_stock/features/inventory/data/in_memory_inventory_repository.dart';
import 'package:open_pharma_stock/features/inventory/presentation/product_detail_page.dart';
import 'package:open_pharma_stock/features/medication_catalog/application/lookup_hints.dart';
import 'package:open_pharma_stock/features/medication_catalog/domain/models.dart';

import 'support/test_medication_catalog.dart';

void main() {
  testWidgets('renders stable placeholders when there is no catalog', (
    tester,
  ) async {
    final repository = InMemoryInventoryRepository();
    final session = await repository.createSession('Sessão A');
    await repository.registerScan(
      sessionId: session.id,
      raw: '010560123456789017250101',
    );
    final item = (await repository.listItems(session.id)).single;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: ProductDetailPage(
          repository: repository,
          enrichmentService: createTestEnrichmentService(),
          session: session,
          item: item,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Links oficiais'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Metadados do medicamento', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Links oficiais', skipOffstage: false), findsOneWidget);
    expect(find.text('Sem catálogo', skipOffstage: false), findsWidgets);
    expect(find.text('Indisponível', skipOffstage: false), findsWidgets);
  });

  testWidgets('renders CSV metadata when a CSV match exists', (tester) async {
    final repository = InMemoryInventoryRepository();
    final session = await repository.createSession('Sessão B');
    await repository.registerScan(
      sessionId: session.id,
      raw: '010560123456789017250101',
    );
    final item = (await repository.listItems(session.id)).single;

    final catalogRepository = TestMedicationCatalogRepository();
    await catalogRepository.replaceCsvCatalog(
      medications: const [
        CatalogImportMedicationInput(
          sourceName: MedicationSource.csvManual,
          sourcePriority: MedicationSourcePriority.csvManual,
          sourceRecordId: 'csv-1',
          canonicalCode: '05601234567890',
          displayName: 'Medicamento CSV',
          activeSubstance: 'Substância CSV',
          strength: '20 mg',
          pharmaceuticalForm: 'Cápsula',
          presentation: '10 unidades',
          holder: 'Laboratório CSV',
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

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: ProductDetailPage(
          repository: repository,
          enrichmentService: createTestEnrichmentService(
            repository: catalogRepository,
          ),
          session: session,
          item: item,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medicamento CSV'), findsWidgets);
    expect(find.text('Substância CSV'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
  });

  testWidgets('renders INFARMED source label when fallback data exists', (
    tester,
  ) async {
    final repository = InMemoryInventoryRepository();
    final session = await repository.createSession('Sessão C');
    await repository.registerScan(
      sessionId: session.id,
      raw: '010560123456789017250101',
    );
    final item = (await repository.listItems(session.id)).single;

    final catalogRepository = TestMedicationCatalogRepository();
    await catalogRepository.upsertRemoteEntry(
      RemoteProviderResult(
        status: RemoteProviderStatus.resolved,
        providerName: MedicationSource.infarmed,
        entry: MedicationCatalogEntry(
          id: 'infarmed::pt-1',
          sourceName: MedicationSource.infarmed,
          sourcePriority: MedicationSourcePriority.infarmed,
          sourceRecordId: 'pt-1',
          canonicalCode: '05601234567890',
          displayName: 'Medicamento INFARMED',
          activeSubstance: 'Substância INFARMED',
          strength: '150 mg',
          pharmaceuticalForm: 'Comprimido',
          presentation: '1 unidade',
          holder: 'INFARMED',
          leafletUrl: null,
          rcmUrl: null,
          sourceUrl: 'https://example.com/source',
          imageUrl: null,
          updatedAt: DateTime.now(),
        ),
        lookupCodes: const [
          MedicationLookupCode(
            id: 'infarmed::pt-1::GTIN::05601234567890',
            medicationId: 'infarmed::pt-1',
            normalizedCode: '05601234567890',
            codeKind: 'GTIN',
            isPrimary: true,
          ),
        ],
      ),
      const [
        LookupHint(
          normalizedCode: '05601234567890',
          codeKind: 'GTIN',
          label: 'GTIN',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: ProductDetailPage(
          repository: repository,
          enrichmentService: createTestEnrichmentService(
            repository: catalogRepository,
          ),
          session: session,
          item: item,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medicamento INFARMED'), findsWidgets);
    expect(find.text('INFARMED'), findsWidgets);
  });

  testWidgets('requires confirmation before deleting a read', (tester) async {
    final repository = InMemoryInventoryRepository();
    final session = await repository.createSession('Sessão D');
    await repository.registerScan(
      sessionId: session.id,
      raw: '01056012345678901725010121ABC123',
    );
    final item = (await repository.listItems(session.id)).single;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: ProductDetailPage(
          repository: repository,
          enrichmentService: createTestEnrichmentService(),
          session: session,
          item: item,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final deleteButton = find.byIcon(Icons.delete_outline);
    await tester.scrollUntilVisible(
      deleteButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Apagar leitura'), findsOneWidget);
    expect(
      (await repository.listEventsForProduct(
        session.id,
        item.productCode,
      )).single.isDeleted,
      isFalse,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(
      (await repository.listEventsForProduct(
        session.id,
        item.productCode,
      )).single.isDeleted,
      isFalse,
    );

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();

    expect(
      (await repository.listEventsForProduct(
        session.id,
        item.productCode,
      )).single.isDeleted,
      isTrue,
    );
  });
}
