import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/backup/app_backup_service.dart';
import '../../../app/settings/app_settings.dart';
import '../../../app/settings/settings_scope.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/qa/app_qa_controller.dart';
import '../../../app/qa/app_qa_scope.dart';
import '../../../app/tour/app_tour_controller.dart';
import '../../../app/tour/app_tour_scope.dart';
import '../../../app/tour/app_tour_state.dart';
import '../../../app/tour/app_tour_targets.dart';
import '../../../core/gs1/scan_normalizer.dart';
import '../../../core/sound/sound_player.dart';
import '../../../export/inventory_exporter.dart';
import '../../../scanner/mobile_scanner_engine.dart';
import '../../../scanner/scanner_engine.dart';
import '../../../l10n/localized_text.dart';
import '../../medication_catalog/application/lookup_hints.dart';
import '../../medication_catalog/data/catalog_csv_importer.dart';
import '../../medication_catalog/domain/medication_catalog_repository.dart';
import '../../medication_catalog/domain/medication_enrichment_service.dart';
import '../../medication_catalog/domain/models.dart';
import '../domain/inventory_repository.dart';
import '../domain/models.dart';
import 'product_detail_page.dart';

enum InventoryTab { products, recentReads }

enum InventoryQuickFilter { all, expiring, unresolved }

enum ExportFormat { csv, json, txt }

enum ExportMode { standard, custom }

enum ScannerVisualState { searching, detected, reading, read, paused, error }

class InventoryPage extends StatefulWidget {
  const InventoryPage({
    super.key,
    required this.repository,
    required this.exporter,
    required this.backupService,
    required this.enrichmentService,
    required this.catalogImporter,
    required this.catalogRepository,
    required this.session,
    this.scannerEngine,
  });

  final InventoryRepository repository;
  final InventoryExporter exporter;
  final AppBackupService backupService;
  final MedicationEnrichmentService enrichmentService;
  final CatalogCsvImporter catalogImporter;
  final MedicationCatalogRepository catalogRepository;
  final InventorySession session;
  final ScannerEngine? scannerEngine;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with WidgetsBindingObserver {
  final List<InventoryItem> _items = [];
  final List<ScanEvent> _events = [];
  final SoundPlayer _soundPlayer = SoundPlayer();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, MedicationResolution> _resolutions = {};

  static const bool _enableFallbackDecoder = true;
  static const bool _debugReturnImage = false;

  bool _isExporting = false;
  bool _scannerOpen = false;
  bool _isPaused = false;
  bool _isRegistering = false;
  bool _autoTorchAttempted = false;
  bool _isSearching = false;
  bool _pausedByLifecycle = false;
  bool _startingScanner = false;

  late ScanMode _scanMode;
  late ScannerEngine _engine;
  late InventorySession _session;
  InventoryTab _activeTab = InventoryTab.products;
  InventoryQuickFilter _activeFilter = InventoryQuickFilter.all;
  StreamSubscription<ScanResult>? _subscription;
  MobileScannerController? _cameraController;
  AppSettingsController? _settings;
  AppTourController? _tourController;
  AppQaController? _qaController;
  ScannerVisualState _scannerVisualState = ScannerVisualState.searching;
  String _scannerStatusTitle = 'A procurar';
  String _scannerFeedbackText = '';
  Rect? _trackedCodeRect;
  _TrackedBarcodeLock? _trackedBarcodeLock;
  late final ValueNotifier<_ScannerOverlayViewState> _scannerOverlay;
  Timer? _scannerStatusResetTimer;
  VoidCallback? _cameraControllerListener;
  DateTime? _lastOverlayMetricAt;
  DateTime? _scannerStatusHoldUntil;
  int _overlayUpdateCount = 0;

  static const Duration _scannerStartTimeout = Duration(milliseconds: 1200);
  static const int _trackingMissFramesToDrop = 3;
  static const Duration _trackingLostTimeout = Duration(milliseconds: 260);
  static const double _trackedRectDeltaThreshold = 0.5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings ??= SettingsScope.of(context);
    final nextQaController = AppQaScope.maybeOf(context);
    if (_qaController != nextQaController) {
      _unregisterQaActions();
      _qaController = nextQaController;
      _registerQaActions();
    }
    final nextTourController = AppTourScope.maybeOf(context);
    if (_tourController != nextTourController) {
      _unregisterTourActions();
      _tourController = nextTourController;
      _registerTourActions();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_scannerOpen && !_isPaused && _pausedByLifecycle) {
          unawaited(_resumeScannerAfterLifecycle());
        }
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_scannerOpen && !_isPaused && !_pausedByLifecycle) {
          unawaited(_pauseScannerForLifecycle());
        }
        return;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = widget.session;
    _scanMode = ScanMode.dataMatrix;
    _engine =
        widget.scannerEngine ??
        MobileScannerEngine(
          mode: _scanMode,
          enableFallbackDecoder: _enableFallbackDecoder,
          debugReturnImage: _debugReturnImage,
        );
    _scannerOverlay = ValueNotifier(
      _ScannerOverlayViewState(
        visualState: _scannerVisualState,
        title: _scannerStatusTitle,
        modeHint: _modeHelperLabel,
        feedbackText: _scannerFeedbackText,
        trackedRect: _trackedCodeRect,
      ),
    );
    _bindEngine();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    unawaited(_reloadInventoryData());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = _settings?.value;
      if (settings == null || !mounted) {
        return;
      }
      _applyInitialSettings(settings);
    });
  }

  int get _totalReads => _events.where((event) => !event.isDeleted).length;

  MedicationResolution? _resolutionForCode(String code, String codeType) {
    return _resolutions['$codeType|$code'];
  }

  String get _latestReadLabel {
    if (_events.isEmpty) {
      return '—';
    }
    final event = _events.first;
    final resolution = _resolutionForCode(event.productCode, event.codeType);
    return resolution?.medication?.entry.displayName ?? event.productCode;
  }

  String get _searchQuery => _searchController.text.trim().toLowerCase();

  List<InventoryItem> get _filteredItems {
    final statsByCode = _eventStatsByCode;
    return _items.where((item) {
      final queryMatch =
          _searchQuery.isEmpty ||
          item.productCode.toLowerCase().contains(_searchQuery) ||
          item.codeType.toLowerCase().contains(_searchQuery) ||
          (_resolutionForCode(item.productCode, item.codeType)
                  ?.medication
                  ?.entry
                  .displayName
                  .toLowerCase()
                  .contains(_searchQuery) ??
              false) ||
          (_resolutionForCode(item.productCode, item.codeType)
                  ?.medication
                  ?.entry
                  .activeSubstance
                  ?.toLowerCase()
                  .contains(_searchQuery) ??
              false) ||
          (_resolutionForCode(item.productCode, item.codeType)
                  ?.medication
                  ?.entry
                  .strength
                  ?.toLowerCase()
                  .contains(_searchQuery) ??
              false) ||
          (_resolutionForCode(item.productCode, item.codeType)
                  ?.medication
                  ?.entry
                  .pharmaceuticalForm
                  ?.toLowerCase()
                  .contains(_searchQuery) ??
              false) ||
          (_resolutionForCode(item.productCode, item.codeType)
                  ?.medication
                  ?.entry
                  .presentation
                  ?.toLowerCase()
                  .contains(_searchQuery) ??
              false);
      if (!queryMatch) {
        return false;
      }
      switch (_activeFilter) {
        case InventoryQuickFilter.all:
          return true;
        case InventoryQuickFilter.expiring:
          return _isExpiring(statsByCode[item.productCode]?.expiry);
        case InventoryQuickFilter.unresolved:
          return !(_resolutionForCode(
                item.productCode,
                item.codeType,
              )?.isResolved ??
              false);
      }
    }).toList();
  }

  List<ScanEvent> get _filteredEvents {
    return _events.where((event) {
      final queryMatch =
          _searchQuery.isEmpty ||
          event.productCode.toLowerCase().contains(_searchQuery) ||
          (event.serialNumber ?? '').toLowerCase().contains(_searchQuery) ||
          (event.lot ?? '').toLowerCase().contains(_searchQuery) ||
          (_resolutionForCode(event.productCode, event.codeType)
                  ?.medication
                  ?.entry
                  .displayName
                  .toLowerCase()
                  .contains(_searchQuery) ??
              false) ||
          (_resolutionForCode(event.productCode, event.codeType)
                  ?.medication
                  ?.entry
                  .activeSubstance
                  ?.toLowerCase()
                  .contains(_searchQuery) ??
              false);
      if (!queryMatch) {
        return false;
      }
      switch (_activeFilter) {
        case InventoryQuickFilter.all:
          return true;
        case InventoryQuickFilter.expiring:
          return _isExpiring(event.expiry);
        case InventoryQuickFilter.unresolved:
          return !(_resolutionForCode(
                event.productCode,
                event.codeType,
              )?.isResolved ??
              false);
      }
    }).toList();
  }

  Map<String, _EventSummary> get _eventStatsByCode {
    final summary = <String, _EventSummary>{};
    for (final event in _events) {
      if (event.isDeleted) {
        continue;
      }
      summary.putIfAbsent(
        event.productCode,
        () => _EventSummary(latestScanAt: event.createdAt),
      );
      final current = summary[event.productCode]!;
      summary[event.productCode] = current.copyWith(
        latestScanAt: event.createdAt.isAfter(current.latestScanAt)
            ? event.createdAt
            : current.latestScanAt,
        expiry: current.expiry ?? event.expiry,
        lot: current.lot ?? event.lot,
      );
    }
    return summary;
  }

  void _bindEngine() {
    _cameraControllerListener?.call();
    if (_engine is MobileScannerEngine) {
      _cameraController = (_engine as MobileScannerEngine).controller;
      final listener = _handleCameraControllerChanged;
      _cameraController!.addListener(listener);
      _cameraControllerListener = () {
        _cameraController?.removeListener(listener);
      };
    } else {
      _cameraController = null;
      _cameraControllerListener = null;
    }
    _subscription = _engine.scans.listen(_handleScan);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unregisterQaActions();
    _unregisterTourActions();
    _scannerStatusResetTimer?.cancel();
    _cameraControllerListener?.call();
    _subscription?.cancel();
    unawaited(_engine.stop());
    if (_engine is MobileScannerEngine) {
      unawaited((_engine as MobileScannerEngine).dispose());
    }
    _scannerOverlay.dispose();
    _searchController.dispose();
    _soundPlayer.dispose();
    super.dispose();
  }

  Future<void> _applyInitialSettings(AppSettingsState settings) async {
    if (_scanMode != settings.preferredScanMode) {
      await _changeScanMode(
        settings.preferredScanMode,
        persistPreference: false,
      );
    }
    if (settings.openScannerOnSessionEntry) {
      await _openScanner();
    }
  }

  void _handleCameraControllerChanged() {
    final controller = _cameraController;
    if (controller == null || !mounted) {
      return;
    }
    final state = controller.value;
    final error = state.error;
    if (error != null) {
      _scannerLog(
        'camera_error code=${error.errorCode.name} '
        'message=${error.errorDetails?.message ?? ''}',
      );
      _setScannerVisualState(
        ScannerVisualState.error,
        title: 'Câmara indisponível',
        feedback: _describeScannerError(error),
        keepFor: const Duration(seconds: 3),
      );
    } else if (_scannerOpen && !_isPaused && !_pausedByLifecycle) {
      if (state.isRunning &&
          (_scannerVisualState == ScannerVisualState.paused ||
              _scannerVisualState == ScannerVisualState.error)) {
        _setScannerVisualState(
          ScannerVisualState.searching,
          title: 'A procurar',
          feedback: '',
        );
      }
    }
  }

  Future<void> _pauseScannerForLifecycle() async {
    _pausedByLifecycle = true;
    await _engine.stop();
    if (!mounted) {
      return;
    }
    _setScannerVisualState(
      ScannerVisualState.paused,
      title: 'Scanner em pausa',
      feedback: 'A app ficou em segundo plano.',
    );
  }

  Future<void> _resumeScannerAfterLifecycle() async {
    await _startScannerEngine();
    if (!mounted) {
      return;
    }
    setState(() {
      _pausedByLifecycle = false;
    });
    _setScannerVisualState(
      ScannerVisualState.searching,
      title: 'A procurar',
      feedback: '',
    );
  }

  void _registerTourActions() {
    final controller = _tourController;
    if (controller == null) {
      return;
    }
    controller.registerAction(AppTourActionId.openSearch, _openSearchForTour);
    controller.registerAction(AppTourActionId.openScanner, _openScannerForTour);
    controller.registerAction(AppTourActionId.closeScanner, _closeScanner);
    controller.registerAction(
      AppTourActionId.showProductsTab,
      _showProductsTab,
    );
    controller.registerAction(AppTourActionId.showReadsTab, _showReadsTab);
    controller.registerAction(AppTourActionId.openExport, _openExportForTour);
  }

  void _registerQaActions() {
    final controller = _qaController;
    if (controller == null) {
      return;
    }
    controller.registerAction(
      AppQaActionId.inventoryOpenExport,
      (_) => _openExportForTour(),
    );
    controller.registerAction(AppQaActionId.inventoryOpenFirstProductDetail, (
      _,
    ) async {
      if (_items.isEmpty) {
        await _reloadInventoryData();
      }
      if (!mounted || _items.isEmpty) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            repository: widget.repository,
            enrichmentService: widget.enrichmentService,
            session: widget.session,
            item: _items.first,
          ),
        ),
      );
    });
  }

  void _unregisterQaActions() {
    final controller = _qaController;
    if (controller == null) {
      return;
    }
    controller.unregisterAction(AppQaActionId.inventoryOpenExport);
    controller.unregisterAction(AppQaActionId.inventoryOpenFirstProductDetail);
  }

  void _unregisterTourActions() {
    final controller = _tourController;
    if (controller == null) {
      return;
    }
    controller.unregisterAction(AppTourActionId.openSearch);
    controller.unregisterAction(AppTourActionId.openScanner);
    controller.unregisterAction(AppTourActionId.closeScanner);
    controller.unregisterAction(AppTourActionId.showProductsTab);
    controller.unregisterAction(AppTourActionId.showReadsTab);
    controller.unregisterAction(AppTourActionId.openExport);
  }

  Future<void> _openScannerForTour() async {
    if (_scannerOpen) {
      return;
    }
    await _openScanner();
  }

  Future<void> _showProductsTab() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _activeTab = InventoryTab.products;
    });
  }

  Future<void> _showReadsTab() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _activeTab = InventoryTab.recentReads;
    });
  }

  Future<void> _openExportForTour() async {
    if (_isExporting) {
      return;
    }
    unawaited(_openExportFlow());
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    _tourController?.markPageVisible(AppTourPage.export);
  }

  Future<void> _openSearchForTour() async {
    if (_isSearching) {
      return;
    }
    _toggleSearch();
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _loadItems() async {
    final items = await widget.repository.listItems(widget.session.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(items);
    });
  }

  Future<void> _loadEvents() async {
    final events = await widget.repository.listRecentEvents(widget.session.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _events
        ..clear()
        ..addAll(events);
    });
  }

  Future<void> _reloadInventoryData({bool triggerBackground = true}) async {
    await Future.wait([_loadItems(), _loadEvents()]);
    await _refreshResolutions(triggerBackground: triggerBackground);
  }

  Future<void> _refreshResolutions({bool triggerBackground = true}) async {
    final next = <String, MedicationResolution>{};
    final pending = <String, List<LookupHint>>{};

    for (final item in _items) {
      final hints = _lookupHintsForProduct(item.productCode, item.codeType);
      final resolution = await widget.enrichmentService.resolveNow(hints);
      next['${item.codeType}|${item.productCode}'] = resolution;
      if (triggerBackground && !resolution.isResolved) {
        final key = LookupHints.bestInfarmedLookupKey(hints);
        if (key != null) {
          pending[key] = hints;
        }
      }
    }

    for (final event in _events) {
      final key = '${event.codeType}|${event.productCode}';
      if (next.containsKey(key)) {
        continue;
      }
      final hints = LookupHints.fromScanEvent(event);
      final resolution = await widget.enrichmentService.resolveNow(hints);
      next[key] = resolution;
      if (triggerBackground && !resolution.isResolved) {
        final pendingKey = LookupHints.bestInfarmedLookupKey(hints);
        if (pendingKey != null) {
          pending[pendingKey] = hints;
        }
      }
    }

    if (mounted) {
      setState(() {
        _resolutions
          ..clear()
          ..addAll(next);
      });
    }

    if (triggerBackground) {
      for (final hints in pending.values) {
        unawaited(_ensureBackgroundEnrichment(hints));
      }
    }
  }

  List<LookupHint> _lookupHintsForProduct(String productCode, String codeType) {
    final event = _events.lastWhere(
      (candidate) =>
          candidate.productCode == productCode &&
          candidate.codeType == codeType,
      orElse: () => ScanEvent(
        id: '',
        sessionId: widget.session.id,
        productCode: productCode,
        codeType: codeType,
        raw: productCode,
        serialNumber: null,
        lot: null,
        expiry: null,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        isDeleted: false,
      ),
    );
    if (event.id.isEmpty) {
      return LookupHints.fromRaw(
        productCode,
        productCode: productCode,
        codeType: codeType,
      );
    }
    return LookupHints.fromScanEvent(event);
  }

  Future<void> _ensureBackgroundEnrichment(List<LookupHint> hints) async {
    await widget.enrichmentService.ensureEnrichedInBackground(hints);
    if (!mounted) {
      return;
    }
    await _refreshResolutions(triggerBackground: false);
  }

  Future<void> _changeScanMode(
    ScanMode mode, {
    bool persistPreference = true,
  }) async {
    if (_scanMode == mode) {
      return;
    }
    if (_engine is MobileScannerEngine) {
      (_engine as MobileScannerEngine).setMode(mode);
    } else {
      final wasOpen = _scannerOpen;
      final shouldRestart = wasOpen && !_isPaused;
      if (wasOpen) {
        await _engine.stop();
      }

      await _subscription?.cancel();
      if (_engine is MobileScannerEngine) {
        await (_engine as MobileScannerEngine).dispose();
      }

      _engine = MobileScannerEngine(
        mode: mode,
        enableFallbackDecoder: _enableFallbackDecoder,
        debugReturnImage: _debugReturnImage,
      );
      _bindEngine();

      if (shouldRestart) {
        await _startScannerEngine();
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _scanMode = mode;
      _autoTorchAttempted = false;
      _trackedCodeRect = null;
      _trackedBarcodeLock = null;
    });
    _setScannerVisualState(
      _isPaused || _pausedByLifecycle
          ? ScannerVisualState.paused
          : ScannerVisualState.searching,
      title: _isPaused || _pausedByLifecycle
          ? 'Scanner em pausa'
          : 'A procurar',
      feedback: _isPaused || _pausedByLifecycle
          ? 'Retome para continuar a leitura.'
          : '',
    );

    if (persistPreference) {
      await _settings?.setPreferredScanMode(mode);
    }
  }

  Future<void> _handleScan(ScanResult result) async {
    if (!_scannerOpen || _isPaused || _pausedByLifecycle || _isRegistering) {
      return;
    }
    _isRegistering = true;

    try {
      final quantity = await _resolveRequestedQuantity(result);
      if (quantity == null) {
        _setScannerVisualState(
          ScannerVisualState.searching,
          title: 'A procurar',
          feedback: '',
        );
        return;
      }

      final acceptedEvents = <ScanEvent>[];
      var duplicateSerial = false;

      for (var index = 0; index < quantity; index += 1) {
        final outcome = await widget.repository.registerScan(
          sessionId: widget.session.id,
          raw: result.raw,
          formatHint: result.format,
        );
        if (outcome.wasDuplicateSerial) {
          duplicateSerial = true;
          break;
        }
        if (outcome.event != null) {
          acceptedEvents.add(outcome.event!);
        }
      }

      if (!mounted) {
        return;
      }

      if (duplicateSerial) {
        _setScannerVisualState(
          ScannerVisualState.error,
          title: 'Código repetido',
          feedback: 'A embalagem já foi registada nesta sessão.',
          keepFor: const Duration(seconds: 2),
        );
        return;
      }

      if (acceptedEvents.isEmpty) {
        await _reloadInventoryData();
        _setScannerVisualState(
          ScannerVisualState.error,
          title: 'Código não reconhecido',
          feedback: 'A leitura não produziu um registo válido.',
          keepFor: const Duration(seconds: 2),
        );
        return;
      }

      _applyAcceptedScans(acceptedEvents);
      final registeredCount = acceptedEvents.length;
      _setScannerVisualState(
        ScannerVisualState.read,
        title: registeredCount > 1
            ? context.trFormat(r'Lido x$registeredCount', {
                'registeredCount': registeredCount,
              })
            : 'Lido',
        feedback: registeredCount > 1
            ? context.trFormat(r'Leitura registada com quantidade x$count.', {
                'count': registeredCount,
              })
            : 'Leitura registada.',
        keepFor: const Duration(milliseconds: 1400),
      );

      if (_settings?.value.soundOnRead ?? true) {
        await _soundPlayer.playScanAccepted();
      }
      unawaited(_refreshResolutions(triggerBackground: true));
    } finally {
      _isRegistering = false;
    }
  }

  void _applyAcceptedScans(List<ScanEvent> events) {
    setState(() {
      for (final event in events) {
        _events
          ..removeWhere((existing) => existing.id == event.id)
          ..insert(0, event);
        if (_events.length > 50) {
          _events.removeRange(50, _events.length);
        }

        final index = _items.indexWhere(
          (item) =>
              item.productCode == event.productCode &&
              item.codeType == event.codeType,
        );
        if (index == -1) {
          _items.insert(
            0,
            InventoryItem(
              id: '${event.productCode}|${event.codeType}',
              sessionId: event.sessionId,
              productCode: event.productCode,
              codeType: event.codeType,
              qty: 1,
              lastScanAt: event.createdAt,
            ),
          );
        } else {
          final current = _items.removeAt(index);
          _items.insert(
            0,
            InventoryItem(
              id: current.id,
              sessionId: current.sessionId,
              productCode: current.productCode,
              codeType: current.codeType,
              qty: current.qty + 1,
              lastScanAt: event.createdAt,
            ),
          );
        }
      }
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  String get _modeHelperLabel => _scanMode == ScanMode.dataMatrix
      ? 'Aponte para o Data Matrix dentro da moldura.'
      : 'Aponte para o código de barras dentro da moldura.';

  bool get _shouldPromptBarcodeQuantity =>
      _scanMode == ScanMode.barcodes && _session.barcodeQuantityPromptEnabled;

  Future<bool> _startScannerEngine() async {
    await _engine.start();
    final controller = _cameraController;
    if (controller == null) {
      return true;
    }
    final state = await _waitForScannerReady(controller);
    if (state.isRunning) {
      await _applyAutoTorchIfNeeded();
      return true;
    }
    final error = state.error;
    _scannerLog(
      'start_failed code=${error?.errorCode.name ?? 'unknown'} '
      'message=${error?.errorDetails?.message ?? ''}',
    );
    if (mounted) {
      _setScannerVisualState(
        ScannerVisualState.error,
        title: 'Falha ao abrir a câmara',
        feedback: _describeScannerError(error),
        keepFor: const Duration(seconds: 3),
      );
    }
    return false;
  }

  Future<MobileScannerState> _waitForScannerReady(
    MobileScannerController controller,
  ) async {
    final initialState = controller.value;
    if (initialState.isRunning || initialState.error != null) {
      return initialState;
    }

    final completer = Completer<MobileScannerState>();

    void listener() {
      final next = controller.value;
      if (!completer.isCompleted &&
          (next.isRunning || next.error != null || !mounted)) {
        completer.complete(next);
      }
    }

    controller.addListener(listener);
    try {
      return await completer.future.timeout(
        _scannerStartTimeout,
        onTimeout: () => controller.value,
      );
    } finally {
      controller.removeListener(listener);
    }
  }

  Future<int?> _resolveRequestedQuantity(ScanResult result) async {
    if (!_shouldPromptBarcodeQuantity) {
      return 1;
    }
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => _BarcodeQuantitySheet(
        code: result.raw,
        onConfirm: (value) => Navigator.of(context).pop(value),
      ),
    );
  }

  Future<void> _openSessionSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _SessionSettingsSheet(
          barcodeQuantityPromptEnabled: _session.barcodeQuantityPromptEnabled,
          onBarcodeQuantityPromptChanged: _setSessionBarcodeQuantityPrompt,
        );
      },
    );
  }

  void _setScannerVisualState(
    ScannerVisualState state, {
    required String title,
    required String feedback,
    Duration? keepFor,
  }) {
    final now = DateTime.now();
    final holdUntil = _scannerStatusHoldUntil;
    final canOverrideHeldState =
        state == ScannerVisualState.paused || state == ScannerVisualState.error;
    final isTransientState =
        state == ScannerVisualState.searching ||
        state == ScannerVisualState.detected;
    if (holdUntil != null &&
        now.isBefore(holdUntil) &&
        isTransientState &&
        !canOverrideHeldState &&
        (_scannerVisualState == ScannerVisualState.read ||
            _scannerVisualState == ScannerVisualState.error)) {
      return;
    }
    final changed =
        _scannerVisualState != state ||
        _scannerStatusTitle != title ||
        _scannerFeedbackText != feedback;
    _scannerStatusResetTimer?.cancel();
    if (!mounted) {
      return;
    }
    _scannerVisualState = state;
    _scannerStatusTitle = title;
    _scannerFeedbackText = feedback;
    if (changed) {
      _publishScannerOverlay();
    }
    if (keepFor == null) {
      _scannerStatusHoldUntil = null;
      return;
    }
    _scannerStatusHoldUntil = now.add(keepFor);
    _scannerStatusResetTimer = Timer(keepFor, () {
      if (!mounted || !_scannerOpen) {
        return;
      }
      _scannerStatusHoldUntil = null;
      _setScannerVisualState(
        _isPaused || _pausedByLifecycle
            ? ScannerVisualState.paused
            : ScannerVisualState.searching,
        title: _isPaused || _pausedByLifecycle
            ? 'Scanner em pausa'
            : 'A procurar',
        feedback: _isPaused || _pausedByLifecycle
            ? 'Retome para continuar a leitura.'
            : '',
      );
    });
  }

  String _describeScannerError(MobileScannerException? error) {
    if (error == null) {
      return 'Confirme a permissão e tente novamente.';
    }
    final message = error.errorDetails?.message;
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'A app precisa de permissão de câmara para ler códigos.';
      case MobileScannerErrorCode.unsupported:
        return 'Este dispositivo não suporta o scanner atual.';
      case MobileScannerErrorCode.controllerDisposed:
      case MobileScannerErrorCode.controllerUninitialized:
      case MobileScannerErrorCode.controllerAlreadyInitialized:
      case MobileScannerErrorCode.genericError:
        return message?.isNotEmpty == true
            ? message!
            : 'O scanner falhou ao iniciar corretamente.';
    }
  }

  void _scannerLog(String message) {
    debugPrint('[inventory-scanner] $message');
  }

  Future<void> _toggleScanner() async {
    if (_scannerOpen) {
      await _closeScanner();
    } else {
      await _openScanner();
    }
  }

  Future<void> _openScanner() async {
    if (_scannerOpen || _startingScanner) {
      return;
    }
    _startingScanner = true;
    final started = await _startScannerEngine();
    _startingScanner = false;
    if (!mounted || !started) {
      return;
    }
    setState(() {
      _scannerOpen = true;
      _isPaused = false;
      _pausedByLifecycle = false;
      _autoTorchAttempted = false;
      _trackedCodeRect = null;
      _trackedBarcodeLock = null;
    });
    _setScannerVisualState(
      ScannerVisualState.searching,
      title: 'A procurar',
      feedback: '',
    );
  }

  Future<void> _closeScanner() async {
    await _engine.stop();
    if (!mounted) {
      return;
    }
    setState(() {
      _scannerOpen = false;
      _isPaused = false;
      _pausedByLifecycle = false;
      _autoTorchAttempted = false;
      _trackedCodeRect = null;
      _trackedBarcodeLock = null;
    });
    _publishScannerOverlay();
  }

  Future<void> _applyAutoTorchIfNeeded() async {
    final controller = _cameraController;
    final settings = _settings?.value;
    if (controller == null ||
        settings == null ||
        !settings.autoTorch ||
        _autoTorchAttempted) {
      return;
    }
    _autoTorchAttempted = true;
    final state = controller.value;
    if (state.torchState == TorchState.unavailable ||
        state.torchState == TorchState.on) {
      return;
    }
    await controller.toggleTorch();
  }

  Future<void> _setSessionBarcodeQuantityPrompt(bool enabled) async {
    final updated = await widget.repository.updateSessionBarcodeQuantityPrompt(
      widget.session.id,
      enabled,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _session = updated;
    });
    _showSnack(
      enabled
          ? 'Sessão: quantidade em barras ativa'
          : 'Sessão: quantidade em barras desativada',
    );
  }

  Future<void> _deleteEvent(ScanEvent event) async {
    if (event.isDeleted) {
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Apagar leitura'),
          content: const Text(
            'Tem a certeza que deseja apagar esta leitura? Esta ação não pode ser anulada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }
    final deleted = await widget.repository.deleteEvent(event.id);
    if (deleted) {
      await _reloadInventoryData();
      _showSnack('Leitura apagada');
    }
  }

  Future<void> _confirmDeleteSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Apagar sessão'),
          content: Text(
            context.trFormat(
              r'Tem a certeza que deseja apagar "$name"? Todos os eventos serão removidos.',
              {'name': widget.session.name},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Apagar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }
    await widget.repository.deleteSession(widget.session.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openExportFlow() async {
    if (_isExporting) {
      return;
    }
    setState(() {
      _isExporting = true;
    });

    final settings = _settings?.value;
    final initialFormat = _mapExportPreference(
      settings?.exportPreference ?? ExportPreference.csv,
    );
    final initialTemplate =
        settings?.customTxtTemplate ??
        AppSettingsState.defaultCustomTxtTemplate;

    if (!(settings?.previewBeforeSaving ?? true)) {
      await _saveExport(initialFormat, ExportMode.standard, initialTemplate);
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExportFlowPage(
          sessionName: widget.session.name,
          itemCount: _items.length,
          initialFormat: initialFormat,
          initialMode: ExportMode.standard,
          initialTemplate: initialTemplate,
          buildPreview: _buildExportPreview,
          onSave: _saveExport,
          onTemplateSaved: (template) async {
            await _settings?.setCustomTxtTemplate(template);
          },
          onPreferredFormatChanged: (format) async {
            await _settings?.setExportPreference(_mapExportFormat(format));
          },
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<String> _buildExportPreview(
    ExportFormat format,
    ExportMode mode,
    String template,
  ) async {
    if (mode == ExportMode.custom) {
      return widget.exporter.buildCustomPreview(widget.session.id, template);
    }
    switch (format) {
      case ExportFormat.csv:
        return widget.exporter.exportCsv(widget.session.id);
      case ExportFormat.json:
        return widget.exporter.exportJson(widget.session.id);
      case ExportFormat.txt:
        return widget.exporter.exportTxt(widget.session.id);
    }
  }

  Future<void> _saveExport(
    ExportFormat format,
    ExportMode mode,
    String template,
  ) async {
    final content = await _buildExportPreview(format, mode, template);
    final extension = switch (format) {
      ExportFormat.csv => 'csv',
      ExportFormat.json => 'json',
      ExportFormat.txt => 'txt',
    };
    final location = await getSaveLocation(
      suggestedName: 'inventario_${widget.session.name}.$extension',
    );
    if (location == null) {
      return;
    }
    await File(location.path).writeAsString(content);
  }

  ExportFormat _mapExportPreference(ExportPreference preference) {
    switch (preference) {
      case ExportPreference.csv:
        return ExportFormat.csv;
      case ExportPreference.json:
        return ExportFormat.json;
      case ExportPreference.txt:
        return ExportFormat.txt;
    }
  }

  ExportPreference _mapExportFormat(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return ExportPreference.csv;
      case ExportFormat.json:
        return ExportPreference.json;
      case ExportFormat.txt:
        return ExportPreference.txt;
    }
  }

  Widget _buildFeedbackPanel() {
    return const SizedBox.shrink();
  }

  Widget _buildScannerDebugOverlay() {
    return const SizedBox.shrink();
  }

  void _handleScannerCapture(
    BarcodeCapture capture,
    Size previewSize,
    Rect scanWindow,
  ) {
    if (!mounted || _isPaused || _pausedByLifecycle || !_scannerOpen) {
      return;
    }
    final now = DateTime.now();
    final textureSize = capture.size == Size.zero
        ? (_cameraController?.value.size ?? Size.zero)
        : capture.size;
    final candidates = _resolveTrackedCandidates(
      capture,
      previewSize,
      textureSize,
      scanWindow,
    );
    final selected = _selectTrackedCandidate(candidates, scanWindow);
    final nextTrackedRect = _updateTrackedLock(selected, now);
    if (_hasMaterialRectChange(_trackedCodeRect, nextTrackedRect)) {
      _trackedCodeRect = nextTrackedRect;
      _publishScannerOverlay();
      _recordOverlayMetrics(now);
    }
    if (_isRegistering) {
      return;
    }
    if (selected?.hasReadableRawValue == true) {
      _setScannerVisualState(
        ScannerVisualState.detected,
        title: 'Detetado',
        feedback: 'Mantenha o código dentro da moldura.',
        keepFor: const Duration(milliseconds: 700),
      );
      return;
    }
    if (candidates.isEmpty &&
        _scannerVisualState == ScannerVisualState.detected) {
      _setScannerVisualState(
        ScannerVisualState.searching,
        title: 'A procurar',
        feedback: '',
      );
    }
  }

  List<_TrackedBarcodeCandidate> _resolveTrackedCandidates(
    BarcodeCapture capture,
    Size previewSize,
    Size textureSize,
    Rect scanWindow,
  ) {
    final candidates = <_TrackedBarcodeCandidate>[];
    for (final barcode in capture.barcodes) {
      final rect = _mapTrackedBarcodeToPreviewRect(
        barcode: barcode,
        previewSize: previewSize,
        textureSize: textureSize,
      );
      if (rect == null) {
        continue;
      }
      final roiOverlap = _rectOverlapRatio(rect, scanWindow);
      if (!barcode.inScanWindow && barcode.track == null) {
        continue;
      }
      candidates.add(
        _TrackedBarcodeCandidate(
          barcode: barcode,
          rect: rect,
          roiOverlap: roiOverlap,
          nativeTrack: barcode.track,
        ),
      );
    }
    return candidates;
  }

  _TrackedBarcodeCandidate? _selectTrackedCandidate(
    List<_TrackedBarcodeCandidate> candidates,
    Rect scanWindow,
  ) {
    if (candidates.isEmpty) {
      return null;
    }
    final primaryNative = candidates
        .where((candidate) => candidate.hasNativeTrack)
        .fold<_TrackedBarcodeCandidate?>(null, (best, candidate) {
          if (best == null) {
            return candidate;
          }
          final bestConfidence = best.nativeTrack?.confidence ?? 0;
          final candidateConfidence = candidate.nativeTrack?.confidence ?? 0;
          if (candidateConfidence != bestConfidence) {
            return candidateConfidence > bestConfidence ? candidate : best;
          }
          final bestFrames = best.nativeTrack?.stableFrames ?? 0;
          final candidateFrames = candidate.nativeTrack?.stableFrames ?? 0;
          if (candidateFrames != bestFrames) {
            return candidateFrames > bestFrames ? candidate : best;
          }
          return candidate.roiOverlap > best.roiOverlap ? candidate : best;
        });
    if (primaryNative != null) {
      return primaryNative;
    }
    final lock = _trackedBarcodeLock;
    if (lock != null) {
      _TrackedBarcodeCandidate? best;
      var bestScore = double.negativeInfinity;
      for (final candidate in candidates) {
        final score = _continuityScore(candidate, lock, scanWindow);
        if (score > bestScore) {
          bestScore = score;
          best = candidate;
        }
      }
      if (best != null && bestScore > 120) {
        return best;
      }
    }

    _TrackedBarcodeCandidate? best;
    var bestScore = double.negativeInfinity;
    for (final candidate in candidates) {
      final score = _acquisitionScore(candidate, scanWindow);
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best;
  }

  bool _hasMaterialRectChange(Rect? current, Rect? next) {
    if (current == null || next == null) {
      return current != next;
    }
    return (current.left - next.left).abs() > _trackedRectDeltaThreshold ||
        (current.top - next.top).abs() > _trackedRectDeltaThreshold ||
        (current.width - next.width).abs() > _trackedRectDeltaThreshold ||
        (current.height - next.height).abs() > _trackedRectDeltaThreshold;
  }

  Rect? _mapTrackedBarcodeToPreviewRect({
    required Barcode barcode,
    required Size previewSize,
    required Size textureSize,
  }) {
    final track = barcode.track;
    final trackedCorners = track?.corners ?? barcode.corners;
    final trackedRect = track?.rect ?? Rect.zero;
    if (textureSize == Size.zero) {
      return null;
    }
    final fitted = applyBoxFit(BoxFit.cover, textureSize, previewSize);
    final destination = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & previewSize,
    );
    final scaleX = destination.width / textureSize.width;
    final scaleY = destination.height / textureSize.height;
    final dx = destination.left;
    final dy = destination.top;
    Rect? cornersRect;
    if (trackedCorners.length >= 4) {
      final mapped = trackedCorners
          .map(
            (corner) =>
                Offset(dx + (corner.dx * scaleX), dy + (corner.dy * scaleY)),
          )
          .toList();
      final left = mapped
          .map((corner) => corner.dx)
          .reduce((a, b) => a < b ? a : b);
      final top = mapped
          .map((corner) => corner.dy)
          .reduce((a, b) => a < b ? a : b);
      final right = mapped
          .map((corner) => corner.dx)
          .reduce((a, b) => a > b ? a : b);
      final bottom = mapped
          .map((corner) => corner.dy)
          .reduce((a, b) => a > b ? a : b);
      cornersRect = Rect.fromLTRB(left, top, right, bottom);
    }
    Rect? nativeRect;
    if (track != null && trackedRect != Rect.zero) {
      nativeRect = Rect.fromLTRB(
        dx + (trackedRect.left * scaleX),
        dy + (trackedRect.top * scaleY),
        dx + (trackedRect.right * scaleX),
        dy + (trackedRect.bottom * scaleY),
      );
    }
    final anchorRect = nativeRect ?? cornersRect;
    if (anchorRect == null || anchorRect.width <= 0 || anchorRect.height <= 0) {
      return null;
    }
    final sizeRect = _mapBarcodeSizeRect(
      barcode: barcode,
      scaleX: scaleX,
      scaleY: scaleY,
      center: anchorRect.center,
    );
    final widthCandidates = <double>[
      if (cornersRect != null) cornersRect.width,
      if (nativeRect != null) nativeRect.width,
      if (sizeRect != null) sizeRect.width,
    ];
    final heightCandidates = <double>[
      if (cornersRect != null) cornersRect.height,
      if (nativeRect != null) nativeRect.height,
      if (sizeRect != null) sizeRect.height,
    ];
    if (widthCandidates.isEmpty || heightCandidates.isEmpty) {
      return null;
    }
    final width = widthCandidates.fold<double>(0, max);
    final height = heightCandidates.fold<double>(0, max);
    var rect = _scanMode == ScanMode.dataMatrix
        ? _squareTrackedRect(
            center: anchorRect.center,
            widths: widthCandidates,
            heights: heightCandidates,
          )
        : Rect.fromCenter(
            center: anchorRect.center,
            width: width,
            height: height,
          );
    if (rect.width <= 0 || rect.height <= 0) {
      return null;
    }
    rect = _expandTrackedRect(rect);
    return rect.intersect(Offset.zero & previewSize);
  }

  Rect? _mapBarcodeSizeRect({
    required Barcode barcode,
    required double scaleX,
    required double scaleY,
    required Offset center,
  }) {
    if (barcode.size == Size.zero) {
      return null;
    }
    final width = barcode.size.width * scaleX;
    final height = barcode.size.height * scaleY;
    if (width <= 0 || height <= 0) {
      return null;
    }
    return Rect.fromCenter(center: center, width: width, height: height);
  }

  Rect _expandTrackedRect(Rect rect) {
    final horizontalPadding = _scanMode == ScanMode.dataMatrix
        ? (rect.width * 0.03).clamp(3.0, 8.0)
        : (rect.width * 0.05).clamp(8.0, 16.0);
    final verticalPadding = _scanMode == ScanMode.dataMatrix
        ? (rect.height * 0.03).clamp(3.0, 8.0)
        : (rect.height * 0.08).clamp(5.0, 14.0);
    final expanded = Rect.fromLTRB(
      rect.left - horizontalPadding,
      rect.top - verticalPadding,
      rect.right + horizontalPadding,
      rect.bottom + verticalPadding,
    );
    if (expanded.width < 28 || expanded.height < 28) {
      return rect;
    }
    return expanded;
  }

  Rect _squareTrackedRect({
    required Offset center,
    required List<double> widths,
    required List<double> heights,
  }) {
    final minWidth = widths.reduce(min);
    final minHeight = heights.reduce(min);
    final side = max(minWidth, minHeight).clamp(22.0, 240.0);
    return Rect.fromCenter(center: center, width: side, height: side);
  }

  Rect? _updateTrackedLock(_TrackedBarcodeCandidate? selected, DateTime now) {
    if (selected == null) {
      final current = _trackedBarcodeLock;
      if (current == null) {
        return null;
      }
      final missedFrames = current.missedFrames + 1;
      if (missedFrames >= _trackingMissFramesToDrop ||
          now.difference(current.lastSeenAt) > _trackingLostTimeout) {
        _trackedBarcodeLock = null;
        return null;
      }
      _trackedBarcodeLock = current.copyWith(missedFrames: missedFrames);
      return current.rect;
    }

    if (selected.hasNativeTrack) {
      final nativeTrack = selected.nativeTrack!;
      _trackedBarcodeLock = _TrackedBarcodeLock(
        identity: selected.identity,
        rect: selected.rect,
        lastSeenAt: now,
        stableFrames: nativeTrack.stableFrames,
        missedFrames: 0,
        roiOverlap: selected.roiOverlap,
      );
      return selected.rect;
    }

    final current = _trackedBarcodeLock;
    final identity = selected.identity;
    final continuedTarget =
        current != null &&
        (current.identity == identity ||
            _rectIou(current.rect, selected.rect) > 0.38);
    final stableFrames = continuedTarget ? current.stableFrames + 1 : 1;
    final smoothed = _smoothTrackedRect(
      current?.rect,
      selected.rect,
      stableFrames: stableFrames,
    );
    _trackedBarcodeLock = _TrackedBarcodeLock(
      identity: identity,
      rect: smoothed,
      lastSeenAt: now,
      stableFrames: stableFrames,
      missedFrames: 0,
      roiOverlap: selected.roiOverlap,
    );
    return smoothed;
  }

  Rect _smoothTrackedRect(
    Rect? current,
    Rect next, {
    required int stableFrames,
  }) {
    if (current == null) {
      return next;
    }
    final centerDistance = (current.center - next.center).distance;
    final widthDelta = (current.width - next.width).abs() / next.width;
    final heightDelta = (current.height - next.height).abs() / next.height;
    final sizeDelta = widthDelta > heightDelta ? widthDelta : heightDelta;
    final factor = centerDistance > 84 || sizeDelta > 0.42 ? 0.6 : 0.25;
    return Rect.fromLTRB(
      lerpDouble(current.left, next.left, factor)!,
      lerpDouble(current.top, next.top, factor)!,
      lerpDouble(current.right, next.right, factor)!,
      lerpDouble(current.bottom, next.bottom, factor)!,
    );
  }

  double _acquisitionScore(
    _TrackedBarcodeCandidate candidate,
    Rect scanWindow,
  ) {
    final area = candidate.rect.width * candidate.rect.height;
    final distance = (candidate.rect.center - scanWindow.center).distance;
    return (candidate.roiOverlap * 520) + (area * 0.018) - (distance * 1.1);
  }

  double _continuityScore(
    _TrackedBarcodeCandidate candidate,
    _TrackedBarcodeLock lock,
    Rect scanWindow,
  ) {
    final iou = _rectIou(candidate.rect, lock.rect);
    final distance = (candidate.rect.center - lock.rect.center).distance;
    final area = candidate.rect.width * candidate.rect.height;
    final identityBonus = candidate.identity == lock.identity ? 220.0 : 0.0;
    return (iou * 900) +
        (candidate.roiOverlap * 180) +
        identityBonus +
        (area * 0.012) -
        (distance * 1.35) -
        ((candidate.rect.center - scanWindow.center).distance * 0.3);
  }

  double _rectIou(Rect a, Rect b) {
    final intersection = a.intersect(b);
    if (intersection.isEmpty) {
      return 0;
    }
    final intersectionArea = intersection.width * intersection.height;
    final unionArea =
        (a.width * a.height) + (b.width * b.height) - intersectionArea;
    if (unionArea <= 0) {
      return 0;
    }
    return intersectionArea / unionArea;
  }

  double _rectOverlapRatio(Rect rect, Rect roi) {
    final overlap = rect.intersect(roi);
    if (overlap.isEmpty) {
      return 0;
    }
    final rectArea = rect.width * rect.height;
    if (rectArea <= 0) {
      return 0;
    }
    return (overlap.width * overlap.height) / rectArea;
  }

  void _recordOverlayMetrics(DateTime now) {
    if (!kDebugMode) {
      return;
    }
    _overlayUpdateCount += 1;
    final last = _lastOverlayMetricAt;
    if (last == null) {
      _lastOverlayMetricAt = now;
      return;
    }
    final elapsed = now.difference(last);
    if (elapsed < const Duration(seconds: 2)) {
      return;
    }
    final rate = (_overlayUpdateCount * 1000) / elapsed.inMilliseconds;
    _scannerLog(
      'overlay_updates=${rate.toStringAsFixed(1)}/s '
      'tracked=${_trackedBarcodeLock != null} '
      'stableFrames=${_trackedBarcodeLock?.stableFrames ?? 0}',
    );
    _overlayUpdateCount = 0;
    _lastOverlayMetricAt = now;
  }

  void _publishScannerOverlay() {
    final next = _ScannerOverlayViewState(
      visualState: _scannerVisualState,
      title: _scannerStatusTitle,
      modeHint: _modeHelperLabel,
      feedbackText: _scannerFeedbackText,
      trackedRect: _trackedCodeRect,
    );
    if (_scannerOverlay.value == next) {
      return;
    }
    _scannerOverlay.value = next;
  }

  double _cameraPreviewHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width * 0.64).clamp(208.0, 268.0);
  }

  Widget _buildCameraPreview() {
    final mobileEngine = _engine is MobileScannerEngine
        ? _engine as MobileScannerEngine
        : null;
    if (!_scannerOpen || mobileEngine == null || _cameraController == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layoutSize = Size(constraints.maxWidth, constraints.maxHeight);
        final scanWindow = _scanWindowForMode(layoutSize);
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: MobileScanner(
                controller: _cameraController!,
                onDetect: (capture) {
                  _handleScannerCapture(capture, layoutSize, scanWindow);
                  mobileEngine.handleDetect(capture);
                },
                scanWindow: scanWindow,
                errorBuilder: (context, error, child) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        _describeScannerError(error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ),
            ValueListenableBuilder<_ScannerOverlayViewState>(
              valueListenable: _scannerOverlay,
              builder: (context, overlay, child) {
                return _ScannerOverlay(
                  scanWindow: scanWindow,
                  trackedRect: overlay.trackedRect,
                  mode: _scanMode,
                  visualState: overlay.visualState,
                  title: overlay.title,
                );
              },
            ),
            _buildScannerDebugOverlay(),
          ],
        );
      },
    );
  }

  Rect _scanWindowForMode(Size layoutSize) {
    if (_scanMode == ScanMode.dataMatrix) {
      final size = layoutSize.shortestSide * 0.74;
      return Rect.fromCenter(
        center: layoutSize.center(Offset.zero),
        width: size,
        height: size,
      );
    }
    final width = layoutSize.width * 0.92;
    final height = width * 0.46;
    return Rect.fromCenter(
      center: layoutSize.center(Offset.zero),
      width: width,
      height: height,
    );
  }

  Widget _buildSummaryStrip() {
    return TourTargetAnchor(
      targetId: AppTourTargetId.inventorySummaryStrip,
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(label: 'ITENS', value: '${_items.length}'),
          ),
          Expanded(
            child: _SummaryMetric(label: 'QTD', value: '$_totalReads'),
          ),
          Expanded(
            child: _SummaryMetric(label: 'ÚLTIMO', value: _latestReadLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    return TourTargetAnchor(
      targetId: AppTourTargetId.inventoryModeTabs,
      child: Row(
        children: [
          _PillTab(
            label: 'Produtos',
            selected: _activeTab == InventoryTab.products,
            onTap: () => setState(() => _activeTab = InventoryTab.products),
          ),
          const SizedBox(width: 8),
          _PillTab(
            label: 'Leituras',
            selected: _activeTab == InventoryTab.recentReads,
            onTap: () => setState(() => _activeTab = InventoryTab.recentReads),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return TourTargetAnchor(
      targetId: AppTourTargetId.inventoryFilterChips,
      child: Row(
        children: [
          _FilterChip(
            label: 'Todos',
            selected: _activeFilter == InventoryQuickFilter.all,
            onTap: () =>
                setState(() => _activeFilter = InventoryQuickFilter.all),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'A expirar',
            selected: _activeFilter == InventoryQuickFilter.expiring,
            warning: true,
            onTap: () =>
                setState(() => _activeFilter = InventoryQuickFilter.expiring),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Sem catálogo',
            selected: _activeFilter == InventoryQuickFilter.unresolved,
            onTap: () =>
                setState(() => _activeFilter = InventoryQuickFilter.unresolved),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final statsByCode = _eventStatsByCode;
    final items = _filteredItems;
    if (items.isEmpty) {
      return TourTargetAnchor(
        targetId: AppTourTargetId.inventoryProductsList,
        child: _EmptyState(
          query: _searchController.text,
          onClearQuery: _clearSearch,
        ),
      );
    }

    return TourTargetAnchor(
      targetId: AppTourTargetId.inventoryProductsList,
      child: Column(
        children: items.map((item) {
          final summary = statsByCode[item.productCode];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ProductCard(
              item: item,
              summary: summary,
              resolution: _resolutionForCode(item.productCode, item.codeType),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(
                      repository: widget.repository,
                      enrichmentService: widget.enrichmentService,
                      session: widget.session,
                      item: item,
                    ),
                  ),
                );
                await _reloadInventoryData();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentReadsTab() {
    final events = _filteredEvents;
    if (events.isEmpty) {
      return TourTargetAnchor(
        targetId: AppTourTargetId.inventoryReadsList,
        child: _EmptyState(
          query: _searchController.text,
          onClearQuery: _clearSearch,
        ),
      );
    }

    return TourTargetAnchor(
      targetId: AppTourTargetId.inventoryReadsList,
      child: Column(
        children: events.map((event) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReadCard(
              event: event,
              resolution: _resolutionForCode(event.productCode, event.codeType),
              onDelete: event.isDeleted ? null : () => _deleteEvent(event),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isExpiring(DateTime? expiry) {
    if (expiry == null) {
      return false;
    }
    final alertDays = _settings?.value.expiryAlertDays ?? 30;
    final today = DateTime.now();
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final startOfToday = DateTime(today.year, today.month, today.day);
    return expiryDay.difference(startOfToday).inDays <= alertDays;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _clearSearch();
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    _tourController?.markPageVisible(AppTourPage.inventory);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _reloadInventoryData();
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.s(18),
              context.s(14),
              context.s(18),
              context.s(132),
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  SizedBox(width: context.s(8)),
                  Expanded(
                    child: _isSearching
                        ? TourTargetAnchor(
                            targetId: AppTourTargetId.inventorySearchField,
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: context.tr('Filtrar produtos...'),
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.session.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              SizedBox(height: context.s(3)),
                              Text(
                                'A contar...',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                  ),
                  SizedBox(width: context.s(8)),
                  TourTargetAnchor(
                    targetId: AppTourTargetId.inventorySearchButton,
                    child: SizedBox.square(
                      dimension: context.s(48),
                      child: IconButton(
                        tooltip: context.tr('Pesquisar'),
                        onPressed: _toggleSearch,
                        icon: Icon(_isSearching ? Icons.close : Icons.search),
                      ),
                    ),
                  ),
                  TourTargetAnchor(
                    targetId: AppTourTargetId.inventoryExportButton,
                    child: SizedBox.square(
                      dimension: context.s(48),
                      child: IconButton(
                        tooltip: context.tr('Exportar dados'),
                        onPressed: _isExporting ? null : _openExportFlow,
                        icon: const Icon(Icons.file_download_outlined),
                      ),
                    ),
                  ),
                  TourTargetAnchor(
                    targetId: AppTourTargetId.inventoryMenuButton,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'session_settings') {
                          _openSessionSettingsSheet();
                        } else if (value == 'delete_session') {
                          _confirmDeleteSession();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'session_settings',
                          child: Text('Definições da sessão'),
                        ),
                        PopupMenuItem(
                          value: 'delete_session',
                          child: Text('Apagar sessão'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.s(12)),
              _buildFeedbackPanel(),
              if (_scannerOpen) ...[
                SizedBox(height: context.s(14)),
                Card(
                  color: Colors.black,
                  child: Padding(
                    padding: EdgeInsets.all(context.s(12)),
                    child: Column(
                      children: [
                        SizedBox(
                          height: _cameraPreviewHeight(context),
                          child: _buildCameraPreview(),
                        ),
                        ValueListenableBuilder<_ScannerOverlayViewState>(
                          valueListenable: _scannerOverlay,
                          builder: (context, overlay, child) {
                            return Column(
                              children: [
                                SizedBox(height: context.s(8)),
                                _ScannerStatusHint(
                                  feedbackText: overlay.feedbackText,
                                  hintText: overlay.modeHint,
                                  visualState: overlay.visualState,
                                ),
                                SizedBox(height: context.s(10)),
                                _ScannerModeControlsBar(
                                  scanMode: _scanMode,
                                  onModeChanged: _changeScanMode,
                                  torchButton: TourTargetAnchor(
                                    targetId: AppTourTargetId
                                        .inventoryScannerTorchButton,
                                    child: _TorchButton(
                                      controller: _cameraController,
                                      scannerOpen: _scannerOpen,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: context.s(14)),
              _buildSummaryStrip(),
              SizedBox(height: context.s(16)),
              _buildFilterChips(),
              SizedBox(height: context.s(14)),
              _buildModeTabs(),
              SizedBox(height: context.s(18)),
              if (_activeTab == InventoryTab.products)
                _buildProductsTab()
              else
                _buildRecentReadsTab(),
            ],
          ),
        ),
      ),
      floatingActionButton: TourTargetAnchor(
        targetId: AppTourTargetId.inventoryScannerFab,
        child: FloatingActionButton(
          onPressed: _toggleScanner,
          child: Icon(_scannerOpen ? Icons.close : Icons.center_focus_strong),
        ),
      ),
    );
  }
}

class ExportFlowPage extends StatefulWidget {
  const ExportFlowPage({
    super.key,
    required this.sessionName,
    required this.itemCount,
    required this.initialFormat,
    required this.initialMode,
    required this.initialTemplate,
    required this.buildPreview,
    required this.onSave,
    required this.onTemplateSaved,
    required this.onPreferredFormatChanged,
  });

  final String sessionName;
  final int itemCount;
  final ExportFormat initialFormat;
  final ExportMode initialMode;
  final String initialTemplate;
  final Future<String> Function(
    ExportFormat format,
    ExportMode mode,
    String template,
  )
  buildPreview;
  final Future<void> Function(
    ExportFormat format,
    ExportMode mode,
    String template,
  )
  onSave;
  final Future<void> Function(String template) onTemplateSaved;
  final Future<void> Function(ExportFormat format) onPreferredFormatChanged;

  @override
  State<ExportFlowPage> createState() => _ExportFlowPageState();
}

class _ExportFlowPageState extends State<ExportFlowPage> {
  late ExportFormat _format;
  late ExportMode _mode;
  late TextEditingController _templateController;
  String _preview = '...';
  bool _isLoading = true;

  static const _variables = [
    ('code', 'Código'),
    ('name', 'Nome'),
    ('quantity', 'Qtd'),
    ('lot', 'Lote'),
    ('expiry', 'Validade'),
    ('session', 'Sessão'),
    ('date', 'Data'),
  ];

  @override
  void initState() {
    super.initState();
    _format = widget.initialFormat;
    _mode = widget.initialMode;
    _templateController = TextEditingController(text: widget.initialTemplate);
    _templateController.addListener(_refreshPreview);
    _refreshPreview();
  }

  @override
  void dispose() {
    _templateController.removeListener(_refreshPreview);
    _templateController.dispose();
    super.dispose();
  }

  Future<void> _refreshPreview() async {
    setState(() {
      _isLoading = true;
    });
    final preview = await widget.buildPreview(
      _format,
      _mode,
      _templateController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _preview = preview.isEmpty ? '...' : preview;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    await widget.onTemplateSaved(_templateController.text);
    await widget.onPreferredFormatChanged(_format);
    await widget.onSave(_format, _mode, _templateController.text);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ficheiro guardado.')));
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _preview));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Texto copiado.')));
    }
  }

  void _insertVariable(String variable) {
    final token = '{{$variable}}';
    final selection = _templateController.selection;
    final start = selection.start < 0
        ? _templateController.text.length
        : selection.start;
    final end = selection.end < 0
        ? _templateController.text.length
        : selection.end;
    final next = _templateController.text.replaceRange(start, end, token);
    _templateController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      color: context.palette.success,
    );
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.s(18),
            context.s(14),
            context.s(18),
            context.s(28),
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                SizedBox(width: context.s(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exportar sessão',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: context.s(3)),
                      Text(
                        'Escolha formato e conteúdo do ficheiro',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.s(26)),
            TourTargetAnchor(
              targetId: AppTourTargetId.exportFormatSection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FORMATO DE SAÍDA',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  SizedBox(height: context.s(10)),
                  Row(
                    children: [
                      Expanded(
                        child: _ExportFormatButton(
                          label: 'CSV',
                          icon: Icons.description_outlined,
                          selected: _format == ExportFormat.csv,
                          onTap: () {
                            setState(() {
                              _format = ExportFormat.csv;
                              _mode = ExportMode.standard;
                            });
                            _refreshPreview();
                          },
                        ),
                      ),
                      SizedBox(width: context.s(10)),
                      Expanded(
                        child: _ExportFormatButton(
                          label: 'JSON',
                          icon: Icons.data_object,
                          selected: _format == ExportFormat.json,
                          onTap: () {
                            setState(() {
                              _format = ExportFormat.json;
                              _mode = ExportMode.standard;
                            });
                            _refreshPreview();
                          },
                        ),
                      ),
                      SizedBox(width: context.s(10)),
                      Expanded(
                        child: _ExportFormatButton(
                          label: 'TXT',
                          icon: Icons.article_outlined,
                          selected: _format == ExportFormat.txt,
                          onTap: () {
                            setState(() {
                              _format = ExportFormat.txt;
                            });
                            _refreshPreview();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: context.s(24)),
            TourTargetAnchor(
              targetId: AppTourTargetId.exportModeSection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MODO DE EXPORTAÇÃO',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  SizedBox(height: context.s(10)),
                  Row(
                    children: [
                      Expanded(
                        child: _SegmentButton(
                          label: 'Padrão',
                          selected: _mode == ExportMode.standard,
                          onTap: () {
                            setState(() {
                              _mode = ExportMode.standard;
                            });
                            _refreshPreview();
                          },
                        ),
                      ),
                      SizedBox(width: context.s(10)),
                      Expanded(
                        child: _SegmentButton(
                          label: 'Personalizado',
                          selected: _mode == ExportMode.custom,
                          onTap: () {
                            setState(() {
                              _mode = ExportMode.custom;
                              _format = ExportFormat.txt;
                            });
                            _refreshPreview();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_mode == ExportMode.custom) ...[
              SizedBox(height: context.s(24)),
              Text(
                'TEMPLATE PERSONALIZADO',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              SizedBox(height: context.s(10)),
              TextField(
                controller: _templateController,
                maxLines: 4,
                decoration: const InputDecoration(),
              ),
              SizedBox(height: context.s(18)),
              Text(
                'INSERIR VARIÁVEIS',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              SizedBox(height: context.s(10)),
              Wrap(
                spacing: context.s(8),
                runSpacing: context.s(8),
                children: _variables
                    .map(
                      (entry) => _MiniVariableChip(
                        label: entry.$2,
                        onTap: () => _insertVariable(entry.$1),
                      ),
                    )
                    .toList(),
              ),
            ],
            SizedBox(height: context.s(24)),
            TourTargetAnchor(
              targetId: AppTourTargetId.exportPreviewSection,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'PRÉ-VISUALIZAÇÃO REAL',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      Text(
                        context.trPlural(
                          count: widget.itemCount,
                          oneSource: r'$count registo',
                          otherSource: r'$count registos',
                          placeholder: 'count',
                        ),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: context.palette.accent),
                      ),
                    ],
                  ),
                  SizedBox(height: context.s(10)),
                  Card(
                    color: context.palette.surfaceStrong,
                    child: Padding(
                      padding: EdgeInsets.all(context.s(16)),
                      child: _isLoading
                          ? const SizedBox(
                              height: 60,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : SelectableText(_preview, style: previewStyle),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.s(34)),
            TourTargetAnchor(
              targetId: AppTourTargetId.exportSaveButton,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Guardar ficheiro'),
              ),
            ),
            SizedBox(height: context.s(10)),
            TextButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.content_copy_outlined),
              label: const Text('Copiar texto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.summary,
    required this.resolution,
    required this.onTap,
  });

  final InventoryItem item;
  final _EventSummary? summary;
  final MedicationResolution? resolution;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final expiry = summary?.expiry;
    final metadata = resolution?.medication?.entry;
    final subtitle = [
      metadata?.activeSubstance,
      metadata?.strength,
      metadata?.pharmaceuticalForm,
      metadata?.presentation,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata?.displayName ?? item.productCode,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(label: _sourceLabel(resolution)),
                        _MetaPill(
                          label: item.codeType == CodeType.gtin
                              ? 'GTIN'
                              : item.codeType,
                        ),
                        _MetaPill(
                          label: context.trFormat(r'Qtd $quantity', {
                            'quantity': item.qty,
                          }),
                        ),
                        if (summary?.lot != null && summary!.lot!.isNotEmpty)
                          _MetaPill(
                            label: context.trFormat(r'Lote $lot', {
                              'lot': summary!.lot!,
                            }),
                          ),
                      ],
                    ),
                    if (expiry != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        context.trFormat(r'Validade $expiry', {
                          'expiry': expiry,
                        }),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.palette.warningText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.palette.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  String _sourceLabel(MedicationResolution? resolution) {
    switch (resolution?.preferredSourceName) {
      case MedicationSource.csvManual:
        return 'CSV';
      case MedicationSource.infarmed:
        return 'INFARMED';
      case MedicationSource.ema:
        return 'EMA';
      case MedicationSource.gepir:
        return 'GEPIR';
      default:
        return 'Sem catálogo';
    }
  }
}

class _ReadCard extends StatelessWidget {
  const _ReadCard({
    required this.event,
    required this.resolution,
    required this.onDelete,
  });

  final ScanEvent event;
  final MedicationResolution? resolution;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final metadata = resolution?.medication?.entry;
    final subtitleParts = <String>[
      if (metadata?.activeSubstance != null &&
          metadata!.activeSubstance!.isNotEmpty)
        metadata.activeSubstance!,
      if (event.serialNumber != null && event.serialNumber!.isNotEmpty)
        context.trFormat(r'SN $serialNumber', {
          'serialNumber': event.serialNumber,
        }),
      if (event.lot != null && event.lot!.isNotEmpty)
        context.trFormat(r'Lote $lot', {'lot': event.lot}),
      if (event.expiry != null)
        context.trFormat(r'Validade $expiry', {
          'expiry':
              '${event.expiry!.day.toString().padLeft(2, '0')}/${event.expiry!.month.toString().padLeft(2, '0')}/${event.expiry!.year}',
        }),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: context.palette.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                event.codeType == CodeType.gtin ? 'DM' : '1D',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metadata?.displayName ?? event.productCode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitleParts.isEmpty
                        ? 'Sem detalhes adicionais'
                        : subtitleParts.join(' • '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, required this.onClearQuery});

  final String query;
  final VoidCallback onClearQuery;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 68,
            color: context.palette.textMuted,
          ),
          const SizedBox(height: 18),
          Text(
            hasQuery ? 'Sem resultados' : 'Ainda não há leituras',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            hasQuery
                ? 'A pesquisa não encontrou produtos ou leituras com esse termo.'
                : 'Abra o scanner para começar a contar.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (hasQuery) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClearQuery,
              child: const Text('Limpar pesquisa'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? context.palette.surfaceMuted
              : context.palette.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: selected
                ? context.palette.textPrimary
                : context.palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.warning = false,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final bool warning;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    if (selected) {
      background = warning ? context.palette.warning : context.palette.accent;
      foreground = warning
          ? context.palette.warningText
          : context.palette.accentInk;
    } else {
      background = context.palette.surface;
      foreground = context.palette.textPrimary;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}

class _TorchButton extends StatelessWidget {
  const _TorchButton({required this.controller, required this.scannerOpen});

  final MobileScannerController? controller;
  final bool scannerOpen;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return const _TorchToggleChip(enabled: false, isOn: false, onTap: null);
    }
    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, child) {
        final torchState = state.torchState;
        final canToggle = scannerOpen && torchState != TorchState.unavailable;
        final isOn = torchState == TorchState.on;
        return _TorchToggleChip(
          enabled: canToggle,
          isOn: isOn,
          onTap: canToggle ? () => controller.toggleTorch() : null,
        );
      },
    );
  }
}

class _TorchToggleChip extends StatelessWidget {
  const _TorchToggleChip({
    required this.enabled,
    required this.isOn,
    required this.onTap,
  });

  final bool enabled;
  final bool isOn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final background = enabled
        ? Colors.black.withValues(alpha: 0.36)
        : Colors.black.withValues(alpha: 0.22);
    final foreground = enabled ? Colors.white : Colors.white54;
    return SizedBox(
      height: 52,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOn ? Icons.flash_on : Icons.flash_off,
                  color: foreground,
                ),
                const SizedBox(width: 8),
                Text(
                  'Flash',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlayViewState {
  const _ScannerOverlayViewState({
    required this.visualState,
    required this.title,
    required this.modeHint,
    required this.feedbackText,
    required this.trackedRect,
  });

  final ScannerVisualState visualState;
  final String title;
  final String modeHint;
  final String feedbackText;
  final Rect? trackedRect;

  @override
  bool operator ==(Object other) {
    return other is _ScannerOverlayViewState &&
        other.visualState == visualState &&
        other.title == title &&
        other.modeHint == modeHint &&
        other.feedbackText == feedbackText &&
        other.trackedRect == trackedRect;
  }

  @override
  int get hashCode =>
      Object.hash(visualState, title, modeHint, feedbackText, trackedRect);
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({
    required this.scanWindow,
    required this.trackedRect,
    required this.mode,
    required this.visualState,
    required this.title,
  });

  final Rect scanWindow;
  final Rect? trackedRect;
  final ScanMode mode;
  final ScannerVisualState visualState;
  final String title;

  @override
  Widget build(BuildContext context) {
    final highlightRect = trackedRect ?? scanWindow;
    final borderRadius = _trackedBorderRadius(highlightRect);
    final accent = switch (visualState) {
      ScannerVisualState.searching => Colors.white,
      ScannerVisualState.detected => const Color(0xFF8BD7FF),
      ScannerVisualState.reading => const Color(0xFFFFD166),
      ScannerVisualState.read => const Color(0xFF5CE1A8),
      ScannerVisualState.paused => Colors.white70,
      ScannerVisualState.error => const Color(0xFFFF8A80),
    };
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.26),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(
                rect: highlightRect,
                accent: accent,
                borderRadius: borderRadius,
              ),
            ),
          ),
          Positioned(
            left: 4,
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BorderRadius _trackedBorderRadius(Rect rect) {
    final minSide = min(rect.width, rect.height);
    final radius = mode == ScanMode.dataMatrix
        ? (minSide * 0.12).clamp(6.0, 12.0)
        : (minSide * 0.08).clamp(4.0, 8.0);
    return BorderRadius.circular(radius);
  }
}

class _ScannerModeControlsBar extends StatelessWidget {
  const _ScannerModeControlsBar({
    required this.scanMode,
    required this.onModeChanged,
    required this.torchButton,
  });

  final ScanMode scanMode;
  final ValueChanged<ScanMode> onModeChanged;
  final Widget torchButton;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.36),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TourTargetAnchor(
                    targetId: AppTourTargetId.inventoryScannerModeDataMatrix,
                    child: _FilterChip(
                      label: 'Data Matrix',
                      selected: scanMode == ScanMode.dataMatrix,
                      compact: true,
                      onTap: () => onModeChanged(ScanMode.dataMatrix),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TourTargetAnchor(
                    targetId: AppTourTargetId.inventoryScannerModeBarcode,
                    child: _FilterChip(
                      label: 'Barras',
                      selected: scanMode == ScanMode.barcodes,
                      compact: true,
                      onTap: () => onModeChanged(ScanMode.barcodes),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        torchButton,
      ],
    );
  }
}

class _ScannerStatusHint extends StatelessWidget {
  const _ScannerStatusHint({
    required this.feedbackText,
    required this.hintText,
    required this.visualState,
  });

  final String feedbackText;
  final String hintText;
  final ScannerVisualState visualState;

  @override
  Widget build(BuildContext context) {
    final feedbackColor = switch (visualState) {
      ScannerVisualState.error => const Color(0xFFFFB4AB),
      ScannerVisualState.read => const Color(0xFFB9F6D3),
      ScannerVisualState.reading => const Color(0xFFFFE08A),
      ScannerVisualState.detected => Colors.white70,
      ScannerVisualState.paused => Colors.white60,
      _ => Colors.white70,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (feedbackText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  feedbackText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: feedbackColor),
                ),
              ),
            Text(
              hintText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({
    required this.rect,
    required this.accent,
    required this.borderRadius,
  });

  final Rect rect;
  final Color accent;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = borderRadius.toRRect(rect);
    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final borderPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.accent != accent ||
        oldDelegate.borderRadius != borderRadius;
  }
}

class _TrackedBarcodeCandidate {
  const _TrackedBarcodeCandidate({
    required this.barcode,
    required this.rect,
    required this.roiOverlap,
    required this.nativeTrack,
  });

  final Barcode barcode;
  final Rect rect;
  final double roiOverlap;
  final BarcodeTrack? nativeTrack;

  String get identity => barcode.rawValue?.isNotEmpty == true
      ? barcode.rawValue!
      : nativeTrack?.id.isNotEmpty == true
      ? nativeTrack!.id
      : '${barcode.format.name}:${rect.center.dx.round()}:${rect.center.dy.round()}';

  bool get hasReadableRawValue => barcode.rawValue?.isNotEmpty == true;
  bool get hasNativeTrack => nativeTrack != null;
}

class _TrackedBarcodeLock {
  const _TrackedBarcodeLock({
    required this.identity,
    required this.rect,
    required this.lastSeenAt,
    required this.stableFrames,
    required this.missedFrames,
    required this.roiOverlap,
  });

  final String identity;
  final Rect rect;
  final DateTime lastSeenAt;
  final int stableFrames;
  final int missedFrames;
  final double roiOverlap;

  _TrackedBarcodeLock copyWith({
    Rect? rect,
    DateTime? lastSeenAt,
    int? stableFrames,
    int? missedFrames,
    double? roiOverlap,
  }) {
    return _TrackedBarcodeLock(
      identity: identity,
      rect: rect ?? this.rect,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      stableFrames: stableFrames ?? this.stableFrames,
      missedFrames: missedFrames ?? this.missedFrames,
      roiOverlap: roiOverlap ?? this.roiOverlap,
    );
  }
}

class _SessionSettingsSheet extends StatefulWidget {
  const _SessionSettingsSheet({
    required this.barcodeQuantityPromptEnabled,
    required this.onBarcodeQuantityPromptChanged,
  });

  final bool barcodeQuantityPromptEnabled;
  final ValueChanged<bool> onBarcodeQuantityPromptChanged;

  @override
  State<_SessionSettingsSheet> createState() => _SessionSettingsSheetState();
}

class _SessionSettingsSheetState extends State<_SessionSettingsSheet> {
  late bool _barcodeQuantityPromptEnabled;

  @override
  void initState() {
    super.initState();
    _barcodeQuantityPromptEnabled = widget.barcodeQuantityPromptEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.s(18),
          context.s(8),
          context.s(18),
          context.s(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Definições da sessão',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: context.s(8)),
            Text(
              'Estas opções prevalecem sobre o default global da aplicação para esta sessão.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            SizedBox(height: context.s(18)),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.s(14),
                  vertical: context.s(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sessão: pedir quantidade nas barras',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: context.s(4)),
                          Text(
                            'Fica guardado para esta sessão e aplica-se quando mudar para Barras.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.palette.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.s(12)),
                    Switch.adaptive(
                      value: _barcodeQuantityPromptEnabled,
                      onChanged: (value) {
                        setState(() {
                          _barcodeQuantityPromptEnabled = value;
                        });
                        widget.onBarcodeQuantityPromptChanged(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarcodeQuantitySheet extends StatefulWidget {
  const _BarcodeQuantitySheet({required this.code, required this.onConfirm});

  final String code;
  final ValueChanged<int> onConfirm;

  @override
  State<_BarcodeQuantitySheet> createState() => _BarcodeQuantitySheetState();
}

class _BarcodeQuantitySheetState extends State<_BarcodeQuantitySheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final codePreview = widget.code.length > 24
        ? '${widget.code.substring(0, 24)}…'
        : widget.code;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.s(18),
          context.s(20),
          context.s(18),
          context.s(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantidade para código de barras',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: context.s(6)),
            Text(codePreview, style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: context.s(16)),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.tr('Quantidade'),
                hintText: '1',
              ),
            ),
            SizedBox(height: context.s(14)),
            Wrap(
              spacing: context.s(8),
              runSpacing: context.s(8),
              children: [1, 2, 3, 5, 10]
                  .map(
                    (value) => _QuickQtyChip(
                      value: value,
                      onTap: () => _controller.text = '$value',
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: context.s(20)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                SizedBox(width: context.s(12)),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final parsed = int.tryParse(_controller.text.trim()) ?? 1;
                      widget.onConfirm(parsed.clamp(1, 999));
                    },
                    child: const Text('Registar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickQtyChip extends StatelessWidget {
  const _QuickQtyChip({required this.value, required this.onTap});

  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.palette.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(context.trFormat(r'x$value', {'value': value})),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ExportFormatButton extends StatelessWidget {
  const _ExportFormatButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: selected
              ? context.palette.surfaceMuted
              : context.palette.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: context.palette.textPrimary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? context.palette.accent : context.palette.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: selected
                  ? context.palette.accentInk
                  : context.palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniVariableChip extends StatelessWidget {
  const _MiniVariableChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _EventSummary {
  const _EventSummary({required this.latestScanAt, this.expiry, this.lot});

  final DateTime latestScanAt;
  final DateTime? expiry;
  final String? lot;

  _EventSummary copyWith({
    DateTime? latestScanAt,
    DateTime? expiry,
    String? lot,
  }) {
    return _EventSummary(
      latestScanAt: latestScanAt ?? this.latestScanAt,
      expiry: expiry ?? this.expiry,
      lot: lot ?? this.lot,
    );
  }
}
