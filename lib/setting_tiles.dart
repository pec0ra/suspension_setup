import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/SetupFormController.dart';
import 'models/field.dart';
import 'models/setting_change.dart';
import 'models/settings.dart';
import 'models/tyres.dart';

class SettingTiles extends StatelessWidget {
  const SettingTiles({
    super.key,
    this.settings,
    this.settingsFormController,
  });

  final Settings? settings;
  final SettingsFormController? settingsFormController;

  @override
  Widget build(BuildContext context) {
    final ctrl = settingsFormController;
    if (ctrl != null) {
      return _buildEditMode(ctrl);
    }
    final s = settings;
    if (s != null) {
      return _buildViewMode(s);
    }
    return const SizedBox.shrink();
  }

  Widget _buildEditMode(SettingsFormController ctrl) {
    return Column(
      children: [
        FieldEditCard(name: SettingType.airPressure.label, controller: ctrl.airPressure),
        FieldEditCard(name: SettingType.sag.label, controller: ctrl.sag),
        FieldEditCard(name: 'Volume Spacers', controller: ctrl.volumeSpacer),
        FieldEditCard(name: SettingType.lsc.label, controller: ctrl.lsc),
        FieldEditCard(name: SettingType.hsc.label, controller: ctrl.hsc),
        FieldEditCard(name: SettingType.lsr.label, controller: ctrl.lsr),
        FieldEditCard(name: SettingType.hsr.label, controller: ctrl.hsr),
      ],
    );
  }

  Widget _buildViewMode(Settings s) {
    Widget group(List<({String name, Field? field})> specs) {
      final enabled = specs.where((e) => e.field != null).toList();
      if (enabled.isEmpty) return const SizedBox.shrink();
      return Row(
        children: [
          for (final e in enabled)
            SettingTile(name: e.name, value: e.field!.value, unit: e.field!.unit),
        ],
      );
    }

    return Column(
      children: [
        group([
          (name: SettingType.airPressure.label, field: s.airPressure),
          (name: SettingType.sag.label, field: s.sag),
          (name: 'Volume', field: s.volumeSpacer),
        ]),
        group([
          (name: SettingType.lsc.label, field: s.lsc),
          (name: SettingType.hsc.label, field: s.hsc),
        ]),
        group([
          (name: SettingType.lsr.label, field: s.lsr),
          (name: SettingType.hsr.label, field: s.hsr),
        ]),
      ],
    );
  }
}

class TyreTiles extends StatelessWidget {
  const TyreTiles({
    super.key,
    this.tyres,
    this.tyresFormController,
  });

  final Tyres? tyres;
  final TyresFormController? tyresFormController;

  @override
  Widget build(BuildContext context) {
    final ctrl = tyresFormController;
    if (ctrl != null) {
      return _buildEditMode(ctrl);
    }
    final t = tyres;
    if (t != null) {
      return _buildViewMode(t);
    }
    return const SizedBox.shrink();
  }

  Widget _buildEditMode(TyresFormController ctrl) {
    return Column(
      children: [
        FieldEditCard(
            name: SettingType.frontTyrePressure.label, controller: ctrl.front),
        FieldEditCard(
            name: SettingType.rearTyrePressure.label, controller: ctrl.rear),
      ],
    );
  }

  Widget _buildViewMode(Tyres t) {
    final enabled = [
      (name: SettingType.frontTyrePressure.label, field: t.front),
      (name: SettingType.rearTyrePressure.label, field: t.rear),
    ].where((e) => e.field != null).toList();
    if (enabled.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (final e in enabled)
          SettingTile(name: e.name, value: e.field!.value, unit: e.field!.unit),
      ],
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({
    super.key,
    required this.name,
    required this.value,
    required this.unit,
  });

  final String name;
  final int value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        color: theme.colorScheme.tertiary,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            children: [
              Text(name, style: theme.primaryTextTheme.bodyMedium),
              Text(value.toString(), style: theme.primaryTextTheme.headlineSmall),
              Text(unit, style: theme.primaryTextTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class FieldEditCard extends StatelessWidget {
  const FieldEditCard({
    super.key,
    required this.name,
    required this.controller,
  });

  final String name;
  final FieldFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: controller.enabled,
      builder: (context, enabled, _) {
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                title: Text(name, style: theme.textTheme.titleMedium),
                value: enabled,
                onChanged: (v) {
                  controller.enabled.value = v ?? false;
                  if (!controller.enabled.value) {
                    controller.value.clear();
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (enabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Theme(
                    data: ThemeData(
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Value',
                              labelStyle: theme.textTheme.bodySmall,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            controller: controller.value,
                            validator: (v) {
                              if (controller.enabled.value &&
                                  (v == null || v.isEmpty)) {
                                return 'Value required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              labelStyle: theme.textTheme.bodySmall,
                            ),
                            controller: controller.unit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}