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
  final Map<String, Setup> setupMap = {};

  UnmodifiableListView<Setup> getSetupList() {
    return UnmodifiableListView(setupMap.values);
  }

  Setup? getSetup(String id) {
    return setupMap[id];
  }

  Future<void> initSetups() async {
    var setupsFromFile = await SetupFileUtil.readSetups(
        await SetupFileUtil.defaultLocalFilePath);
    setupMap.clear();
    if (setupsFromFile != null) {
      setupMap.addAll(setupsFromFile);
    }
    notifyListeners();
  }

  void upsertSetup(Setup setup) async {
    setupMap[setup.id] = setup;
    await SetupFileUtil.writeSetups(
        setupMap, await SetupFileUtil.defaultLocalFilePath);
    notifyListeners();
  }

  void deleteSetup(Setup setup) async {
    setupMap.remove(setup.id);
    await SetupFileUtil.writeSetups(
        setupMap, await SetupFileUtil.defaultLocalFilePath);
    notifyListeners();
  }

  Future<bool> backup() async {
    String date = DateFormat("yyyy-MM-dd").format(DateTime.now());
    var fileName = "suspension-setup-$date.json";
    Uint8List fileContent = stringToUint8List(jsonEncode(setupMap));
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select a backup file:',
      fileName: fileName,
      bytes: fileContent
    );

    if (outputFile == null) {
      return false;
      // User canceled the picker
    }
    if (!Platform.isAndroid && !Platform.isIOS) {
      await SetupFileUtil.writeSetups(setupMap, outputFile);
    }
    return true;
  }

  Uint8List stringToUint8List(String data) {
    // Convert string to bytes (List<int>)
    List<int> encoded = utf8.encode(data);

    // Convert List<int> to Uint8List
    Uint8List uint8List = Uint8List.fromList(encoded);

    return uint8List;
  }

  Future<bool> restore() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);

    if (result != null) {
      String filePath = result.files.single.path!;
      var setupsFromFile = await SetupFileUtil.readSetups(filePath);
      if (setupsFromFile != null) {
        setupMap.addAll(setupsFromFile);
        await SetupFileUtil.writeSetups(
            setupMap, await SetupFileUtil.defaultLocalFilePath);
        notifyListeners();
      }
      return true;
    } else {
      return false;
    }
  }
}
