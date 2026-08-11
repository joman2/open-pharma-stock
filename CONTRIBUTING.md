# Contributing to OpenPharmaStock

Keep contributions focused on clarity, stability, and practical Android-first workflows.

## Local Setup

```bash
flutter pub get
flutter test
flutter run
```

Build an APK when the change justifies it:

```bash
flutter build apk --debug
```

## Working Rules

- Keep the project Android-first and avoid adding unused platform scaffolding.
- Prefer small, reviewable changes over process-heavy repository scaffolding.
- Extend existing seams before introducing new architecture.
- Keep documentation truthful to the current repository state.

## Validation

- Run `flutter test` for relevant code changes.
- Run `flutter analyze lib test` when applicable.
- Do not claim emulator or device validation unless you actually ran it.

## Bug Reports

Include:

- Android version
- Device or emulator details
- Steps to reproduce
- Expected behavior
- Actual behavior
- Relevant logs, screenshots, or dumps when available

Do not share real or sensitive pharmacy data in issues or logs.
