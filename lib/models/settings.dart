import 'package:suspension_setup/models/field.dart';

import 'setting_change.dart';

class Settings {
  Field? airPressure;
  Field? volumeSpacer;
  Field? sag;
  Field? lsr;
  Field? hsr;
  Field? lsc;
  Field? hsc;

  Settings({
    this.airPressure,
    this.volumeSpacer,
    this.sag,
    this.lsr,
    this.hsr,
    this.lsc,
    this.hsc,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    Field? parse(String key) {
      final raw = json[key];
      if (raw == null) return null;
      return Field.fromJson(raw as Map<String, dynamic>);
    }

    return Settings(
      airPressure: parse('airPressure'),
      volumeSpacer: parse('volumeSpacer'),
      sag: parse('sag'),
      lsr: parse('lsr'),
      hsr: parse('hsr'),
      lsc: parse('lsc'),
      hsc: parse('hsc'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'airPressure': airPressure?.toJson(),
      'volumeSpacer': volumeSpacer?.toJson(),
      'sag': sag?.toJson(),
      'lsr': lsr?.toJson(),
      'hsr': hsr?.toJson(),
      'lsc': lsc?.toJson(),
      'hsc': hsc?.toJson(),
    };
  }

  static const Map<SettingType, String> defaultUnits = {
    SettingType.airPressure: 'PSI',
    SettingType.sag: '%',
    SettingType.volumeSpacer: 'Spacers',
    SettingType.lsc: 'Clicks',
    SettingType.hsc: 'Clicks',
    SettingType.lsr: 'Clicks',
    SettingType.hsr: 'Clicks',
    SettingType.frontTyrePressure: 'PSI',
    SettingType.rearTyrePressure: 'PSI',
  };

  factory Settings.getDefault() {
    return Settings(
      airPressure: Field(value: 0, unit: defaultUnits[SettingType.airPressure]!),
      sag: Field(value: 0, unit: defaultUnits[SettingType.sag]!),
      volumeSpacer: null,
      lsc: Field(value: 0, unit: defaultUnits[SettingType.lsc]!),
      hsc: null,
      lsr: Field(value: 0, unit: defaultUnits[SettingType.lsr]!),
      hsr: null,
    );
  }

  bool get hasAnyField =>
      airPressure != null ||
      volumeSpacer != null ||
      sag != null ||
      lsr != null ||
      hsr != null ||
      lsc != null ||
      hsc != null;

  Field? fieldFor(SettingType type) => switch (type) {
        SettingType.airPressure => airPressure,
        SettingType.sag => sag,
        SettingType.volumeSpacer => volumeSpacer,
        SettingType.lsc => lsc,
        SettingType.hsc => hsc,
        SettingType.lsr => lsr,
        SettingType.hsr => hsr,
        SettingType.frontTyrePressure || SettingType.rearTyrePressure => null,
      };

  Settings clone() {
    return Settings(
      airPressure: airPressure,
      volumeSpacer: volumeSpacer,
      sag: sag,
      lsr: lsr,
      hsr: hsr,
      lsc: lsc,
      hsc: hsc,
    );
  }
}