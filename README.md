# open-pharma-stock

Privacy-conscious Flutter app for pharmacy inventory workflows, developed for
Android.

## Status

open-pharma-stock is an early release. It is useful for local stock counting and
exports, but has not yet been validated as a replacement for professional
pharmacy software.

## Current Capabilities

- Scan GS1 DataMatrix codes and extract GTIN plus serial number
- Scan EAN and other 1D barcodes for items without DataMatrix
- Aggregate stock counts by product
- Deduplicate by serial number when available
- Store data locally with Drift/SQLite
- Keep scan history by session
- Delete sessions and individual scan events
- Export inventory summaries as TXT or CSV
- Copy export content and save it locally
- Export and import local app backups
- Play feedback sounds on accepted scans
- Optionally look up medicine metadata at INFARMED after explicit opt-in

## Current Limits

- No claim of production or regulatory validation
- No cloud backup or sync service
- No Google Drive integration
- No medicine authenticity validation
- No guarantee of iOS readiness
- Online INFARMED lookups require network access and are disabled by default

## License

open-pharma-stock is licensed under the [Apache License 2.0](LICENSE).

## Releases and F-Droid

`v0.2.1` is the first F-Droid candidate. Android barcode scanning uses only
FLOSS components: CameraX, ZXing, OpenCV and libdmtx. F-Droid builds and signs
its APK directly from the tagged public source.

Release rules and the reusable F-Droid workflow are documented in
[docs/fdroid.md](docs/fdroid.md).

## Project Hygiene

- Security notes: [SECURITY.md](SECURITY.md)
- License: [LICENSE](LICENSE)
- Third-party notices: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)
- Change history and release status: [CHANGELOG.md](CHANGELOG.md)
- Public release policy: [docs/public_release.md](docs/public_release.md)
- Privacy policy: [PRIVACY.md](PRIVACY.md)
- F-Droid release guide: [docs/fdroid.md](docs/fdroid.md)
- CI: pull requests and pushes to `main` run Flutter analyze and tests

## Development

Typical local workflow:

```bash
flutter pub get
flutter test
flutter run
```

Build a debug APK when Android packaging matters:

```bash
flutter build apk --debug
```

Repository-specific agent guidance lives in `AGENTS.md`.

## Data and Privacy

Inventory data is stored locally on the device. Online INFARMED lookup is
disabled by default; enabling it sends the medicine lookup code to INFARMED.
Inventory exports and serial numbers may be sensitive. Avoid sharing real
pharmacy data in issues, screenshots, or logs. See [PRIVACY.md](PRIVACY.md).

## Feedback

Issues and suggestions are welcome. When reporting a bug, include reproduction steps, expected behavior, actual behavior, device details, and any relevant logs.
