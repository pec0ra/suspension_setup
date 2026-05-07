import 'package:flutter/widgets.dart';
import 'package:suspension_setup/models/setting_change.dart';
import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/tyres.dart';

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

  void dispose() {
    name.dispose();
    fork.dispose();
    shock.dispose();
    tyres.dispose();
  }
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
        );

  final FieldFormController airPressure;
  final FieldFormController volumeSpacer;
  final FieldFormController sag;
  final FieldFormController lsr;
  final FieldFormController hsr;
  final FieldFormController lsc;
  final FieldFormController hsc;

  void dispose() {
    airPressure.dispose();
    volumeSpacer.dispose();
    sag.dispose();
    lsr.dispose();
    hsr.dispose();
    lsc.dispose();
    hsc.dispose();
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