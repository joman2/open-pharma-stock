import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../backup/app_backup_service.dart';
import '../qa/app_qa_controller.dart';
import '../qa/app_qa_scope.dart';
import '../../features/medication_catalog/data/catalog_csv_importer.dart';
import '../../features/medication_catalog/domain/medication_catalog_repository.dart';
import '../../features/medication_catalog/domain/models.dart';
import '../../scanner/scanner_engine.dart';
import '../theme/app_theme.dart';
import '../tour/app_tour_scope.dart';
import '../tour/app_tour_targets.dart';
import 'app_settings.dart';
import 'settings_scope.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.backupService,
    required this.catalogImporter,
    required this.catalogRepository,
  });

  final AppBackupService backupService;
  final CatalogCsvImporter catalogImporter;
  final MedicationCatalogRepository catalogRepository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  CatalogState? _catalogState;
  bool _loadingCatalogState = true;
  bool _importingCatalog = false;
  bool _exportingBackup = false;
  bool _importingBackup = false;
  AppQaController? _qaController;

  @override
  void initState() {
    super.initState();
    _refreshCatalogState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextQaController = AppQaScope.maybeOf(context);
    if (_qaController == nextQaController) {
      return;
    }
    _qaController?.unregisterAction(AppQaActionId.settingsRefreshCatalogState);
    _qaController = nextQaController;
    _qaController?.registerAction(
      AppQaActionId.settingsRefreshCatalogState,
      (_) => _refreshCatalogState(),
    );
  }

  Future<void> _refreshCatalogState() async {
    final state = await widget.catalogRepository.getCatalogState();
    if (!mounted) {
      return;
    }
    setState(() {
      _catalogState = state;
      _loadingCatalogState = false;
    });
  }

  Future<void> _importCatalog() async {
    if (_importingCatalog) {
      return;
    }
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'CSV', extensions: ['csv'], mimeTypes: ['text/csv']),
      ],
    );
    if (file == null) {
      return;
    }

    setState(() {
      _importingCatalog = true;
    });
    try {
      final result = await widget.catalogImporter.importFile(file);
      await _refreshCatalogState();
      if (!mounted) {
        return;
      }
      final warningSuffix = result.warnings.isEmpty
          ? ''
          : ' Avisos: ${result.warnings.first}';
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'CSV importado: ${result.importedMedicationCount} medicamentos, ${result.importedLookupCount} códigos.$warningSuffix',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('Falha ao importar CSV: $error')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _importingCatalog = false;
        });
      }
    }
  }

  Future<void> _exportBackup() async {
    if (_exportingBackup || _importingBackup) {
      return;
    }
    final timestamp = DateTime.now();
    final suggestedName =
        'open-pharma-stock-backup-'
        '${timestamp.year}'
        '${timestamp.month.toString().padLeft(2, '0')}'
        '${timestamp.day.toString().padLeft(2, '0')}-'
        '${timestamp.hour.toString().padLeft(2, '0')}'
        '${timestamp.minute.toString().padLeft(2, '0')}.opsbackup.json';
    String? exportPath;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      exportPath = suggestedName;
    } else {
      try {
        final location = await getSaveLocation(
          suggestedName: suggestedName,
          acceptedTypeGroups: const [
            XTypeGroup(label: 'Backup', extensions: ['json', 'opsbackup']),
          ],
        );
        exportPath = location?.path;
      } on UnsupportedError {
        final directory = await getDirectoryPath(
          confirmButtonText: 'Guardar backup aqui',
        );
        if (directory != null) {
          exportPath = '$directory/$suggestedName';
        }
      }
    }
    if (exportPath == null) {
      return;
    }

    setState(() {
      _exportingBackup = true;
    });
    try {
      final result = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? await widget.backupService.exportNamedBackup(exportPath)
          : AppBackupExportResult(
              path: exportPath,
              summary: await widget.backupService.exportToPath(exportPath),
            );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Backup exportado: ${result.summary.sessionCount} sessões, ${result.summary.scanCount} leituras, ${result.summary.catalogEntryCount} medicamentos. Local: ${result.path}',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('Falha ao exportar backup: $error')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _exportingBackup = false;
        });
      }
    }
  }

  Future<void> _importBackup() async {
    if (_exportingBackup || _importingBackup) {
      return;
    }
    final selectedPath = await _pickBackupPath();
    if (selectedPath == null || !mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Importar backup'),
          content: const Text(
            'Esta ação substitui os dados locais atuais por aqueles que estão no ficheiro selecionado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }
    if (confirmed != true) {
      return;
    }

    setState(() {
      _importingBackup = true;
    });
    try {
      final summary = await widget.backupService.importFromPath(selectedPath);
      await _refreshCatalogState();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Backup importado: ${summary.sessionCount} sessões, ${summary.scanCount} leituras e ${summary.catalogEntryCount} medicamentos.',
            ),
          ),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('Falha ao importar backup: $error')),
        );
    } finally {
      if (mounted) {
        setState(() {
          _importingBackup = false;
        });
      }
    }
  }

  Future<String?> _pickBackupPath() async {
    final candidates = await widget.backupService.findImportCandidates();
    if (!mounted) {
      return null;
    }
    if (candidates.isEmpty) {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Backup', extensions: ['json', 'opsbackup']),
        ],
      );
      return file?.path;
    }

    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
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
                  'Backups encontrados',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: context.s(12)),
                ...candidates.take(4).map((candidate) {
                  final date = candidate.modifiedAt;
                  final stamp =
                      '${date.day.toString().padLeft(2, '0')}/'
                      '${date.month.toString().padLeft(2, '0')}/'
                      '${date.year} '
                      '${date.hour.toString().padLeft(2, '0')}:'
                      '${date.minute.toString().padLeft(2, '0')}';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(candidate.label),
                    subtitle: Text(candidate.path),
                    trailing: Text(stamp),
                    onTap: () => Navigator.of(context).pop(candidate.path),
                  );
                }),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Escolher outro ficheiro'),
                  trailing: const Icon(Icons.folder_open_outlined),
                  onTap: () => Navigator.of(context).pop('__pick__'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen == '__pick__') {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Backup', extensions: ['json', 'opsbackup']),
        ],
      );
      return file?.path;
    }
    return chosen;
  }

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScope.of(context);
    final tourController = AppTourScope.maybeOf(context);
    return ValueListenableBuilder<AppSettingsState>(
      valueListenable: controller,
      builder: (context, settings, child) {
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                context.s(18),
                context.s(14),
                context.s(18),
                context.s(30),
              ),
              children: [
                _PageHeader(
                  title: 'Definições',
                  subtitle: 'Ajuste inventário, backups e leitor',
                  trailing: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                SizedBox(height: context.s(28)),
                _SectionTitle('APARÊNCIA'),
                SizedBox(height: context.s(12)),
                _SettingsBlock(
                  children: [
                    _OptionRow(
                      icon: Icons.palette_outlined,
                      title: 'Tema',
                      subtitle: 'Tema escuro fixo nesta versão',
                      trailing: const _SelectionPill('Escuro'),
                    ),
                  ],
                ),
                SizedBox(height: context.s(28)),
                _SectionTitle('LEITOR'),
                SizedBox(height: context.s(12)),
                _SettingsBlock(
                  children: [
                    _OptionRow(
                      icon: Icons.center_focus_strong_outlined,
                      title: 'Modo de leitura',
                      trailing: _SelectionPill(
                        settings.preferredScanMode == ScanMode.dataMatrix
                            ? 'Data Matrix'
                            : 'Barras',
                      ),
                      onTap: () =>
                          _showScanModeSheet(context, controller, settings),
                    ),
                    _ToggleRow(
                      icon: Icons.settings_backup_restore_outlined,
                      title: 'Abrir scanner ao entrar',
                      value: settings.openScannerOnSessionEntry,
                      onChanged: controller.setOpenScannerOnSessionEntry,
                    ),
                    _ToggleRow(
                      icon: Icons.flashlight_on_outlined,
                      title: 'Lanterna automática',
                      value: settings.autoTorch,
                      onChanged: controller.setAutoTorch,
                    ),
                    _ToggleRow(
                      icon: Icons.pin_outlined,
                      title: 'Barras: pedir quantidade',
                      value: settings.barcodeQuantityPromptByDefault,
                      onChanged: controller.setBarcodeQuantityPromptByDefault,
                    ),
                    _ToggleRow(
                      icon: Icons.vibration_outlined,
                      title: 'Vibrar na leitura',
                      value: settings.vibrateOnRead,
                      onChanged: controller.setVibrateOnRead,
                    ),
                    _ToggleRow(
                      icon: Icons.volume_up_outlined,
                      title: 'Som na leitura',
                      value: settings.soundOnRead,
                      onChanged: controller.setSoundOnRead,
                    ),
                  ],
                ),
                SizedBox(height: context.s(28)),
                _SectionTitle('EXPORTAÇÃO'),
                SizedBox(height: context.s(12)),
                _SettingsBlock(
                  children: [
                    _OptionRow(
                      icon: Icons.file_download_outlined,
                      title: 'Formato preferido',
                      trailing: _SelectionPill(
                        _exportPreferenceLabel(settings.exportPreference),
                      ),
                      onTap: () => _showExportPreferenceSheet(
                        context,
                        controller,
                        settings,
                      ),
                    ),
                    _ToggleRow(
                      icon: Icons.preview_outlined,
                      title: 'Pré-visualizar antes de guardar',
                      subtitle:
                          'Ao desligar, o botão Exportar abre diretamente a gravação.',
                      value: settings.previewBeforeSaving,
                      onChanged: controller.setPreviewBeforeSaving,
                    ),
                    _OptionRow(
                      icon: Icons.text_fields_rounded,
                      title: 'Template TXT',
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CustomTemplateEditorPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: context.s(28)),
                _SectionTitle('VALIDADES'),
                SizedBox(height: context.s(12)),
                _SettingsBlock(
                  children: [
                    _ToggleRow(
                      icon: Icons.event_available_outlined,
                      title: 'Marcar/filtrar validades próximas',
                      value: settings.expiryAlertsEnabled,
                      onChanged: controller.setExpiryAlertsEnabled,
                    ),
                    _OptionRow(
                      icon: Icons.today_outlined,
                      title: 'Antecedência (dias)',
                      trailing: _SelectionPill(
                        '${settings.expiryAlertDays} dias',
                      ),
                      onTap: () =>
                          _showExpiryDaysSheet(context, controller, settings),
                    ),
                  ],
                ),
                SizedBox(height: context.s(28)),
                _SectionTitle('CATÁLOGO'),
                SizedBox(height: context.s(12)),
                _SettingsBlock(
                  children: [
                    _ToggleRow(
                      icon: Icons.cloud_outlined,
                      title: 'Pesquisa online no INFARMED',
                      value: settings.onlineCatalogLookupEnabled,
                      onChanged: controller.setOnlineCatalogLookupEnabled,
                    ),
                    TourTargetAnchor(
                      targetId: AppTourTargetId.settingsCatalogImportButton,
                      child: _OptionRow(
                        icon: Icons.upload_file_outlined,
                        title:
                            _catalogState?.csvEntryCount == null ||
                                (_catalogState?.csvEntryCount ?? 0) == 0
                            ? 'Importar catálogo CSV'
                            : 'Reimportar catálogo CSV',
                        trailing: _importingCatalog
                            ? SizedBox(
                                width: context.s(24),
                                height: context.s(24),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _importCatalog,
                      ),
                    ),
                    TourTargetAnchor(
                      targetId: AppTourTargetId.settingsCatalogStateCard,
                      child: _CatalogStateCard(
                        loading: _loadingCatalogState,
                        state: _catalogState,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.s(8),
                        context.s(8),
                        context.s(8),
                        context.s(12),
                      ),
                      child: Text(
                        'A pesquisa online está desligada por defeito. Quando '
                        'ativada, a app envia o código do medicamento ao '
                        'INFARMED; o catálogo CSV continua a prevalecer.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.s(28)),
                _SectionTitle('CÓPIA DE SEGURANÇA'),
                SizedBox(height: context.s(12)),
                _SettingsBlock(
                  children: [
                    _OptionRow(
                      icon: Icons.ios_share_outlined,
                      title: 'Exportar backup',
                      trailing: _exportingBackup
                          ? SizedBox(
                              width: context.s(24),
                              height: context.s(24),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _exportBackup,
                    ),
                    _OptionRow(
                      icon: Icons.download_for_offline_outlined,
                      title: 'Importar backup',
                      trailing: _importingBackup
                          ? SizedBox(
                              width: context.s(24),
                              height: context.s(24),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: _importBackup,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.s(8),
                        context.s(8),
                        context.s(8),
                        context.s(12),
                      ),
                      child: Text(
                        'Use este backup para migrar sessões, leituras, catálogo e preferências entre instalações da app.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.s(28)),
                _SectionTitle('TUTORIAL'),
                SizedBox(height: context.s(12)),
                _SettingsBlock(
                  children: [
                    TourTargetAnchor(
                      targetId: AppTourTargetId.settingsTourReplayButton,
                      child: _OptionRow(
                        icon: Icons.school_outlined,
                        title: 'Ver tutorial novamente',
                        trailing: const Icon(Icons.play_arrow_rounded),
                        onTap: () {
                          tourController?.startManualTour();
                        },
                      ),
                    ),
                    TourTargetAnchor(
                      targetId: AppTourTargetId.settingsTourAutoStartToggle,
                      child: _ToggleRow(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Mostrar tutorial automaticamente',
                        value: settings.tourAutoStartEnabled,
                        onChanged: controller.setTourAutoStartEnabled,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _qaController?.unregisterAction(AppQaActionId.settingsRefreshCatalogState);
    super.dispose();
  }

  Future<void> _showScanModeSheet(
    BuildContext context,
    AppSettingsController controller,
    AppSettingsState settings,
  ) async {
    final selected = await showModalBottomSheet<ScanMode>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
        return _OptionsSheet<ScanMode>(
          title: 'Modo de leitura',
          value: settings.preferredScanMode,
          options: const [
            _SheetOption(value: ScanMode.dataMatrix, label: 'Data Matrix'),
            _SheetOption(value: ScanMode.barcodes, label: 'Barras'),
          ],
        );
      },
    );
    if (selected != null) {
      await controller.setPreferredScanMode(selected);
    }
  }

  Future<void> _showExportPreferenceSheet(
    BuildContext context,
    AppSettingsController controller,
    AppSettingsState settings,
  ) async {
    final selected = await showModalBottomSheet<ExportPreference>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
        return _OptionsSheet<ExportPreference>(
          title: 'Formato preferido',
          value: settings.exportPreference,
          options: const [
            _SheetOption(value: ExportPreference.csv, label: 'CSV'),
            _SheetOption(value: ExportPreference.json, label: 'JSON'),
            _SheetOption(value: ExportPreference.txt, label: 'TXT'),
          ],
        );
      },
    );
    if (selected != null) {
      await controller.setExportPreference(selected);
    }
  }

  Future<void> _showExpiryDaysSheet(
    BuildContext context,
    AppSettingsController controller,
    AppSettingsState settings,
  ) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) {
        return _OptionsSheet<int>(
          title: 'Antecedência',
          value: settings.expiryAlertDays,
          options: const [
            _SheetOption(value: 7, label: '7 dias'),
            _SheetOption(value: 15, label: '15 dias'),
            _SheetOption(value: 30, label: '30 dias'),
            _SheetOption(value: 60, label: '60 dias'),
          ],
        );
      },
    );
    if (selected != null) {
      await controller.setExpiryAlertDays(selected);
    }
  }

  String _exportPreferenceLabel(ExportPreference preference) {
    switch (preference) {
      case ExportPreference.csv:
        return 'CSV';
      case ExportPreference.json:
        return 'JSON';
      case ExportPreference.txt:
        return 'TXT';
    }
  }
}

class CustomTemplateEditorPage extends StatefulWidget {
  const CustomTemplateEditorPage({super.key});

  @override
  State<CustomTemplateEditorPage> createState() =>
      _CustomTemplateEditorPageState();
}

class _CustomTemplateEditorPageState extends State<CustomTemplateEditorPage> {
  late final TextEditingController _controller;

  static const _variables = [
    ('codigo', 'Código'),
    ('nome', 'Nome'),
    ('quantidade', 'Qtd'),
    ('lote', 'Lote'),
    ('validade', 'Validade'),
    ('sessao', 'Sessão'),
    ('data', 'Data'),
    ('substancia', 'Substância'),
    ('dosagem', 'Dosagem'),
    ('forma', 'Forma'),
    ('apresentacao', 'Apresentação'),
    ('titular', 'Titular'),
    ('bula_url', 'FI URL'),
    ('rcm_url', 'RCM URL'),
    ('fonte', 'Fonte'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = SettingsScope.of(context).value;
    if (_controller.text.isEmpty) {
      _controller.text = settings.customTxtTemplate;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = SettingsScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.s(18),
            context.s(14),
            context.s(18),
            context.s(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PageHeader(
                title: 'Template TXT',
                subtitle: 'Defina o modelo de exportação personalizada',
                trailing: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              SizedBox(height: context.s(28)),
              const _SectionTitle('TEMPLATE PERSONALIZADO'),
              SizedBox(height: context.s(12)),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  style: Theme.of(context).textTheme.titleMedium,
                  decoration: const InputDecoration(
                    hintText:
                        '{{codigo}} - {{nome}} [{{quantidade}}]\n{{dosagem}} {{forma}}\n{{bula_url}}',
                  ),
                ),
              ),
              SizedBox(height: context.s(20)),
              const _SectionTitle('INSERIR VARIÁVEIS'),
              SizedBox(height: context.s(12)),
              Wrap(
                spacing: context.s(10),
                runSpacing: context.s(10),
                children: _variables
                    .map(
                      (entry) => _VariableChip(
                        label: entry.$2,
                        onTap: () => _insertVariable(entry.$1),
                      ),
                    )
                    .toList(),
              ),
              SizedBox(height: context.s(28)),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _controller.text =
                            AppSettingsState.defaultCustomTxtTemplate;
                      },
                      child: const Text('Repor'),
                    ),
                  ),
                  SizedBox(width: context.s(14)),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await controller.setCustomTxtTemplate(_controller.text);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Guardar template'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _insertVariable(String variable) {
    final token = '{{$variable}}';
    final selection = _controller.selection;
    final start = selection.start < 0
        ? _controller.text.length
        : selection.start;
    final end = selection.end < 0 ? _controller.text.length : selection.end;
    final next = _controller.text.replaceRange(start, end, token);
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }
}

class _CatalogStateCard extends StatelessWidget {
  const _CatalogStateCard({required this.loading, required this.state});

  final bool loading;
  final CatalogState? state;

  @override
  Widget build(BuildContext context) {
    final label = loading
        ? 'A carregar...'
        : state == null || state!.csvLastImportedAt == null
        ? 'Nenhum CSV importado'
        : 'Última importação: ${_formatDateTime(state!.csvLastImportedAt!)}';
    final countLabel = loading ? '—' : '${state?.csvEntryCount ?? 0} entradas';
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        context.s(8),
        context.s(8),
        context.s(8),
        context.s(12),
      ),
      padding: EdgeInsets.all(context.s(16)),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(context.s(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado do catálogo CSV',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: context.s(8)),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          SizedBox(height: context.s(6)),
          Text(countLabel, style: Theme.of(context).textTheme.bodySmall),
          if (state?.csvSourceLabel != null) ...[
            SizedBox(height: context.s(4)),
            Text(
              'Fonte: ${state!.csvSourceLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: context.s(42), child: trailing),
        SizedBox(width: context.s(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: context.s(3)),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelMedium);
  }
}

class _SettingsBlock extends StatelessWidget {
  const _SettingsBlock({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.s(16),
          vertical: context.s(10),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(context.s(18)),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.s(8),
          vertical: context.s(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _LeadingIcon(icon: icon),
            SizedBox(width: context.s(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (subtitle case final subtitle?) ...[
                    SizedBox(height: context.s(3)),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: context.s(12)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.s(144)),
              child: trailing,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.s(8),
        vertical: context.s(8),
      ),
      child: Row(
        children: [
          _LeadingIcon(icon: icon),
          SizedBox(width: context.s(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subtitle case final subtitle?) ...[
                  SizedBox(height: context.s(3)),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: context.s(12)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.s(42),
      height: context.s(42),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(context.s(12)),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: context.palette.textSecondary,
        size: context.s(20),
      ),
    );
  }
}

class _SelectionPill extends StatelessWidget {
  const _SelectionPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.s(14),
        vertical: context.s(10),
      ),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(context.s(14)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13),
      ),
    );
  }
}

class _VariableChip extends StatelessWidget {
  const _VariableChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.s(12)),
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: context.s(12),
          vertical: context.s(10),
        ),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(context.s(12)),
        ),
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

class _SheetOption<T> {
  const _SheetOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _OptionsSheet<T> extends StatelessWidget {
  const _OptionsSheet({
    required this.title,
    required this.value,
    required this.options,
  });

  final String title;
  final T value;
  final List<_SheetOption<T>> options;

  @override
  Widget build(BuildContext context) {
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
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: context.s(16)),
            ...options.map((option) {
              final selected = option.value == value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.label),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(option.value),
              );
            }),
          ],
        ),
      ),
    );
  }
}
