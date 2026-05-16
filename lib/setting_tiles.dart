import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/setup_form_controller.dart';
import 'models/field.dart';
import 'models/setting_change.dart';
import 'models/settings.dart';
import 'models/tyres.dart';

class SettingTiles extends StatelessWidget {
  const SettingTiles({super.key, required this.settings});

  final Settings settings;

  @override
  Widget build(BuildContext context) {
    Widget group(List<({String name, Field? field})> specs) {
      final enabled = specs.where((e) => e.field != null).toList();
      if (enabled.isEmpty) return const SizedBox.shrink();
      return Row(
        children: [
          for (final e in enabled)
            SettingTile(
                name: e.name, value: e.field!.value, unit: e.field!.unit),
        ],
      );
    }

    return Column(
      children: [
        group([
          (name: SettingType.airPressure.label, field: settings.airPressure),
          (name: SettingType.sag.label, field: settings.sag),
          (name: SettingType.volumeSpacer.label, field: settings.volumeSpacer),
        ]),
        group([
          (name: SettingType.lsc.label, field: settings.lsc),
          (name: SettingType.hsc.label, field: settings.hsc),
        ]),
        group([
          (name: SettingType.lsr.label, field: settings.lsr),
          (name: SettingType.hsr.label, field: settings.hsr),
        ]),
      ],
    );
  }
}

class TyreTiles extends StatelessWidget {
  const TyreTiles({super.key, required this.tyres});

  final Tyres tyres;

  @override
  Widget build(BuildContext context) {
    final enabled = [
      (name: SettingType.frontTyrePressure.label, field: tyres.front),
      (name: SettingType.rearTyrePressure.label, field: tyres.rear),
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
  final num value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Column(
            children: [
              Text(name,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
              Text(value.toString(),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
              Text(unit,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
            ],
          ),
        ),
      ),
    );
  }
}

class FieldConfigCard extends StatelessWidget {
  const FieldConfigCard({
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
        );
      },
    );
  }
}

class FieldValueCard extends StatelessWidget {
  const FieldValueCard({
    super.key,
    required this.name,
    required this.controller,
  });

  final String name;
  final FieldFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = controller.unit.text;
    return Column(
      children: [
        Text(
          name,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        TextFormField(
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            helperText: unit.isEmpty ? null : unit,
            helperStyle: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            helperMaxLines: 1,
            errorStyle: theme.textTheme.bodySmall,
          ),
          keyboardType: const TextInputType.numberWithOptions(
              signed: true, decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-]')),
          ],
          controller: controller.value,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Value required';
            if (num.tryParse(v) == null) return 'Invalid number';
            return null;
          },
        ),
      ],
    );
  }
}
