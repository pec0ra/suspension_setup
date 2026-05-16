import 'package:flutter_test/flutter_test.dart';
import 'package:suspension_setup/models/field.dart';
import 'package:suspension_setup/models/setting_change.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/models/setup_form_controller.dart';
import 'package:suspension_setup/models/tyres.dart';

Setup _makeSetup({Field? airPressure, Field? sag, Field? frontTyre}) {
  return Setup(
    id: 'test',
    name: 'Test Setup',
    fork: Settings(airPressure: airPressure, sag: sag),
    shock: Settings(),
    tyres: Tyres(front: frontTyre),
    history: [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hasNewlyEnabledFields', () {
    test('null setup — no fields enabled → false', () {
      final ctrl = SetupFormController(null);
      addTearDown(ctrl.dispose);
      expect(ctrl.hasNewlyEnabledFields(null), isFalse);
    });

    test('null setup — one field enabled → true', () {
      final ctrl = SetupFormController(null);
      addTearDown(ctrl.dispose);
      ctrl.fork.airPressure.enabled.value = true;
      expect(ctrl.hasNewlyEnabledFields(null), isTrue);
    });

    test('existing setup — enabled fields unchanged → false', () {
      final setup =
          _makeSetup(airPressure: const Field(value: 73, unit: 'PSI'));
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      expect(ctrl.hasNewlyEnabledFields(setup), isFalse);
    });

    test('existing setup — field newly enabled → true', () {
      final setup =
          _makeSetup(airPressure: const Field(value: 73, unit: 'PSI'));
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      ctrl.fork.sag.enabled.value = true;
      expect(ctrl.hasNewlyEnabledFields(setup), isTrue);
    });

    test('existing setup — field disabled (not newly enabled) → false', () {
      final setup = _makeSetup(
        airPressure: const Field(value: 73, unit: 'PSI'),
        sag: const Field(value: 30, unit: '%'),
      );
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      ctrl.fork.sag.enabled.value = false;
      expect(ctrl.hasNewlyEnabledFields(setup), isFalse);
    });

    test('existing setup — tyre field newly enabled → true', () {
      final setup = _makeSetup();
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      ctrl.tyres.front.enabled.value = true;
      expect(ctrl.hasNewlyEnabledFields(setup), isTrue);
    });
  });

  group('buildResult', () {
    test('new setup: field values written, no changes recorded', () {
      final ctrl = SetupFormController(null);
      addTearDown(ctrl.dispose);
      ctrl.name.text = 'My Setup';
      ctrl.fork.airPressure.enabled.value = true;
      ctrl.fork.airPressure.value.text = '73';
      ctrl.fork.airPressure.unit.text = 'PSI';

      final (setup, changes) = ctrl.buildResult(null);

      expect(setup.name, 'My Setup');
      expect(setup.fork.airPressure?.value, 73);
      expect(setup.fork.airPressure?.unit, 'PSI');
      expect(changes.changes, isEmpty);
    });

    test('existing setup: unchanged fields produce no changes', () {
      final setup =
          _makeSetup(airPressure: const Field(value: 73, unit: 'PSI'));
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);

      final (_, changes) = ctrl.buildResult(setup);

      expect(changes.changes, isEmpty);
    });

    test('existing setup: value change produces correct SettingChange', () {
      final setup =
          _makeSetup(airPressure: const Field(value: 73, unit: 'PSI'));
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      ctrl.fork.airPressure.value.text = '80';

      final (_, changes) = ctrl.buildResult(setup);

      expect(changes.changes.length, 1);
      final change = changes.changes.first;
      expect(change.settingType, SettingType.airPressure);
      expect(change.suspensionType, SuspensionType.fork);
      expect(change.oldValue, 73);
      expect(change.newValue, 80);
      expect(change.newEnabled, isNull);
    });

    test('existing setup: newly enabled field sets newEnabled=true', () {
      final setup =
          _makeSetup(airPressure: const Field(value: 73, unit: 'PSI'));
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      ctrl.fork.sag.enabled.value = true;
      ctrl.fork.sag.value.text = '30';

      final (_, changes) = ctrl.buildResult(setup);

      expect(changes.changes.length, 1);
      final change = changes.changes.first;
      expect(change.settingType, SettingType.sag);
      expect(change.newEnabled, isTrue);
      expect(change.oldEnabled, isFalse);
      expect(change.newValue, 30);
      expect(change.oldValue, isNull);
    });

    test('existing setup: disabled field sets newEnabled=false', () {
      final setup = _makeSetup(
        airPressure: const Field(value: 73, unit: 'PSI'),
        sag: const Field(value: 30, unit: '%'),
      );
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      ctrl.fork.sag.enabled.value = false;

      final (_, changes) = ctrl.buildResult(setup);

      expect(changes.changes.length, 1);
      final change = changes.changes.first;
      expect(change.settingType, SettingType.sag);
      expect(change.newEnabled, isFalse);
      expect(change.oldEnabled, isTrue);
      expect(change.oldValue, 30);
      expect(change.newValue, isNull);
    });

    test('tyre field change is recorded with SuspensionType.tyre', () {
      final setup = _makeSetup(frontTyre: const Field(value: 28, unit: 'PSI'));
      final ctrl = SetupFormController(setup);
      addTearDown(ctrl.dispose);
      ctrl.tyres.front.value.text = '30';

      final (_, changes) = ctrl.buildResult(setup);

      expect(changes.changes.length, 1);
      final change = changes.changes.first;
      expect(change.settingType, SettingType.frontTyrePressure);
      expect(change.suspensionType, SuspensionType.tyre);
      expect(change.oldValue, 28);
      expect(change.newValue, 30);
    });
  });
}
