# Localization

`open-pharma-stock` uses ARB catalogs in `lib/l10n/app_*.arb`, packaged with
the APK. The runtime catalog resolves the complete existing presentation-copy
set through stable ARB keys; missing UI keys throw rather than silently falling
back to another language. New copy should be added as a typed ARB message.

## Supported languages

The release set follows the 2025 Ethnologue total-speaker ranking, using the
ten globally most widely spoken languages: English, Mandarin Chinese, Hindi,
Spanish, Arabic, French, Bengali, Portuguese, Russian, and Indonesian.

The implementation has 12 locale variants:

| Language | App locale(s) | Fastlane metadata |
| --- | --- | --- |
| English | `en` | `en-US` |
| Mandarin Chinese | `zh-Hans`, `zh-Hant` | `zh-CN`, `zh-TW` |
| Hindi | `hi` | `hi-IN` |
| Spanish | `es` | `es-ES` |
| Arabic | `ar` (RTL) | `ar` |
| French | `fr` | `fr-FR` |
| Bengali | `bn` | `bn-BD` |
| Portuguese | `pt-PT`, `pt-BR` | `pt-PT`, `pt-BR` |
| Russian | `ru` | `ru-RU` |
| Indonesian | `id` | `id-ID` |

Chinese devices in Taiwan, Hong Kong, and Macao resolve to `zh-Hant`; other
Chinese devices resolve to `zh-Hans`. Portuguese defaults to `pt-PT` unless
the device explicitly requests Brazil. Flutter's global localization delegates
provide RTL layout direction for Arabic.

## Adding or changing UI copy

1. Add new, stable messages to `app_en.arb` and every supported `app_*.arb`.
   Use named placeholders and the ICU plural/select syntax where needed.
2. Run `flutter gen-l10n`; generated `generated_app_localizations*.dart`
   sources are ignored and are not committed.
3. For existing visual text, use the local `Text` wrapper from
   `lib/l10n/localized_text.dart` or `context.tr(...)` for tooltips and input
   hints. For values, use `context.trFormat(...)` with an explicit placeholder;
   never concatenate translated strings.
4. Review all locale variants on device/emulator. Check line wrapping, named
   placeholders, plurals, the Arabic RTL layout, and the two Chinese scripts.
5. Keep Fastlane's `title.txt`, `short_description.txt`,
   `full_description.txt`, and the current version's changelog aligned with
   user-visible claims. Do not imply that the optional INFARMED lookup is
   enabled by default or that camera frames leave the device.

The ranking is a coverage decision, not a claim of country-specific medicine
catalogue support. Local catalog import and optional INFARMED lookup retain
their existing behavior in every locale.
