import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:suspension_setup/error_screen.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/suspension_icons.dart';
import 'package:suspension_setup/text_with_icon.dart';

import 'models/setting_change.dart';
import 'setting_tiles.dart';
import 'setup_edit.dart';
import 'setup_storage_model.dart';
import 'title_with_icon.dart';

class SetupDetail extends StatelessWidget {
  const SetupDetail({
    super.key,
    required this.setupId,
  });

  final String setupId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<SetupStorageModel>(builder: (context, setupModel, child) {
      var setup = setupModel.getSetup(setupId);
      if (setup == null) {
        return const ErrorScreenWidget(
            title: 'Setup not found',
            message: 'The setup requested does not exist');
      } else {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            title: Text(setup.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
                onPressed: () => {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SetupEdit(setup: setup)),
                  )
                },
              ),
              OverflowMenu(setup: setup)
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  if (!setup.fork.hasAnyField &&
                      !setup.shock.hasAnyField &&
                      !setup.tyres.hasAnyField)
                    _EmptySettings(
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SetupEdit(setup: setup)),
                      ),
                    ),
                  if (setup.fork.hasAnyField) ...[
                    const TitleWithIcon(
                        title: 'Fork', icon: SuspensionIcons.fork),
                    SettingTiles(settings: setup.fork),
                  ],
                  if (setup.shock.hasAnyField) ...[
                    const TitleWithIcon(
                        title: 'Shock', icon: SuspensionIcons.shock),
                    SettingTiles(settings: setup.shock),
                  ],
                  if (setup.tyres.hasAnyField) ...[
                    const TitleWithIcon(
                        title: 'Tyres', icon: SuspensionIcons.tyre),
                    TyreTiles(tyres: setup.tyres),
                  ],
                  if (setup.history.isNotEmpty) History(setup: setup),
                ],
              ),
            ),
          ),
        );
      }
    });
  }
}

class _EmptySettings extends StatelessWidget {
  const _EmptySettings({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Text(
              'Activate at least one field to see your settings here',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Edit setup'),
            ),
          ],
        ),
      ),
    );
  }
}

class History extends StatelessWidget {
  const History({
    super.key,
    required this.setup,
  });

  final Setup setup;

  String _changeText(SettingChange change, Setup setup) {
    final String unit;
    if (change.suspensionType == SuspensionType.tyre) {
      unit = (change.settingType == SettingType.frontTyrePressure
              ? setup.tyres.front?.unit
              : setup.tyres.rear?.unit) ??
          '';
    } else {
      final settings = change.suspensionType == SuspensionType.fork
          ? setup.fork
          : setup.shock;
      unit = settings.fieldFor(change.settingType)?.unit ?? '';
    }
    final label = change.settingType.label;

    if (change.newEnabled == true) {
      return '$label: enabled (${change.newValue} $unit)'.trim();
    }
    if (change.newEnabled == false) {
      return '$label: disabled (was ${change.oldValue} $unit)'.trim();
    }
    return '$label: ${change.oldValue} → ${change.newValue} $unit'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Divider(
          indent: 8,
          endIndent: 8,
          height: 48,
        ),
        const TitleWithIcon(title: 'History'),
        for (SettingChanges settingChange in setup.history.reversed)
          Card(
            surfaceTintColor: theme.colorScheme.secondary,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: theme.colorScheme.secondary.withOpacity(0.08),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(DateFormat.yMMMd()
                              .add_Hm()
                              .format(settingChange.date)),
                        ),
                        Divider(
                          color: theme.colorScheme.secondary.withOpacity(0.3),
                          height: 0,
                        ),
                        if (settingChange.comment != null &&
                            settingChange.comment!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              bottom: 12,
                              top: 12,
                            ),
                            child: TextWithIcon(
                              text: settingChange.comment!,
                              icon: Icons.info_outline,
                            ),
                          ),
                        Divider(
                          color: theme.colorScheme.secondary.withOpacity(0.3),
                          height: 0,
                        ),
                      ]),
                ),
                for (SettingChange change in settingChange.changes)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      bottom: 8,
                      top: 8,
                    ),
                    child: TextWithIcon(
                      text: _changeText(change, setup),
                      icon: switch (change.suspensionType) {
                        SuspensionType.fork => SuspensionIcons.fork,
                        SuspensionType.shock => SuspensionIcons.shock,
                        SuspensionType.tyre => SuspensionIcons.tyre,
                      },
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class OverflowMenu extends StatefulWidget {
  const OverflowMenu({super.key, required this.setup});

  final Setup setup;

  @override
  State<StatefulWidget> createState() => _OverflowMenuState();
}

class _OverflowMenuState extends State<OverflowMenu> {
  bool _copyHistory = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
        itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Clone'),
                ),
                onTap: () => duplicate(context),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.delete),
                  title: Text('Delete'),
                ),
                onTap: () => delete(context),
              ),
            ]);
  }

  void duplicate(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Duplicate Setup \'${widget.setup.name}\'?'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) =>
              CheckboxListTile(
            value: _copyHistory,
            title: const Text('Copy history'),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (bool? value) {
              setState(() {
                _copyHistory = value ?? false;
              });
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'OK');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        SetupEdit(setup: widget.setup.clone(_copyHistory))),
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void delete(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Delete Setup \'${widget.setup.name}\'?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await Provider.of<SetupStorageModel>(context, listen: false)
                  .deleteSetup(widget.setup);
              if (!context.mounted) return;
              Navigator.pop(context, 'OK');
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
