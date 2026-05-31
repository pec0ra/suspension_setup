import 'package:uuid/uuid.dart';

import 'setting_change.dart';
import 'settings.dart';

class Setup {
  final String id;
  String name;
  final SectionSettings fork;
  final SectionSettings shock;
  final SectionSettings tyres;
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
      fork: SectionSettings.fromJson(json['fork']),
      shock: SectionSettings.fromJson(json['shock']),
      tyres: json['tyres'] != null
          ? SectionSettings.fromJson(json['tyres'] as Map<String, dynamic>)
          : SectionSettings(fields: [], layout: []),
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
      'history': history.map((e) => e.toJson()).toList(),
    };
  }

  factory Setup.getDefault() {
    return Setup(
      id: const Uuid().v1(),
      name: '',
      fork: SectionSettings.getDefaultForSuspension(),
      shock: SectionSettings.getDefaultForSuspension(),
      tyres: SectionSettings.getDefaultForTyres(),
      history: [],
    );
  }

  Setup copyMutable() => Setup.fromJson(toJson());

  SectionSettings _sectionFor(SuspensionType type) => switch (type) {
        SuspensionType.fork => fork,
        SuspensionType.shock => shock,
        SuspensionType.tyre => tyres,
      };

  List<SettingChange> computeUndo(SettingChanges historyEntry) {
    assert(!historyEntry.isCreationEntry, 'cannot undo a creation entry');
    final result = <SettingChange>[];
    for (final change in historyEntry.changes) {
      final section = _sectionFor(change.suspensionType);
      final currentField = section.fieldById(change.fieldId);
      final bool currentEnabled = currentField != null && !currentField.deleted;
      final num? currentValue = currentEnabled ? currentField.value : null;
      final bool targetEnabled = change.oldEnabled ?? true;

      final bool enabledChanges = currentEnabled != targetEnabled;
      final bool valueChanges =
          !enabledChanges && currentEnabled && currentValue != change.oldValue;

      if (!enabledChanges && !valueChanges) continue;

      result.add(SettingChange(
        suspensionType: change.suspensionType,
        fieldId: change.fieldId,
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
      final section = _sectionFor(change.suspensionType);
      final bool targetEnabled = change.newEnabled ?? true;
      final num? targetValue = change.newValue;
      assert(!targetEnabled || targetValue != null,
          'targetValue must not be null when targetEnabled is true');
      if (targetEnabled && targetValue == null) continue;

      final idx = section.fields.indexWhere((f) => f.id == change.fieldId);
      if (idx < 0) continue;

      if (targetEnabled) {
        section.fields[idx] = section.fields[idx].copyWith(
          value: targetValue,
          deleted: false,
        );
        if (!section.layout.any((row) => row.contains(change.fieldId))) {
          section.layout.add([change.fieldId]);
        }
      } else {
        section.fields[idx] = section.fields[idx].copyWith(
          deleted: true,
          clearValue: true,
        );
        section.layout = section.layout
            .map((row) => row.where((id) => id != change.fieldId).toList())
            .where((row) => row.isNotEmpty)
            .toList();
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
