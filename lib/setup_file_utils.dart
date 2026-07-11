import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:suspension_setup/migrations/migrator.dart';
import 'package:suspension_setup/models/setup.dart';

sealed class SetupLoadException implements Exception {
  String get message;
  @override
  String toString() => message;
}

class SetupCorruptFileException extends SetupLoadException {
  @override
  final String message;
  final Object cause;
  SetupCorruptFileException(this.message, this.cause);
}

class SetupVersionTooNewException extends SetupLoadException {
  @override
  String get message =>
      'Your setups were saved with a newer version of the app. Please update the app to open them.';
}

/// The two shapes a file picked for import can hold: a full backup (a map of
/// setups) or a single shared setup.
sealed class ImportResult {}

class BackupImport extends ImportResult {
  final Map<String, Setup> setups;
  BackupImport(this.setups);
}

class SingleSetupImport extends ImportResult {
  final Setup setup;
  SingleSetupImport(this.setup);
}

class SetupFileUtil {
  static Future<String> get defaultLocalFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/setups.json';
  }

  static Future<Map<String, Setup>?> readSetups(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    Map<String, dynamic> decoded;
    try {
      final contents = await file.readAsString();
      decoded = jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      throw SetupCorruptFileException(
          'Could not load your setups — the file may be corrupt.', e);
    }

    final version = decoded['schemaVersion'] as int? ?? 1;
    if (version > currentSchemaVersion) {
      throw SetupVersionTooNewException();
    }

    try {
      final needsMigration = version < currentSchemaVersion;
      if (needsMigration) {
        decoded = migrateIfNeeded(decoded);
      }
      final setupsJson = decoded['setups'] as Map<String, dynamic>;
      final setups = setupsJson.map(
        (key, value) =>
            MapEntry(key, Setup.fromJson(value as Map<String, dynamic>)),
      );
      if (needsMigration) {
        await writeSetups(setups, filePath);
      }
      return setups;
    } catch (e) {
      throw SetupCorruptFileException(
          'Could not load your setups — the file may be corrupt.', e);
    }
  }

  static Future<void> writeSetups(
      Map<String, Setup> setupMap, String filePath) async {
    final file = File(filePath);
    await file.writeAsString(encodeSetups(setupMap));
  }

  static String encodeSetups(Map<String, Setup> setupMap) {
    return jsonEncode({
      'schemaVersion': currentSchemaVersion,
      'setups': setupMap.map((k, v) => MapEntry(k, v.toJson())),
    });
  }

  static Future<void> writeSetup(Setup setup, String filePath) async {
    final file = File(filePath);
    await file.writeAsString(encodeSetup(setup));
  }

  static String encodeSetup(Setup setup) {
    return jsonEncode({
      'schemaVersion': currentSchemaVersion,
      'setup': setup.toJson(),
    });
  }

  /// Reads a file picked for import, detecting whether it is a full backup
  /// (a `setups` map) or a single shared setup (a `setup` object). Parses in
  /// memory only — unlike [readSetups] it never writes migrated data back to
  /// the source file.
  static Future<ImportResult?> readImportFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    Map<String, dynamic> decoded;
    try {
      final contents = await file.readAsString();
      decoded = jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      throw SetupCorruptFileException(
          'Could not load the file — it may be corrupt.', e);
    }

    final version = decoded['schemaVersion'] as int? ?? 1;
    if (version > currentSchemaVersion) {
      throw SetupVersionTooNewException();
    }

    try {
      if (decoded.containsKey('setup')) {
        // Single-setup share: wrap into a one-entry setups map so the existing
        // migrator runs unchanged, then extract the single setup.
        final wrapped = <String, dynamic>{
          'schemaVersion': version,
          'setups': {'_': decoded['setup']},
        };
        final migrated = migrateIfNeeded(wrapped);
        final setupsJson = migrated['setups'] as Map<String, dynamic>;
        final setup = Setup.fromJson(setupsJson['_'] as Map<String, dynamic>);
        return SingleSetupImport(setup);
      } else if (decoded.containsKey('setups')) {
        final migrated = migrateIfNeeded(decoded);
        final setupsJson = migrated['setups'] as Map<String, dynamic>;
        final setups = setupsJson.map(
          (key, value) =>
              MapEntry(key, Setup.fromJson(value as Map<String, dynamic>)),
        );
        return BackupImport(setups);
      } else {
        throw const FormatException('No setup or setups key');
      }
    } catch (e) {
      throw SetupCorruptFileException(
          'Could not load the file — it may be corrupt.', e);
    }
  }
}
