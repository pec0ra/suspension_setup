import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/setup_file_utils.dart';

class SetupStorageModel extends ChangeNotifier {
  final Map<String, Setup> _setupMap = {};
  SetupLoadException? loadError;

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
      loadError = e;
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

  Future<bool> saveBackupToDevice() async {
    String date = DateFormat("yyyy-MM-dd").format(DateTime.now());
    var fileName = "suspension-setup-$date.json";
    Uint8List fileContent = utf8.encode(SetupFileUtil.encodeSetups(_setupMap));

    String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Please select a backup file:',
        fileName: fileName,
        bytes: fileContent);

    if (outputFile == null) return false;
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      await SetupFileUtil.writeSetups(_setupMap, outputFile);
    }
    return true;
  }

  Future<void> shareBackup() async {
    String date = DateFormat("yyyy-MM-dd").format(DateTime.now());
    var fileName = "suspension-setup-$date.json";
    Uint8List fileContent = utf8.encode(SetupFileUtil.encodeSetups(_setupMap));

    final dir = await getTemporaryDirectory();
    final tempFile = File('${dir.path}/$fileName');
    await tempFile.writeAsBytes(fileContent);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path, mimeType: 'application/json')],
        subject: 'Suspension Setup backup',
      ),
    );
  }

  Future<bool> saveSetupToDevice(Setup setup) async {
    var fileName = _setupFileName(setup);
    Uint8List fileContent = utf8.encode(SetupFileUtil.encodeSetup(setup));

    String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Please select a file:',
        fileName: fileName,
        bytes: fileContent);

    if (outputFile == null) return false;
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      await SetupFileUtil.writeSetup(setup, outputFile);
    }
    return true;
  }

  Future<void> shareSetup(Setup setup) async {
    var fileName = _setupFileName(setup);
    Uint8List fileContent = utf8.encode(SetupFileUtil.encodeSetup(setup));

    final dir = await getTemporaryDirectory();
    final tempFile = File('${dir.path}/$fileName');
    await tempFile.writeAsBytes(fileContent);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(tempFile.path, mimeType: 'application/json')],
        subject: 'Suspension Setup \'${setup.name}\'',
      ),
    );
  }

  String _setupFileName(Setup setup) {
    String date = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final slug = setup.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty
        ? "suspension-setup-$date.json"
        : "suspension-setup-$slug-$date.json";
  }

  Future<String?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(
        type: FileType.custom, allowedExtensions: ['json']);
    return result?.files.single.path;
  }

  Future<ImportResult?> readImport(String filePath) {
    return SetupFileUtil.readImportFile(filePath);
  }

  Future<void> replaceAllWith(Map<String, Setup> setups) async {
    _setupMap
      ..clear()
      ..addAll(setups);
    await SetupFileUtil.writeSetups(
        _setupMap, await SetupFileUtil.defaultLocalFilePath);
    loadError = null;
    notifyListeners();
  }

  Future<void> importSetup(Setup setup) async {
    // Assign a fresh id (via clone) so an import can never overwrite an
    // existing setup; keep the full history.
    final imported = setup.clone(true);
    _setupMap[imported.id] = imported;
    await SetupFileUtil.writeSetups(
        _setupMap, await SetupFileUtil.defaultLocalFilePath);
    loadError = null;
    notifyListeners();
  }
}
