import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/migrations/migrator.dart';
import 'package:suspension_setup/models/field.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/setup_file_utils.dart';

Setup _makeSetup(String id, String name) {
  final forkFields = [
    Field(name: 'Air Pressure', unit: 'PSI', value: 100),
    Field(name: 'Sag', unit: '%', value: 25),
    Field(name: 'Low Speed Compression', unit: 'Clicks', value: 8),
    Field(name: 'Low Speed Rebound', unit: 'Clicks', value: 6),
  ];
  final shockFields = [
    Field(name: 'Air Pressure', unit: 'PSI', value: 180),
    Field(name: 'Sag', unit: '%', value: 30),
    Field(name: 'Low Speed Compression', unit: 'Clicks', value: 5),
    Field(name: 'Low Speed Rebound', unit: 'Clicks', value: 4),
  ];
  return Setup(
    id: id,
    name: name,
    fork: SectionSettings(
      fields: forkFields,
      layout: [forkFields.map((f) => f.id).toList()],
    ),
    shock: SectionSettings(
      fields: shockFields,
      layout: [shockFields.map((f) => f.id).toList()],
    ),
    tyres: SectionSettings(fields: [], layout: []),
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
      expect(
        result['id-1']
            ?.fork
            .activeFields
            .firstWhere((f) => f.name == 'Air Pressure')
            .value,
        100,
      );
    });

    test('migrates v1 file to v4 on read', () async {
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
      final fork = result!['id-1']!.fork;
      expect(
        fork.activeFields.firstWhere((f) => f.name == 'Air Pressure').value,
        100,
      );
      expect(
        fork.activeFields.firstWhere((f) => f.name == 'Air Pressure').unit,
        'PSI',
      );
      // hsc was null in v1 so it should be deleted (not active)
      expect(
        fork.activeFields.any((f) => f.name == 'High Speed Compression'),
        isFalse,
      );

      // File should have been rewritten in v4 format
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

    test('throws SetupCorruptFileException for corrupt JSON', () async {
      final filePath = '${tempDir.path}/corrupt.json';
      await File(filePath).writeAsString('not valid json {{{{');

      expect(
        () => SetupFileUtil.readSetups(filePath),
        throwsA(isA<SetupCorruptFileException>()),
      );
    });

    test('throws SetupCorruptFileException when JSON root is not an object',
        () async {
      final filePath = '${tempDir.path}/array.json';
      await File(filePath).writeAsString(jsonEncode([1, 2, 3]));

      expect(
        () => SetupFileUtil.readSetups(filePath),
        throwsA(isA<SetupCorruptFileException>()),
      );
    });

    test(
        'throws SetupVersionTooNewException for file with future schema version',
        () async {
      final filePath = '${tempDir.path}/future.json';
      await File(filePath).writeAsString(jsonEncode({
        'schemaVersion': currentSchemaVersion + 1,
        'setups': {},
      }));

      expect(
        () => SetupFileUtil.readSetups(filePath),
        throwsA(isA<SetupVersionTooNewException>()),
      );
    });
  });

  group('SetupFileUtil.encodeSetup', () {
    test('wraps a single setup under the singular "setup" key', () {
      final encoded = SetupFileUtil.encodeSetup(_makeSetup('id-1', 'Trail'));
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['schemaVersion'], currentSchemaVersion);
      expect(decoded.containsKey('setup'), isTrue);
      expect(decoded.containsKey('setups'), isFalse);
      expect(decoded['setup']['name'], 'Trail');
    });
  });

  group('SetupFileUtil.readImportFile', () {
    test('returns null for non-existent file', () async {
      final result =
          await SetupFileUtil.readImportFile('${tempDir.path}/nope.json');
      expect(result, isNull);
    });

    test('returns SingleSetupImport for a share file', () async {
      final setup = _makeSetup('id-1', 'Enduro');
      final filePath = '${tempDir.path}/share.json';
      await SetupFileUtil.writeSetup(setup, filePath);

      final result = await SetupFileUtil.readImportFile(filePath);

      expect(result, isA<SingleSetupImport>());
      final imported = (result as SingleSetupImport).setup;
      expect(imported.name, 'Enduro');
      expect(
        imported.fork.activeFields
            .firstWhere((f) => f.name == 'Air Pressure')
            .value,
        100,
      );
    });

    test('returns BackupImport for a backup file', () async {
      final setups = {
        'id-1': _makeSetup('id-1', 'DH'),
        'id-2': _makeSetup('id-2', 'XC'),
      };
      final filePath = '${tempDir.path}/backup.json';
      await SetupFileUtil.writeSetups(setups, filePath);

      final result = await SetupFileUtil.readImportFile(filePath);

      expect(result, isA<BackupImport>());
      final imported = (result as BackupImport).setups;
      expect(imported.keys, containsAll(['id-1', 'id-2']));
      expect(imported['id-2']?.name, 'XC');
    });

    test('imports a v1 backup (no "setups" wrapper) via migration', () async {
      final filePath = '${tempDir.path}/v1backup.json';
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

      final result = await SetupFileUtil.readImportFile(filePath);

      expect(result, isA<BackupImport>());
      final setups = (result as BackupImport).setups;
      expect(setups['id-1']?.name, 'Old setup');
    });

    test('throws SetupCorruptFileException when neither key is present',
        () async {
      final filePath = '${tempDir.path}/unknown.json';
      await File(filePath).writeAsString(jsonEncode({
        'schemaVersion': currentSchemaVersion,
        'somethingElse': {},
      }));

      expect(
        () => SetupFileUtil.readImportFile(filePath),
        throwsA(isA<SetupCorruptFileException>()),
      );
    });

    test('throws SetupCorruptFileException for corrupt JSON', () async {
      final filePath = '${tempDir.path}/corrupt.json';
      await File(filePath).writeAsString('not valid json {{{{');

      expect(
        () => SetupFileUtil.readImportFile(filePath),
        throwsA(isA<SetupCorruptFileException>()),
      );
    });

    test('throws SetupVersionTooNewException for a future-version share',
        () async {
      final filePath = '${tempDir.path}/future_share.json';
      await File(filePath).writeAsString(jsonEncode({
        'schemaVersion': currentSchemaVersion + 1,
        'setup': _makeSetup('id-1', 'Trail').toJson(),
      }));

      expect(
        () => SetupFileUtil.readImportFile(filePath),
        throwsA(isA<SetupVersionTooNewException>()),
      );
    });
  });
}
