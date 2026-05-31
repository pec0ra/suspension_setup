import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/models/field.dart';
import 'package:suspension_setup/models/setting_change.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';

void main() {
  group('Field', () {
    test('roundtrips a decimal value through JSON', () {
      final original = Field(name: 'Air Pressure', unit: 'PSI', value: 28.5);
      final restored = Field.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, 'Air Pressure');
      expect(restored.value, 28.5);
      expect(restored.unit, 'PSI');
      expect(restored.deleted, false);
    });

    test('roundtrips a deleted field through JSON', () {
      final original = Field(name: 'Sag', unit: '%', deleted: true);
      final restored = Field.fromJson(original.toJson());
      expect(restored.deleted, true);
      expect(restored.value, isNull);
    });

    test('legacy integer JSON parses as int (no coercion to double)', () {
      final restored = Field.fromJson(
          {'id': 'test-id', 'name': 'Air', 'unit': 'PSI', 'value': 100});
      expect(restored.value, 100);
      expect(restored.value, isA<int>());
    });

    test('copyWith updates fields and preserves id', () {
      final original = Field(name: 'Air', unit: 'PSI', value: 73);
      final updated = original.copyWith(value: 80, unit: 'bar');
      expect(updated.id, original.id);
      expect(updated.value, 80);
      expect(updated.unit, 'bar');
      expect(updated.name, 'Air');
    });

    test('copyWith clearValue nulls the value', () {
      final original = Field(name: 'Air', unit: 'PSI', value: 73);
      final cleared = original.copyWith(clearValue: true);
      expect(cleared.value, isNull);
    });
  });

  group('SectionSettings', () {
    test('roundtrips through JSON with active and deleted fields', () {
      final active = Field(name: 'Air Pressure', unit: 'PSI', value: 100);
      final deleted = Field(name: 'Sag', unit: '%', deleted: true);
      final section = SectionSettings(
        fields: [active, deleted],
        layout: [
          [active.id]
        ],
        serialNumber: 'SN-123',
        infoUrl: 'https://example.com',
      );
      final restored = SectionSettings.fromJson(section.toJson());
      expect(restored.fields, hasLength(2));
      expect(restored.activeFields.toList(), hasLength(1));
      expect(restored.activeFields.first.name, 'Air Pressure');
      expect(restored.serialNumber, 'SN-123');
      expect(restored.infoUrl, 'https://example.com');
      expect(restored.layout, [
        [active.id]
      ]);
    });

    test('hasAnyField true when there are active fields', () {
      final f = Field(name: 'Air', unit: 'PSI', value: 100);
      final section = SectionSettings(fields: [
        f
      ], layout: [
        [f.id]
      ]);
      expect(section.hasAnyField, isTrue);
    });

    test('hasAnyField false when all fields are deleted', () {
      final f = Field(name: 'Air', unit: 'PSI', deleted: true);
      final section = SectionSettings(fields: [f], layout: []);
      expect(section.hasAnyField, isFalse);
    });

    test('hasAnyField true when only serialNumber set', () {
      final section =
          SectionSettings(fields: [], layout: [], serialNumber: 'SN-123');
      expect(section.hasAnyField, isTrue);
    });

    test('hasAnyField false when empty', () {
      expect(SectionSettings(fields: [], layout: []).hasAnyField, isFalse);
    });

    test('fieldById returns field by id', () {
      final f = Field(name: 'Air', unit: 'PSI', value: 100);
      final section = SectionSettings(fields: [
        f
      ], layout: [
        [f.id]
      ]);
      expect(section.fieldById(f.id), isNotNull);
      expect(section.fieldById(f.id)!.name, 'Air');
    });

    test('fieldById returns null for unknown id', () {
      final section = SectionSettings(fields: [], layout: []);
      expect(section.fieldById('no-such-id'), isNull);
    });

    test('fieldById returns deleted fields too', () {
      final f = Field(name: 'Air', unit: 'PSI', deleted: true);
      final section = SectionSettings(fields: [f], layout: []);
      expect(section.fieldById(f.id), isNotNull);
    });

    test('clone produces independent copy', () {
      final f = Field(name: 'Air', unit: 'PSI', value: 100);
      final original = SectionSettings(fields: [
        f
      ], layout: [
        [f.id]
      ], serialNumber: 'SN-1');
      final clone = original.clone();
      clone.fields.add(Field(name: 'Sag', unit: '%', value: 25));
      expect(original.fields, hasLength(1));
    });
  });

  group('SettingChange', () {
    test('roundtrips through JSON', () {
      final change = SettingChange(
        suspensionType: SuspensionType.fork,
        fieldId: 'field-uuid-123',
        oldValue: 100,
        newValue: 120,
      );
      final restored = SettingChange.fromJson(change.toJson());
      expect(restored.suspensionType, SuspensionType.fork);
      expect(restored.fieldId, 'field-uuid-123');
      expect(restored.oldValue, 100);
      expect(restored.newValue, 120);
    });

    test('roundtrips decimal old/new values through JSON', () {
      final change = SettingChange(
        suspensionType: SuspensionType.tyre,
        fieldId: 'tyre-field-id',
        oldValue: 27.5,
        newValue: 28.25,
      );
      final restored = SettingChange.fromJson(change.toJson());
      expect(restored.oldValue, 27.5);
      expect(restored.newValue, 28.25);
    });

    test('roundtrips with null values', () {
      final change = SettingChange(
        suspensionType: SuspensionType.shock,
        fieldId: 'field-id',
        oldValue: null,
        newValue: null,
      );
      final restored = SettingChange.fromJson(change.toJson());
      expect(restored.oldValue, isNull);
      expect(restored.newValue, isNull);
    });

    test('roundtrips with enabled/disabled toggle', () {
      final change = SettingChange(
        suspensionType: SuspensionType.fork,
        fieldId: 'field-id',
        oldValue: null,
        newValue: 5,
        oldEnabled: false,
        newEnabled: true,
      );
      final restored = SettingChange.fromJson(change.toJson());
      expect(restored.oldEnabled, false);
      expect(restored.newEnabled, true);
      expect(restored.newValue, 5);
    });

    test('inverted swaps old/new', () {
      final change = SettingChange(
        suspensionType: SuspensionType.fork,
        fieldId: 'field-id',
        oldValue: 100,
        newValue: 120,
      );
      final inv = change.inverted();
      expect(inv.oldValue, 120);
      expect(inv.newValue, 100);
    });
  });

  group('SettingChanges', () {
    test('roundtrips through JSON preserving date and comment', () {
      final date = DateTime.utc(2024, 6, 15, 10, 30);
      final changes = SettingChanges(
        changes: [
          SettingChange(
            suspensionType: SuspensionType.fork,
            fieldId: 'field-id',
            oldValue: 25,
            newValue: 28,
          ),
        ],
        date: date,
        comment: 'Trail ride tuning',
      );
      final restored = SettingChanges.fromJson(changes.toJson());
      expect(restored.id, changes.id);
      expect(restored.date, date);
      expect(restored.comment, 'Trail ride tuning');
      expect(restored.changes, hasLength(1));
      expect(restored.changes.first.newValue, 28);
    });

    test('roundtrips with null comment', () {
      final changes = SettingChanges(
        changes: [],
        date: DateTime.now(),
        comment: null,
      );
      final restored = SettingChanges.fromJson(changes.toJson());
      expect(restored.comment, isNull);
    });
  });

  group('Setup', () {
    test('fromJson with null tyres falls back to empty section', () {
      final json = {
        'id': 'test-id',
        'name': 'Trail Setup',
        'fork': {
          'fields': [],
          'layout': [],
          'serialNumber': null,
          'infoUrl': null
        },
        'shock': {
          'fields': [],
          'layout': [],
          'serialNumber': null,
          'infoUrl': null
        },
        'tyres': null,
        'history': [],
      };
      final setup = Setup.fromJson(json);
      expect(setup.tyres.fields, isEmpty);
      expect(setup.tyres.layout, isEmpty);
    });

    test('roundtrips through JSON preserving all fields', () {
      final airField = Field(name: 'Air Pressure', unit: 'PSI', value: 110);
      final sagField = Field(name: 'Sag', unit: '%', value: 25);
      final original = Setup(
        id: 'test-id-123',
        name: 'Enduro race',
        fork: SectionSettings(
          fields: [airField, sagField],
          layout: [
            [airField.id, sagField.id]
          ],
        ),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [
          SettingChanges(
            changes: [],
            date: DateTime.utc(2024, 1, 1),
            comment: 'Setup creation',
            isCreationEntry: true,
          ),
        ],
      );
      final restored = Setup.fromJson(original.toJson());
      expect(restored.id, 'test-id-123');
      expect(restored.name, 'Enduro race');
      expect(
          restored.fork.activeFields
              .firstWhere((f) => f.name == 'Air Pressure')
              .value,
          110);
      expect(restored.history, hasLength(1));
      expect(restored.history.first.comment, 'Setup creation');
      expect(restored.history.first.isCreationEntry, isTrue);
    });

    test('clone with history produces independent copy with new id', () {
      final f = Field(name: 'Air Pressure', unit: 'PSI', value: 100);
      final original = Setup(
        id: 'original-id',
        name: 'Base setup',
        fork: SectionSettings(fields: [
          f
        ], layout: [
          [f.id]
        ]),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [
          SettingChanges(changes: [], date: DateTime.now(), comment: 'initial'),
        ],
      );
      final clone = original.clone(true);
      expect(clone.id, isNot('original-id'));
      expect(clone.name, 'Base setup');
      expect(clone.history, hasLength(1));
    });

    test('clone without history produces empty history', () {
      final f = Field(name: 'Air Pressure', unit: 'PSI', value: 100);
      final original = Setup(
        id: 'original-id',
        name: 'Base setup',
        fork: SectionSettings(fields: [
          f
        ], layout: [
          [f.id]
        ]),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [
          SettingChanges(changes: [], date: DateTime.now()),
        ],
      );
      final clone = original.clone(false);
      expect(clone.history, isEmpty);
    });

    test('copyMutable preserves history entry ids', () {
      final entry = SettingChanges(changes: [], date: DateTime.now());
      final f = Field(name: 'Air Pressure', unit: 'PSI', value: 100);
      final original = Setup(
        id: 'original-id',
        name: 'Test',
        fork: SectionSettings(fields: [
          f
        ], layout: [
          [f.id]
        ]),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [entry],
      );
      final copy = original.copyMutable();
      expect(copy.history.first.id, entry.id);
    });
  });

  group('computeUndo', () {
    late String airId;
    late String lscId;
    late String frontTyreId;

    late Setup Function({
      num forkAir,
      num forkLsc,
      num? frontTyre,
    }) makeSetup;

    setUp(() {
      airId = 'air-pressure-id';
      lscId = 'lsc-id';
      frontTyreId = 'front-tyre-id';

      makeSetup = ({num forkAir = 110, num forkLsc = 10, num? frontTyre}) {
        final airField =
            Field(id: airId, name: 'Air Pressure', unit: 'PSI', value: forkAir);
        final lscField =
            Field(id: lscId, name: 'LSC', unit: 'Clicks', value: forkLsc);
        final tyreField = frontTyre != null
            ? Field(
                id: frontTyreId,
                name: 'Front Tyre',
                unit: 'PSI',
                value: frontTyre)
            : Field(
                id: frontTyreId,
                name: 'Front Tyre',
                unit: 'PSI',
                deleted: true);

        return Setup(
          id: 'test',
          name: 'Test',
          fork: SectionSettings(
            fields: [airField, lscField],
            layout: [
              [airField.id, lscField.id]
            ],
          ),
          shock: SectionSettings(fields: [], layout: []),
          tyres: SectionSettings(
            fields: [tyreField],
            layout: frontTyre != null
                ? [
                    [tyreField.id]
                  ]
                : [],
          ),
          history: [],
        );
      };
    });

    test('returns undo change when value differs from old value', () {
      final setup = makeSetup(forkAir: 110);
      final entry = SettingChanges(
        changes: [
          SettingChange(
              suspensionType: SuspensionType.fork,
              fieldId: airId,
              oldValue: 100,
              newValue: 110)
        ],
        date: DateTime.now(),
      );
      final result = setup.computeUndo(entry);
      expect(result, hasLength(1));
      expect(result.first.fieldId, airId);
      expect(result.first.oldValue, 110);
      expect(result.first.newValue, 100);
    });

    test('skips change when current value already equals old value (no-op)',
        () {
      final setup = makeSetup(forkAir: 100);
      final entry = SettingChanges(
        changes: [
          SettingChange(
              suspensionType: SuspensionType.fork,
              fieldId: airId,
              oldValue: 100,
              newValue: 110)
        ],
        date: DateTime.now(),
      );
      expect(setup.computeUndo(entry), isEmpty);
    });

    test('returns empty list for entry with no changes', () {
      final setup = makeSetup();
      final entry = SettingChanges(changes: [], date: DateTime.now());
      expect(setup.computeUndo(entry), isEmpty);
    });

    test('asserts when called on a creation entry', () {
      final setup = makeSetup();
      final entry = SettingChanges(
        changes: [],
        date: DateTime.now(),
        isCreationEntry: true,
      );
      expect(() => setup.computeUndo(entry), throwsA(isA<AssertionError>()));
    });

    test('undo of enable: disables field and sets newValue to null', () {
      final setup = makeSetup(forkAir: 120);
      final entry = SettingChanges(
        changes: [
          SettingChange(
              suspensionType: SuspensionType.fork,
              fieldId: airId,
              oldValue: null,
              newValue: 120,
              oldEnabled: false,
              newEnabled: true)
        ],
        date: DateTime.now(),
      );
      final result = setup.computeUndo(entry);
      expect(result, hasLength(1));
      expect(result.first.newEnabled, false);
      expect(result.first.newValue, isNull);
    });

    test('undo of disable: re-enables field with old value', () {
      final disabledField =
          Field(id: airId, name: 'Air Pressure', unit: 'PSI', deleted: true);
      final sagField = Field(name: 'Sag', unit: '%', value: 25);
      final setup = Setup(
        id: 'test',
        name: 'Test',
        fork: SectionSettings(fields: [
          disabledField,
          sagField
        ], layout: [
          [sagField.id]
        ]),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [],
      );
      final entry = SettingChanges(
        changes: [
          SettingChange(
              suspensionType: SuspensionType.fork,
              fieldId: airId,
              oldValue: 100,
              newValue: null,
              oldEnabled: true,
              newEnabled: false)
        ],
        date: DateTime.now(),
      );
      final result = setup.computeUndo(entry);
      expect(result, hasLength(1));
      expect(result.first.newEnabled, true);
      expect(result.first.newValue, 100);
    });

    test('handles tyre pressure undo', () {
      final setup = makeSetup(frontTyre: 24);
      final entry = SettingChanges(
        changes: [
          SettingChange(
              suspensionType: SuspensionType.tyre,
              fieldId: frontTyreId,
              oldValue: 22,
              newValue: 24)
        ],
        date: DateTime.now(),
      );
      final result = setup.computeUndo(entry);
      expect(result, hasLength(1));
      expect(result.first.suspensionType, SuspensionType.tyre);
      expect(result.first.newValue, 22);
    });

    test('handles multiple fields with partial no-ops', () {
      final setup = makeSetup(forkAir: 100, forkLsc: 10);
      final entry = SettingChanges(
        changes: [
          SettingChange(
              suspensionType: SuspensionType.fork,
              fieldId: airId,
              oldValue: 100,
              newValue: 110),
          SettingChange(
              suspensionType: SuspensionType.fork,
              fieldId: lscId,
              oldValue: 8,
              newValue: 10),
        ],
        date: DateTime.now(),
      );
      final result = setup.computeUndo(entry);
      expect(result, hasLength(1));
      expect(result.first.fieldId, lscId);
      expect(result.first.newValue, 8);
    });
  });

  group('applyChanges', () {
    late String airId;

    late Setup makeSetup;

    setUp(() {
      airId = 'air-pressure-id';
      final airField =
          Field(id: airId, name: 'Air Pressure', unit: 'PSI', value: 100);
      makeSetup = Setup(
        id: 'test',
        name: 'Test',
        fork: SectionSettings(fields: [
          airField
        ], layout: [
          [airId]
        ]),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [],
      );
    });

    test('updates fork field value', () {
      makeSetup.applyChanges([
        SettingChange(
            suspensionType: SuspensionType.fork,
            fieldId: airId,
            oldValue: 100,
            newValue: 90),
      ]);
      expect(makeSetup.fork.fieldById(airId)?.value, 90);
    });

    test('preserves existing field unit when updating value', () {
      makeSetup.applyChanges([
        SettingChange(
            suspensionType: SuspensionType.fork,
            fieldId: airId,
            oldValue: 100,
            newValue: 90),
      ]);
      expect(makeSetup.fork.fieldById(airId)?.unit, 'PSI');
    });

    test('marks field deleted when newEnabled is false', () {
      makeSetup.applyChanges([
        SettingChange(
            suspensionType: SuspensionType.fork,
            fieldId: airId,
            oldValue: 100,
            newValue: null,
            oldEnabled: true,
            newEnabled: false),
      ]);
      expect(makeSetup.fork.fieldById(airId)?.deleted, isTrue);
      expect(makeSetup.fork.activeFields.toList(), isEmpty);
    });

    test('removes deleted field from layout', () {
      makeSetup.applyChanges([
        SettingChange(
            suspensionType: SuspensionType.fork,
            fieldId: airId,
            oldValue: 100,
            newValue: null,
            oldEnabled: true,
            newEnabled: false),
      ]);
      expect(makeSetup.fork.layout, isEmpty);
    });

    test('undeletes field when newEnabled is true', () {
      final deletedField =
          Field(id: airId, name: 'Air Pressure', unit: 'PSI', deleted: true);
      final setup = Setup(
        id: 'test',
        name: 'Test',
        fork: SectionSettings(fields: [deletedField], layout: []),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [],
      );
      setup.applyChanges([
        SettingChange(
            suspensionType: SuspensionType.fork,
            fieldId: airId,
            oldValue: null,
            newValue: 100,
            oldEnabled: false,
            newEnabled: true),
      ]);
      expect(setup.fork.fieldById(airId)?.deleted, isFalse);
      expect(setup.fork.fieldById(airId)?.value, 100);
    });

    test('adds re-enabled field back to layout', () {
      final deletedField =
          Field(id: airId, name: 'Air Pressure', unit: 'PSI', deleted: true);
      final setup = Setup(
        id: 'test',
        name: 'Test',
        fork: SectionSettings(fields: [deletedField], layout: []),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [],
      );
      setup.applyChanges([
        SettingChange(
            suspensionType: SuspensionType.fork,
            fieldId: airId,
            oldValue: null,
            newValue: 100,
            oldEnabled: false,
            newEnabled: true),
      ]);
      expect(setup.fork.layout, [
        [airId]
      ]);
    });
  });

  group('computeUndo + applyChanges round-trip', () {
    test('undo restores setup to state before a value change', () {
      final airId = 'air-id';
      final lscId = 'lsc-id';
      final airField =
          Field(id: airId, name: 'Air Pressure', unit: 'PSI', value: 110);
      final lscField = Field(id: lscId, name: 'LSC', unit: 'Clicks', value: 10);
      final setup = Setup(
        id: 'test',
        name: 'Test',
        fork: SectionSettings(fields: [
          airField,
          lscField
        ], layout: [
          [airId, lscId]
        ]),
        shock: SectionSettings(fields: [], layout: []),
        tyres: SectionSettings(fields: [], layout: []),
        history: [],
      );
      final entry = SettingChanges(
        changes: [
          SettingChange(
              suspensionType: SuspensionType.fork,
              fieldId: airId,
              oldValue: 100,
              newValue: 110),
          SettingChange(
              suspensionType: SuspensionType.fork,
              fieldId: lscId,
              oldValue: 8,
              newValue: 10),
        ],
        date: DateTime.now(),
      );
      final undoChanges = setup.computeUndo(entry);
      setup.applyChanges(undoChanges);
      expect(setup.fork.fieldById(airId)?.value, 100);
      expect(setup.fork.fieldById(lscId)?.value, 8);
    });
  });
}
