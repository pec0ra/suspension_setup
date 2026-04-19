import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/migrations/v1_to_v2.dart';
import 'package:suspension_setup/models/setting_change.dart';
import 'package:suspension_setup/models/settings.dart';

Map<String, dynamic> _v1Settings({
  int? airPressure = 100,
  int? sag = 25,
  int? lsc = 8,
  int? lsr = 6,
  int? volumeSpacer,
  int? hsc,
  int? hsr,
}) =>
    {
      'airPressure': airPressure,
      'sag': sag,
      'volumeSpacer': volumeSpacer,
      'lsc': lsc,
      'hsc': hsc,
      'lsr': lsr,
      'hsr': hsr,
    };

Map<String, dynamic> _v1Setup({
  String id = 'id-1',
  String name = 'Test Setup',
  Map<String, dynamic>? fork,
  Map<String, dynamic>? shock,
  List<dynamic> history = const [],
}) =>
    {
      'id': id,
      'name': name,
      'fork': fork ?? _v1Settings(),
      'shock': shock ?? _v1Settings(),
      'history': history,
    };

Map<String, dynamic> _v1Data([Map<String, dynamic>? setup]) =>
    {'id-1': setup ?? _v1Setup()};

void main() {
  group('migrateV1ToV2 — output structure', () {
    test('wraps setups under schemaVersion and setups keys', () {
      final result = migrateV1ToV2(_v1Data());
      expect(result['schemaVersion'], 2);
      expect(result['setups'], isA<Map>());
    });

    test('empty v1 data produces empty setups map', () {
      final result = migrateV1ToV2({});
      expect(result['setups'], isEmpty);
    });

    test('preserves setup id as map key', () {
      final result = migrateV1ToV2({'my-id': _v1Setup(id: 'my-id')});
      expect(result['setups'], contains('my-id'));
    });

    test('preserves setup id field inside setup', () {
      final setup = migrateV1ToV2(_v1Data())['setups']['id-1'];
      expect(setup['id'], 'id-1');
    });

    test('preserves setup name', () {
      final data = {'id-1': _v1Setup(name: 'Enduro Race')};
      final setup = migrateV1ToV2(data)['setups']['id-1'];
      expect(setup['name'], 'Enduro Race');
    });

    test('preserves history entries unchanged', () {
      final history = [
        {'date': '2024-01-01T00:00:00.000Z', 'changes': [], 'comment': 'initial'},
      ];
      final data = {'id-1': _v1Setup(history: history)};
      final setup = migrateV1ToV2(data)['setups']['id-1'];
      expect(setup['history'], hasLength(1));
      expect(setup['history'][0]['comment'], 'initial');
    });

    test('migrates multiple setups independently', () {
      final data = {
        'id-1': _v1Setup(id: 'id-1', name: 'DH'),
        'id-2': _v1Setup(id: 'id-2', name: 'XC'),
      };
      final result = migrateV1ToV2(data)['setups'] as Map;
      expect(result.keys, containsAll(['id-1', 'id-2']));
      expect(result['id-1']['name'], 'DH');
      expect(result['id-2']['name'], 'XC');
    });
  });

  group('migrateV1ToV2 — enabled fields', () {
    test('non-null field becomes {value, unit} object', () {
      final fork = migrateV1ToV2(_v1Data())['setups']['id-1']['fork'];
      expect(fork['airPressure'], isA<Map>());
      expect(fork['airPressure']['value'], 100);
    });

    test('null field remains null', () {
      final fork = migrateV1ToV2(_v1Data())['setups']['id-1']['fork'];
      expect(fork['volumeSpacer'], isNull);
      expect(fork['hsc'], isNull);
      expect(fork['hsr'], isNull);
    });

    test('field with value 0 is treated as enabled', () {
      final data = {'id-1': _v1Setup(fork: _v1Settings(airPressure: 0))};
      final fork = migrateV1ToV2(data)['setups']['id-1']['fork'];
      expect(fork['airPressure']['value'], 0);
    });

    test('fork and shock are migrated independently', () {
      final data = {
        'id-1': _v1Setup(
          fork: _v1Settings(airPressure: 110, hsc: 5),
          shock: _v1Settings(airPressure: 200, hsc: null),
        ),
      };
      final setup = migrateV1ToV2(data)['setups']['id-1'];
      expect(setup['fork']['airPressure']['value'], 110);
      expect(setup['fork']['hsc']['value'], 5);
      expect(setup['shock']['airPressure']['value'], 200);
      expect(setup['shock']['hsc'], isNull);
    });

    test('all fields null produces all-null settings', () {
      final data = {
        'id-1': _v1Setup(
          fork: _v1Settings(
            airPressure: null,
            sag: null,
            lsc: null,
            lsr: null,
          ),
        ),
      };
      final fork = migrateV1ToV2(data)['setups']['id-1']['fork'];
      for (final key in ['airPressure', 'sag', 'lsc', 'lsr', 'hsc', 'hsr', 'volumeSpacer']) {
        expect(fork[key], isNull, reason: '$key should be null');
      }
    });
  });

  group('migrateV1ToV2 — default units', () {
    late Map<String, dynamic> fork;

    setUp(() {
      final data = {
        'id-1': _v1Setup(
          fork: _v1Settings(
            airPressure: 100,
            sag: 25,
            lsc: 8,
            lsr: 6,
            volumeSpacer: 3,
            hsc: 4,
            hsr: 2,
          ),
        ),
      };
      fork = migrateV1ToV2(data)['setups']['id-1']['fork'];
    });

    test('airPressure unit is PSI', () {
      expect(fork['airPressure']['unit'], Settings.defaultUnits[SettingType.airPressure]);
    });

    test('sag unit is %', () {
      expect(fork['sag']['unit'], Settings.defaultUnits[SettingType.sag]);
    });

    test('volumeSpacer unit is Spacers', () {
      expect(fork['volumeSpacer']['unit'], Settings.defaultUnits[SettingType.volumeSpacer]);
    });

    test('lsc unit is Clicks', () {
      expect(fork['lsc']['unit'], Settings.defaultUnits[SettingType.lsc]);
    });

    test('hsc unit is Clicks', () {
      expect(fork['hsc']['unit'], Settings.defaultUnits[SettingType.hsc]);
    });

    test('lsr unit is Clicks', () {
      expect(fork['lsr']['unit'], Settings.defaultUnits[SettingType.lsr]);
    });

    test('hsr unit is Clicks', () {
      expect(fork['hsr']['unit'], Settings.defaultUnits[SettingType.hsr]);
    });

    test('null field has no unit', () {
      final data = {'id-1': _v1Setup(fork: _v1Settings(hsc: null))};
      final f = migrateV1ToV2(data)['setups']['id-1']['fork'];
      expect(f['hsc'], isNull);
    });
  });
}