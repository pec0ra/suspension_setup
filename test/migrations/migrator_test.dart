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

Map<String, dynamic> _v2Data() => {
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
          'history': [],
        },
      },
    };

void main() {
  group('currentSchemaVersion', () {
    test('is 2', () => expect(currentSchemaVersion, 2));
  });

  group('migrateIfNeeded', () {
    test('migrates data with no schemaVersion (treated as v1)', () {
      final result = migrateIfNeeded(_v1Data());
      expect(result['schemaVersion'], 2);
      expect(result['setups'], isA<Map>());
    });

    test('migrates data with explicit schemaVersion 1', () {
      final data = {'schemaVersion': 1, ..._v1Data()};
      final result = migrateIfNeeded(data);
      expect(result['schemaVersion'], 2);
    });

    test('returns v2 data unchanged', () {
      final v2 = _v2Data();
      final result = migrateIfNeeded(v2);
      expect(result['schemaVersion'], 2);
      expect(result['setups']['id-1']['fork']['airPressure']['value'], 100);
    });

    test('does not re-migrate already-v2 data', () {
      final v2 = _v2Data();
      final result = migrateIfNeeded(v2);
      // The fork airPressure should still be the v2 field object, not double-wrapped
      expect(result['setups']['id-1']['fork']['airPressure'], isA<Map>());
      expect(result['setups']['id-1']['fork']['airPressure']['value'], 100);
      expect(result['setups']['id-1']['fork']['airPressure']['unit'], 'PSI');
    });

    test('returns future schema version data unchanged', () {
      final futureData = {'schemaVersion': 99, 'setups': {}, 'someNewKey': true};
      final result = migrateIfNeeded(futureData);
      expect(result['schemaVersion'], 99);
      expect(result['someNewKey'], true);
    });
  });
}