# Third-Party Notices

This source preview includes third-party software through Flutter, Dart packages,
Android libraries, and vendored scanner code. Package versions are pinned by
`pubspec.lock` and Gradle configuration.

## Vendored Source

| Component | Location | License evidence |
| --- | --- | --- |
| `mobile_scanner` 5.2.3 fork | `plugins/mobile_scanner` | BSD-3-Clause, see `plugins/mobile_scanner/LICENSE`. Android barcode decoding was adapted to use FLOSS components only. |
| `libdmtx` sources | `plugins/mobile_scanner/android/src/main/cpp/libdmtx` | BSD-style license, see `plugins/mobile_scanner/android/src/main/cpp/libdmtx/LICENSE`. |

## Dart and Flutter Packages

Hosted Dart and Flutter packages are resolved from `pubspec.lock`. Their license
files remain in the local Pub cache during development and are included by
Flutter tooling in app license registries where applicable.

Direct runtime packages:

- `audioplayers`
- `csv`
- `cupertino_icons`
- `drift`
- `file_selector`
- `html`
- `http`
- `image`
- `path_provider`
- `shared_preferences`
- `sqlite3_flutter_libs`
- `url_launcher`

Direct development packages:

- `build_runner`
- `drift_dev`
- `flutter_lints`
- `path`
- `sqlite3`

Transitive package versions are listed in `pubspec.lock`.

## Android Libraries

Android dependencies are declared in `android/app/build.gradle.kts` and
`plugins/mobile_scanner/android/build.gradle`.

- AndroidX CameraX
- ZXing core
- QuickBird Studios OpenCV Android package
- Kotlin standard libraries and Gradle plugin dependencies

## Project-Owned Assets

The following assets were generated for open-pharma-stock and are covered by the
repository Apache-2.0 license:

- `assets/sounds/scan_beep.wav`
- `web/favicon.png`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`
- `assets/branding/app_icon_1024.png`
- Android launcher icon derivatives under `android/app/src/main/res/mipmap-*`
- `fastlane/metadata/android/en-US/images/icon.png`

## Release Note

`v0.1.0-poc` is a source and technical preview. A public APK requires a separate
release-signing process and a final third-party notice bundle for binary
distribution.
