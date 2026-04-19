import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:suspension_setup/migrations/migrator.dart';
import 'package:suspension_setup/models/setup.dart';

class SetupLoadException implements Exception {
  final String message;
  final Object cause;
  SetupLoadException(this.message, this.cause);
  @override
  String toString() => message;
}

class SetupFileUtil {
  static Future<String> get defaultLocalFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/setups.json';
  }

  static Future<Map<String, Setup>?> readSetups(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;
    try {
      final contents = await file.readAsString();
      var decoded = jsonDecode(contents) as Map<String, dynamic>;
      final needsMigration = (decoded['schemaVersion'] as int? ?? 1) < currentSchemaVersion;
      if (needsMigration) {
        decoded = migrateIfNeeded(decoded);
      }
      final setupsJson = decoded['setups'] as Map<String, dynamic>;
      final setups = setupsJson.map(
        (key, value) => MapEntry(key, Setup.fromJson(value as Map<String, dynamic>)),
      );
      if (needsMigration) {
        await writeSetups(setups, filePath);
      }
      return setups;
    } catch (e) {
      throw SetupLoadException(
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
}