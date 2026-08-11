import 'dart:convert';

import '../features/inventory/domain/inventory_repository.dart';
import '../features/inventory/domain/models.dart';
import '../features/medication_catalog/application/lookup_hints.dart';
import '../features/medication_catalog/domain/medication_enrichment_service.dart';
import '../features/medication_catalog/domain/models.dart';

class InventoryExporter {
  InventoryExporter({
    required this.repository,
    required this.enrichmentService,
  });

  final InventoryRepository repository;
  final MedicationEnrichmentService enrichmentService;

  Future<String> exportCsv(String sessionId) async {
    final summary = await _buildSessionSummary(sessionId);
    if (summary == null) {
      return '';
    }

    final buffer = StringBuffer()..writeln('code,name,quantity,expiry,lot');
    for (final item in summary.items) {
      buffer.writeln(
        [
          item.code,
          item.name,
          item.quantity.toString(),
          item.expiry ?? '',
          item.lot ?? '',
        ].map(_escapeCsv).join(','),
      );
    }
    return buffer.toString();
  }

  Future<String> exportJson(String sessionId) async {
    final summary = await _buildSessionSummary(sessionId);
    if (summary == null) {
      return '[]';
    }

    return const JsonEncoder.withIndent('  ').convert(
      summary.items
          .map(
            (item) => {
              'session': summary.session.name,
              'updated_at': summary.session.updatedAt.toIso8601String(),
              'code': item.code,
              'name': item.name,
              'quantity': item.quantity,
              'expiry': item.expiry,
              'lot': item.lot,
              'substancia': item.activeSubstance,
              'dosagem': item.strength,
              'forma': item.pharmaceuticalForm,
              'apresentacao': item.presentation,
              'titular': item.holder,
              'bula_url': item.leafletUrl,
              'rcm_url': item.rcmUrl,
              'fonte': item.sourceLabel,
            },
          )
          .toList(),
    );
  }

  Future<String> exportTxt(String sessionId) async {
    final summary = await _buildSessionSummary(sessionId);
    if (summary == null) {
      return '';
    }

    final buffer = StringBuffer()
      ..writeln('Sessão: ${summary.session.name}')
      ..writeln('Atualizada: ${_formatDateTime(summary.session.updatedAt)}')
      ..writeln('');

    for (final item in summary.items) {
      final expiry = item.expiry == null ? '' : ' | validade ${item.expiry}';
      final lot = item.lot == null || item.lot!.isEmpty
          ? ''
          : ' | lote ${item.lot}';
      buffer.writeln(
        '${item.code} - ${item.name} [${item.quantity}]$expiry$lot',
      );
    }

    return buffer.toString().trimRight();
  }

  Future<String> buildCustomPreview(String sessionId, String template) async {
    final summary = await _buildSessionSummary(sessionId);
    if (summary == null) {
      return '...';
    }
    final topItem = summary.items.isEmpty ? null : summary.items.first;
    final replacements = buildTemplateVariables(
      sessionName: summary.session.name,
      now: DateTime.now(),
      item: topItem,
    );

    var output = template;
    replacements.forEach((key, value) {
      output = output.replaceAll('{{$key}}', value);
    });
    return output;
  }

  Map<String, String> buildTemplateVariables({
    required String sessionName,
    required DateTime now,
    required InventoryExportRow? item,
  }) {
    return <String, String>{
      'code': item?.code ?? '',
      'codigo': item?.code ?? '',
      'name': item?.name ?? '',
      'nome': item?.name ?? '',
      'quantity': item?.quantity.toString() ?? '0',
      'quantidade': item?.quantity.toString() ?? '0',
      'lot': item?.lot ?? '',
      'lote': item?.lot ?? '',
      'expiry': item?.expiry ?? '',
      'validade': item?.expiry ?? '',
      'session': sessionName,
      'sessao': sessionName,
      'data': _formatDate(now),
      'date': _formatDate(now),
      'substancia': item?.activeSubstance ?? '',
      'dosagem': item?.strength ?? '',
      'forma': item?.pharmaceuticalForm ?? '',
      'apresentacao': item?.presentation ?? '',
      'titular': item?.holder ?? '',
      'bula_url': item?.leafletUrl ?? '',
      'rcm_url': item?.rcmUrl ?? '',
      'fonte': item?.sourceLabel ?? 'Sem catálogo',
    };
  }

  Future<List<InventoryExportRow>> buildRows(String sessionId) async {
    final summary = await _buildSessionSummary(sessionId);
    return summary?.items ?? const [];
  }

  Future<_SessionSummary?> _buildSessionSummary(String sessionId) async {
    final session = await repository.getSession(sessionId);
    if (session == null) {
      return null;
    }

    final items = await repository.listItems(sessionId);
    final events = await repository.listEventsForSession(sessionId);
    final latestEventByCode = <String, ScanEvent>{};
    for (final event in events) {
      latestEventByCode[event.productCode] = event;
    }

    final rows = <InventoryExportRow>[];
    for (final item in items) {
      final event = latestEventByCode[item.productCode];
      final hints = event == null
          ? LookupHints.fromInventoryItem(item)
          : LookupHints.fromScanEvent(event);
      final resolution = await enrichmentService.resolveNow(hints);
      final metadata = resolution.medication?.entry;
      rows.add(
        InventoryExportRow(
          code: item.productCode,
          name: metadata?.displayName ?? item.productCode,
          quantity: item.qty,
          expiry: _formatExpiry(event?.expiry),
          lot: event?.lot,
          activeSubstance: metadata?.activeSubstance,
          strength: metadata?.strength,
          pharmaceuticalForm: metadata?.pharmaceuticalForm,
          presentation: metadata?.presentation,
          holder: metadata?.holder,
          leafletUrl: metadata?.leafletUrl,
          rcmUrl: metadata?.rcmUrl,
          sourceLabel: _sourceLabel(resolution),
        ),
      );
    }

    rows.sort((a, b) => a.code.compareTo(b.code));
    return _SessionSummary(session: session, items: rows);
  }

  String _sourceLabel(MedicationResolution resolution) {
    switch (resolution.preferredSourceName) {
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

  String _escapeCsv(String value) {
    final needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) {
      return value;
    }
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }

  String? _formatExpiry(DateTime? expiry) {
    if (expiry == null) {
      return null;
    }
    final day = expiry.day.toString().padLeft(2, '0');
    final month = expiry.month.toString().padLeft(2, '0');
    return '$day/$month/${expiry.year}';
  }
}

class InventoryExportRow {
  const InventoryExportRow({
    required this.code,
    required this.name,
    required this.quantity,
    required this.expiry,
    required this.lot,
    required this.activeSubstance,
    required this.strength,
    required this.pharmaceuticalForm,
    required this.presentation,
    required this.holder,
    required this.leafletUrl,
    required this.rcmUrl,
    required this.sourceLabel,
  });

  final String code;
  final String name;
  final int quantity;
  final String? expiry;
  final String? lot;
  final String? activeSubstance;
  final String? strength;
  final String? pharmaceuticalForm;
  final String? presentation;
  final String? holder;
  final String? leafletUrl;
  final String? rcmUrl;
  final String sourceLabel;
}

class _SessionSummary {
  const _SessionSummary({required this.session, required this.items});

  final InventorySession session;
  final List<InventoryExportRow> items;
}
