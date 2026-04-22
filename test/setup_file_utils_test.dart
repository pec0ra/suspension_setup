import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/migrations/migrator.dart';
import 'package:suspension_setup/models/field.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/models/tyres.dart';
import 'package:suspension_setup/setup_file_utils.dart';

Setup _makeSetup(String id, String name) {
  return Setup(
    id: id,
    name: name,
    fork: Settings(
      airPressure: const Field(value: 100, unit: 'PSI'),
      sag: const Field(value: 25, unit: '%'),
      lsc: const Field(value: 8, unit: 'Clicks'),
      lsr: const Field(value: 6, unit: 'Clicks'),
    ),
    shock: Settings(
      airPressure: const Field(value: 180, unit: 'PSI'),
      sag: const Field(value: 30, unit: '%'),
      lsc: const Field(value: 5, unit: 'Clicks'),
      lsr: const Field(value: 4, unit: 'Clicks'),
    ),
    tyres: Tyres(),
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

    test('reads and parses valid v2 setup file', () async {
      final setup = _makeSetup('id-1', 'Trail setup');
      final filePath = '${tempDir.path}/setups.json';
      await SetupFileUtil.writeSetups({'id-1': setup}, filePath);

      final result = await SetupFileUtil.readSetups(filePath);

      expect(result, isNotNull);
      expect(result!.length, 1);
      expect(result['id-1']?.name, 'Trail setup');
      expect(result['id-1']?.fork.airPressure?.value, 100);
    });

    test('migrates v1 file to v2 on read', () async {
      final filePath = '${tempDir.path}/v1setups.json';
      final v1Json = jsonEncode({
        'id-1': {
          'id': 'id-1',
          'name': 'Old setup',
          'fork': {
            'airPressure': 100,
            'sag': 25,
            'lsc': 8,
            'lsr': 6,
            'hsc': null,
            'hsr': null,
            'volumeSpacer': null,
          },
          'shock': {
            'airPressure': 180,
            'sag': 30,
            'lsc': 5,
            'lsr': 4,
            'hsc': null,
            'hsr': null,
            'volumeSpacer': null,
          },
          'history': [],
        },
      });
      await File(filePath).writeAsString(v1Json);

      final result = await SetupFileUtil.readSetups(filePath);

      expect(result, isNotNull);
      expect(result!['id-1']?.fork.airPressure?.value, 100);
      expect(result['id-1']?.fork.airPressure?.unit, 'PSI');
      expect(result['id-1']?.fork.hsc, isNull);

      // File should have been rewritten in v2 format
      final rewritten = jsonDecode(await File(filePath).readAsString());
      expect(rewritten['schemaVersion'], currentSchemaVersion);
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