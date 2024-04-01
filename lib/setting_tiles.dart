import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/SetupFormController.dart';
import 'models/setting_change.dart';
import 'models/settings.dart';

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
    return Column(
      children: [
        Row(
          children: [
            SettingTile(
              settingType: SettingType.airPressure,
              name: 'Air Pressure',
              value: settings?.airPressure,
              unit: 'PSI',
              controller: settingsFormController?.airPressure,
            ),
            SettingTile(
              settingType: SettingType.sag,
              name: 'Sag',
              value: settings?.sag,
              unit: '%',
              controller: settingsFormController?.sag,
            ),
            if (settings?.volumeSpacer != null ||
                settingsFormController != null)
              SettingTile(
                settingType: SettingType.volumeSpacer,
                name: 'Volume',
                value: settings?.volumeSpacer,
                unit: 'Spacers',
                controller: settingsFormController?.volumeSpacer,
              ),
          ],
        ),
        Row(
          children: [
            SettingTile(
              settingType: SettingType.lsc,
              name: 'LSC',
              value: settings?.lsc,
              unit: 'Clicks',
              controller: settingsFormController?.lsc,
            ),
            if (settings?.hsc != null || settingsFormController != null)
              SettingTile(
                settingType: SettingType.hsc,
                name: 'HSC',
                value: settings?.hsc,
                unit: 'Clicks',
                controller: settingsFormController?.hsc,
              ),
          ],
        ),
        Row(
          children: [
            SettingTile(
              settingType: SettingType.lsr,
              name: 'LSR',
              value: settings?.lsr,
              unit: 'Clicks',
              controller: settingsFormController?.lsr,
            ),
            if (settings?.hsr != null || settingsFormController != null)
              SettingTile(
                settingType: SettingType.hsr,
                name: 'HSR',
                value: settings?.hsr,
                unit: 'Clicks',
                controller: settingsFormController?.hsr,
              ),
          ],
        ),
      ],
    );
  }
}

class SettingTile extends StatelessWidget {
  SettingTile({
    super.key,
    required SettingType this.settingType,
    required this.name,
    this.value,
    this.unit,
    this.controller,
  });

  final SettingType settingType;
  final String name;
  final int? value;
  final String? unit;
  final TextEditingController? controller;

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
              Text(
                name,
                style: theme.primaryTextTheme.bodyMedium,
              ),
              if (controller != null)
                SettingEditTile(
                  settingType: settingType,
                  name: name,
                  value: value,
                  unit: unit,
                  controller: controller!,
                )
              else
                Text(
                  value.toString(),
                  style: theme.primaryTextTheme.headlineSmall,
                ),
              if (unit != null)
                Text(
                  unit.toString(),
                  style: theme.primaryTextTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingEditTile extends StatelessWidget {
  const SettingEditTile({
    super.key,
    required this.settingType,
    required this.name,
    this.value,
    this.unit,
    required this.controller,
  });

  final SettingType settingType;
  final String name;
  final int? value;
  final String? unit;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: ThemeData(
          textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Colors.white,
              selectionColor: Colors.white38,
              selectionHandleColor: Colors.black)),
      child: TextFormField(
        style: theme.primaryTextTheme.bodyLarge,
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        controller: controller,
        validator: (value) {
          if ((value == null || value.isEmpty) &&
              (settingType != SettingType.hsc &&
                  settingType != SettingType.hsr &&
                  settingType != SettingType.volumeSpacer)) {
            return 'Value required';
          }
          return null;
        },
      ),
    );
  }
}
