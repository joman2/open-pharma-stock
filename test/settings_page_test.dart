import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/app/settings/app_settings.dart';
import 'package:open_pharma_stock/app/settings/settings_page.dart';
import 'package:open_pharma_stock/app/settings/settings_scope.dart';
import 'package:open_pharma_stock/app/theme/app_theme.dart';
import 'package:open_pharma_stock/app/tour/app_tour_controller.dart';
import 'package:open_pharma_stock/app/tour/app_tour_overlay.dart';
import 'package:open_pharma_stock/app/tour/app_tour_scope.dart';
import 'package:open_pharma_stock/export/inventory_exporter.dart';
import 'package:open_pharma_stock/features/inventory/data/in_memory_inventory_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_medication_catalog.dart';
import 'support/test_backup_service.dart';

void main() {
  Future<({AppSettingsController settings, AppTourController tour})>
  createHarness({Map<String, Object> preferences = const {}}) async {
    SharedPreferences.setMockInitialValues(preferences);
    final sharedPreferences = await SharedPreferences.getInstance();
    final repository = InMemoryInventoryRepository();
    final settings = AppSettingsController(preferences: sharedPreferences);
    final catalogRepository = TestMedicationCatalogRepository();
    final enrichmentService = createTestEnrichmentService(
      repository: catalogRepository,
    );
    final tour = AppTourController(
      settingsController: settings,
      repository: repository,
      exporter: InventoryExporter(
        repository: repository,
        enrichmentService: enrichmentService,
      ),
      backupService: createTestBackupService(settingsController: settings),
      catalogImporter: createTestCatalogImporter(repository: catalogRepository),
      catalogRepository: catalogRepository,
      enrichmentService: enrichmentService,
    );
    return (settings: settings, tour: tour);
  }

  Future<({AppSettingsController settings, AppTourController tour})>
  pumpSettingsPage(
    WidgetTester tester, {
    Map<String, Object> preferences = const {},
  }) async {
    final harness = await createHarness(preferences: preferences);
    final catalogRepository = TestMedicationCatalogRepository();

    await tester.pumpWidget(
      SettingsScope(
        controller: harness.settings,
        child: AppTourScope(
          controller: harness.tour,
          child: MaterialApp(
            navigatorKey: harness.tour.navigatorKey,
            theme: buildAppTheme(Brightness.dark),
            builder: (context, child) {
              return AppTourOverlay(child: child ?? const SizedBox.shrink());
            },
            home: SettingsPage(
              backupService: createTestBackupService(
                settingsController: harness.settings,
              ),
              catalogImporter: createTestCatalogImporter(
                repository: catalogRepository,
              ),
              catalogRepository: catalogRepository,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return harness;
  }

  testWidgets('settings use factual copy for dark-only theme', (tester) async {
    await pumpSettingsPage(
      tester,
      preferences: {'app.theme_mode': ThemeMode.light.name},
    );

    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);
    expect(find.text('Tema escuro fixo nesta versão'), findsOneWidget);

    await tester.tap(find.text('Tema'));
    await tester.pumpAndSettle();

    expect(find.text('Sistema'), findsNothing);
    expect(find.text('Claro'), findsNothing);
  });

  testWidgets('settings do not expose unsupported duplicate action', (
    tester,
  ) async {
    await pumpSettingsPage(
      tester,
      preferences: {
        'scanner.duplicate_action': DuplicateCodeAction.countPlusOne.name,
      },
    );

    expect(find.text('Comportamento de repetição'), findsNothing);
    expect(find.text('Auto-incrementar'), findsNothing);
    expect(find.text('Ignorar'), findsNothing);
  });

  testWidgets('settings describe expiry markers without notification promise', (
    tester,
  ) async {
    await pumpSettingsPage(tester);

    final expiryFinder = find.text('Marcar/filtrar validades próximas');
    await tester.dragUntilVisible(
      expiryFinder,
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(expiryFinder, findsOneWidget);
    expect(find.text('Alertas de validade'), findsNothing);
  });

  testWidgets(
    'settings can replay the tutorial manually without changing auto-start',
    (tester) async {
      final harness = await createHarness(
        preferences: {'tour.auto_start_enabled': false},
      );
      final catalogRepository = TestMedicationCatalogRepository();

      await tester.pumpWidget(
        SettingsScope(
          controller: harness.settings,
          child: AppTourScope(
            controller: harness.tour,
            child: MaterialApp(
              navigatorKey: harness.tour.navigatorKey,
              theme: buildAppTheme(Brightness.dark),
              builder: (context, child) {
                return AppTourOverlay(child: child ?? const SizedBox.shrink());
              },
              home: SettingsPage(
                backupService: createTestBackupService(
                  settingsController: harness.settings,
                ),
                catalogImporter: createTestCatalogImporter(
                  repository: catalogRepository,
                ),
                catalogRepository: catalogRepository,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final replayFinder = find.text('Ver tutorial novamente');
      await tester.dragUntilVisible(
        replayFinder,
        find.byType(ListView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(replayFinder);
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(harness.tour.value.isActive, isTrue);
      expect(
        find.text('Passo 1 de ${harness.tour.value.steps.length}'),
        findsOneWidget,
      );
      expect(harness.tour.value.currentStep?.id, 'settings.catalog_import');

      await harness.tour.skip();
      await tester.pump();

      expect(harness.tour.value.isActive, isFalse);
      expect(harness.settings.value.tourAutoStartEnabled, isFalse);
      expect(
        harness.settings.value.lastDismissedTourVersion,
        AppSettingsState.currentTourVersion,
      );
    },
  );
}
