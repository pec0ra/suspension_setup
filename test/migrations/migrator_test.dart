import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/migrations/migrator.dart';

Map<String, dynamic> _v1Data() => {
      'id-1': {
        'id': 'id-1',
        'name': 'Test',
        'fork': {'airPressure': 100, 'sag': 25, 'lsc': 8, 'lsr': 6, 'volumeSpacer': null, 'hsc': null, 'hsr': null},
        'shock': {'airPressure': 180, 'sag': 30, 'lsc': 5, 'lsr': 4, 'volumeSpacer': null, 'hsc': null, 'hsr': null},
        'history': [],
      },
    };

Map<String, dynamic> _v2Data({List<dynamic> history = const []}) => {
      'schemaVersion': 2,
      'setups': {
        'id-1': {
          'id': 'id-1',
          'name': 'Test',
          'fork': {
            'airPressure': {'value': 100, 'unit': 'PSI'},
            'sag': {'value': 25, 'unit': '%'},
            'volumeSpacer': null,
            'lsc': {'value': 8, 'unit': 'Clicks'},
            'hsc': null,
            'lsr': {'value': 6, 'unit': 'Clicks'},
            'hsr': null,
          },
          'shock': {
            'airPressure': {'value': 180, 'unit': 'PSI'},
            'sag': {'value': 30, 'unit': '%'},
            'volumeSpacer': null,
            'lsc': {'value': 5, 'unit': 'Clicks'},
            'hsc': null,
            'lsr': {'value': 4, 'unit': 'Clicks'},
            'hsr': null,
          },
          'history': history,
        },
      },
    };

Map<String, dynamic> _v3Data() => {
      'schemaVersion': 3,
      'setups': {
        'id-1': {
          'id': 'id-1',
          'name': 'Test',
          'fork': {
            'airPressure': {'value': 100, 'unit': 'PSI'},
          },
          'shock': {},
          'history': [
            {'changes': [], 'date': '2024-01-01T00:00:00.000Z', 'comment': 'Setup creation', 'isCreationEntry': true},
          ],
        },
      },
    };

void main() {
  group('currentSchemaVersion', () {
    test('is 3', () => expect(currentSchemaVersion, 3));
  });

  group('migrateIfNeeded', () {
    test('migrates data with no schemaVersion (treated as v1)', () {
      final result = migrateIfNeeded(_v1Data());
      expect(result['schemaVersion'], 3);
      expect(result['setups'], isA<Map>());
    });

    test('migrates data with explicit schemaVersion 1', () {
      final data = {'schemaVersion': 1, ..._v1Data()};
      final result = migrateIfNeeded(data);
      expect(result['schemaVersion'], 3);
    });

    test('migrates v2 data to v3', () {
      final result = migrateIfNeeded(_v2Data());
      expect(result['schemaVersion'], 3);
      expect(result['setups']['id-1']['fork']['airPressure']['value'], 100);
    });

    test('does not re-migrate already-v3 data', () {
      final result = migrateIfNeeded(_v3Data());
      expect(result['schemaVersion'], 3);
      expect(result['setups']['id-1']['history'][0]['isCreationEntry'], true);
    });

    test('v2 to v3 sets isCreationEntry on first history entry', () {
      final v2 = _v2Data(history: [
        {'changes': [], 'date': '2024-01-01T00:00:00.000Z', 'comment': 'Setup creation'},
        {'changes': [], 'date': '2024-01-02T00:00:00.000Z', 'comment': 'Rebound tweak'},
      ]);
      final result = migrateIfNeeded(v2);
      final history = result['setups']['id-1']['history'] as List;
      expect(history[0]['isCreationEntry'], true);
      expect(history[1]['isCreationEntry'], isNull);
    });

    test('v2 to v3 leaves empty history unchanged', () {
      final result = migrateIfNeeded(_v2Data());
      final history = result['setups']['id-1']['history'] as List;
      expect(history, isEmpty);
    });

    test('returns future schema version data unchanged', () {
      final futureData = {'schemaVersion': 99, 'setups': {}, 'someNewKey': true};
      final result = migrateIfNeeded(futureData);
      expect(result['schemaVersion'], 99);
      expect(result['someNewKey'], true);
    });
  });
}