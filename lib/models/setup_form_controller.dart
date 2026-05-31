import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'field.dart';
import 'setting_change.dart';
import 'settings.dart';
import 'setup.dart';

class SetupFormController {
  SetupFormController(Setup? setup)
      : name = TextEditingController(text: setup?.name),
        fork = SectionFormController(setup?.fork),
        shock = SectionFormController(setup?.shock),
        tyres = SectionFormController(setup?.tyres) {
    if (setup == null) {
      final defaults = Setup.getDefault();
      fork.addFields(defaults.fork);
      shock.addFields(defaults.shock);
      tyres.addFields(defaults.tyres);
    }
  }

  final TextEditingController name;
  final SectionFormController fork;
  final SectionFormController shock;
  final SectionFormController tyres;

  /// True if any section has a newly added field (needs value entry).
  bool hasNewlyAddedFields() {
    return fork.fields.any((f) => f.isNew) ||
        shock.fields.any((f) => f.isNew) ||
        tyres.fields.any((f) => f.isNew);
  }

  (Setup, SettingChanges) buildResult(Setup? originalSetup) {
    final newSetup = originalSetup?.copyMutable() ??
        Setup(
          id: const Uuid().v1(),
          name: '',
          fork: SectionSettings(fields: [], layout: []),
          shock: SectionSettings(fields: [], layout: []),
          tyres: SectionSettings(fields: [], layout: []),
          history: [],
        );
    final changes = SettingChanges(changes: [], date: DateTime.now());
    final isEditing = originalSetup != null;

    _applySection(SuspensionType.fork, fork, originalSetup?.fork, changes,
        newSetup.fork, isEditing);
    _applySection(SuspensionType.shock, shock, originalSetup?.shock, changes,
        newSetup.shock, isEditing);
    _applySection(SuspensionType.tyre, tyres, originalSetup?.tyres, changes,
        newSetup.tyres, isEditing);

    String? trimmed(TextEditingController ctrl) {
      final t = ctrl.text.trim();
      return t.isEmpty ? null : t;
    }

    newSetup.name = name.text;
    newSetup.fork.serialNumber = trimmed(fork.serialNumber);
    newSetup.fork.infoUrl = trimmed(fork.infoUrl);
    newSetup.shock.serialNumber = trimmed(shock.serialNumber);
    newSetup.shock.infoUrl = trimmed(shock.infoUrl);
    newSetup.tyres.serialNumber = trimmed(tyres.serialNumber);
    newSetup.tyres.infoUrl = trimmed(tyres.infoUrl);

    return (newSetup, changes);
  }

  void dispose() {
    name.dispose();
    fork.dispose();
    shock.dispose();
    tyres.dispose();
  }
}

void _applySection(
  SuspensionType suspensionType,
  SectionFormController ctrl,
  SectionSettings? original,
  SettingChanges changes,
  SectionSettings target,
  bool isEditing,
) {
  // Apply layout from the form controller.
  target.layout = ctrl.layout.map((row) => List<String>.from(row)).toList();

  // Apply each active field in the form.
  for (final fieldCtrl in ctrl.fields) {
    final origField = original?.fieldById(fieldCtrl.id);
    final newValue = num.tryParse(fieldCtrl.value.text);
    final newUnit = fieldCtrl.unit.text;
    final newName = fieldCtrl.name.text;

    if (fieldCtrl.isNew) {
      // Newly created field — add to target registry.
      final newField = Field(
        id: fieldCtrl.id,
        name: newName,
        unit: newUnit,
        value: newValue,
      );
      final existingIdx = target.fields.indexWhere((f) => f.id == fieldCtrl.id);
      if (existingIdx >= 0) {
        target.fields[existingIdx] = newField;
      } else {
        target.fields.add(newField);
      }
      if (isEditing && newValue != null) {
        changes.changes.add(SettingChange(
          suspensionType: suspensionType,
          fieldId: fieldCtrl.id,
          oldValue: null,
          newValue: newValue,
          oldEnabled: false,
          newEnabled: true,
        ));
      }
    } else if (origField != null) {
      // Existing field — update metadata and value.
      final idx = target.fields.indexWhere((f) => f.id == fieldCtrl.id);
      if (idx >= 0) {
        target.fields[idx] = origField.copyWith(
          name: newName,
          unit: newUnit,
          value: newValue,
          deleted: false,
        );
      }
      if (isEditing && newValue != null && origField.value != newValue) {
        changes.changes.add(SettingChange(
          suspensionType: suspensionType,
          fieldId: fieldCtrl.id,
          oldValue: origField.value,
          newValue: newValue,
        ));
      }
    }
  }

  // Handle fields removed from the form (were active, now gone).
  if (isEditing && original != null) {
    final activeFormIds = ctrl.fields.map((f) => f.id).toSet();
    for (final origField in original.activeFields) {
      if (!activeFormIds.contains(origField.id)) {
        final idx = target.fields.indexWhere((f) => f.id == origField.id);
        if (idx >= 0) {
          target.fields[idx] =
              target.fields[idx].copyWith(deleted: true, clearValue: true);
        }
        target.layout = target.layout
            .map((row) => row.where((id) => id != origField.id).toList())
            .where((row) => row.isNotEmpty)
            .toList();
        changes.changes.add(SettingChange(
          suspensionType: suspensionType,
          fieldId: origField.id,
          oldValue: origField.value,
          newValue: null,
          oldEnabled: true,
          newEnabled: false,
        ));
      }
    }
  }
}

class SectionFormController {
  SectionFormController(SectionSettings? section)
      : fields =
            section?.activeFields.map(FieldFormController.fromField).toList() ??
                [],
        layout =
            section?.layout.map((row) => List<String>.from(row)).toList() ?? [],
        serialNumber = TextEditingController(text: section?.serialNumber),
        infoUrl = TextEditingController(text: section?.infoUrl);

  final List<FieldFormController> fields;
  List<List<String>> layout;
  final TextEditingController serialNumber;
  final TextEditingController infoUrl;

  bool get hasActiveFields => fields.isNotEmpty;

  /// Returns layout rows resolved to their [FieldFormController]s.
  List<List<FieldFormController>> get layoutControllers {
    final map = {for (final f in fields) f.id: f};
    return layout
        .map((row) =>
            row.map((id) => map[id]).whereType<FieldFormController>().toList())
        .where((row) => row.isNotEmpty)
        .toList();
  }

  void addFields(SectionSettings section) {
    for (final f in section.activeFields) {
      fields.add(FieldFormController(
        id: f.id,
        fieldName: f.name,
        unit: f.unit,
        isNew: true,
      ));
    }
    layout = section.layout.map((row) => List<String>.from(row)).toList();
  }

  void addField(String fieldName, String unit) {
    final ctrl = FieldFormController(
      id: const Uuid().v4(),
      fieldName: fieldName,
      unit: unit,
      isNew: true,
    );
    fields.add(ctrl);
    layout.add([ctrl.id]);
  }

  void removeField(String fieldId) {
    fields.removeWhere((f) => f.id == fieldId);
    layout = layout
        .map((row) => row.where((id) => id != fieldId).toList())
        .where((row) => row.isNotEmpty)
        .toList();
  }

  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    serialNumber.dispose();
    infoUrl.dispose();
  }
}

class FieldFormController {
  FieldFormController({
    required this.id,
    required String fieldName,
    required String unit,
    num? value,
    this.isNew = false,
  })  : name = TextEditingController(text: fieldName),
        unit = TextEditingController(text: unit),
        value = TextEditingController(text: value?.toString() ?? '');

  factory FieldFormController.fromField(Field field) => FieldFormController(
        id: field.id,
        fieldName: field.name,
        unit: field.unit,
        value: field.value,
      );

  final String id;
  final bool isNew;
  final TextEditingController name;
  final TextEditingController unit;
  final TextEditingController value;

  void dispose() {
    name.dispose();
    unit.dispose();
    value.dispose();
  }
}
