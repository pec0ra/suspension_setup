import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
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

    if (!await file.exists()) {
      return null;
    }
    try {
      final contents = await file.readAsString();
      final decoded = jsonDecode(contents) as Map<String, dynamic>;
      return decoded.map((key, value) =>
          MapEntry(key, Setup.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      throw SetupLoadException(
          'Could not load your setups — the file may be corrupt.', e);
    }
  }

  static Future<void> writeSetups(
      Map<String, Setup> setupMap, String filePath) async {
    final file = File(filePath);
    final jsonContents = jsonEncode(setupMap);
    // Write the file
    await file.writeAsString(jsonContents);
  }
}
