import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/setup_file_utils.dart';

class SetupStorageModel extends ChangeNotifier {
  final Map<String, Setup> _setupMap = {};
  String? loadError;

  UnmodifiableListView<Setup> getSetupList() {
    return UnmodifiableListView(_setupMap.values);
  }

  Setup? getSetup(String id) {
    return _setupMap[id];
  }

  Future<void> initSetups() async {
    try {
      var setupsFromFile = await SetupFileUtil.readSetups(
          await SetupFileUtil.defaultLocalFilePath);
      _setupMap.clear();
      if (setupsFromFile != null) {
        _setupMap.addAll(setupsFromFile);
      }
    } on SetupLoadException catch (e) {
      loadError = e.message;
    }
    notifyListeners();
  }

  Future<void> upsertSetup(Setup setup) async {
    _setupMap[setup.id] = setup;
    await SetupFileUtil.writeSetups(
        _setupMap, await SetupFileUtil.defaultLocalFilePath);
    notifyListeners();
  }

  Future<void> deleteSetup(Setup setup) async {
    _setupMap.remove(setup.id);
    await SetupFileUtil.writeSetups(
        _setupMap, await SetupFileUtil.defaultLocalFilePath);
    notifyListeners();
  }

  Future<bool> backup() async {
    String date = DateFormat("yyyy-MM-dd").format(DateTime.now());
    var fileName = "suspension-setup-$date.json";
    Uint8List fileContent = utf8.encode(SetupFileUtil.encodeSetups(_setupMap));
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Please select a backup file:',
      fileName: fileName,
      bytes: fileContent
    );

    if (outputFile == null) {
      return false;
      // User canceled the picker
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      await SetupFileUtil.writeSetups(_setupMap, outputFile);
    }
    return true;
  }

  Future<String?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    return result?.files.single.path;
  }

  Future<void> restoreFromFile(String filePath) async {
    final setupsFromFile = await SetupFileUtil.readSetups(filePath);
    if (setupsFromFile != null) {
      _setupMap
        ..clear()
        ..addAll(setupsFromFile);
      await SetupFileUtil.writeSetups(
          _setupMap, await SetupFileUtil.defaultLocalFilePath);
      loadError = null;
      notifyListeners();
    }
  }
}
