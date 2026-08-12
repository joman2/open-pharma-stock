# Public Release Policy

This document defines the public release architecture of open-pharma-stock.

## Release Scope

`v0.2.1` is the first F-Droid release candidate.

The app is an early-stage inventory utility. It has not been validated for
regulated pharmacy operations and does not replace professional pharmacy
software. Do not use real pharmacy data in public issues, screenshots, logs,
sample backups, or other shared release evidence.

F-Droid builds and signs the Android package from the tagged source. A release
is not ready until the privacy review, metadata validation and Android release
build gates pass.

## Recommended Architecture

The public `main` branch contains release-ready Android source. CI detects
regressions after a push; release tags are created only after all gates pass.

## Tag Policy

Use stable `vMAJOR.MINOR.PATCH` tags only on commits where the release gates
pass.

Do not move published tags. Release notes should be derived from `CHANGELOG.md`.

## Artifact Policy

Do not commit screenshots, UI dumps, logs, APKs, backups, or exported inventory files unless a separate artifact policy explicitly allows the exact artifact type.

QA evidence should remain temporary, redacted, or attached as a synthetic release artifact rather than committed to the repository.

## Release Gates

Before tagging or publishing a release, the release commit must pass:

- `git diff --check`
- `flutter analyze --no-pub lib test`
- `flutter test --no-pub`

`pubspec.lock` must be generated with the exact Flutter version pinned for the
release and `flutter pub get --enforce-lockfile` must pass.

Also build a release APK and inspect it for unexpected permissions and
proprietary libraries. The complete public history must pass a secrets scan.

The full reusable procedure is in `docs/fdroid.md`.
