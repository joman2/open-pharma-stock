import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/features/medication_catalog/application/lookup_hints.dart';
import 'package:open_pharma_stock/features/medication_catalog/data/providers/medication_remote_provider.dart';
import 'package:open_pharma_stock/features/medication_catalog/domain/medication_enrichment_service.dart';
import 'package:open_pharma_stock/features/medication_catalog/domain/models.dart';

import 'support/test_medication_catalog.dart';

void main() {
  test('resolveNow prefers CSV over INFARMED for the same code', () async {
    final repository = TestMedicationCatalogRepository();
    await repository.upsertRemoteEntry(
      RemoteProviderResult(
        status: RemoteProviderStatus.resolved,
        providerName: MedicationSource.infarmed,
        entry: MedicationCatalogEntry(
          id: 'infarmed::pt-1',
          sourceName: MedicationSource.infarmed,
          sourcePriority: MedicationSourcePriority.infarmed,
          sourceRecordId: 'pt-1',
          canonicalCode: '56012345678901',
          displayName: 'Medicamento INFARMED',
          activeSubstance: 'Substância',
          strength: '10 mg',
          pharmaceuticalForm: 'Comprimido',
          presentation: '20 unidades',
          holder: 'INFARMED',
          leafletUrl: null,
          rcmUrl: null,
          sourceUrl: 'https://example.com/infarmed',
          imageUrl: null,
          updatedAt: DateTime.now(),
        ),
        lookupCodes: const [
          MedicationLookupCode(
            id: 'infarmed::pt-1::GTIN::56012345678901',
            medicationId: 'infarmed::pt-1',
            normalizedCode: '56012345678901',
            codeKind: MedicationCodeKind.gtin,
            isPrimary: true,
          ),
        ],
      ),
      const [
        LookupHint(
          normalizedCode: '56012345678901',
          codeKind: MedicationCodeKind.gtin,
          label: 'GTIN',
        ),
      ],
    );

    await repository.replaceCsvCatalog(
      medications: const [
        CatalogImportMedicationInput(
          sourceName: MedicationSource.csvManual,
          sourcePriority: MedicationSourcePriority.csvManual,
          sourceRecordId: 'csv-1',
          canonicalCode: '56012345678901',
          displayName: 'Medicamento CSV',
          activeSubstance: 'Substância',
          strength: '10 mg',
          pharmaceuticalForm: 'Comprimido',
          presentation: '20 unidades',
          holder: 'CSV',
          leafletUrl: null,
          rcmUrl: null,
          sourceUrl: null,
          imageUrl: null,
          lookupCodes: [
            CatalogImportLookupInput(
              normalizedCode: '56012345678901',
              codeKind: MedicationCodeKind.gtin,
              isPrimary: true,
            ),
          ],
        ),
      ],
      sourceLabel: 'catalog.csv',
      invalidRowCount: 0,
      warnings: const [],
    );

    final service = createTestEnrichmentService(repository: repository);
    final resolution = await service.resolveNow(
      const [
        LookupHint(
          normalizedCode: '56012345678901',
          codeKind: MedicationCodeKind.gtin,
          label: 'GTIN',
        ),
      ],
    );

    expect(resolution.medication?.entry.displayName, 'Medicamento CSV');
    expect(resolution.preferredSourceName, MedicationSource.csvManual);
  });

  test('negative caching avoids repeated INFARMED calls during cooldown', () async {
    final repository = TestMedicationCatalogRepository();
    final provider = _CountingInfarmedProvider();
    final service = MedicationEnrichmentService(
      repository: repository,
      remoteProviders: [provider],
      remoteLookupEnabled: () => true,
    );
    const hints = [
      LookupHint(
        normalizedCode: '1234567',
        codeKind: MedicationCodeKind.ptReg,
        label: 'PT_REG',
      ),
    ];

    await service.ensureEnrichedInBackground(hints);
    await service.ensureEnrichedInBackground(hints);

    expect(provider.lookupCount, 1);
  });

  test('remote lookup is disabled by default', () async {
    final repository = TestMedicationCatalogRepository();
    final provider = _CountingInfarmedProvider();
    final service = MedicationEnrichmentService(
      repository: repository,
      remoteProviders: [provider],
    );

    await service.ensureEnrichedInBackground(const [
      LookupHint(
        normalizedCode: '1234567',
        codeKind: MedicationCodeKind.ptReg,
        label: 'PT_REG',
      ),
    ]);

    expect(provider.lookupCount, 0);
  });
}

class _CountingInfarmedProvider implements MedicationRemoteProvider {
  int lookupCount = 0;

  @override
  String get providerName => MedicationSource.infarmed;

  @override
  int get providerPriority => MedicationSourcePriority.infarmed;

  @override
  Future<RemoteProviderResult> resolve(List<LookupHint> hints) async {
    lookupCount += 1;
    return const RemoteProviderResult(
      status: RemoteProviderStatus.notFound,
      providerName: MedicationSource.infarmed,
      entry: null,
      lookupCodes: [],
      errorMessage: 'Sem resultado.',
    );
  }
}
