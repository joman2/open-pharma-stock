import 'package:flutter/material.dart';

import '../../../app/backup/app_backup_service.dart';
import '../../../app/qa/app_qa_controller.dart';
import '../../../app/qa/app_qa_scope.dart';
import '../../../app/settings/settings_scope.dart';
import '../../../app/settings/settings_page.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/tour/app_tour_targets.dart';
import '../../../export/inventory_exporter.dart';
import '../domain/inventory_repository.dart';
import '../domain/models.dart';
import '../../medication_catalog/data/catalog_csv_importer.dart';
import '../../medication_catalog/domain/medication_catalog_repository.dart';
import '../../medication_catalog/domain/medication_enrichment_service.dart';
import 'inventory_page.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({
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
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  final List<InventorySession> _sessions = [];
  AppQaController? _qaController;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextQaController = AppQaScope.maybeOf(context);
    if (_qaController == nextQaController) {
      return;
    }
    _qaController?.unregisterAction(AppQaActionId.sessionsReload);
    _qaController?.unregisterAction(AppQaActionId.sessionsOpenSettings);
    _qaController?.unregisterAction(AppQaActionId.sessionsOpenFirstSession);
    _qaController = nextQaController;
    _qaController?.registerAction(
      AppQaActionId.sessionsReload,
      (_) => _loadSessions(),
    );
    _qaController?.registerAction(AppQaActionId.sessionsOpenSettings, (
      _,
    ) async {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SettingsPage(
            backupService: widget.backupService,
            catalogImporter: widget.catalogImporter,
            catalogRepository: widget.catalogRepository,
          ),
        ),
      );
    });
    _qaController?.registerAction(AppQaActionId.sessionsOpenFirstSession, (
      _,
    ) async {
      await _loadSessions();
      if (!mounted || _sessions.isEmpty) {
        return;
      }
      final session = _sessions.first;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InventoryPage(
            repository: widget.repository,
            exporter: widget.exporter,
            backupService: widget.backupService,
            enrichmentService: widget.enrichmentService,
            catalogImporter: widget.catalogImporter,
            catalogRepository: widget.catalogRepository,
            session: session,
          ),
        ),
      );
    });
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await widget.repository.listSessions();
      if (!mounted) {
        return;
      }
      setState(() {
        _sessions
          ..clear()
          ..addAll(sessions);
      });
    } catch (error, stack) {
      debugPrint('Erro ao listar sessoes: $error');
      debugPrintStack(stackTrace: stack);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('Falha ao carregar sessões: $error')),
        );
    }
  }

  Future<void> _openNewSessionPage() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewSessionPage(repository: widget.repository),
      ),
    );
    if (created == true) {
      await _loadSessions();
    }
  }

  Future<void> _confirmDelete(InventorySession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Apagar sessão'),
          content: Text(
            'Tem a certeza que deseja apagar "${session.name}"? Todos os eventos serão removidos.',
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
    await widget.repository.deleteSession(session.id);
    await _loadSessions();
  }

  Future<_SessionStats> _loadSessionStats(String sessionId) async {
    final items = await widget.repository.listItems(sessionId);
    final events = await widget.repository.listRecentEvents(
      sessionId,
      limit: 500,
    );
    return _SessionStats(products: items.length, reads: events.length);
  }

  @override
  void dispose() {
    _qaController?.unregisterAction(AppQaActionId.sessionsReload);
    _qaController?.unregisterAction(AppQaActionId.sessionsOpenSettings);
    _qaController?.unregisterAction(AppQaActionId.sessionsOpenFirstSession);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSessions,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.s(18),
              context.s(18),
              context.s(18),
              context.s(132),
            ),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'open-pharma-stock',
                          style: theme.textTheme.headlineSmall,
                        ),
                        SizedBox(height: context.s(3)),
                        Text(
                          'sessões de inventário',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  TourTargetAnchor(
                    targetId: AppTourTargetId.sessionsSettingsButton,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SettingsPage(
                              backupService: widget.backupService,
                              catalogImporter: widget.catalogImporter,
                              catalogRepository: widget.catalogRepository,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Definições',
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.s(32)),
              TourTargetAnchor(
                targetId: AppTourTargetId.sessionsSessionList,
                child: _sessions.isEmpty
                    ? Card(
                        child: Padding(
                          padding: EdgeInsets.all(context.s(28)),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: context.s(54),
                                color: context.palette.textMuted,
                              ),
                              SizedBox(height: context.s(16)),
                              Text(
                                'Ainda não há sessões',
                                style: theme.textTheme.titleLarge,
                              ),
                              SizedBox(height: context.s(10)),
                              Text(
                                'Crie a primeira sessão para começar a contar embalagens.',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: _sessions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final session = entry.value;
                          final card = Padding(
                            padding: EdgeInsets.only(bottom: context.s(16)),
                            child: FutureBuilder<_SessionStats>(
                              future: _loadSessionStats(session.id),
                              builder: (context, snapshot) {
                                final stats =
                                    snapshot.data ??
                                    const _SessionStats(products: 0, reads: 0);
                                return _SessionCard(
                                  session: session,
                                  stats: stats,
                                  onOpen: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => InventoryPage(
                                          repository: widget.repository,
                                          exporter: widget.exporter,
                                          backupService: widget.backupService,
                                          enrichmentService:
                                              widget.enrichmentService,
                                          catalogImporter:
                                              widget.catalogImporter,
                                          catalogRepository:
                                              widget.catalogRepository,
                                          session: session,
                                        ),
                                      ),
                                    );
                                  },
                                  onDelete: () => _confirmDelete(session),
                                );
                              },
                            ),
                          );
                          if (index == 0) {
                            return TourTargetAnchor(
                              targetId:
                                  AppTourTargetId.sessionsFirstSessionCard,
                              child: card,
                            );
                          }
                          return card;
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: TourTargetAnchor(
        targetId: AppTourTargetId.sessionsNewSessionFab,
        child: FloatingActionButton(
          onPressed: _openNewSessionPage,
          child: Icon(Icons.add, size: context.s(38)),
        ),
      ),
    );
  }
}

class NewSessionPage extends StatefulWidget {
  const NewSessionPage({super.key, required this.repository});

  final InventoryRepository repository;

  @override
  State<NewSessionPage> createState() => _NewSessionPageState();
}

class _NewSessionPageState extends State<NewSessionPage> {
  final TextEditingController _controller = TextEditingController();
  static const _suggestions = [
    'Prateleira A',
    'Frigorífico',
    'Balcão',
    'Armazém Geral',
  ];
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final defaultQuantityPrompt =
          SettingsScope.of(context).value.barcodeQuantityPromptByDefault;
      await widget.repository.createSession(
        name,
        barcodeQuantityPromptEnabled: defaultQuantityPrompt,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('Falha ao criar a sessão: $error')),
        );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                context.s(18),
                context.s(14),
                context.s(18),
                context.s(18) + viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          SizedBox(width: context.s(10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nova sessão',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                SizedBox(height: context.s(3)),
                                Text(
                                  'Identifique o local da contagem',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.s(32)),
                      Text(
                        'NOME DA SESSÃO',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      SizedBox(height: context.s(12)),
                      TextField(
                        controller: _controller,
                        autofocus: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          hintText: 'Ex: Prateleira A1, Balcão, Armazém',
                        ),
                      ),
                      SizedBox(height: context.s(16)),
                      Text(
                        'Escolha um nome simples para identificar onde está a fazer a contagem.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: context.s(24)),
                      Wrap(
                        spacing: context.s(10),
                        runSpacing: context.s(10),
                        children: _suggestions
                            .map(
                              (suggestion) => InkWell(
                                onTap: () {
                                  _controller.text = suggestion;
                                  _controller.selection =
                                      TextSelection.collapsed(
                                        offset: suggestion.length,
                                      );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Ink(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.s(16),
                                    vertical: context.s(12),
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.palette.surfaceMuted,
                                    borderRadius: BorderRadius.circular(
                                      context.s(12),
                                    ),
                                  ),
                                  child: Text(
                                    suggestion,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      SizedBox(height: context.s(32)),
                      Card(
                        color: const Color(0xFF0F5A9D),
                        child: Padding(
                          padding: EdgeInsets.all(context.s(18)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.white,
                                size: context.s(22),
                              ),
                              SizedBox(width: context.s(14)),
                              Expanded(
                                child: Text(
                                  'Poderá exportar os dados e limpar as contagens a qualquer momento após começar.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(height: context.s(32)),
                      FilledButton(
                        onPressed: _isSaving ? null : _submit,
                        child: Text(_isSaving ? 'A criar...' : 'Começar contagem'),
                      ),
                      SizedBox(height: context.s(14)),
                      Center(
                        child: TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.stats,
    required this.onOpen,
    required this.onDelete,
  });

  final InventorySession session;
  final _SessionStats stats;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(context.s(22)),
        onTap: onOpen,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.s(18),
            context.s(18),
            context.s(12),
            context.s(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: context.s(10)),
                    Text(
                      '${_formatDate(session.updatedAt)}  •  ${stats.products} produtos',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: context.s(10)),
                    Text(
                      '${stats.reads} leituras',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Apagar sessão'),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  ),
                  SizedBox(height: context.s(14)),
                  Icon(
                    Icons.chevron_right,
                    color: context.palette.textMuted,
                    size: context.s(24),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _SessionStats {
  const _SessionStats({required this.products, required this.reads});

  final int products;
  final int reads;
}
