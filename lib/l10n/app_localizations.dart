import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'legacy_message_keys.dart';

/// ARB-backed application localization used by both generated messages and
/// legacy presentation copy while that copy is converted to typed getters.
class AppLocalizations {
  const AppLocalizations._(this.locale, this._messages);

  final Locale locale;
  final Map<String, String> _messages;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('hi'),
    Locale('es'),
    Locale('fr'),
    Locale('ar'),
    Locale('bn'),
    Locale('pt', 'PT'),
    Locale('pt', 'BR'),
    Locale('ru'),
    Locale('id'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final _testFallback = AppLocalizations._(
    const Locale('pt', 'PT'),
    const <String, String>{},
  );

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        _testFallback;
  }

  String get appTitle => _messages['appTitle'] ?? 'Open Pharma Stock';

  String text(String source) {
    final key = legacyMessageKeys[source];
    if (_messages.isEmpty && locale.languageCode == 'pt') {
      // Widget tests that mount a page without MaterialApp do not load assets.
      return source;
    }
    if (key == null) {
      // Product names, scanned values, local file names and server-provided
      // medicine data are content, not UI copy, and must remain unchanged.
      return source;
    }
    final message = _messages[key];
    if (message == null) {
      throw StateError(
        'Missing ARB message $key for ${locale.toLanguageTag()}',
      );
    }
    return message;
  }

  String format(String source, Map<String, Object?> values) {
    var message = text(source);
    for (final entry in values.entries) {
      message = message.replaceAll('\$${entry.key}', '${entry.value}');
    }
    return message;
  }

  String plural({
    required int count,
    required String oneSource,
    required String otherSource,
    required String placeholder,
  }) {
    return format(count == 1 ? oneSource : otherSource, {placeholder: count});
  }

  static Future<AppLocalizations> load(Locale requestedLocale) async {
    final locale = _resolvedLocale(requestedLocale);
    final asset = 'lib/l10n/app_${_arbSuffix(locale)}.arb';
    final decoded = jsonDecode(await rootBundle.loadString(asset)) as Map;
    final messages = <String, String>{
      for (final entry in decoded.entries)
        if (!entry.key.toString().startsWith('@') && entry.value is String)
          entry.key.toString(): entry.value as String,
    };
    return AppLocalizations._(locale, messages);
  }

  static Locale _resolvedLocale(Locale locale) {
    if (locale.languageCode == 'zh') {
      return locale.scriptCode == 'Hant' ||
              const {'TW', 'HK', 'MO'}.contains(locale.countryCode)
          ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
          : const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    }
    if (locale.languageCode == 'pt') {
      return locale.countryCode == 'BR'
          ? const Locale('pt', 'BR')
          : const Locale('pt', 'PT');
    }
    return supportedLocales.firstWhere(
      (supported) => supported.languageCode == locale.languageCode,
      orElse: () => const Locale('en'),
    );
  }

  static String _arbSuffix(Locale locale) {
    final script = locale.scriptCode;
    if (script != null && script.isNotEmpty) {
      return '${locale.languageCode}_$script';
    }
    final country = locale.countryCode;
    return country == null || country.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}_$country';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationBuildContext on BuildContext {
  String tr(String source) => AppLocalizations.of(this).text(source);

  String trFormat(String source, Map<String, Object?> values) =>
      AppLocalizations.of(this).format(source, values);

  String trPlural({
    required int count,
    required String oneSource,
    required String otherSource,
    required String placeholder,
  }) => AppLocalizations.of(this).plural(
    count: count,
    oneSource: oneSource,
    otherSource: otherSource,
    placeholder: placeholder,
  );
}
