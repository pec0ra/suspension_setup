class SettingChanges {
  final List<SettingChange> changes;
  final DateTime date;
  String? comment;

  static const String defaultComment = 'Setup creation';

  SettingChanges({
    required this.changes,
    required this.date,
    this.comment,
  });

  factory SettingChanges.fromJson(Map<String, dynamic> json) {
    return SettingChanges(
      changes: List<SettingChange>.from(
          json['changes'].map((c) => SettingChange.fromJson(c))),
      date: DateTime.parse((json['date'])),
      comment: (json['comment']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'changes': changes.map((c) => c.toJson()).toList(),
      'date': date.toIso8601String(),
      'comment': comment,
    };
  }

  SettingChanges clone() {
    return SettingChanges(
      changes: changes.map((e) => e.clone()).toList(),
      date: date,
      comment: comment,
    );
  }
}

class SettingChange {
  final SuspensionType suspensionType;
  final SettingType settingType;
  final int? oldValue;
  final int? newValue;
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
  hsc;

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
      };
}

enum SuspensionType {
  fork,
  shock;

  static SuspensionType fromJson(String json) => values.byName(json);

  String toJson() => name;
}