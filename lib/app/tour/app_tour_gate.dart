import 'package:flutter/material.dart';

import '../backup/app_backup_service.dart';
import '../../export/inventory_exporter.dart';
import '../../features/inventory/domain/inventory_repository.dart';
import '../../features/inventory/presentation/sessions_page.dart';
import '../../features/medication_catalog/data/catalog_csv_importer.dart';
import '../../features/medication_catalog/domain/medication_catalog_repository.dart';
import '../../features/medication_catalog/domain/medication_enrichment_service.dart';
import 'app_tour_scope.dart';

class AppTourGate extends StatefulWidget {
  const AppTourGate({
    super.key,
    required this.repository,
    required this.exporter,
    required this.backupService,
    required this.catalogImporter,
    required this.catalogRepository,
    required this.enrichmentService,
  });

  final InventoryRepository repository;
  final InventoryExporter exporter;
  final AppBackupService backupService;
  final CatalogCsvImporter catalogImporter;
  final MedicationCatalogRepository catalogRepository;
  final MedicationEnrichmentService enrichmentService;

  @override
  State<AppTourGate> createState() => _AppTourGateState();
}

class _AppTourGateState extends State<AppTourGate> {
  bool _requestedAutoStart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedAutoStart) {
      return;
    }
    _requestedAutoStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = AppTourScope.maybeOf(context);
      controller?.maybeStartAutomatically();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SessionsPage(
      repository: widget.repository,
      exporter: widget.exporter,
      backupService: widget.backupService,
      catalogImporter: widget.catalogImporter,
      catalogRepository: widget.catalogRepository,
      enrichmentService: widget.enrichmentService,
    );
  }
}
