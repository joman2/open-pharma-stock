# F-Droid Release Guide

This is the reusable release process for OpenPharmaStock.

## Invariants

- Develop on `main`.
- Keep the Android application ID
  `io.github.joman2.openpharmastock`.
- Use monotonically increasing integer build numbers in `pubspec.yaml`.
- Create stable tags as `vMAJOR.MINOR.PATCH`; never move a published tag.
- Keep Flutter pinned to the same exact version in `.metadata`, CI and
  `.fdroid.yml`.
- Never commit signing keys, `key.properties`, APK/AAB files, backups, exports,
  real pharmacy data, QA dumps or local credentials.
- F-Droid builds and signs its own APK. No private signing key is submitted.

## Release checklist

1. Update `version:` in `pubspec.yaml` and add the release to `CHANGELOG.md`.
2. Run `flutter pub get --enforce-lockfile` with Flutter 3.38.3.
3. Run `git diff --check`.
4. Run `flutter analyze --no-pub lib test`.
5. Run `flutter test --no-pub`.
6. Run `flutter build apk --release --no-pub`.
7. Confirm the APK contains no unexpected permissions or proprietary barcode
   libraries.
8. Audit the complete public Git history with Gitleaks.
9. Tag the exact release commit and push `main` plus the tag.
10. Replace the build `commit` in fdroiddata metadata with the full tagged
    commit hash, then validate with:
    `fdroid readmeta`, `fdroid rewritemeta`, `fdroid checkupdates`,
    `fdroid lint` and `fdroid build -v -l`.

## Future updates

F-Droid's `UpdateCheckMode: Tags` reads the version and build number from
`pubspec.yaml`. A new stable tag lets the update bot propose the next build.
If Flutter changes, update CI, `.metadata`, `.fdroid.yml` and `pubspec.lock`
together and test the F-Droid recipe before tagging.
