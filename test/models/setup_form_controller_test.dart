import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/models/field.dart';
import 'package:suspension_setup/models/setting_change.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/models/setup_form_controller.dart';

Setup _makeSetup({List<Field> forkFields = const []}) {
  final ids = forkFields.map((f) => f.id).toList();
  return Setup(
    id: 'test',
    name: 'Test Setup',
    fork: SectionSettings(
      fields: List.from(forkFields),
      layout: ids.isEmpty ? [] : [ids],
    ),
    shock: SectionSettings(fields: [], layout: []),
    tyres: SectionSettings(fields: [], layout: []),
    history: [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hasNewlyAddedFields', () {
    test('null setup — no fields added → false', () {
      final ctrl = SetupFormController(null);
      addTearDown(ctrl.dispose);
      expect(ctrl.hasNewlyAddedFields(), isFalse);
    });

    test('null setup — field added → true', () {
      final ctrl = SetupFormController(null);
      addTearDown(ctrl.dispose);
      ctrl.fork.addField('Air Pressure', 'PSI');
      expect(ctrl.hasNewlyAddedFields(), isTrue);
    });

    test('existing setup — no new fields → false', () {
      final f = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final ctrl = SetupFormController(_makeSetup(forkFields: [f]));
      addTearDown(ctrl.dispose);
      expect(ctrl.hasNewlyAddedFields(), isFalse);
    });

    test('existing setup — field added → true', () {
      final f = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final ctrl = SetupFormController(_makeSetup(forkFields: [f]));
      addTearDown(ctrl.dispose);
      ctrl.fork.addField('Sag', '%');
      expect(ctrl.hasNewlyAddedFields(), isTrue);
    });
  });

  group('SectionFormController.addField / removeField', () {
    test('addField adds to fields list and layout', () {
      final ctrl = SectionFormController(null);
      ctrl.addField('Sag', '%');
      expect(ctrl.fields, hasLength(1));
      expect(ctrl.fields.first.name.text, 'Sag');
      expect(ctrl.fields.first.unit.text, '%');
      expect(ctrl.fields.first.isNew, isTrue);
      expect(ctrl.layout, hasLength(1));
      expect(ctrl.layout.first, contains(ctrl.fields.first.id));
    });

    test('removeField removes from fields list and layout', () {
      final f1 = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final f2 = Field(name: 'Sag', unit: '%', value: 25);
      final section = SectionSettings(fields: [
        f1,
        f2
      ], layout: [
        [f1.id, f2.id]
      ]);
      final ctrl = SectionFormController(section);
      ctrl.removeField(f1.id);
      expect(ctrl.fields, hasLength(1));
      expect(ctrl.fields.first.id, f2.id);
      expect(ctrl.layout.expand((r) => r).toList(), isNot(contains(f1.id)));
    });

    test('layoutControllers returns field controllers in layout order', () {
      final f1 = Field(name: 'Air', unit: 'PSI', value: 73);
      final f2 = Field(name: 'Sag', unit: '%', value: 25);
      final section = SectionSettings(fields: [
        f1,
        f2
      ], layout: [
        [f1.id],
        [f2.id]
      ]);
      final ctrl = SectionFormController(section);
      final rows = ctrl.layoutControllers;
      expect(rows, hasLength(2));
      expect(rows[0].first.id, f1.id);
      expect(rows[1].first.id, f2.id);
    });
  });

  group('buildResult', () {
    test('new setup: field values written, no changes recorded', () {
      final ctrl = SetupFormController(null);
      addTearDown(ctrl.dispose);
      ctrl.name.text = 'My Setup';
      ctrl.fork.addField('Air Pressure', 'PSI');
      ctrl.fork.fields.first.value.text = '73';

      final (setup, changes) = ctrl.buildResult(null);

      expect(setup.name, 'My Setup');
      expect(setup.fork.activeFields.first.value, 73);
      expect(setup.fork.activeFields.first.unit, 'PSI');
      expect(changes.changes, isEmpty);
    });

    test('existing setup: unchanged fields produce no changes', () {
      final f = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final setup = _makeSetup(forkFields: [f]);
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);

      final (_, changes) = ctrl.buildResult(setup);

      expect(changes.changes, isEmpty);
    });

    test('existing setup: value change produces correct SettingChange', () {
      final f = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final setup = _makeSetup(forkFields: [f]);
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      ctrl.fork.fields.first.value.text = '80';

      final (_, changes) = ctrl.buildResult(setup);

      expect(changes.changes.length, 1);
      final change = changes.changes.first;
      expect(change.fieldId, f.id);
      expect(change.suspensionType, SuspensionType.fork);
      expect(change.oldValue, 73);
      expect(change.newValue, 80);
      expect(change.newEnabled, isNull);
    });

    test('existing setup: newly added field emits enable change', () {
      final f = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final setup = _makeSetup(forkFields: [f]);
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      ctrl.fork.addField('Sag', '%');
      ctrl.fork.fields.last.value.text = '30';

      final (_, changes) = ctrl.buildResult(setup);

      expect(changes.changes.length, 1);
      final change = changes.changes.first;
      expect(change.newEnabled, isTrue);
      expect(change.oldEnabled, isFalse);
      expect(change.newValue, 30);
      expect(change.oldValue, isNull);
    });

    test('existing setup: removed field emits disable change', () {
      final f1 = Field(name: 'Air Pressure', unit: 'PSI', value: 73);
      final f2 = Field(name: 'Sag', unit: '%', value: 25);
      final setup = _makeSetup(forkFields: [f1, f2]);
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      ctrl.fork.removeField(f2.id);

      final (_, changes) = ctrl.buildResult(setup);

      expect(changes.changes.length, 1);
      final change = changes.changes.first;
      expect(change.fieldId, f2.id);
      expect(change.newEnabled, isFalse);
      expect(change.oldEnabled, isTrue);
      expect(change.oldValue, 25);
      expect(change.newValue, isNull);
    });
  });
}
