class SettingChanges {
  final List<SettingChange> changes;
  final DateTime date;
  String? comment;
  final bool isCreationEntry;

  SettingChanges({
    required this.changes,
    required this.date,
    this.comment,
    this.isCreationEntry = false,
  });

  factory SettingChanges.fromJson(Map<String, dynamic> json) {
    return SettingChanges(
      changes: List<SettingChange>.from(
          json['changes'].map((c) => SettingChange.fromJson(c))),
      date: DateTime.parse((json['date'])),
      comment: (json['comment']),
      isCreationEntry: json['isCreationEntry'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'changes': changes.map((c) => c.toJson()).toList(),
      'date': date.toIso8601String(),
      'comment': comment,
      'isCreationEntry': isCreationEntry,
    };
  }

  SettingChanges clone() {
    return SettingChanges(
      changes: changes.map((e) => e.clone()).toList(),
      date: date,
      comment: comment,
      isCreationEntry: isCreationEntry,
    );
  }
}

class SettingChange {
  final SuspensionType suspensionType;
  final SettingType settingType;
  final num? oldValue;
  final num? newValue;
  final bool? oldEnabled;
  final bool? newEnabled;

  SettingChange({
    required this.suspensionType,
    required this.settingType,
    required this.oldValue,
    required this.newValue,
    this.oldEnabled,
    this.newEnabled,
  });

  factory SettingChange.fromJson(Map<String, dynamic> json) {
    return SettingChange(
      suspensionType: SuspensionType.fromJson(json['suspensionType']),
      settingType: SettingType.fromJson(json['settingType']),
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      oldEnabled: json['oldEnabled'],
      newEnabled: json['newEnabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suspensionType': suspensionType.toJson(),
      'settingType': settingType.toJson(),
      'oldValue': oldValue,
      'newValue': newValue,
      'oldEnabled': oldEnabled,
      'newEnabled': newEnabled,
    };
  }

  SettingChange clone() {
    return SettingChange(
      suspensionType: suspensionType,
      settingType: settingType,
      oldValue: oldValue,
      newValue: newValue,
      oldEnabled: oldEnabled,
      newEnabled: newEnabled,
    );
  }
}

enum SettingType {
  airPressure,
  volumeSpacer,
  sag,
  lsr,
  hsr,
  lsc,
  hsc,
  frontTyrePressure,
  rearTyrePressure;

  static SettingType fromJson(String json) => values.byName(json);

  String toJson() => name;

  String get label => switch (this) {
        SettingType.airPressure => 'Air Pressure',
        SettingType.sag => 'Sag',
        SettingType.volumeSpacer => 'Volume',
        SettingType.lsc => 'Low Speed Compression',
        SettingType.hsc => 'High Speed Compression',
        SettingType.lsr => 'Low Speed Rebound',
        SettingType.hsr => 'High Speed Rebound',
        SettingType.frontTyrePressure => 'Front Tyre Pressure',
        SettingType.rearTyrePressure => 'Rear Tyre Pressure',
      };
}

enum SuspensionType {
  fork,
  shock,
  tyre;

  static SuspensionType fromJson(String json) => values.byName(json);

  String toJson() => name;
}