import 'package:uuid/uuid.dart';

class SettingChanges {
  final String id;
  final List<SettingChange> changes;
  final DateTime date;
  String? comment;
  final bool isCreationEntry;

  SettingChanges({
    String? id,
    required this.changes,
    required this.date,
    this.comment,
    this.isCreationEntry = false,
  }) : id = id ?? const Uuid().v1();

  factory SettingChanges.fromJson(Map<String, dynamic> json) {
    return SettingChanges(
      id: json['id'] as String,
      changes: List<SettingChange>.from(
          json['changes'].map((c) => SettingChange.fromJson(c))),
      date: DateTime.parse((json['date'])),
      comment: (json['comment']),
      isCreationEntry: json['isCreationEntry'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'changes': changes.map((c) => c.toJson()).toList(),
      'date': date.toIso8601String(),
      'comment': comment,
      'isCreationEntry': isCreationEntry,
    };
  }

  SettingChanges clone() {
    return SettingChanges(
      id: id,
      changes: changes.map((e) => e.clone()).toList(),
      date: date,
      comment: comment,
      isCreationEntry: isCreationEntry,
    );
  }
}

class SettingChange {
  final SuspensionType suspensionType;
  final String fieldId;
  final num? oldValue;
  final num? newValue;
  final bool? oldEnabled;
  final bool? newEnabled;

  SettingChange({
    required this.suspensionType,
    required this.fieldId,
    required this.oldValue,
    required this.newValue,
    this.oldEnabled,
    this.newEnabled,
  });

  factory SettingChange.fromJson(Map<String, dynamic> json) {
    return SettingChange(
      suspensionType: SuspensionType.fromJson(json['suspensionType']),
      fieldId: json['fieldId'] as String,
      oldValue: json['oldValue'],
      newValue: json['newValue'],
      oldEnabled: json['oldEnabled'],
      newEnabled: json['newEnabled'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suspensionType': suspensionType.toJson(),
      'fieldId': fieldId,
      'oldValue': oldValue,
      'newValue': newValue,
      'oldEnabled': oldEnabled,
      'newEnabled': newEnabled,
    };
  }

  SettingChange clone() {
    return SettingChange(
      suspensionType: suspensionType,
      fieldId: fieldId,
      oldValue: oldValue,
      newValue: newValue,
      oldEnabled: oldEnabled,
      newEnabled: newEnabled,
    );
  }

  SettingChange inverted() {
    return SettingChange(
      suspensionType: suspensionType,
      fieldId: fieldId,
      oldValue: newValue,
      newValue: oldValue,
      oldEnabled: newEnabled,
      newEnabled: oldEnabled,
    );
  }
}

enum SuspensionType {
  fork,
  shock,
  tyre;

  static SuspensionType fromJson(String json) => values.byName(json);

  String toJson() => name;
}
