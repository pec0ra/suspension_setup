import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:suspension_setup/models/setup.dart';

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
    // Read the file
    final contents = await file.readAsString();

    var map = jsonDecode(contents).map((key, value) =>
        MapEntry<String, Setup>(key as String, Setup.fromJson(value)));
    Map<String, Setup> setupMap = Map<String, Setup>.from(map);
    return setupMap;
  }

  static Future<void> writeSetups(
      Map<String, Setup> setupMap, String filePath) async {
    final file = File(filePath);
    final jsonContents = jsonEncode(setupMap);
    // Write the file
    await file.writeAsString(jsonContents);
  }
}
