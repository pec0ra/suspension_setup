import 'package:suspension_setup/models/settings.dart';
import 'package:suspension_setup/models/tyres.dart';
import 'package:uuid/uuid.dart';

import 'field.dart';
import 'setting_change.dart';

class Setup {
  final String id;
  String name;
  final Settings fork;
  final Settings shock;
  final Tyres tyres;
  final List<SettingChanges> history;

  Setup({
    required this.id,
    required this.name,
    required this.fork,
    required this.shock,
    required this.tyres,
    required this.history,
  });

  factory Setup.fromJson(Map<String, dynamic> json) {
    return Setup(
      id: json['id'],
      name: json['name'],
      fork: Settings.fromJson(json['fork']),
      shock: Settings.fromJson(json['shock']),
      tyres: Tyres.fromJson(json['tyres'] as Map<String, dynamic>?),
      history: List<SettingChanges>.from(
          json['history'].map((e) => SettingChanges.fromJson(e))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fork': fork.toJson(),
      'shock': shock.toJson(),
      'tyres': tyres.toJson(),
      'history': history.map((e) => e.toJson()).toList()
    };
  }

  factory Setup.getDefault() {
    return Setup(
      id: const Uuid().v1(),
      name: '',
      fork: Settings.getDefault(),
      shock: Settings.getDefault(),
      tyres: Tyres(),
      history: [],
    );
  }

  Setup copyMutable() => Setup.fromJson(toJson());

  List<SettingChange> computeUndo(SettingChanges historyEntry) {
    assert(!historyEntry.isCreationEntry, 'cannot undo a creation entry');
    final result = <SettingChange>[];
    for (final change in historyEntry.changes) {
      final Field? currentField;
      if (change.suspensionType == SuspensionType.tyre) {
        currentField = change.settingType == SettingType.frontTyrePressure
            ? tyres.front
            : tyres.rear;
      } else {
        final settings =
            change.suspensionType == SuspensionType.fork ? fork : shock;
        currentField = settings.fieldFor(change.settingType);
      }

      final num? currentValue = currentField?.value;
      final bool currentEnabled = currentField != null;
      final bool targetEnabled = change.oldEnabled ?? true;

      final bool enabledChanges = currentEnabled != targetEnabled;
      final bool valueChanges =
          !enabledChanges && currentEnabled && currentValue != change.oldValue;

      if (!enabledChanges && !valueChanges) continue;

      result.add(SettingChange(
        suspensionType: change.suspensionType,
        settingType: change.settingType,
        oldValue: currentValue,
        newValue: targetEnabled ? change.oldValue : null,
        oldEnabled: enabledChanges ? currentEnabled : null,
        newEnabled: enabledChanges ? targetEnabled : null,
      ));
    }
    return result;
  }

  void applyChanges(List<SettingChange> changes) {
    for (final change in changes) {
      final bool targetEnabled = change.newEnabled ?? true;
      final num? targetValue = change.newValue;
      assert(!targetEnabled || targetValue != null,
          'targetValue must not be null when targetEnabled is true');
      if (targetEnabled && targetValue == null) continue;

      if (change.suspensionType == SuspensionType.tyre) {
        final isFront = change.settingType == SettingType.frontTyrePressure;
        final currentField = isFront ? tyres.front : tyres.rear;
        final newField = targetEnabled
            ? Field(
                value: targetValue!,
                unit: currentField?.unit ??
                    Settings.defaultUnits[change.settingType] ??
                    'PSI')
            : null;
        if (isFront) {
          tyres.front = newField;
        } else {
          tyres.rear = newField;
        }
      } else {
        final settings =
            change.suspensionType == SuspensionType.fork ? fork : shock;
        if (targetEnabled) {
          final currentField = settings.fieldFor(change.settingType);
          final unit = currentField?.unit ??
              Settings.defaultUnits[change.settingType] ??
              '';
          settings.setField(
              change.settingType, Field(value: targetValue!, unit: unit));
        } else {
          settings.setField(change.settingType, null);
        }
      }
    }
  }

  Setup snapshotAt(SettingChanges target) {
    final snapshot = copyMutable();
    for (final entry in history.reversed) {
      if (entry.id == target.id) break;
      snapshot.applyChanges(entry.changes.map((c) => c.inverted()).toList());
    }
    return snapshot;
  }

  Setup clone(bool includeHistory) {
    return Setup(
      id: const Uuid().v1(),
      name: name,
      fork: fork.clone(),
      shock: shock.clone(),
      tyres: tyres.clone(),
      history: includeHistory ? history.map((e) => e.clone()).toList() : [],
    );
  }
}
