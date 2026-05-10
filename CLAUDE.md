# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Suspension Setup** is a Flutter mobile app for mountain bike riders to track suspension settings and their change history. It targets Android, iOS, web, and desktop platforms.

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Lint (flutter_lints)
flutter test             # Run tests
flutter run              # Run on connected device/emulator
flutter build apk        # Android APK
flutter build web        # Web build
flutter gen-l10n         # Regenerate localizations (intl)
dart fix --apply         # Apply automated Dart fixes
dart format .            # Format all Dart files (enforces trailing newlines, etc.)
```

To regenerate icons/splash after editing their config files:
```bash
flutter pub run flutter_launcher_icons:main
flutter pub run flutter_native_splash:create
```

## Design

The app follows **Material 3** guidelines and best practices. When building or modifying UI:
- Use M3 components (`FilledButton`, `Card`, `NavigationBar`, etc.) over their M2 equivalents
- Use color roles from `Theme.of(context).colorScheme` (e.g. `surfaceContainerHigh`, `onSurfaceVariant`) rather than hardcoded colors
- Refer to [material.io/design](https://material.io/design) for component behavior and spacing guidance

## Architecture

The app uses **Provider** for state management with a simple single-file-on-disk persistence model.

**State layer** — `SetupStorageModel` (`lib/setup_storage_model.dart`) is the single `ChangeNotifier` injected at the root. It holds an in-memory `Map<String, Setup>` and delegates all file I/O to `SetupFileUtil`. Backup/restore uses `file_picker` to import/export the same JSON file.

**Persistence** — `SetupFileUtil` (`lib/setup_file_utils.dart`) reads/writes a single `setups.json` in the platform documents directory. All models have `toJson`/`fromJson` factory methods.

**Data models** (`lib/models/`):
- `Setup` — top-level entity: fork `Settings`, shock `Settings`, and a `List<SettingChanges>` history
- `Settings` — suspension parameters (airPressure, sag, volumeSpacer, LSC/HSC/LSR/HSR clicks); some are nullable (volumeSpacer, HSC, HSR are optional)
- `SettingChange` / `SettingChanges` — delta objects capturing before/after values per parameter; one `SettingChanges` groups all changes in a single save event
- `SetupFormController` — wraps `TextEditingController` instances for the edit form; compared against the original `Setup` on save to produce `SettingChange` deltas

**Navigation flow**: `HomePage` → `SetupDetail` (view + history) or `SetupEdit` (create/edit). Edit computes a diff on save, appends a `SettingChanges` to the setup history, then calls `SetupStorageModel.upsert()`.

**Custom assets**: `fonts/SuspensionIcons.ttf` with constants in `lib/suspension_icons.dart`; `assets/icon/icon-white.svg` used in the AppBar.
