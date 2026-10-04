# Areka Study

Areka Study is an offline-first Android learning app built with Flutter and Dart. It bundles its study material and keeps learner progress on the device, so the core learning features work without an account or network connection.

## Study material

The app combines a verified question bank with an additional Grade 10 Geography packet:

| Material | Units | Questions | Flashcards |
|---|---:|---:|---:|
| Original bank | 66 | 1,776 | 462 |
| Additional Geography packet | 8 | 48 | 64 |
| **Total** | **74** | **1,824** | **526** |

The original bank covers Biology, Chemistry, Citizenship / Civics, Economics, Geography, Health & Physical Education, History, Mathematics, and Physics. The Geography packet is based on *Geography Student Textbook, Grade 10*, Federal Democratic Republic of Ethiopia, Ministry of Education (2023), ISBN 978-99990-0-049-9. Its questions retain unit, section, printed-page, and PDF-page citations (PDF page = printed page + 6). The app and source data disclose the Unit 5 RDI category/label discrepancy on printed pages 141–142. The textbook PDFs are not included.

The bundled curriculum is `assets/data/curriculum.json`; its import summary is `assets/data/import-report.json`. `tools/import_curriculum.py` is an optional conversion utility that reads the earlier Kotlin curriculum sources and validated Geography JSON, then writes the bundled JSON and report. Its source directories can be set with `--legacy-data-dir` and `--geography-data-dir`. Ordinary builds use the bundled assets and do not run the importer or require those earlier source directories.

## Features and boundaries

The app includes searchable subject and unit navigation, offline study guides, multiple-choice quizzes with immediate feedback, written-response practice with model answers and self-assessment, quiz results and missed-question review, flashcards with recall ratings, local learner progress, activity-based achievements, and light/dark themes.

Google or Supabase sign-in, cloud sync, remote content refresh, and cross-device progress are not connected. The original leaderboard, streak and time-spent metrics, and full achievement system are not ported. The Android debug variant retains Flutter's standard Internet permission for development tooling; the app does not configure cloud authentication, remote sync, remote content, or app-side network calls.

## Build and test

Install Flutter stable and the Android SDK. This candidate was validated with Flutter 3.47.6 and Dart 3.13.5.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

To run Android lint:

```bash
cd android
./gradlew :app:lintDebug
```

The optional importer requires the earlier Kotlin source files and validated Geography JSON; it is not part of the normal build. See [Flutter installation guidance](https://docs.flutter.dev/install) for environment setup.

## Distribution readiness

The Android application ID is `com.areka.learning.areka_learning`; the current version is `1.0.0+1`. **No release signing configuration or release keystore is included, and no signed release APK has been built.** Release signing must be arranged privately by the project owner. Do not configure a release variant to use the debug key.

A debug APK was built only to validate the staged project. It is signed with Android's standard debug certificate and contains absolute workspace, Flutter SDK, and package-cache paths in Flutter debug metadata. It is a local-testing artifact only: it is not included in this source tree and must not be distributed as a public release.

## License and content rights

No `LICENSE` file or code/content license is included in this candidate. Confirm the rights to publish and redistribute the original question bank and textbook-derived material, and choose an appropriate project license, before making the repository public. Textbook references are retained in the app data; the textbook PDFs are not redistributed here.

## Validation in the staging copy

| Check | Result |
|---|---|
| `flutter pub get --offline` | Passed |
| Dart format check | Passed; 7 Dart files unchanged |
| `flutter analyze --no-pub` | Passed; no issues found |
| `flutter test --no-pub` | Passed; all 9 tests passed |
| Importer compile and `--help` | Passed |
| Android `:app:lintDebug` | Passed; Gradle notes that 9.8.0 is available above the pinned 9.3.1 wrapper, with Android Gradle Plugin/Kotlin migration deprecation notices |
| `flutter build apk --debug --no-pub` | Passed for local validation; debug-signed APK was 153,222,220 bytes and was removed from staging |
| Device smoke test | Not run; no Android device or emulator was attached (only the Linux desktop target was available) |
