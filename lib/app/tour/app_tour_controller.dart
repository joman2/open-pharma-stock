import 'package:flutter/material.dart';

import '../backup/app_backup_service.dart';
import '../../export/inventory_exporter.dart';
import '../../features/inventory/domain/inventory_repository.dart';
import '../../features/inventory/presentation/inventory_page.dart';
import '../../features/inventory/presentation/product_detail_page.dart';
import '../../features/medication_catalog/data/catalog_csv_importer.dart';
import '../../features/medication_catalog/domain/medication_catalog_repository.dart';
import '../../features/medication_catalog/domain/medication_enrichment_service.dart';
import '../settings/app_settings.dart';
import '../settings/settings_page.dart';
import 'app_tour_state.dart';
import 'app_tour_targets.dart';

class AppTourController extends ValueNotifier<AppTourState> {
  AppTourController({
    required this.settingsController,
    required this.repository,
    required this.exporter,
    required this.backupService,
    required this.catalogImporter,
    required this.catalogRepository,
    required this.enrichmentService,
  }) : super(const AppTourState());

  final AppSettingsController settingsController;
  final InventoryRepository repository;
  final InventoryExporter exporter;
  final AppBackupService backupService;
  final CatalogCsvImporter catalogImporter;
  final MedicationCatalogRepository catalogRepository;
  final MedicationEnrichmentService enrichmentService;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final AppTourTargets targets = AppTourTargets();

  final Map<AppTourActionId, Future<void> Function()> _actions = {};
  bool _autoStartAttempted = false;
  AppTourPage? _visiblePage;

  void registerAction(
    AppTourActionId actionId,
    Future<void> Function() callback,
  ) {
    _actions[actionId] = callback;
  }

  void unregisterAction(AppTourActionId actionId) {
    _actions.remove(actionId);
  }

  Future<void> maybeStartAutomatically() async {
    if (_autoStartAttempted || value.isActive) {
      return;
    }
    _autoStartAttempted = true;
    if (!settingsController.value.shouldAutoStartTour) {
      return;
    }
    await _startTour(AppTourStartOrigin.automatic);
  }

  Future<void> startManualTour() async {
    await _startTour(AppTourStartOrigin.manualReplay);
  }

  void markPageVisible(AppTourPage page) {
    _visiblePage = page;
  }

  Future<void> next() async {
    if (!value.isActive || value.isBusy) {
      return;
    }
    final nextIndex = value.stepIndex + 1;
    if (nextIndex >= value.steps.length) {
      await complete();
      return;
    }
    await _activateStep(nextIndex);
  }

  Future<void> previous() async {
    if (!value.isActive || value.isBusy || !value.hasPrevious) {
      return;
    }
    await _activateStep(value.stepIndex - 1);
  }

  Future<void> skip() async {
    if (!value.isActive) {
      return;
    }
    await settingsController.markTourDismissed();
    value = const AppTourState();
  }

  Future<void> complete() async {
    if (!value.isActive) {
      return;
    }
    await settingsController.markTourCompleted();
    value = const AppTourState();
  }

  Future<void> _startTour(AppTourStartOrigin origin) async {
    if (value.isActive) {
      value = const AppTourState();
    }

    final steps = await buildStepsForTesting(origin);
    if (steps.isEmpty) {
      return;
    }

    _visiblePage = null;

    value = AppTourState(
      isActive: true,
      isBusy: true,
      stepIndex: 0,
      steps: steps,
      origin: origin,
    );

    await _activateStep(0);
  }

  @visibleForTesting
  Future<List<AppTourStep>> buildStepsForTesting(
    AppTourStartOrigin origin,
  ) async {
    final sessions = await repository.listSessions();
    final firstSession = sessions.isEmpty ? null : sessions.first;
    final hasSessions = firstSession != null;
    final firstSessionItems = firstSession == null
        ? const []
        : await repository.listItems(firstSession.id);
    final hasProductDetailSurface = firstSessionItems.isNotEmpty;

    final steps = <AppTourStep>[];

    if (origin == AppTourStartOrigin.manualReplay) {
      steps.addAll(
        _settingsSegment(includeProductDetail: hasProductDetailSurface),
      );
    }

    steps.addAll(_sessionsSegment(hasSessions));

    if (hasSessions) {
      steps.addAll(_inventorySegment());
      steps.addAll(_exportSegment());
    } else {
      steps.add(
        const AppTourStep(
          id: 'sessions.await_session',
          page: AppTourPage.sessions,
          title: 'Próximo passo',
          description:
              'Quando criar a primeira sessão, pode voltar a abrir este tutorial para ver o fluxo completo de contagem, scanner e exportação.',
          allowBack: true,
        ),
      );
    }

    if (origin == AppTourStartOrigin.automatic) {
      steps.addAll(
        _settingsSegment(includeProductDetail: hasProductDetailSurface),
      );
    }

    return steps;
  }

  List<AppTourStep> _sessionsSegment(bool hasSessions) {
    return [
      const AppTourStep(
        id: 'sessions.new_session',
        page: AppTourPage.sessions,
        title: 'Sessões de inventário',
        description:
            'A app organiza o trabalho por sessões. Cada sessão representa um local ou momento de contagem.',
        allowBack: false,
      ),
      const AppTourStep(
        id: 'sessions.settings',
        page: AppTourPage.sessions,
        title: 'Definições rápidas',
        description:
            'Aqui entra nas definições globais da app, incluindo preferências do leitor e a forma de relançar este tutorial.',
        targetId: AppTourTargetId.sessionsSettingsButton,
      ),
      const AppTourStep(
        id: 'sessions.fab',
        page: AppTourPage.sessions,
        title: 'Criar nova sessão',
        description:
            'Use este botão para começar uma nova contagem sem perder o histórico das sessões anteriores.',
        targetId: AppTourTargetId.sessionsNewSessionFab,
      ),
      if (hasSessions)
        const AppTourStep(
          id: 'sessions.first_card',
          page: AppTourPage.sessions,
          title: 'Retomar trabalho',
          description:
              'Se já existir uma sessão, pode tocar no cartão para retomar a contagem onde ficou.',
          targetId: AppTourTargetId.sessionsFirstSessionCard,
        ),
    ];
  }

  List<AppTourStep> _inventorySegment() {
    return const [
      AppTourStep(
        id: 'inventory.search',
        page: AppTourPage.inventory,
        title: 'Pesquisar rápido',
        description:
            'A pesquisa abre aqui e permite filtrar produtos ou leituras sem sair da sessão atual.',
        targetId: AppTourTargetId.inventorySearchField,
        enterActionId: AppTourActionId.openSearch,
      ),
      AppTourStep(
        id: 'inventory.export',
        page: AppTourPage.inventory,
        title: 'Exportar dados',
        description:
            'A exportação fica sempre acessível na barra superior para guardar a sessão a qualquer momento.',
        targetId: AppTourTargetId.inventoryExportButton,
      ),
      AppTourStep(
        id: 'inventory.summary',
        page: AppTourPage.inventory,
        title: 'Resumo imediato',
        description:
            'Este resumo mostra quantos itens tem, quantas leituras já foram registadas e qual foi a leitura mais recente.',
        targetId: AppTourTargetId.inventorySummaryStrip,
      ),
      AppTourStep(
        id: 'inventory.filters',
        page: AppTourPage.inventory,
        title: 'Filtros rápidos',
        description:
            'Use os filtros para se concentrar em produtos a expirar, por resolver, ou ver tudo de uma vez.',
        targetId: AppTourTargetId.inventoryFilterChips,
      ),
      AppTourStep(
        id: 'inventory.tabs',
        page: AppTourPage.inventory,
        title: 'Produtos ou leituras',
        description:
            'Pode alternar entre a vista agregada de produtos e o histórico de leituras individuais.',
        targetId: AppTourTargetId.inventoryModeTabs,
      ),
      AppTourStep(
        id: 'inventory.products',
        page: AppTourPage.inventory,
        title: 'Lista de produtos',
        description:
            'A lista principal adapta-se ao estado da sessão. Mesmo vazia, continua a ser o ponto de referência do que já foi contado.',
        targetId: AppTourTargetId.inventoryProductsList,
        enterActionId: AppTourActionId.showProductsTab,
      ),
      AppTourStep(
        id: 'inventory.scanner_fab',
        page: AppTourPage.inventory,
        title: 'Abrir o scanner',
        description:
            'Este botão abre o scanner. É aqui que começa o registo das embalagens.',
        targetId: AppTourTargetId.inventoryScannerFab,
      ),
      AppTourStep(
        id: 'inventory.scanner_modes',
        page: AppTourPage.inventory,
        title: 'Escolher o modo de leitura',
        description:
            'Com o scanner aberto pode alternar entre Data Matrix e códigos de barras consoante a embalagem.',
        targetId: AppTourTargetId.inventoryScannerModeDataMatrix,
        enterActionId: AppTourActionId.openScanner,
      ),
      AppTourStep(
        id: 'inventory.scanner_pause',
        page: AppTourPage.inventory,
        title: 'Lanterna manual',
        description:
            'Na faixa inferior do scanner pode alternar entre Data Matrix, Barras e ligar ou desligar manualmente a lanterna.',
        targetId: AppTourTargetId.inventoryScannerTorchButton,
        enterActionId: AppTourActionId.openScanner,
      ),
      AppTourStep(
        id: 'inventory.reads',
        page: AppTourPage.inventory,
        title: 'Histórico de leituras',
        description:
            'Quando alterna para Leituras, vê o histórico detalhado do que entrou na sessão.',
        targetId: AppTourTargetId.inventoryReadsList,
        enterActionId: AppTourActionId.showReadsTab,
      ),
    ];
  }

  List<AppTourStep> _exportSegment() {
    return const [
      AppTourStep(
        id: 'export.format',
        page: AppTourPage.export,
        title: 'Formato de saída',
        description:
            'Escolha rapidamente CSV, JSON ou TXT. O tour abre esta página a partir da sessão para mostrar o fluxo real.',
        targetId: AppTourTargetId.exportFormatSection,
        enterActionId: AppTourActionId.openExport,
      ),
      AppTourStep(
        id: 'export.mode',
        page: AppTourPage.export,
        title: 'Modo padrão ou personalizado',
        description:
            'Pode usar o formato padrão ou um template TXT personalizado com variáveis reais da sessão.',
        targetId: AppTourTargetId.exportModeSection,
      ),
      AppTourStep(
        id: 'export.preview',
        page: AppTourPage.export,
        title: 'Pré-visualização real',
        description:
            'A pré-visualização mostra imediatamente o resultado antes de guardar ou copiar o texto.',
        targetId: AppTourTargetId.exportPreviewSection,
      ),
      AppTourStep(
        id: 'export.save',
        page: AppTourPage.export,
        title: 'Guardar o ficheiro',
        description:
            'Quando estiver satisfeito com o formato, use este botão para exportar a sessão.',
        targetId: AppTourTargetId.exportSaveButton,
      ),
    ];
  }

  List<AppTourStep> _settingsSegment({required bool includeProductDetail}) {
    return [
      AppTourStep(
        id: 'settings.catalog_import',
        page: AppTourPage.settings,
        title: 'Importar catálogo CSV',
        description:
            'Aqui pode importar manualmente um catálogo CSV local. Quando existir correspondência no CSV, ela prevalece sempre sobre qualquer fallback remoto.',
        targetId: AppTourTargetId.settingsCatalogImportButton,
      ),
      AppTourStep(
        id: 'settings.catalog_state',
        page: AppTourPage.settings,
        title: 'Estado do catálogo',
        description:
            'Este cartão mostra a última importação CSV e quantas entradas ficaram persistidas localmente na app.',
        targetId: AppTourTargetId.settingsCatalogStateCard,
      ),
      AppTourStep(
        id: 'settings.replay',
        page: AppTourPage.settings,
        title: 'Ver o tutorial novamente',
        description:
            'Nas definições pode relançar o tutorial sempre que precisar, sem mexer nos dados de inventário.',
        targetId: AppTourTargetId.settingsTourReplayButton,
      ),
      AppTourStep(
        id: 'settings.autostart',
        page: AppTourPage.settings,
        title: 'Arranque automático',
        description:
            'Aqui controla se novas versões do tutorial devem arrancar automaticamente ao abrir a app.',
        targetId: AppTourTargetId.settingsTourAutoStartToggle,
      ),
      if (includeProductDetail)
        const AppTourStep(
          id: 'product_detail.metadata',
          page: AppTourPage.productDetail,
          title: 'Metadados do medicamento',
        description:
            'No detalhe do produto vê sempre o cartão de metadados. Se houver CSV, ele domina; se não houver, a app pode mostrar dados enriquecidos por fallback remoto com proveniência visível.',
          targetId: AppTourTargetId.productDetailMetadataCard,
        ),
      AppTourStep(
        id: includeProductDetail ? 'product_detail.links' : 'settings.finish',
        page: includeProductDetail
            ? AppTourPage.productDetail
            : AppTourPage.settings,
        title: includeProductDetail ? 'Links oficiais' : 'Tutorial atualizado',
        description: includeProductDetail
            ? 'Os links oficiais mantêm a estrutura estável mesmo sem catálogo ou sem rede. Quando existirem URLs oficiais, pode abri-las a partir daqui.'
            : 'Mesmo sem catálogo importado, a app continua local-first e o tutorial pode ser relançado quando precisar.',
        targetId: includeProductDetail
            ? AppTourTargetId.productDetailExternalLinksRow
            : AppTourTargetId.settingsTourReplayButton,
        nextLabel: 'Terminar',
      ),
    ];
  }

  Future<void> _activateStep(int index) async {
    if (index < 0 || index >= value.steps.length) {
      await complete();
      return;
    }

    value = value.copyWith(isBusy: true, stepIndex: index);
    final step = value.steps[index];

    await _navigateForStep(step);
    if (step.enterActionId != null) {
      final action = _actions[step.enterActionId!];
      if (action != null) {
        await action();
      }
    }
    if (step.targetId != null) {
      await waitForTarget(step.targetId!);
    }

    if (value.isActive) {
      value = value.copyWith(isBusy: false, stepIndex: index);
    }
  }

  Future<void> _navigateForStep(AppTourStep step) async {
    switch (step.page) {
      case AppTourPage.sessions:
        await _goToSessionsRoot();
        return;
      case AppTourPage.inventory:
        await _openInventoryIfPossible();
        return;
      case AppTourPage.export:
        if (_visiblePage != AppTourPage.export) {
          await _openInventoryIfPossible();
        } else {
          await _waitForFrames();
        }
        return;
      case AppTourPage.settings:
        await _openSettingsPage();
        return;
      case AppTourPage.productDetail:
        await _openProductDetailIfPossible();
        return;
    }
  }

  Future<void> _goToSessionsRoot() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    navigator.popUntil((route) => route.isFirst);
    _visiblePage = AppTourPage.sessions;
    await _waitForFrames();
  }

  Future<void> _openInventoryIfPossible() async {
    if (_visiblePage == AppTourPage.inventory) {
      await _waitForFrames();
      return;
    }

    await _goToSessionsRoot();
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    final sessions = await repository.listSessions();
    if (sessions.isEmpty) {
      return;
    }

    final session = sessions.first;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => InventoryPage(
          repository: repository,
          exporter: exporter,
          backupService: backupService,
          enrichmentService: enrichmentService,
          catalogImporter: catalogImporter,
          catalogRepository: catalogRepository,
          session: session,
        ),
      ),
    );
    _visiblePage = AppTourPage.inventory;
    await _waitForFrames(4);
  }

  Future<void> _openSettingsPage() async {
    if (_visiblePage == AppTourPage.settings) {
      await _waitForFrames();
      return;
    }
    if (value.origin == AppTourStartOrigin.manualReplay &&
        value.currentStep?.page == AppTourPage.settings) {
      _visiblePage = AppTourPage.settings;
      await _waitForFrames();
      return;
    }
    await _goToSessionsRoot();
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    navigator.push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          backupService: backupService,
          catalogImporter: catalogImporter,
          catalogRepository: catalogRepository,
        ),
      ),
    );
    _visiblePage = AppTourPage.settings;
    await _waitForFrames(4);
  }

  Future<void> _openProductDetailIfPossible() async {
    await _openInventoryIfPossible();
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }
    final sessions = await repository.listSessions();
    if (sessions.isEmpty) {
      return;
    }
    final items = await repository.listItems(sessions.first.id);
    if (items.isEmpty) {
      return;
    }
    navigator.push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          repository: repository,
          enrichmentService: enrichmentService,
          session: sessions.first,
          item: items.first,
        ),
      ),
    );
    _visiblePage = AppTourPage.productDetail;
    await _waitForFrames(4);
  }

  @visibleForTesting
  Future<bool> waitForTarget(
    AppTourTargetId targetId, {
    int maxAttempts = 20,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final context = targets.contextOf(targetId);
      if (context != null && context.mounted) {
        try {
          await Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 220),
          );
        } catch (_) {}
        await _waitForFrames();
        return true;
      }
      await _waitForFrames();
    }
    return false;
  }

  Future<void> _waitForFrames([int count = 2]) async {
    for (var i = 0; i < count; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
  }
}
