import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/app/settings/app_settings.dart';
import 'package:open_pharma_stock/app/tour/app_tour_controller.dart';
import 'package:open_pharma_stock/app/tour/app_tour_state.dart';
import 'package:open_pharma_stock/app/tour/app_tour_targets.dart';
import 'package:open_pharma_stock/export/inventory_exporter.dart';
import 'package:open_pharma_stock/features/inventory/data/in_memory_inventory_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_medication_catalog.dart';
import 'support/test_backup_service.dart';

void main() {
  Future<AppTourController> createController({
    Map<String, Object> preferences = const {},
    InMemoryInventoryRepository? repository,
  }) async {
    SharedPreferences.setMockInitialValues(preferences);
    final prefs = await SharedPreferences.getInstance();
    final repo = repository ?? InMemoryInventoryRepository();
    final settings = AppSettingsController(preferences: prefs);
    final catalogRepository = TestMedicationCatalogRepository();
    final enrichmentService = createTestEnrichmentService(
      repository: catalogRepository,
    );
    return AppTourController(
      settingsController: settings,
      repository: repo,
      exporter: InventoryExporter(
        repository: repo,
        enrichmentService: enrichmentService,
      ),
      backupService: createTestBackupService(settingsController: settings),
      catalogImporter: createTestCatalogImporter(repository: catalogRepository),
      catalogRepository: catalogRepository,
      enrichmentService: enrichmentService,
    );
  }

  test(
    'manual tour with zero sessions stays on sessions/settings flow only',
    () async {
      final controller = await createController();

      final steps = await controller.buildStepsForTesting(
        AppTourStartOrigin.manualReplay,
      );

      expect(steps.any((step) => step.page == AppTourPage.inventory), isFalse);
      expect(steps.any((step) => step.page == AppTourPage.export), isFalse);
      expect(steps.any((step) => step.id == 'sessions.await_session'), isTrue);
    },
  );

  test(
    'manual tour with an existing session includes inventory and export',
    () async {
      final repository = InMemoryInventoryRepository();
      await repository.createSession('Prateleira A');
      final controller = await createController(repository: repository);

      final steps = await controller.buildStepsForTesting(
        AppTourStartOrigin.manualReplay,
      );

      expect(steps.any((step) => step.page == AppTourPage.inventory), isTrue);
      expect(steps.any((step) => step.page == AppTourPage.export), isTrue);
    },
  );

  testWidgets('waitForTarget is safe when the target is not mounted', (
    tester,
  ) async {
    final controller = await createController();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    final future = controller.waitForTarget(
      AppTourTargetId.inventorySearchButton,
      maxAttempts: 1,
    );
    await tester.pump();
    await tester.pump();

    expect(await future, isFalse);
  });

  testWidgets('skip and complete update persisted tutorial state', (
    tester,
  ) async {
    final controller = await createController();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: controller.navigatorKey,
        home: Builder(
          builder: (context) {
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );

    controller.value = AppTourState(
      isActive: true,
      steps: const [
        AppTourStep(
          id: 'test',
          page: AppTourPage.sessions,
          title: 'Teste',
          description: 'Teste',
        ),
      ],
    );

    await controller.skip();
    expect(controller.value.isActive, isFalse);
    expect(
      controller.settingsController.value.lastDismissedTourVersion,
      AppSettingsState.currentTourVersion,
    );

    controller.value = AppTourState(
      isActive: true,
      steps: const [
        AppTourStep(
          id: 'test',
          page: AppTourPage.sessions,
          title: 'Teste',
          description: 'Teste',
        ),
      ],
    );

    await controller.complete();
    expect(controller.value.isActive, isFalse);
    expect(
      controller.settingsController.value.lastCompletedTourVersion,
      AppSettingsState.currentTourVersion,
    );
  });
}
