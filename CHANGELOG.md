# Changelog

## v0.2.1 - Unreleased

- Set the Android application ID and visible application name to
  `open.pharma.stock` and `open-pharma-stock` respectively before the first
  F-Droid submission.

## v0.2.0

- Replaced the proprietary Android ML Kit barcode runtime with a FLOSS scanner
  based on CameraX, ZXing, OpenCV and libdmtx.
- Made INFARMED network lookup explicit opt-in and disabled it by default.
- Added reusable F-Droid build metadata and localized store listing text.
- Pinned Flutter 3.38.3 across CI, the lockfile and the F-Droid build recipe.
- Expanded ignores and repository hygiene checks for keys, credentials, builds,
  backups, exports and QA evidence.
- Added an original open-pharma-stock application icon and privacy policy.

## Release Status

- The application is an early release candidate and is not validated for
  regulated pharmacy operations.
- Public release policy is defined in
  [docs/public_release.md](docs/public_release.md).
- Repository license is Apache-2.0.
- Third-party notices are documented in
  [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
- F-Droid performs the public release build and signing from tagged source.
