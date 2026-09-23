# Flutter application

The application package lives here. Repository-level setup, architecture, data flow, limitations, and verification results are documented in the root [README](../README.md).

Common commands from this directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=dart_defines/dev.json
```

Runtime configuration is documented in `dart_defines/dev.example.json`. Copy it to `dart_defines/dev.json` and use private values; the latter is gitignored.
