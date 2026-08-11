import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/backup/app_backup_service.dart';
import '../app/qa/app_qa_controller.dart';
import '../app/qa/app_qa_platform_bridge.dart';
import '../app/qa/app_qa_scope.dart';
import '../app/settings/app_settings.dart';
import '../app/settings/settings_scope.dart';
import '../app/theme/app_theme.dart';
import '../app/tour/app_tour_controller.dart';
import '../app/tour/app_tour_gate.dart';
import '../app/tour/app_tour_overlay.dart';
import '../app/tour/app_tour_platform_bridge.dart';
import '../app/tour/app_tour_scope.dart';
import '../export/inventory_exporter.dart';
import '../features/inventory/domain/inventory_repository.dart';
import '../features/medication_catalog/data/catalog_csv_importer.dart';
import '../features/medication_catalog/domain/medication_catalog_repository.dart';
import '../features/medication_catalog/domain/medication_enrichment_service.dart';

class OpenPharmaStockApp extends StatefulWidget {
  const OpenPharmaStockApp({
    super.key,
    required this.repository,
    required this.exporter,
    required this.settingsController,
    required this.backupService,
    required this.catalogRepository,
    required this.catalogImporter,
    required this.enrichmentService,
  });

  final InventoryRepository repository;
  final InventoryExporter exporter;
  final AppSettingsController settingsController;
  final AppBackupService backupService;
  final MedicationCatalogRepository catalogRepository;
  final CatalogCsvImporter catalogImporter;
  final MedicationEnrichmentService enrichmentService;

  @override
  State<OpenPharmaStockApp> createState() => _OpenPharmaStockAppState();
}

class _OpenPharmaStockAppState extends State<OpenPharmaStockApp> {
  late final AppTourController _tourController;
  late final AppTourPlatformBridge _tourPlatformBridge;
  AppQaController? _qaController;
  AppQaPlatformBridge? _qaPlatformBridge;

  @override
  void initState() {
    super.initState();
    _tourController = AppTourController(
      settingsController: widget.settingsController,
      repository: widget.repository,
      exporter: widget.exporter,
      backupService: widget.backupService,
      catalogImporter: widget.catalogImporter,
      catalogRepository: widget.catalogRepository,
      enrichmentService: widget.enrichmentService,
    );
    _tourPlatformBridge = AppTourPlatformBridge(controller: _tourController);
    if (kDebugMode) {
      _qaController = AppQaController(
        settingsController: widget.settingsController,
        repository: widget.repository,
        catalogImporter: widget.catalogImporter,
        catalogRepository: widget.catalogRepository,
        backupService: widget.backupService,
        tourController: _tourController,
        navigatorKey: _tourController.navigatorKey,
      );
      _qaPlatformBridge = AppQaPlatformBridge(controller: _qaController!);
    }
  }

  @override
  void dispose() {
    _qaPlatformBridge?.dispose();
    _tourPlatformBridge.dispose();
    _tourController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = SettingsScope(
      controller: widget.settingsController,
      child: AppTourScope(
        controller: _tourController,
        child: ValueListenableBuilder<AppSettingsState>(
          valueListenable: widget.settingsController,
          builder: (context, settings, child) {
            return MaterialApp(
              title: 'OpenPharmaStock',
              navigatorKey: _tourController.navigatorKey,
              theme: buildAppTheme(Brightness.dark),
              darkTheme: buildAppTheme(Brightness.dark),
              themeMode: ThemeMode.dark,
              builder: (context, child) {
                return AppTourOverlay(child: child ?? const SizedBox.shrink());
              },
              home: AppTourGate(
                repository: widget.repository,
                exporter: widget.exporter,
                backupService: widget.backupService,
                catalogImporter: widget.catalogImporter,
                catalogRepository: widget.catalogRepository,
                enrichmentService: widget.enrichmentService,
              ),
            );
          },
        ),
      ),
    );
    if (_qaController != null) {
      child = AppQaScope(controller: _qaController!, child: child);
    }
    return child;
  }
}
