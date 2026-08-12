import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_pharma_stock/l10n/app_localizations.dart';
import 'package:open_pharma_stock/l10n/legacy_message_keys.dart';

void main() {
  test('supports the documented language variants', () {
    expect(
      AppLocalizations.supportedLocales,
      contains(const Locale('pt', 'PT')),
    );
    expect(
      AppLocalizations.supportedLocales,
      contains(const Locale('pt', 'BR')),
    );
    expect(
      AppLocalizations.supportedLocales,
      contains(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ),
    );
    expect(
      AppLocalizations.supportedLocales,
      contains(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ),
    );
    expect(AppLocalizations.supportedLocales, contains(const Locale('ar')));
  });

  testWidgets('every supported locale has every extracted UI message', (
    tester,
  ) async {
    expect(legacyMessageCount, greaterThan(200));
    for (final locale in AppLocalizations.supportedLocales) {
      final translations = await AppLocalizations.load(locale);
      expect(translations.appTitle, isNotEmpty, reason: locale.toLanguageTag());
      for (final source in legacyMessageKeys.keys) {
        expect(
          translations.text(source),
          isNotEmpty,
          reason: '${locale.toLanguageTag()}: $source',
        );
      }
      if (locale.languageCode == 'ar') {
        expect(translations.text('Definições'), 'الإعدادات');
      }
      if (locale.scriptCode == 'Hans') {
        expect(translations.text('Definições'), '设置');
      }
      if (locale.scriptCode == 'Hant') {
        expect(translations.text('Definições'), '設定');
      }
      if (locale.languageCode == 'en') {
        expect(
          translations.plural(
            count: 1,
            oneSource: r'$count registo',
            otherSource: r'$count registos',
            placeholder: 'count',
          ),
          '1 record',
        );
        expect(
          translations.plural(
            count: 2,
            oneSource: r'$count registo',
            otherSource: r'$count registos',
            placeholder: 'count',
          ),
          '2 records',
        );
      }
    }
  });
}
