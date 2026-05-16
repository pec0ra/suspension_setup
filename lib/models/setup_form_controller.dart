import 'package:flutter/widgets.dart';
import 'package:suspension_setup/models/setting_change.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/tyres.dart';

import 'field.dart';
import 'setup.dart';

class SetupFormController {
  SetupFormController(Setup? setup)
      : name = TextEditingController(text: setup?.name),
        fork = SettingsFormController(setup?.fork),
        shock = SettingsFormController(setup?.shock),
        tyres = TyresFormController(setup?.tyres);

  final TextEditingController name;
  final SettingsFormController fork;
  final SettingsFormController shock;
  final TyresFormController tyres;

  bool hasNewlyEnabledFields(Setup? originalSetup) {
    bool isNew(FieldFormController ctrl, Field? original) =>
        ctrl.enabled.value && original == null;
    if (originalSetup == null) {
      return fork.airPressure.enabled.value ||
          fork.sag.enabled.value ||
          fork.volumeSpacer.enabled.value ||
          fork.lsc.enabled.value ||
          fork.hsc.enabled.value ||
          fork.lsr.enabled.value ||
          fork.hsr.enabled.value ||
          shock.airPressure.enabled.value ||
          shock.sag.enabled.value ||
          shock.volumeSpacer.enabled.value ||
          shock.lsc.enabled.value ||
          shock.hsc.enabled.value ||
          shock.lsr.enabled.value ||
          shock.hsr.enabled.value ||
          tyres.front.enabled.value ||
          tyres.rear.enabled.value;
    }
    return isNew(fork.airPressure, originalSetup.fork.airPressure) ||
        isNew(fork.sag, originalSetup.fork.sag) ||
        isNew(fork.volumeSpacer, originalSetup.fork.volumeSpacer) ||
        isNew(fork.lsc, originalSetup.fork.lsc) ||
        isNew(fork.hsc, originalSetup.fork.hsc) ||
        isNew(fork.lsr, originalSetup.fork.lsr) ||
        isNew(fork.hsr, originalSetup.fork.hsr) ||
        isNew(shock.airPressure, originalSetup.shock.airPressure) ||
        isNew(shock.sag, originalSetup.shock.sag) ||
        isNew(shock.volumeSpacer, originalSetup.shock.volumeSpacer) ||
        isNew(shock.lsc, originalSetup.shock.lsc) ||
        isNew(shock.hsc, originalSetup.shock.hsc) ||
        isNew(shock.lsr, originalSetup.shock.lsr) ||
        isNew(shock.hsr, originalSetup.shock.hsr) ||
        isNew(tyres.front, originalSetup.tyres.front) ||
        isNew(tyres.rear, originalSetup.tyres.rear);
  }

  (Setup, SettingChanges) buildResult(Setup? originalSetup) {
    final newSetup = originalSetup?.copyMutable() ?? Setup.getDefault();
    final changes = SettingChanges(changes: [], date: DateTime.now());

    _applySettings(
        SuspensionType.fork, fork, originalSetup?.fork, changes, newSetup.fork);
    _applySettings(SuspensionType.shock, shock, originalSetup?.shock, changes,
        newSetup.shock);
    _applyTyres(tyres, originalSetup?.tyres, changes, newSetup.tyres);

    String? trimmed(TextEditingController ctrl) {
      final t = ctrl.text.trim();
      return t.isEmpty ? null : t;
    }

    newSetup.fork.serialNumber = trimmed(fork.serialNumber);
    newSetup.fork.infoUrl = trimmed(fork.infoUrl);
    newSetup.shock.serialNumber = trimmed(shock.serialNumber);
    newSetup.shock.infoUrl = trimmed(shock.infoUrl);
    newSetup.name = name.text;

    return (newSetup, changes);
  }

  void dispose() {
    name.dispose();
    fork.dispose();
    shock.dispose();
    tyres.dispose();
  }
}

void _applySettings(
  SuspensionType suspensionType,
  SettingsFormController controller,
  Settings? oldSettings,
  SettingChanges changes,
  Settings newSettings,
) {
  final isEditing = oldSettings != null;

  void applyField(
    SettingType type,
    Field? oldField,
    FieldFormController ctrl,
    void Function(Field?) setter,
  ) {
    final newField = ctrl.enabled.value
        ? Field(value: num.parse(ctrl.value.text), unit: ctrl.unit.text)
        : null;

    if (isEditing) {
      final wasEnabled = oldField != null;
      final isEnabled = ctrl.enabled.value;
      final enabledChanged = wasEnabled != isEnabled;
      final valueChanged = oldField?.value != newField?.value;

      if (enabledChanged || valueChanged) {
        changes.changes.add(SettingChange(
          settingType: type,
          suspensionType: suspensionType,
          oldValue: oldField?.value,
          newValue: newField?.value,
          oldEnabled: enabledChanged ? wasEnabled : null,
          newEnabled: enabledChanged ? isEnabled : null,
        ));
      }
    }

    setter(newField);
  }

  applyField(SettingType.airPressure, oldSettings?.airPressure,
      controller.airPressure, (f) => newSettings.airPressure = f);
  applyField(SettingType.sag, oldSettings?.sag, controller.sag,
      (f) => newSettings.sag = f);
  applyField(SettingType.volumeSpacer, oldSettings?.volumeSpacer,
      controller.volumeSpacer, (f) => newSettings.volumeSpacer = f);
  applyField(SettingType.lsc, oldSettings?.lsc, controller.lsc,
      (f) => newSettings.lsc = f);
  applyField(SettingType.hsc, oldSettings?.hsc, controller.hsc,
      (f) => newSettings.hsc = f);
  applyField(SettingType.lsr, oldSettings?.lsr, controller.lsr,
      (f) => newSettings.lsr = f);
  applyField(SettingType.hsr, oldSettings?.hsr, controller.hsr,
      (f) => newSettings.hsr = f);
}

void _applyTyres(
  TyresFormController controller,
  Tyres? oldTyres,
  SettingChanges changes,
  Tyres newTyres,
) {
  final isEditing = oldTyres != null;

  void applyField(
    SettingType type,
    Field? oldField,
    FieldFormController ctrl,
    void Function(Field?) setter,
  ) {
    final newField = ctrl.enabled.value
        ? Field(value: num.parse(ctrl.value.text), unit: ctrl.unit.text)
        : null;

    if (isEditing) {
      final wasEnabled = oldField != null;
      final isEnabled = ctrl.enabled.value;
      final enabledChanged = wasEnabled != isEnabled;
      final valueChanged = oldField?.value != newField?.value;

      if (enabledChanged || valueChanged) {
        changes.changes.add(SettingChange(
          settingType: type,
          suspensionType: SuspensionType.tyre,
          oldValue: oldField?.value,
          newValue: newField?.value,
          oldEnabled: enabledChanged ? wasEnabled : null,
          newEnabled: enabledChanged ? isEnabled : null,
        ));
      }
    }

    setter(newField);
  }

  applyField(SettingType.frontTyrePressure, oldTyres?.front, controller.front,
      (f) => newTyres.front = f);
  applyField(SettingType.rearTyrePressure, oldTyres?.rear, controller.rear,
      (f) => newTyres.rear = f);
}

class TyresFormController {
  TyresFormController(Tyres? tyres)
      : front = FieldFormController(
          enabled: tyres?.front != null,
          value: tyres?.front?.value,
          unit: tyres?.front?.unit ??
              Settings.defaultUnits[SettingType.frontTyrePressure]!,
        ),
        rear = FieldFormController(
          enabled: tyres?.rear != null,
          value: tyres?.rear?.value,
          unit: tyres?.rear?.unit ??
              Settings.defaultUnits[SettingType.rearTyrePressure]!,
        );

  final FieldFormController front;
  final FieldFormController rear;

  void dispose() {
    front.dispose();
    rear.dispose();
  }
}

class SettingsFormController {
  SettingsFormController(Settings? settings)
      : airPressure = FieldFormController(
          enabled: settings?.airPressure != null,
          value: settings?.airPressure?.value,
          unit: settings?.airPressure?.unit ??
              Settings.defaultUnits[SettingType.airPressure]!,
        ),
        sag = FieldFormController(
          enabled: settings?.sag != null,
          value: settings?.sag?.value,
          unit: settings?.sag?.unit ?? Settings.defaultUnits[SettingType.sag]!,
        ),
        volumeSpacer = FieldFormController(
          enabled: settings?.volumeSpacer != null,
          value: settings?.volumeSpacer?.value,
          unit: settings?.volumeSpacer?.unit ??
              Settings.defaultUnits[SettingType.volumeSpacer]!,
        ),
        lsc = FieldFormController(
          enabled: settings?.lsc != null,
          value: settings?.lsc?.value,
          unit: settings?.lsc?.unit ?? Settings.defaultUnits[SettingType.lsc]!,
        ),
        hsc = FieldFormController(
          enabled: settings?.hsc != null,
          value: settings?.hsc?.value,
          unit: settings?.hsc?.unit ?? Settings.defaultUnits[SettingType.hsc]!,
        ),
        lsr = FieldFormController(
          enabled: settings?.lsr != null,
          value: settings?.lsr?.value,
          unit: settings?.lsr?.unit ?? Settings.defaultUnits[SettingType.lsr]!,
        ),
        hsr = FieldFormController(
          enabled: settings?.hsr != null,
          value: settings?.hsr?.value,
          unit: settings?.hsr?.unit ?? Settings.defaultUnits[SettingType.hsr]!,
        ),
        serialNumber = TextEditingController(text: settings?.serialNumber),
        infoUrl = TextEditingController(text: settings?.infoUrl);

  final FieldFormController airPressure;
  final FieldFormController volumeSpacer;
  final FieldFormController sag;
  final FieldFormController lsr;
  final FieldFormController hsr;
  final FieldFormController lsc;
  final FieldFormController hsc;
  final TextEditingController serialNumber;
  final TextEditingController infoUrl;

  void dispose() {
    airPressure.dispose();
    volumeSpacer.dispose();
    sag.dispose();
    lsr.dispose();
    hsr.dispose();
    lsc.dispose();
    hsc.dispose();
    serialNumber.dispose();
    infoUrl.dispose();
  }
}

class FieldFormController {
  FieldFormController({required bool enabled, num? value, required String unit})
      : enabled = ValueNotifier(enabled),
        value = TextEditingController(text: value?.toString() ?? ''),
        unit = TextEditingController(text: unit);

  final ValueNotifier<bool> enabled;
  final TextEditingController value;
  final TextEditingController unit;

  void dispose() {
    enabled.dispose();
    value.dispose();
    unit.dispose();
  }
}
