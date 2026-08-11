import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../scanner/scanner_engine.dart';

enum DuplicateCodeAction { ignore, countPlusOne }

enum ExportPreference { csv, json, txt }

@immutable
class AppSettingsState {
  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.preferredScanMode = ScanMode.dataMatrix,
    this.openScannerOnSessionEntry = false,
    this.autoTorch = false,
    this.barcodeQuantityPromptByDefault = false,
    this.duplicateCodeAction = DuplicateCodeAction.ignore,
    this.vibrateOnRead = false,
    this.soundOnRead = true,
    this.exportPreference = ExportPreference.csv,
    this.previewBeforeSaving = true,
    this.customTxtTemplate = defaultCustomTxtTemplate,
    this.expiryAlertsEnabled = true,
    this.expiryAlertDays = 30,
    this.onlineCatalogLookupEnabled = false,
    this.hasSeenAnyTour = false,
    this.tourAutoStartEnabled = true,
    this.lastCompletedTourVersion,
    this.lastDismissedTourVersion,
  });

  static const currentTourVersion = 2;

  static const defaultCustomTxtTemplate =
      'Sessão: {{sessao}}\n'
      'Data: {{data}}\n'
      'Código: {{codigo}}\n'
      'Quantidade: {{quantidade}}\n'
      'Lote: {{lote}}\n'
      'Validade: {{validade}}\n'
      'Nome: {{nome}}';

  final ThemeMode themeMode;
  final ScanMode preferredScanMode;
  final bool openScannerOnSessionEntry;
  final bool autoTorch;
  final bool barcodeQuantityPromptByDefault;
  final DuplicateCodeAction duplicateCodeAction;
  final bool vibrateOnRead;
  final bool soundOnRead;
  final ExportPreference exportPreference;
  final bool previewBeforeSaving;
  final String customTxtTemplate;
  final bool expiryAlertsEnabled;
  final int expiryAlertDays;
  final bool onlineCatalogLookupEnabled;
  final bool hasSeenAnyTour;
  final bool tourAutoStartEnabled;
  final int? lastCompletedTourVersion;
  final int? lastDismissedTourVersion;

  bool get shouldAutoStartTour {
    if (!tourAutoStartEnabled) {
      return false;
    }
    if (lastCompletedTourVersion == currentTourVersion) {
      return false;
    }
    if (lastDismissedTourVersion == currentTourVersion) {
      return false;
    }
    return true;
  }

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    ScanMode? preferredScanMode,
    bool? openScannerOnSessionEntry,
    bool? autoTorch,
    bool? barcodeQuantityPromptByDefault,
    DuplicateCodeAction? duplicateCodeAction,
    bool? vibrateOnRead,
    bool? soundOnRead,
    ExportPreference? exportPreference,
    bool? previewBeforeSaving,
    String? customTxtTemplate,
    bool? expiryAlertsEnabled,
    int? expiryAlertDays,
    bool? onlineCatalogLookupEnabled,
    bool? hasSeenAnyTour,
    bool? tourAutoStartEnabled,
    int? lastCompletedTourVersion,
    bool clearLastCompletedTourVersion = false,
    int? lastDismissedTourVersion,
    bool clearLastDismissedTourVersion = false,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      preferredScanMode: preferredScanMode ?? this.preferredScanMode,
      openScannerOnSessionEntry:
          openScannerOnSessionEntry ?? this.openScannerOnSessionEntry,
      autoTorch: autoTorch ?? this.autoTorch,
      barcodeQuantityPromptByDefault:
          barcodeQuantityPromptByDefault ?? this.barcodeQuantityPromptByDefault,
      duplicateCodeAction: duplicateCodeAction ?? this.duplicateCodeAction,
      vibrateOnRead: vibrateOnRead ?? this.vibrateOnRead,
      soundOnRead: soundOnRead ?? this.soundOnRead,
      exportPreference: exportPreference ?? this.exportPreference,
      previewBeforeSaving: previewBeforeSaving ?? this.previewBeforeSaving,
      customTxtTemplate: customTxtTemplate ?? this.customTxtTemplate,
      expiryAlertsEnabled: expiryAlertsEnabled ?? this.expiryAlertsEnabled,
      expiryAlertDays: expiryAlertDays ?? this.expiryAlertDays,
      onlineCatalogLookupEnabled:
          onlineCatalogLookupEnabled ?? this.onlineCatalogLookupEnabled,
      hasSeenAnyTour: hasSeenAnyTour ?? this.hasSeenAnyTour,
      tourAutoStartEnabled: tourAutoStartEnabled ?? this.tourAutoStartEnabled,
      lastCompletedTourVersion: clearLastCompletedTourVersion
          ? null
          : (lastCompletedTourVersion ?? this.lastCompletedTourVersion),
      lastDismissedTourVersion: clearLastDismissedTourVersion
          ? null
          : (lastDismissedTourVersion ?? this.lastDismissedTourVersion),
    );
  }
}

class AppSettingsController extends ValueNotifier<AppSettingsState> {
  AppSettingsController({required SharedPreferences preferences})
    : _preferences = preferences,
      super(_loadInitialState(preferences));

  static const _themeModeKey = 'app.theme_mode';
  static const _preferredScanModeKey = 'scanner.preferred_mode';
  static const _openScannerOnEntryKey = 'scanner.open_on_session_entry';
  static const _autoTorchKey = 'scanner.auto_torch';
  static const _barcodeQuantityPromptByDefaultKey =
      'scanner.barcode_quantity_prompt_by_default';
  static const _duplicateCodeActionKey = 'scanner.duplicate_action';
  static const _vibrateOnReadKey = 'scanner.vibrate_on_read';
  static const _soundOnReadKey = 'scanner.sound_on_read';
  static const _exportPreferenceKey = 'export.preference';
  static const _previewBeforeSavingKey = 'export.preview_before_saving';
  static const _customTxtTemplateKey = 'export.custom_txt_template';
  static const _expiryAlertsEnabledKey = 'validation.expiry_alerts_enabled';
  static const _expiryAlertDaysKey = 'validation.expiry_alert_days';
  static const _onlineCatalogLookupEnabledKey =
      'catalog.online_lookup_enabled';
  static const _hasSeenAnyTourKey = 'tour.has_seen_any_tour';
  static const _tourAutoStartEnabledKey = 'tour.auto_start_enabled';
  static const _lastCompletedTourVersionKey = 'tour.last_completed_version';
  static const _lastDismissedTourVersionKey = 'tour.last_dismissed_version';

  final SharedPreferences _preferences;

  static AppSettingsState _loadInitialState(SharedPreferences preferences) {
    return AppSettingsState(
      themeMode: _themeModeFromString(preferences.getString(_themeModeKey)),
      preferredScanMode: _scanModeFromString(
        preferences.getString(_preferredScanModeKey),
      ),
      openScannerOnSessionEntry:
          preferences.getBool(_openScannerOnEntryKey) ?? false,
      autoTorch: preferences.getBool(_autoTorchKey) ?? false,
      barcodeQuantityPromptByDefault:
          preferences.getBool(_barcodeQuantityPromptByDefaultKey) ?? false,
      duplicateCodeAction: _duplicateCodeActionFromString(
        preferences.getString(_duplicateCodeActionKey),
      ),
      vibrateOnRead: preferences.getBool(_vibrateOnReadKey) ?? false,
      soundOnRead: preferences.getBool(_soundOnReadKey) ?? true,
      exportPreference: _exportPreferenceFromString(
        preferences.getString(_exportPreferenceKey),
      ),
      previewBeforeSaving: preferences.getBool(_previewBeforeSavingKey) ?? true,
      customTxtTemplate:
          preferences.getString(_customTxtTemplateKey) ??
          AppSettingsState.defaultCustomTxtTemplate,
      expiryAlertsEnabled: preferences.getBool(_expiryAlertsEnabledKey) ?? true,
      expiryAlertDays: preferences.getInt(_expiryAlertDaysKey) ?? 30,
      onlineCatalogLookupEnabled:
          preferences.getBool(_onlineCatalogLookupEnabledKey) ?? false,
      hasSeenAnyTour: preferences.getBool(_hasSeenAnyTourKey) ?? false,
      tourAutoStartEnabled:
          preferences.getBool(_tourAutoStartEnabledKey) ?? true,
      lastCompletedTourVersion: preferences.getInt(
        _lastCompletedTourVersionKey,
      ),
      lastDismissedTourVersion: preferences.getInt(
        _lastDismissedTourVersionKey,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    value = value.copyWith(themeMode: themeMode);
    await _preferences.setString(_themeModeKey, themeMode.name);
  }

  Future<void> setPreferredScanMode(ScanMode mode) async {
    value = value.copyWith(preferredScanMode: mode);
    await _preferences.setString(_preferredScanModeKey, mode.name);
  }

  Future<void> setOpenScannerOnSessionEntry(bool enabled) async {
    value = value.copyWith(openScannerOnSessionEntry: enabled);
    await _preferences.setBool(_openScannerOnEntryKey, enabled);
  }

  Future<void> setAutoTorch(bool enabled) async {
    value = value.copyWith(autoTorch: enabled);
    await _preferences.setBool(_autoTorchKey, enabled);
  }

  Future<void> setBarcodeQuantityPromptByDefault(bool enabled) async {
    value = value.copyWith(barcodeQuantityPromptByDefault: enabled);
    await _preferences.setBool(_barcodeQuantityPromptByDefaultKey, enabled);
  }

  Future<void> setDuplicateCodeAction(DuplicateCodeAction action) async {
    value = value.copyWith(duplicateCodeAction: action);
    await _preferences.setString(_duplicateCodeActionKey, action.name);
  }

  Future<void> setVibrateOnRead(bool enabled) async {
    value = value.copyWith(vibrateOnRead: enabled);
    await _preferences.setBool(_vibrateOnReadKey, enabled);
  }

  Future<void> setSoundOnRead(bool enabled) async {
    value = value.copyWith(soundOnRead: enabled);
    await _preferences.setBool(_soundOnReadKey, enabled);
  }

  Future<void> setExportPreference(ExportPreference preference) async {
    value = value.copyWith(exportPreference: preference);
    await _preferences.setString(_exportPreferenceKey, preference.name);
  }

  Future<void> setPreviewBeforeSaving(bool enabled) async {
    value = value.copyWith(previewBeforeSaving: enabled);
    await _preferences.setBool(_previewBeforeSavingKey, enabled);
  }

  Future<void> setCustomTxtTemplate(String template) async {
    value = value.copyWith(customTxtTemplate: template);
    await _preferences.setString(_customTxtTemplateKey, template);
  }

  Future<void> setExpiryAlertsEnabled(bool enabled) async {
    value = value.copyWith(expiryAlertsEnabled: enabled);
    await _preferences.setBool(_expiryAlertsEnabledKey, enabled);
  }

  Future<void> setExpiryAlertDays(int days) async {
    value = value.copyWith(expiryAlertDays: days);
    await _preferences.setInt(_expiryAlertDaysKey, days);
  }

  Future<void> setOnlineCatalogLookupEnabled(bool enabled) async {
    value = value.copyWith(onlineCatalogLookupEnabled: enabled);
    await _preferences.setBool(_onlineCatalogLookupEnabledKey, enabled);
  }

  Future<void> setTourAutoStartEnabled(bool enabled) async {
    value = value.copyWith(tourAutoStartEnabled: enabled);
    await _preferences.setBool(_tourAutoStartEnabledKey, enabled);
  }

  Future<void> markTourCompleted({
    int version = AppSettingsState.currentTourVersion,
  }) async {
    value = value.copyWith(
      hasSeenAnyTour: true,
      lastCompletedTourVersion: version,
      clearLastDismissedTourVersion: true,
    );
    await _preferences.setBool(_hasSeenAnyTourKey, true);
    await _preferences.setInt(_lastCompletedTourVersionKey, version);
    await _preferences.remove(_lastDismissedTourVersionKey);
  }

  Future<void> markTourDismissed({
    int version = AppSettingsState.currentTourVersion,
  }) async {
    value = value.copyWith(
      hasSeenAnyTour: true,
      lastDismissedTourVersion: version,
    );
    await _preferences.setBool(_hasSeenAnyTourKey, true);
    await _preferences.setInt(_lastDismissedTourVersionKey, version);
  }

  Map<String, Object?> exportAllPreferences() {
    final exported = <String, Object?>{};
    for (final key in _preferences.getKeys()) {
      final raw = _preferences.get(key);
      if (raw == null) {
        continue;
      }
      if (raw is bool) {
        exported[key] = {'type': 'bool', 'value': raw};
        continue;
      }
      if (raw is int) {
        exported[key] = {'type': 'int', 'value': raw};
        continue;
      }
      if (raw is double) {
        exported[key] = {'type': 'double', 'value': raw};
        continue;
      }
      if (raw is String) {
        exported[key] = {'type': 'string', 'value': raw};
        continue;
      }
      if (raw is List<String>) {
        exported[key] = {'type': 'stringList', 'value': raw};
      }
    }
    return exported;
  }

  Future<void> restoreAllPreferences(Map<String, Object?> exported) async {
    for (final key in _preferences.getKeys()) {
      await _preferences.remove(key);
    }
    for (final entry in exported.entries) {
      final payload = entry.value;
      if (payload is! Map) {
        continue;
      }
      final type = payload['type'];
      final value = payload['value'];
      if (type == 'bool' && value is bool) {
        await _preferences.setBool(entry.key, value);
        continue;
      }
      if (type == 'int' && value is int) {
        await _preferences.setInt(entry.key, value);
        continue;
      }
      if (type == 'double' && value is num) {
        await _preferences.setDouble(entry.key, value.toDouble());
        continue;
      }
      if (type == 'string' && value is String) {
        await _preferences.setString(entry.key, value);
        continue;
      }
      if (type == 'stringList') {
        final strings = switch (value) {
          final List<String> list => list,
          final List<dynamic> list => list.map((item) => '$item').toList(),
          _ => null,
        };
        if (strings != null) {
          await _preferences.setStringList(entry.key, strings);
        }
      }
    }
    reloadFromPreferences();
  }

  void reloadFromPreferences() {
    value = _loadInitialState(_preferences);
  }

  static ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static ScanMode _scanModeFromString(String? value) {
    switch (value) {
      case 'barcodes':
        return ScanMode.barcodes;
      case 'dataMatrix':
      default:
        return ScanMode.dataMatrix;
    }
  }

  static DuplicateCodeAction _duplicateCodeActionFromString(String? value) {
    switch (value) {
      case 'countPlusOne':
        return DuplicateCodeAction.countPlusOne;
      case 'ignore':
      default:
        return DuplicateCodeAction.ignore;
    }
  }

  static ExportPreference _exportPreferenceFromString(String? value) {
    switch (value) {
      case 'json':
        return ExportPreference.json;
      case 'txtSimple':
      case 'txtDetailed':
      case 'txtCustom':
      case 'txt':
        return ExportPreference.txt;
      case 'csv':
      default:
        return ExportPreference.csv;
    }
  }
}
