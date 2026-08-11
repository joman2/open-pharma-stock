import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../backup/app_backup_service.dart';
import '../../features/inventory/domain/inventory_repository.dart';
import '../../features/medication_catalog/data/catalog_csv_importer.dart';
import '../../features/medication_catalog/domain/medication_catalog_repository.dart';
import '../settings/app_settings.dart';
import '../tour/app_tour_controller.dart';

enum AppQaActionId {
  sessionsReload,
  sessionsOpenSettings,
  sessionsOpenFirstSession,
  inventoryOpenExport,
  inventoryOpenFirstProductDetail,
  settingsRefreshCatalogState,
}

class AppQaController {
  AppQaController({
    required this.settingsController,
    required this.repository,
    required this.backupService,
    required this.catalogImporter,
    required this.catalogRepository,
    required this.tourController,
    required this.navigatorKey,
  });

  final AppSettingsController settingsController;
  final InventoryRepository repository;
  final AppBackupService backupService;
  final CatalogCsvImporter catalogImporter;
  final MedicationCatalogRepository catalogRepository;
  final AppTourController tourController;
  final GlobalKey<NavigatorState> navigatorKey;

  final Map<AppQaActionId, Future<void> Function(Map<String, Object?> args)>
  _actions = {};

  void registerAction(
    AppQaActionId actionId,
    Future<void> Function(Map<String, Object?> args) callback,
  ) {
    _actions[actionId] = callback;
  }

  void unregisterAction(AppQaActionId actionId) {
    _actions.remove(actionId);
  }

  Future<void> runCommand(String command, Map<String, Object?> args) async {
    debugPrint('QA command: $command $args');
    switch (command) {
      case 'dismissTutorial':
        await tourController.skip();
        return;
      case 'completeTutorial':
        await tourController.complete();
        return;
      case 'startTutorial':
        await tourController.startManualTour();
        return;
      case 'setTutorialAutoStart':
        final enabled = args['enabled'] == true;
        await settingsController.setTourAutoStartEnabled(enabled);
        return;
      case 'createSession':
        final name = (args['name'] as String?)?.trim();
        if (name == null || name.isEmpty) {
          return;
        }
        await repository.createSession(name);
        await _invoke(AppQaActionId.sessionsReload);
        return;
      case 'openSettings':
        await _invoke(AppQaActionId.sessionsOpenSettings);
        return;
      case 'openFirstSession':
        await _invoke(AppQaActionId.sessionsOpenFirstSession);
        return;
      case 'openExport':
        await _invoke(AppQaActionId.inventoryOpenExport);
        return;
      case 'openFirstProductDetail':
        await _invoke(AppQaActionId.inventoryOpenFirstProductDetail);
        return;
      case 'registerScan':
        final raw = args['raw'] as String?;
        if (raw == null || raw.isEmpty) {
          return;
        }
        final sessions = await repository.listSessions();
        if (sessions.isEmpty) {
          return;
        }
        await repository.registerScan(
          sessionId: sessions.first.id,
          raw: raw,
          formatHint: args['formatHint'] as String?,
        );
        await _invoke(AppQaActionId.sessionsReload);
        return;
      case 'importCatalogFromPath':
        final path = args['path'] as String?;
        if (path == null || path.isEmpty) {
          return;
        }
        await catalogImporter.importFile(XFile(path));
        await _invoke(AppQaActionId.settingsRefreshCatalogState);
        return;
      case 'importCatalogRaw':
        final content = args['content'] as String?;
        final sourceLabel =
            (args['sourceLabel'] as String?)?.trim().isNotEmpty == true
            ? (args['sourceLabel'] as String).trim()
            : 'qa-inline.csv';
        if (content == null || content.trim().isEmpty) {
          return;
        }
        final parsed = catalogImporter.parse(content);
        await catalogRepository.replaceCsvCatalog(
          medications: parsed.medications,
          sourceLabel: sourceLabel,
          invalidRowCount: parsed.invalidRowCount,
          warnings: parsed.warnings,
        );
        await _invoke(AppQaActionId.settingsRefreshCatalogState);
        return;
      case 'importCatalogBase64':
        final encoded = args['contentBase64'] as String?;
        final sourceLabel =
            (args['sourceLabel'] as String?)?.trim().isNotEmpty == true
            ? (args['sourceLabel'] as String).trim()
            : 'qa-inline.csv';
        if (encoded == null || encoded.trim().isEmpty) {
          return;
        }
        final decoded = utf8.decode(base64Decode(encoded));
        final parsed = catalogImporter.parse(decoded);
        await catalogRepository.replaceCsvCatalog(
          medications: parsed.medications,
          sourceLabel: sourceLabel,
          invalidRowCount: parsed.invalidRowCount,
          warnings: parsed.warnings,
        );
        await _invoke(AppQaActionId.settingsRefreshCatalogState);
        return;
      case 'exportBackupToPath':
        final exportPath = args['path'] as String?;
        if (exportPath == null || exportPath.isEmpty) {
          return;
        }
        await backupService.exportToPath(exportPath);
        return;
      case 'importBackupFromPath':
        final importPath = args['path'] as String?;
        if (importPath == null || importPath.isEmpty) {
          return;
        }
        await backupService.importFromPath(importPath);
        await _invoke(AppQaActionId.settingsRefreshCatalogState);
        await _invoke(AppQaActionId.sessionsReload);
        return;
      default:
        debugPrint('QA command ignored: $command');
        return;
    }
  }

  Future<void> _invoke(
    AppQaActionId actionId, {
    Map<String, Object?> args = const {},
  }) async {
    final callback = _actions[actionId];
    if (callback == null) {
      debugPrint('QA action unavailable: $actionId');
      return;
    }
    await callback(args);
  }
}
