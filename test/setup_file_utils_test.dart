import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/setup_file_utils.dart';

Setup _makeSetup(String id, String name) {
  return Setup(
    id: id,
    name: name,
    fork: Settings(airPressure: 100, sag: 25, lsc: 8, lsr: 6),
    shock: Settings(airPressure: 180, sag: 30, lsc: 5, lsr: 4),
    history: [],
  );
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('suspension_setup_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('SetupFileUtil.readSetups', () {
    test('returns null for non-existent file', () async {
      final result =
          await SetupFileUtil.readSetups('${tempDir.path}/nonexistent.json');
      expect(result, isNull);
    });

    test('reads and parses valid setup file', () async {
      final setup = _makeSetup('id-1', 'Trail setup');
      final filePath = '${tempDir.path}/setups.json';
      await SetupFileUtil.writeSetups({'id-1': setup}, filePath);

      final result = await SetupFileUtil.readSetups(filePath);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result['id-1']?.name, 'Trail setup');
      expect(result['id-1']?.fork.airPressure, 100);
    });

    test('roundtrip preserves multiple setups', () async {
      final setups = {
        'id-1': _makeSetup('id-1', 'DH setup'),
        'id-2': _makeSetup('id-2', 'XC setup'),
      };
      final filePath = '${tempDir.path}/setups.json';
      await SetupFileUtil.writeSetups(setups, filePath);

      final result = await SetupFileUtil.readSetups(filePath);

      expect(result!.keys, containsAll(['id-1', 'id-2']));
      expect(result['id-2']?.name, 'XC setup');
    });

    test('throws SetupLoadException for corrupt JSON', () async {
      final filePath = '${tempDir.path}/corrupt.json';
      await File(filePath).writeAsString('not valid json {{{{');

      expect(
        () => SetupFileUtil.readSetups(filePath),
        throwsA(isA<SetupLoadException>()),
      );
    });

    test('throws SetupLoadException when JSON root is not an object', () async {
      final filePath = '${tempDir.path}/array.json';
      await File(filePath).writeAsString(jsonEncode([1, 2, 3]));

      expect(
        () => SetupFileUtil.readSetups(filePath),
        throwsA(isA<SetupLoadException>()),
      );
    });
  });
}