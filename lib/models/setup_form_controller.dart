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
    return isNew(fork.airPressure, originalSetup?.fork.airPressure) ||
        isNew(fork.sag, originalSetup?.fork.sag) ||
        isNew(fork.volumeSpacer, originalSetup?.fork.volumeSpacer) ||
        isNew(fork.lsc, originalSetup?.fork.lsc) ||
        isNew(fork.hsc, originalSetup?.fork.hsc) ||
        isNew(fork.lsr, originalSetup?.fork.lsr) ||
        isNew(fork.hsr, originalSetup?.fork.hsr) ||
        isNew(shock.airPressure, originalSetup?.shock.airPressure) ||
        isNew(shock.sag, originalSetup?.shock.sag) ||
        isNew(shock.volumeSpacer, originalSetup?.shock.volumeSpacer) ||
        isNew(shock.lsc, originalSetup?.shock.lsc) ||
        isNew(shock.hsc, originalSetup?.shock.hsc) ||
        isNew(shock.lsr, originalSetup?.shock.lsr) ||
        isNew(shock.hsr, originalSetup?.shock.hsr) ||
        isNew(tyres.front, originalSetup?.tyres.front) ||
        isNew(tyres.rear, originalSetup?.tyres.rear);
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

void _applyField(
  SettingType type,
  SuspensionType suspensionType,
  Field? oldField,
  FieldFormController ctrl,
  bool isEditing,
  SettingChanges changes,
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

void _applySettings(
  SuspensionType suspensionType,
  SettingsFormController controller,
  Settings? oldSettings,
  SettingChanges changes,
  Settings newSettings,
) {
  final isEditing = oldSettings != null;
  _applyField(
      SettingType.airPressure,
      suspensionType,
      oldSettings?.airPressure,
      controller.airPressure,
      isEditing,
      changes,
      (f) => newSettings.airPressure = f);
  _applyField(SettingType.sag, suspensionType, oldSettings?.sag, controller.sag,
      isEditing, changes, (f) => newSettings.sag = f);
  _applyField(
      SettingType.volumeSpacer,
      suspensionType,
      oldSettings?.volumeSpacer,
      controller.volumeSpacer,
      isEditing,
      changes,
      (f) => newSettings.volumeSpacer = f);
  _applyField(SettingType.lsc, suspensionType, oldSettings?.lsc, controller.lsc,
      isEditing, changes, (f) => newSettings.lsc = f);
  _applyField(SettingType.hsc, suspensionType, oldSettings?.hsc, controller.hsc,
      isEditing, changes, (f) => newSettings.hsc = f);
  _applyField(SettingType.lsr, suspensionType, oldSettings?.lsr, controller.lsr,
      isEditing, changes, (f) => newSettings.lsr = f);
  _applyField(SettingType.hsr, suspensionType, oldSettings?.hsr, controller.hsr,
      isEditing, changes, (f) => newSettings.hsr = f);
}

void _applyTyres(
  TyresFormController controller,
  Tyres? oldTyres,
  SettingChanges changes,
  Tyres newTyres,
) {
  final isEditing = oldTyres != null;
  _applyField(
      SettingType.frontTyrePressure,
      SuspensionType.tyre,
      oldTyres?.front,
      controller.front,
      isEditing,
      changes,
      (f) => newTyres.front = f);
  _applyField(SettingType.rearTyrePressure, SuspensionType.tyre, oldTyres?.rear,
      controller.rear, isEditing, changes, (f) => newTyres.rear = f);
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
