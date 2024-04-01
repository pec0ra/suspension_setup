import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/SetupFormController.dart';
import 'models/setting_change.dart';
import 'models/settings.dart';
import 'models/setup.dart';
import 'setting_tiles.dart';
import 'setup_storage_model.dart';
import 'suspension_icons.dart';
import 'title_with_icon.dart';

class SetupEdit extends StatefulWidget {
  const SetupEdit({
    super.key,
    this.setup,
  });

  final Setup? setup;

  @override
  State<StatefulWidget> createState() => _SetupEditState();
}

class _SetupEditState extends State<SetupEdit> {
  final _formKey = GlobalKey<FormState>();
  late SetupFormController _setupFormController;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    _setupFormController = SetupFormController(widget.setup);
    super.initState();
  }

  @override
  void dispose() {
    _setupFormController.dispose();
    super.dispose();
  }

  void _onSetupChanged(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      var newSetup = widget.setup != null
          ? Setup.fromJson(widget.setup!.toJson())
          : Setup.getDefault();
      SettingChanges settingChanges =
          SettingChanges(changes: [], date: DateTime.now());

      _updateValues(
        SuspensionType.fork,
        _setupFormController.fork,
        widget.setup?.fork,
        settingChanges,
        newSetup.fork,
      );
      _updateValues(
        SuspensionType.shock,
        _setupFormController.shock,
        widget.setup?.shock,
        settingChanges,
        newSetup.shock,
      );

      if (settingChanges.changes.isNotEmpty) {
        newSetup.history.add(settingChanges);
      } else if (widget.setup == null || widget.setup!.history.isEmpty) {
        settingChanges.comment = SettingChanges.defaultComment;
        newSetup.history.add(settingChanges);
      }
      newSetup.name = _setupFormController.name.text;

      if (widget.setup != null && settingChanges.changes.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Comment'),
              content: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                    hintText: "Add a comment to your changes"),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    if (_commentController.text.isNotEmpty) {
                      settingChanges.comment = _commentController.text;
                    }
                    _saveSetup(context, newSetup);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      } else {
        _saveSetup(context, newSetup);
      }
    }
  }

  void _saveSetup(BuildContext context, Setup newSetup) {
    Provider.of<SetupStorageModel>(context, listen: false)
        .upsertSetup(newSetup);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setup saved successfully')),
    );
  }

  void _updateValues(
    SuspensionType suspensionType,
    SettingsFormController controller,
    Settings? settings,
    SettingChanges settingChanges,
    Settings newSettings,
  ) {
    int newAirPressure = int.parse(controller.airPressure.text);
    if (settings?.airPressure != newAirPressure) {
      if (settings != null) {
        settingChanges.changes.add(SettingChange(
          settingType: SettingType.airPressure,
          oldValue: settings.airPressure,
          newValue: newAirPressure,
          suspensionType: suspensionType,
        ));
      }
      newSettings.airPressure = newAirPressure;
    }

    int newSag = int.parse(controller.sag.text);
    if (settings?.sag != newSag) {
      if (settings != null) {
        settingChanges.changes.add(SettingChange(
          settingType: SettingType.sag,
          oldValue: settings.sag,
          newValue: newSag,
          suspensionType: suspensionType,
        ));
      }
      newSettings.sag = newSag;
    }

    int? newVolumeSpacer = int.tryParse(controller.volumeSpacer.text);
    if (settings?.volumeSpacer != newVolumeSpacer) {
      if (settings != null) {
        settingChanges.changes.add(SettingChange(
          settingType: SettingType.volumeSpacer,
          oldValue: settings.volumeSpacer,
          newValue: newVolumeSpacer,
          suspensionType: suspensionType,
        ));
      }
      newSettings.volumeSpacer = newVolumeSpacer;
    }

    int newLsc = int.parse(controller.lsc.text);
    if (settings?.lsc != newLsc) {
      if (settings != null) {
        settingChanges.changes.add(SettingChange(
          settingType: SettingType.lsc,
          oldValue: settings.lsc,
          newValue: newLsc,
          suspensionType: suspensionType,
        ));
      }
      newSettings.lsc = newLsc;
    }

    int? newHsc = int.tryParse(controller.hsc.text);
    if (settings?.hsc != newHsc) {
      if (settings != null) {
        settingChanges.changes.add(SettingChange(
          settingType: SettingType.hsc,
          oldValue: settings.hsc,
          newValue: newHsc,
          suspensionType: suspensionType,
        ));
      }
      newSettings.hsc = newHsc;
    }

    int newLsr = int.parse(controller.lsr.text);
    if (settings?.lsr != newLsr) {
      if (settings != null) {
        settingChanges.changes.add(SettingChange(
          settingType: SettingType.lsr,
          oldValue: settings.lsr,
          newValue: newLsr,
          suspensionType: suspensionType,
        ));
      }
      newSettings.lsr = newLsr;
    }

    int? newHsr = int.tryParse(controller.hsr.text);
    if (settings?.hsr != newHsr) {
      if (settings != null) {
        settingChanges.changes.add(SettingChange(
          settingType: SettingType.hsr,
          oldValue: settings.hsr,
          newValue: newHsr,
          suspensionType: suspensionType,
        ));
      }
      newSettings.hsr = newHsr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        title: Text(widget.setup?.name ?? ''),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextFormField(
                  style: theme.textTheme.headlineLarge,
                  decoration: const InputDecoration(
                    hintText: 'Setup Name',
                  ),
                  controller: _setupFormController.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Setup name cannot be empty';
                    }
                    return null;
                  },
                ),
                const TitleWithIcon(title: 'Fork', icon: SuspensionIcons.fork),
                SettingTiles(
                  settings: widget.setup?.fork,
                  settingsFormController: _setupFormController.fork,
                ),
                const TitleWithIcon(
                    title: 'Shock', icon: SuspensionIcons.shock),
                SettingTiles(
                  settings: widget.setup?.shock,
                  settingsFormController: _setupFormController.shock,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.secondary,
        onPressed: () => _onSetupChanged(context),
        tooltip: 'Save setup',
        child: const Icon(Icons.save),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
