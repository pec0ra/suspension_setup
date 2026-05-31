import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/field.dart';
import 'models/setup_form_controller.dart';
import 'models/settings.dart';

class SettingTiles extends StatelessWidget {
  const SettingTiles({super.key, required this.section});

  final SectionSettings section;

  @override
  Widget build(BuildContext context) {
    final rows = section.layout
        .map((row) => row
            .map((id) => section.fieldById(id))
            .whereType<Field>()
            .where((f) => !f.deleted && f.value != null)
            .toList())
        .where((row) => row.isNotEmpty)
        .toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (final row in rows)
          Row(
            children: [
              for (final f in row)
                SettingTile(name: f.name, value: f.value!, unit: f.unit),
            ],
          ),
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

class FieldConfigTile extends StatelessWidget {
  const FieldConfigTile({
    super.key,
    required this.controller,
  });

  final FieldFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = controller.value.text;
    final unit = controller.unit.text;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  controller.name.text,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
                Text(
                  value.isEmpty ? '—' : value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
                Text(
                  unit,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.drag_indicator,
                size: 14,
                color:
                    theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FieldValueCard extends StatelessWidget {
  const FieldValueCard({
    super.key,
    required this.controller,
  });

  final FieldFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = controller.unit.text;
    return Column(
      children: [
        Text(
          controller.name.text,
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
