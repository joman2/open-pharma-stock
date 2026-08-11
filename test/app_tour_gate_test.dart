import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/app/settings/app_settings.dart';
import 'package:open_pharma_stock/app/theme/app_theme.dart';
import 'package:open_pharma_stock/app/tour/app_tour_controller.dart';
import 'package:open_pharma_stock/app/tour/app_tour_gate.dart';
import 'package:open_pharma_stock/app/tour/app_tour_scope.dart';
import 'package:open_pharma_stock/export/inventory_exporter.dart';
import 'package:open_pharma_stock/features/inventory/data/in_memory_inventory_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_medication_catalog.dart';
import 'support/test_backup_service.dart';

void main() {
  Future<AppTourController> createController(
    Map<String, Object> preferences,
  ) async {
    SharedPreferences.setMockInitialValues(preferences);
    final sharedPreferences = await SharedPreferences.getInstance();
    final repository = InMemoryInventoryRepository();
    final settings = AppSettingsController(preferences: sharedPreferences);
    final catalogRepository = TestMedicationCatalogRepository();
    final enrichmentService = createTestEnrichmentService(
      repository: catalogRepository,
    );
    final exporter = InventoryExporter(
      repository: repository,
      enrichmentService: enrichmentService,
    );
    return AppTourController(
      settingsController: settings,
      repository: repository,
      exporter: exporter,
      backupService: createTestBackupService(settingsController: settings),
      catalogImporter: createTestCatalogImporter(repository: catalogRepository),
      catalogRepository: catalogRepository,
      enrichmentService: enrichmentService,
    );
  }

  testWidgets('gate auto-starts the tutorial on first opening', (tester) async {
    final controller = await createController({});
    final repository = controller.repository as InMemoryInventoryRepository;
    final catalogRepository = TestMedicationCatalogRepository();
    final enrichmentService = createTestEnrichmentService(
      repository: catalogRepository,
    );

    await tester.pumpWidget(
      AppTourScope(
        controller: controller,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.dark),
          home: AppTourGate(
            repository: repository,
            exporter: InventoryExporter(
              repository: repository,
              enrichmentService: enrichmentService,
            ),
            backupService: createTestBackupService(
              settingsController: controller.settingsController,
            ),
            catalogImporter: createTestCatalogImporter(
              repository: catalogRepository,
            ),
            catalogRepository: catalogRepository,
            enrichmentService: enrichmentService,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(controller.value.isActive, isTrue);
    expect(controller.value.currentStep?.id, 'sessions.new_session');
  });

  testWidgets(
    'gate does not auto-start when the current version was dismissed',
    (tester) async {
      final controller = await createController({
        'tour.last_dismissed_version': AppSettingsState.currentTourVersion,
      });
      final repository = controller.repository as InMemoryInventoryRepository;
      final catalogRepository = TestMedicationCatalogRepository();
      final enrichmentService = createTestEnrichmentService(
        repository: catalogRepository,
      );

      await tester.pumpWidget(
        AppTourScope(
          controller: controller,
          child: MaterialApp(
            theme: buildAppTheme(Brightness.dark),
            home: AppTourGate(
              repository: repository,
                exporter: InventoryExporter(
                  repository: repository,
                  enrichmentService: enrichmentService,
                ),
                backupService: createTestBackupService(
                  settingsController: controller.settingsController,
                ),
                catalogImporter: createTestCatalogImporter(
                  repository: catalogRepository,
                ),
              catalogRepository: catalogRepository,
              enrichmentService: enrichmentService,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(controller.value.isActive, isFalse);
    },
  );
}
