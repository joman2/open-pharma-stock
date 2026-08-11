import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/backup/app_backup_service.dart';
import 'app/settings/app_settings.dart';
import 'export/inventory_exporter.dart';
import 'features/inventory/data/app_database.dart';
import 'features/inventory/data/drift_inventory_repository.dart';
import 'features/medication_catalog/data/catalog_csv_importer.dart';
import 'features/medication_catalog/data/drift_medication_catalog_repository.dart';
import 'features/medication_catalog/data/infarmed_provider.dart';
import 'features/medication_catalog/data/providers/ema_provider.dart';
import 'features/medication_catalog/data/providers/gepir_provider.dart';
import 'features/medication_catalog/domain/medication_enrichment_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final database = AppDatabase();
  final repository = DriftInventoryRepository(db: database);
  final medicationCatalogRepository = DriftMedicationCatalogRepository(
    db: database,
  );
  final preferences = await SharedPreferences.getInstance();
  final settingsController = AppSettingsController(preferences: preferences);
  final medicationEnrichmentService = MedicationEnrichmentService(
    repository: medicationCatalogRepository,
    remoteProviders: [InfarmedProvider(), EmaProvider(), GepirProvider()],
    remoteLookupEnabled: () =>
        settingsController.value.onlineCatalogLookupEnabled,
  );
  final catalogImporter = CatalogCsvImporter(
    repository: medicationCatalogRepository,
  );
  final exporter = InventoryExporter(
    repository: repository,
    enrichmentService: medicationEnrichmentService,
  );
  final backupService = AppBackupService(
    database: database,
    settingsController: settingsController,
  );

  runApp(
    OpenPharmaStockApp(
      repository: repository,
      exporter: exporter,
      settingsController: settingsController,
      backupService: backupService,
      catalogRepository: medicationCatalogRepository,
      catalogImporter: catalogImporter,
      enrichmentService: medicationEnrichmentService,
    ),
  );
}
