import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/migrations/v2_to_v3.dart';

Map<String, dynamic> _v2History({
  String date = '2024-01-01T00:00:00.000Z',
  String? comment,
  List<dynamic> changes = const [],
}) =>
    {
      'date': date,
      'comment': comment,
      'changes': changes,
    };

Map<String, dynamic> _v2Setup({
  String id = 'id-1',
  String name = 'Test Setup',
  List<dynamic> history = const [],
}) =>
    {
      'id': id,
      'name': name,
      'fork': {'airPressure': null},
      'shock': {'airPressure': null},
      'history': history,
    };

Map<String, dynamic> _v2Data([Map<String, dynamic>? setup]) => {
      'schemaVersion': 2,
      'setups': {'id-1': setup ?? _v2Setup()},
    };

void main() {
  group('migrateV2ToV3 — output structure', () {
    test('bumps schemaVersion to 3', () {
      final result = migrateV2ToV3(_v2Data());
      expect(result['schemaVersion'], 3);
    });

    test('preserves setups map key', () {
      final result = migrateV2ToV3({'schemaVersion': 2, 'setups': {'my-id': _v2Setup(id: 'my-id')}});
      expect(result['setups'], contains('my-id'));
    });

    test('preserves setup name', () {
      final data = _v2Data(_v2Setup(name: 'Enduro Race'));
      final setup = migrateV2ToV3(data)['setups']['id-1'];
      expect(setup['name'], 'Enduro Race');
    });

    test('empty v2 setups map produces empty setups map', () {
      final result = migrateV2ToV3({'schemaVersion': 2, 'setups': {}});
      expect(result['setups'], isEmpty);
    });

    test('migrates multiple setups independently', () {
      final data = {
        'schemaVersion': 2,
        'setups': {
          'id-1': _v2Setup(id: 'id-1', name: 'DH', history: [_v2History()]),
          'id-2': _v2Setup(id: 'id-2', name: 'XC', history: [_v2History()]),
        },
      };
      final result = migrateV2ToV3(data)['setups'] as Map;
      expect(result['id-1']['name'], 'DH');
      expect(result['id-2']['name'], 'XC');
      expect(result['id-1']['history'][0]['isCreationEntry'], true);
      expect(result['id-2']['history'][0]['isCreationEntry'], true);
    });
  });

  group('migrateV2ToV3 — isCreationEntry flag', () {
    test('sets isCreationEntry on first history entry', () {
      final data = _v2Data(_v2Setup(history: [_v2History()]));
      final history = migrateV2ToV3(data)['setups']['id-1']['history'] as List;
      expect(history[0]['isCreationEntry'], true);
    });

    test('does not set isCreationEntry on subsequent entries', () {
      final data = _v2Data(_v2Setup(history: [
        _v2History(date: '2024-01-01T00:00:00.000Z', comment: 'Setup creation'),
        _v2History(date: '2024-01-02T00:00:00.000Z', comment: 'Rebound tweak'),
        _v2History(date: '2024-01-03T00:00:00.000Z', comment: 'Air pressure'),
      ]));
      final history = migrateV2ToV3(data)['setups']['id-1']['history'] as List;
      expect(history[0]['isCreationEntry'], true);
      expect(history[1]['isCreationEntry'], isNull);
      expect(history[2]['isCreationEntry'], isNull);
    });

    test('empty history is left unchanged', () {
      final data = _v2Data(_v2Setup(history: []));
      final history = migrateV2ToV3(data)['setups']['id-1']['history'] as List;
      expect(history, isEmpty);
    });
  });

  group('migrateV2ToV3 — preserves history entry fields', () {
    test('preserves date on first entry', () {
      final data = _v2Data(_v2Setup(history: [_v2History(date: '2024-06-15T10:30:00.000Z')]));
      final entry = migrateV2ToV3(data)['setups']['id-1']['history'][0];
      expect(entry['date'], '2024-06-15T10:30:00.000Z');
    });

    test('preserves comment on first entry', () {
      final data = _v2Data(_v2Setup(history: [_v2History(comment: 'Setup creation')]));
      final entry = migrateV2ToV3(data)['setups']['id-1']['history'][0];
      expect(entry['comment'], 'Setup creation');
    });

    test('preserves changes list on first entry', () {
      final changes = [
        {'settingType': 'airPressure', 'suspensionType': 'fork', 'oldValue': 100, 'newValue': 110},
      ];
      final data = _v2Data(_v2Setup(history: [_v2History(changes: changes)]));
      final entry = migrateV2ToV3(data)['setups']['id-1']['history'][0];
      expect(entry['changes'], hasLength(1));
      expect(entry['changes'][0]['newValue'], 110);
    });

    test('preserves all fields on subsequent entries', () {
      final data = _v2Data(_v2Setup(history: [
        _v2History(date: '2024-01-01T00:00:00.000Z'),
        _v2History(date: '2024-01-02T00:00:00.000Z', comment: 'Rebound tweak'),
      ]));
      final second = migrateV2ToV3(data)['setups']['id-1']['history'][1];
      expect(second['date'], '2024-01-02T00:00:00.000Z');
      expect(second['comment'], 'Rebound tweak');
    });
  });
}