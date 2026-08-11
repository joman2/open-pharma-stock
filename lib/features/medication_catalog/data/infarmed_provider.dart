import 'dart:async';

import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

import '../application/lookup_hints.dart';
import '../domain/models.dart';
import 'providers/medication_remote_provider.dart';
import 'infarmed_models.dart';

class InfarmedProvider implements MedicationRemoteProvider {
  InfarmedProvider({
    http.Client? client,
    Duration timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client(),
       _timeout = timeout;

  final http.Client _client;
  final Duration _timeout;

  @override
  String get providerName => MedicationSource.infarmed;

  @override
  int get providerPriority => MedicationSourcePriority.infarmed;

  static final Uri _searchUri = Uri.parse(
    'https://extranet.infarmed.pt/CITS-pesquisamedicamento-fo/pesquisaMedicamento.jsf',
  );

  Future<InfarmedMedicationPayload?> lookup(List<LookupHint> hints) async {
    final candidates = LookupHints.orderedInfarmedHints(hints);
    if (candidates.isEmpty) {
      return null;
    }

    final initialResponse = await _client.get(_searchUri).timeout(_timeout);
    if (initialResponse.statusCode >= 400) {
      throw StateError(
        'INFARMED indisponível (${initialResponse.statusCode}).',
      );
    }

    final viewState = _extractViewState(initialResponse.body);
    for (final hint in candidates) {
      final body = <String, String>{
        'form': 'form',
        'form:dci_input': '',
        'form:nome_input': '',
        'form:forma_input': '',
        'form:dosagem_input': '',
        'form:tamanho_input': '',
        'form:numeroRegisto': '',
        'form:cnpem': '',
        'form:comerc_input': 'Comercializado',
        'form:search-button': 'form:search-button',
        'javax.faces.ViewState': viewState,
      };

      if (hint.codeKind == MedicationCodeKind.ptReg ||
          (hint.codeKind == MedicationCodeKind.raw &&
              RegExp(r'^\d{7}$').hasMatch(hint.normalizedCode))) {
        body['form:numeroRegisto'] = hint.normalizedCode;
      } else if (hint.codeKind == MedicationCodeKind.cnpem ||
          (hint.codeKind == MedicationCodeKind.raw &&
              RegExp(r'^\d{8}$').hasMatch(hint.normalizedCode))) {
        body['form:cnpem'] = hint.normalizedCode;
      } else {
        continue;
      }

      final response = await _client
          .post(
            _searchUri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(_timeout);
      if (response.statusCode >= 400) {
        throw StateError('Pesquisa INFARMED falhou (${response.statusCode}).');
      }

      final resultRows = _parseResultRows(response.body);
      if (resultRows.isEmpty) {
        continue;
      }

      final bestRow = _pickBestRow(resultRows, hint);
      if (bestRow == null) {
        continue;
      }

      final detailUrl = bestRow.detailUrl == null
          ? null
          : Uri.parse(bestRow.detailUrl!).replace(scheme: 'https');
      String? holder;
      String? leafletUrl;
      String? rcmUrl;
      if (detailUrl != null) {
        final detailResponse = await _client.get(detailUrl).timeout(_timeout);
        if (detailResponse.statusCode < 400) {
          final detailData = _parseDetail(detailResponse.body, detailUrl);
          holder = detailData.holder;
          leafletUrl = detailData.leafletUrl;
          rcmUrl = detailData.rcmUrl;
        }
      }

      return InfarmedMedicationPayload(
        sourceRecordId: bestRow.sourceRecordId,
        canonicalCode:
            bestRow.registrationNumber ?? bestRow.cnpem ?? hint.normalizedCode,
        displayName: bestRow.displayName,
        activeSubstance: bestRow.activeSubstance,
        strength: bestRow.strength,
        pharmaceuticalForm: bestRow.pharmaceuticalForm,
        presentation: bestRow.presentation,
        holder: holder,
        leafletUrl: leafletUrl,
        rcmUrl: rcmUrl,
        sourceUrl: detailUrl?.toString(),
        imageUrl: null,
        lookupCodes: [
          if (bestRow.registrationNumber != null)
            InfarmedLookupCode(
              normalizedCode: bestRow.registrationNumber!,
              codeKind: MedicationCodeKind.ptReg,
              isPrimary: true,
            ),
          if (bestRow.cnpem != null)
            InfarmedLookupCode(
              normalizedCode: bestRow.cnpem!,
              codeKind: MedicationCodeKind.cnpem,
            ),
        ],
      );
    }

    return null;
  }

  @override
  Future<RemoteProviderResult> resolve(List<LookupHint> hints) async {
    try {
      final payload = await lookup(hints);
      if (payload == null) {
        return const RemoteProviderResult(
          status: RemoteProviderStatus.notFound,
          providerName: MedicationSource.infarmed,
          entry: null,
          lookupCodes: [],
          errorMessage: 'Sem resultado no INFARMED.',
        );
      }
      return RemoteProviderResult(
        status: RemoteProviderStatus.resolved,
        providerName: MedicationSource.infarmed,
        entry: MedicationCatalogEntry(
          id: '${MedicationSource.infarmed}::${payload.sourceRecordId}',
          sourceName: MedicationSource.infarmed,
          sourcePriority: MedicationSourcePriority.infarmed,
          sourceRecordId: payload.sourceRecordId,
          canonicalCode: payload.canonicalCode,
          displayName: payload.displayName,
          activeSubstance: payload.activeSubstance,
          strength: payload.strength,
          pharmaceuticalForm: payload.pharmaceuticalForm,
          presentation: payload.presentation,
          holder: payload.holder,
          leafletUrl: payload.leafletUrl,
          rcmUrl: payload.rcmUrl,
          sourceUrl: payload.sourceUrl,
          imageUrl: payload.imageUrl,
          updatedAt: DateTime.now(),
        ),
        lookupCodes: payload.lookupCodes
            .map(
              (lookup) => MedicationLookupCode(
                id: '${payload.sourceRecordId}::${lookup.codeKind}::${lookup.normalizedCode}',
                medicationId:
                    '${MedicationSource.infarmed}::${payload.sourceRecordId}',
                normalizedCode: lookup.normalizedCode,
                codeKind: lookup.codeKind,
                isPrimary: lookup.isPrimary,
              ),
            )
            .toList(),
      );
    } catch (error) {
      return RemoteProviderResult(
        status: RemoteProviderStatus.error,
        providerName: MedicationSource.infarmed,
        entry: null,
        lookupCodes: const [],
        errorMessage: error.toString(),
      );
    }
  }

  String _extractViewState(String htmlContent) {
    final match = RegExp(
      'name="javax.faces.ViewState"[^>]*value="([^"]+)"',
    ).firstMatch(htmlContent);
    if (match == null) {
      throw const FormatException('ViewState do INFARMED não encontrado.');
    }
    return match.group(1)!;
  }

  List<_InfarmedSearchRow> _parseResultRows(String htmlContent) {
    final document = html.parse(htmlContent);
    final rows = document.querySelectorAll('#form\\:tbl_data > tr');
    return rows
        .where((row) => !row.classes.contains('ui-datatable-empty-message'))
        .map((row) {
          final cells = row.querySelectorAll('td');
          if (cells.length < 13) {
            return null;
          }
          final link = row
              .querySelector('a[id*=":infomed"]')
              ?.attributes['href'];
          return _InfarmedSearchRow(
            registrationNumber: _cleanDigits(cells[0].text),
            activeSubstance: _cleanText(cells[1].text),
            displayName: _cleanText(cells[2].text) ?? '',
            pharmaceuticalForm: _cleanText(cells[3].text),
            strength: _cleanText(cells[4].text),
            presentation: _cleanText(cells[5].text),
            cnpem: _cleanDigits(cells[6].text),
            commercialized: _cleanText(cells[11].text) == 'Comercializado',
            detailUrl: link,
          );
        })
        .whereType<_InfarmedSearchRow>()
        .toList();
  }

  _InfarmedSearchRow? _pickBestRow(
    List<_InfarmedSearchRow> rows,
    LookupHint hint,
  ) {
    for (final row in rows) {
      if (hint.codeKind == MedicationCodeKind.ptReg &&
          row.registrationNumber == hint.normalizedCode) {
        return row;
      }
      if (hint.codeKind == MedicationCodeKind.cnpem &&
          row.cnpem == hint.normalizedCode) {
        return row;
      }
    }
    return rows.firstWhere(
      (row) => row.commercialized,
      orElse: () => rows.first,
    );
  }

  _InfarmedDetailData _parseDetail(String htmlContent, Uri detailUrl) {
    String? labelValue(String label) {
      final match = RegExp(
        '$label:</label></div><div[^>]*><label[^>]*class="ui-outputlabel ui-widget labelTexto">([^<]*)</label>',
      ).firstMatch(htmlContent);
      return match == null ? null : _cleanText(match.group(1));
    }

    return _InfarmedDetailData(
      holder: labelValue('Titular de AIM') ?? labelValue('Titular da AIM'),
      leafletUrl: _findDirectDocumentLink(htmlContent, detailUrl, 'Folheto'),
      rcmUrl: _findDirectDocumentLink(
        htmlContent,
        detailUrl,
        'Resumo das Características do Medicamento',
      ),
    );
  }

  String? _findDirectDocumentLink(
    String htmlContent,
    Uri detailUrl,
    String text,
  ) {
    final document = html.parse(htmlContent);
    for (final link in document.querySelectorAll('a[href]')) {
      final href = link.attributes['href'];
      if (href == null) {
        continue;
      }
      if (!link.text.contains(text)) {
        continue;
      }
      final uri = Uri.tryParse(href);
      if (uri == null) {
        continue;
      }
      return detailUrl.resolveUri(uri).toString();
    }
    return null;
  }

  String? _cleanText(String? value) {
    final trimmed = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  String? _cleanDigits(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '');
    return digits == null || digits.isEmpty ? null : digits;
  }
}

class _InfarmedSearchRow {
  const _InfarmedSearchRow({
    required this.registrationNumber,
    required this.activeSubstance,
    required this.displayName,
    required this.pharmaceuticalForm,
    required this.strength,
    required this.presentation,
    required this.cnpem,
    required this.commercialized,
    required this.detailUrl,
  });

  final String? registrationNumber;
  final String? activeSubstance;
  final String displayName;
  final String? pharmaceuticalForm;
  final String? strength;
  final String? presentation;
  final String? cnpem;
  final bool commercialized;
  final String? detailUrl;

  String get sourceRecordId => registrationNumber ?? cnpem ?? displayName;
}

class _InfarmedDetailData {
  const _InfarmedDetailData({
    required this.holder,
    required this.leafletUrl,
    required this.rcmUrl,
  });

  final String? holder;
  final String? leafletUrl;
  final String? rcmUrl;
}
