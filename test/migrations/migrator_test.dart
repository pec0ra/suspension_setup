import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/migrations/migrator.dart';

Map<String, dynamic> _v1Data() => {
      'id-1': {
        'id': 'id-1',
        'name': 'Test',
        'fork': {
          'airPressure': 100,
          'sag': 25,
          'lsc': 8,
          'lsr': 6,
          'volumeSpacer': null,
          'hsc': null,
          'hsr': null
        },
        'shock': {
          'airPressure': 180,
          'sag': 30,
          'lsc': 5,
          'lsr': 4,
          'volumeSpacer': null,
          'hsc': null,
          'hsr': null
        },
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
            'sag': null,
            'volumeSpacer': null,
            'lsc': null,
            'hsc': null,
            'lsr': null,
            'hsr': null,
          },
          'shock': <String, dynamic>{},
          'history': [
            {
              'id': 'hist-id-1',
              'changes': [],
              'date': '2024-01-01T00:00:00.000Z',
              'comment': 'Setup creation',
              'isCreationEntry': true
            },
          ],
        },
      },
    };

Map<String, dynamic> _v4Data() => {
      'schemaVersion': 4,
      'setups': {
        'id-1': {
          'id': 'id-1',
          'name': 'Test',
          'fork': {
            'fields': [
              {
                'id': 'field-id-1',
                'name': 'Air Pressure',
                'unit': 'PSI',
                'value': 100,
                'deleted': false,
              },
            ],
            'layout': [
              ['field-id-1']
            ],
            'serialNumber': null,
            'infoUrl': null,
          },
          'shock': {
            'fields': [],
            'layout': [],
            'serialNumber': null,
            'infoUrl': null,
          },
          'tyres': {
            'fields': [],
            'layout': [],
            'serialNumber': null,
            'infoUrl': null,
          },
          'history': [
            {
              'id': 'hist-id-1',
              'changes': [],
              'date': '2024-01-01T00:00:00.000Z',
              'comment': 'Setup creation',
              'isCreationEntry': true,
            },
          ],
        },
      },
    };

void main() {
  group('currentSchemaVersion', () {
    test('is 4', () => expect(currentSchemaVersion, 4));
  });

  group('migrateIfNeeded', () {
    test('migrates data with no schemaVersion (treated as v1)', () {
      final result = migrateIfNeeded(_v1Data());
      expect(result['schemaVersion'], 4);
      expect(result['setups'], isA<Map>());
    });

    test('migrates data with explicit schemaVersion 1', () {
      final data = {'schemaVersion': 1, ..._v1Data()};
      final result = migrateIfNeeded(data);
      expect(result['schemaVersion'], 4);
    });

    test('migrates v2 data to v4', () {
      final result = migrateIfNeeded(_v2Data());
      expect(result['schemaVersion'], 4);
      final fork = result['setups']['id-1']['fork'] as Map;
      final fields = fork['fields'] as List;
      expect(
          fields.any((f) => f['name'] == 'Air Pressure' && f['value'] == 100),
          isTrue);
    });

    test('migrates v3 data to v4', () {
      final result = migrateIfNeeded(_v3Data());
      expect(result['schemaVersion'], 4);
      final fork = result['setups']['id-1']['fork'] as Map;
      expect(fork['fields'], isA<List>());
      expect(fork['layout'], isA<List>());
    });

    test('does not re-migrate already-v4 data', () {
      final result = migrateIfNeeded(_v4Data());
      expect(result['schemaVersion'], 4);
      expect(result['setups']['id-1']['history'][0]['isCreationEntry'], true);
    });

    test('v1 → v4 preserves history creation entry', () {
      final v1 = {
        'id-1': {
          'id': 'id-1',
          'name': 'Test',
          'fork': {
            'airPressure': 100,
            'sag': 25,
            'lsc': 8,
            'lsr': 6,
            'volumeSpacer': null,
            'hsc': null,
            'hsr': null
          },
          'shock': {
            'airPressure': 180,
            'sag': 30,
            'lsc': 5,
            'lsr': 4,
            'volumeSpacer': null,
            'hsc': null,
            'hsr': null
          },
          'history': [
            {
              'changes': [],
              'date': '2024-01-01T00:00:00.000Z',
              'comment': 'Setup creation'
            },
          ],
        },
      };
      final result = migrateIfNeeded(v1);
      final history = result['setups']['id-1']['history'] as List;
      expect(history[0]['isCreationEntry'], true);
    });

    test('returns future schema version data unchanged', () {
      final futureData = {
        'schemaVersion': 99,
        'setups': {},
        'someNewKey': true
      };
      final result = migrateIfNeeded(futureData);
      expect(result['schemaVersion'], 99);
      expect(result['someNewKey'], true);
    });
  });
}
