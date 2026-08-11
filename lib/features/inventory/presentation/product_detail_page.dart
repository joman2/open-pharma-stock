import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/tour/app_tour_targets.dart';
import '../../medication_catalog/application/lookup_hints.dart';
import '../../medication_catalog/domain/medication_enrichment_service.dart';
import '../../medication_catalog/domain/models.dart';
import '../domain/inventory_repository.dart';
import '../domain/models.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.repository,
    required this.enrichmentService,
    required this.session,
    required this.item,
  });

  final InventoryRepository repository;
  final MedicationEnrichmentService enrichmentService;
  final InventorySession session;
  final InventoryItem item;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final List<ScanEvent> _events = [];
  MedicationResolution? _resolution;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    await _loadEvents();
    await _loadResolution(triggerBackground: true);
  }

  Future<void> _loadEvents() async {
    final events = await widget.repository.listEventsForProduct(
      widget.session.id,
      widget.item.productCode,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _events
        ..clear()
        ..addAll(events);
    });
  }

  Future<void> _loadResolution({required bool triggerBackground}) async {
    final hints = _events.isEmpty
        ? LookupHints.fromInventoryItem(widget.item)
        : LookupHints.fromScanEvent(_events.first);
    final resolution = await widget.enrichmentService.resolveNow(hints);
    if (!mounted) {
      return;
    }
    setState(() {
      _resolution = resolution;
    });
    if (triggerBackground && !resolution.isResolved) {
      await widget.enrichmentService.ensureEnrichedInBackground(hints);
      if (mounted) {
        await _loadResolution(triggerBackground: false);
      }
    }
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
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Leitura apagada.')));
      }
    }
  }

  Future<void> _showRawDialog(String raw) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('RAW'),
          content: SelectableText(raw),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) {
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final metadata = _resolution?.medication?.entry;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          cacheExtent: 2400,
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
                        metadata?.displayName ?? widget.item.productCode,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: context.s(3)),
                      Text(
                        '${widget.item.codeType} • ${widget.item.qty} unidades',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.s(24)),
            TourTargetAnchor(
              targetId: AppTourTargetId.productDetailMetadataCard,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(context.s(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MedicationImage(
                        imageUrl: metadata?.imageUrl,
                        displayName:
                            metadata?.displayName ?? widget.item.productCode,
                      ),
                      SizedBox(height: context.s(16)),
                      Text(
                        'Metadados do medicamento',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: context.s(14)),
                      _MetadataLine(
                        label: 'Nome',
                        value: metadata?.displayName ?? widget.item.productCode,
                      ),
                      _MetadataLine(
                        label: 'Substância ativa',
                        value: metadata?.activeSubstance ?? 'Sem catálogo',
                      ),
                      _MetadataLine(
                        label: 'Dosagem',
                        value: metadata?.strength ?? 'Sem catálogo',
                      ),
                      _MetadataLine(
                        label: 'Forma farmacêutica',
                        value: metadata?.pharmaceuticalForm ?? 'Sem catálogo',
                      ),
                      _MetadataLine(
                        label: 'Apresentação',
                        value: metadata?.presentation ?? 'Sem catálogo',
                      ),
                      _MetadataLine(
                        label: 'Titular / laboratório',
                        value: metadata?.holder ?? 'Sem catálogo',
                      ),
                      _MetadataLine(
                        label: 'Fonte',
                        value: _sourceLabel(_resolution),
                      ),
                      _MetadataLine(
                        label: 'Código principal',
                        value: widget.item.productCode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: context.s(16)),
            TourTargetAnchor(
              targetId: AppTourTargetId.productDetailExternalLinksRow,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(context.s(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Links oficiais',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: context.s(14)),
                      _LinkRow(
                        label: 'Folheto informativo',
                        value: metadata?.leafletUrl,
                        onTap: () => _openUrl(metadata?.leafletUrl),
                      ),
                      _LinkRow(
                        label: 'RCM',
                        value: metadata?.rcmUrl,
                        onTap: () => _openUrl(metadata?.rcmUrl),
                      ),
                      _LinkRow(
                        label: 'Fonte',
                        value: metadata?.sourceUrl,
                        onTap: () => _openUrl(metadata?.sourceUrl),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: context.s(16)),
            Card(
              child: Padding(
                padding: EdgeInsets.all(context.s(18)),
                child: Row(
                  children: [
                    _Metric(label: 'Sessão', value: widget.session.name),
                    SizedBox(width: context.s(12)),
                    _Metric(label: 'Quantidade', value: '${widget.item.qty}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.s(24)),
            Text('LEITURAS', style: Theme.of(context).textTheme.labelMedium),
            SizedBox(height: context.s(12)),
            if (_events.isEmpty)
              TourTargetAnchor(
                targetId: AppTourTargetId.productDetailTimelineList,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(context.s(24)),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: context.s(54),
                          color: AppPalette.textMuted,
                        ),
                        SizedBox(height: context.s(12)),
                        Text(
                          'Sem leituras para este produto',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              TourTargetAnchor(
                targetId: AppTourTargetId.productDetailTimelineList,
                child: Column(
                  children: _events.map((event) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: context.s(12)),
                      child: _EventCard(
                        event: event,
                        onDelete: event.isDeleted
                            ? null
                            : () => _deleteEvent(event),
                        onShowRaw: () => _showRawDialog(event.raw),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
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

class _MedicationImage extends StatelessWidget {
  const _MedicationImage({required this.imageUrl, required this.displayName});

  final String? imageUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.s(18)),
      child: Container(
        height: context.s(148),
        width: double.infinity,
        color: AppPalette.surfaceMuted,
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return _ImagePlaceholder(label: displayName);
                },
              )
            : _ImagePlaceholder(label: displayName),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_outlined,
            size: context.s(38),
            color: AppPalette.textMuted,
          ),
          SizedBox(height: context.s(10)),
          Text(
            'Imagem indisponível',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: context.s(4)),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          SizedBox(height: context.s(6)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _MetadataLine extends StatelessWidget {
  const _MetadataLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.s(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: context.s(132),
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = value != null && value!.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: context.s(10)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(context.s(12)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: context.s(8)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                enabled ? 'Abrir' : 'Indisponível',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? AppPalette.textSecondary
                      : AppPalette.textMuted,
                ),
              ),
              SizedBox(width: context.s(6)),
              Icon(
                enabled ? Icons.open_in_new : Icons.remove,
                size: context.s(18),
                color: enabled
                    ? AppPalette.textSecondary
                    : AppPalette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onDelete,
    required this.onShowRaw,
  });

  final ScanEvent event;
  final VoidCallback? onDelete;
  final VoidCallback onShowRaw;

  @override
  Widget build(BuildContext context) {
    final style = event.isDeleted
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: AppPalette.textMuted,
          )
        : Theme.of(context).textTheme.bodyMedium;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(context.s(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.serialNumber == null || event.serialNumber!.isEmpty
                        ? 'Sem número de série'
                        : 'SN ${event.serialNumber}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TourTargetAnchor(
                  targetId: AppTourTargetId.productDetailDeleteAction,
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ],
            ),
            if (event.lot != null && event.lot!.isNotEmpty)
              Text('Lote ${event.lot}', style: style),
            if (event.expiry != null)
              Text(
                'Validade ${event.expiry!.day.toString().padLeft(2, '0')}/${event.expiry!.month.toString().padLeft(2, '0')}/${event.expiry!.year}',
                style: style,
              ),
            Text(
              event.createdAt
                  .toLocal()
                  .toIso8601String()
                  .substring(0, 16)
                  .replaceFirst('T', ' '),
              style: style,
            ),
            SizedBox(height: context.s(10)),
            TextButton(onPressed: onShowRaw, child: const Text('Ver raw')),
          ],
        ),
      ),
    );
  }
}
