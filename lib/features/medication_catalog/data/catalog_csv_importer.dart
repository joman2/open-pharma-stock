import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';

import '../application/lookup_hints.dart';
import '../domain/medication_catalog_repository.dart';
import '../domain/models.dart';

class CatalogCsvImporter {
  CatalogCsvImporter({required MedicationCatalogRepository repository})
    : _repository = repository;

  final MedicationCatalogRepository _repository;

  static const _requiredHeaders = [
    'source_record_id',
    'lookup_code',
    'lookup_code_kind',
    'canonical_code',
    'display_name',
  ];

  Future<CatalogImportResult> importFile(XFile file) async {
    final content = await file.readAsString();
    final parseResult = parse(content);
    return _repository.replaceCsvCatalog(
      medications: parseResult.medications,
      sourceLabel: file.name,
      invalidRowCount: parseResult.invalidRowCount,
      warnings: parseResult.warnings,
    );
  }

  ParsedCatalogCsv parse(String content) {
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(content);
    if (rows.isEmpty) {
      throw const FormatException('O CSV está vazio.');
    }

    final headers = rows.first
        .map((value) => value.toString().trim())
        .toList(growable: false);
    for (final header in _requiredHeaders) {
      if (!headers.contains(header)) {
        throw FormatException('Falta a coluna obrigatória "$header".');
      }
    }

    final headerIndex = <String, int>{
      for (var i = 0; i < headers.length; i++) headers[i]: i,
    };

    final grouped = <String, _CsvMedicationAccumulator>{};
    final warnings = <String>[];
    var invalidRowCount = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((cell) => cell.toString().trim().isEmpty)) {
        continue;
      }

      String read(String key) {
        final index = headerIndex[key];
        if (index == null || index >= row.length) {
          return '';
        }
        return row[index].toString().trim();
      }

      final sourceRecordId = read('source_record_id');
      final lookupCode = read('lookup_code');
      final lookupCodeKind = read('lookup_code_kind').toUpperCase();
      final canonicalCode = read('canonical_code');
      final displayName = read('display_name');
      if (sourceRecordId.isEmpty ||
          lookupCode.isEmpty ||
          lookupCodeKind.isEmpty ||
          canonicalCode.isEmpty ||
          displayName.isEmpty) {
        invalidRowCount += 1;
        warnings.add(
          'Linha ${i + 1} ignorada por falta de campos obrigatórios.',
        );
        continue;
      }

      final normalizedCode = _normalizeLookupCode(lookupCode, lookupCodeKind);
      if (normalizedCode == null) {
        invalidRowCount += 1;
        warnings.add(
          'Linha ${i + 1} ignorada: código "$lookupCode" inválido para "$lookupCodeKind".',
        );
        continue;
      }

      final accumulator = grouped.putIfAbsent(
        sourceRecordId,
        () => _CsvMedicationAccumulator(
          sourceRecordId: sourceRecordId,
          canonicalCode: canonicalCode,
          displayName: displayName,
          activeSubstance: _optional(read('active_substance')),
          strength: _optional(read('strength')),
          pharmaceuticalForm: _optional(read('pharmaceutical_form')),
          presentation: _optional(read('presentation')),
          holder: _optional(read('holder')),
          leafletUrl: _optional(read('leaflet_url')),
          rcmUrl: _optional(read('rcm_url')),
          sourceUrl: _optional(read('source_url')),
          imageUrl: _optional(read('image_url')),
        ),
      );

      accumulator.lookupCodes.add(
        CatalogImportLookupInput(
          normalizedCode: normalizedCode,
          codeKind: lookupCodeKind,
          isPrimary: read('is_primary').toLowerCase() == 'true',
        ),
      );
    }

    return ParsedCatalogCsv(
      medications: grouped.values
          .map((accumulator) => accumulator.build())
          .toList(),
      invalidRowCount: invalidRowCount,
      warnings: warnings,
    );
  }

  String? _normalizeLookupCode(String value, String kind) {
    final trimmed = value.trim();
    switch (kind) {
      case MedicationCodeKind.gtin:
        if (RegExp(r'^\d{14}$').hasMatch(trimmed)) {
          return trimmed;
        }
        if (RegExp(r'^\d{13}$').hasMatch(trimmed)) {
          return '0$trimmed';
        }
        return null;
      case MedicationCodeKind.ean:
        if (RegExp(r'^\d{8}$').hasMatch(trimmed) ||
            RegExp(r'^\d{13}$').hasMatch(trimmed)) {
          return trimmed;
        }
        return null;
      case MedicationCodeKind.ptReg:
        final digits = trimmed.replaceAll(RegExp(r'\D'), '');
        return digits.length == 7 ? digits : null;
      case MedicationCodeKind.cnpem:
        final digits = trimmed.replaceAll(RegExp(r'\D'), '');
        return digits.length == 8 ? digits : null;
      case MedicationCodeKind.raw:
        return trimmed.isEmpty ? null : trimmed;
      default:
        return null;
    }
  }

  String? _optional(String value) {
    return value.trim().isEmpty ? null : value.trim();
  }
}

class ParsedCatalogCsv {
  const ParsedCatalogCsv({
    required this.medications,
    required this.invalidRowCount,
    required this.warnings,
  });

  final List<CatalogImportMedicationInput> medications;
  final int invalidRowCount;
  final List<String> warnings;
}

class _CsvMedicationAccumulator {
  _CsvMedicationAccumulator({
    required this.sourceRecordId,
    required this.canonicalCode,
    required this.displayName,
    required this.activeSubstance,
    required this.strength,
    required this.pharmaceuticalForm,
    required this.presentation,
    required this.holder,
    required this.leafletUrl,
    required this.rcmUrl,
    required this.sourceUrl,
    required this.imageUrl,
  });

  final String sourceRecordId;
  final String canonicalCode;
  final String displayName;
  final String? activeSubstance;
  final String? strength;
  final String? pharmaceuticalForm;
  final String? presentation;
  final String? holder;
  final String? leafletUrl;
  final String? rcmUrl;
  final String? sourceUrl;
  final String? imageUrl;
  final List<CatalogImportLookupInput> lookupCodes = [];

  CatalogImportMedicationInput build() {
    return CatalogImportMedicationInput(
      sourceName: MedicationSource.csvManual,
      sourcePriority: MedicationSourcePriority.csvManual,
      sourceRecordId: sourceRecordId,
      canonicalCode: canonicalCode,
      displayName: displayName,
      activeSubstance: activeSubstance,
      strength: strength,
      pharmaceuticalForm: pharmaceuticalForm,
      presentation: presentation,
      holder: holder,
      leafletUrl: leafletUrl,
      rcmUrl: rcmUrl,
      sourceUrl: sourceUrl,
      imageUrl: imageUrl,
      lookupCodes: lookupCodes,
    );
  }
}
