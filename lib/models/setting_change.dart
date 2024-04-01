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

  SettingChange({
    required this.suspensionType,
    required this.settingType,
    required this.oldValue,
    required this.newValue,
  });

  factory SettingChange.fromJson(Map<String, dynamic> json) {
    return SettingChange(
      suspensionType: SuspensionType.fromJson(json['suspensionType']),
      settingType: SettingType.fromJson(json['settingType']),
      oldValue: json['oldValue'],
      newValue: json['newValue'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suspensionType': suspensionType.toJson(),
      'settingType': settingType.toJson(),
      'oldValue': oldValue,
      'newValue': newValue,
    };
  }

  SettingChange clone() {
    return SettingChange(
      suspensionType: suspensionType,
      settingType: settingType,
      oldValue: oldValue,
      newValue: newValue,
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
}

enum SuspensionType {
  fork,
  shock;

  static SuspensionType fromJson(String json) => values.byName(json);

  String toJson() => name;
}
