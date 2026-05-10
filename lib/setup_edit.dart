import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/setup_form_controller.dart';
import 'models/field.dart';
import 'models/setting_change.dart';
import 'models/settings.dart';
import 'models/setup.dart';
import 'models/tyres.dart';
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
    _commentController.dispose();
    _setupFormController.dispose();
    super.dispose();
  }

  Future<void> _onSetupChanged(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      var newSetup = widget.setup?.copyMutable() ?? Setup.getDefault();
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
      _updateTyreValues(
        _setupFormController.tyres,
        widget.setup?.tyres,
        settingChanges,
        newSetup.tyres,
      );

      String? trimmed(TextEditingController ctrl) {
        final t = ctrl.text.trim();
        return t.isEmpty ? null : t;
      }

      newSetup.fork.serialNumber = trimmed(_setupFormController.fork.serialNumber);
      newSetup.fork.infoUrl = trimmed(_setupFormController.fork.infoUrl);
      newSetup.shock.serialNumber = trimmed(_setupFormController.shock.serialNumber);
      newSetup.shock.infoUrl = trimmed(_setupFormController.shock.infoUrl);

      if (settingChanges.changes.isNotEmpty) {
        newSetup.history.add(settingChanges);
      } else if (widget.setup == null || widget.setup!.history.isEmpty) {
        newSetup.history.add(SettingChanges(
          changes: [],
          date: settingChanges.date,
          comment: 'Setup creation',
          isCreationEntry: true,
        ));
      }
      newSetup.name = _setupFormController.name.text;

      if (widget.setup != null && settingChanges.changes.isNotEmpty) {
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Comment'),
              content: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                    hintText: "Add a comment to your changes"),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    if (_commentController.text.isNotEmpty) {
                      settingChanges.comment = _commentController.text;
                    }
                    Navigator.pop(dialogContext);
                    await _saveSetup(context, newSetup);
                  },
                ),
              ],
            );
          },
        );
      } else {
        await _saveSetup(context, newSetup);
      }
    }
  }

  Future<void> _saveSetup(BuildContext context, Setup newSetup) async {
    await Provider.of<SetupStorageModel>(context, listen: false)
        .upsertSetup(newSetup);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Setup saved successfully')),
    );
  }

  void _updateValues(
    SuspensionType suspensionType,
    SettingsFormController controller,
    Settings? oldSettings,
    SettingChanges settingChanges,
    Settings newSettings,
  ) {
    final isEditing = oldSettings != null;

    void applyField(
      SettingType type,
      Field? oldField,
      FieldFormController ctrl,
      void Function(Field?) setter,
    ) {
      final newField = ctrl.enabled.value
          ? Field(value: num.parse(ctrl.value.text), unit: ctrl.unit.text)
          : null;

      if (isEditing) {
        final wasEnabled = oldField != null;
        final isEnabled = ctrl.enabled.value;
        final enabledChanged = wasEnabled != isEnabled;
        final valueChanged = oldField?.value != newField?.value;

        if (enabledChanged || valueChanged) {
          settingChanges.changes.add(SettingChange(
            settingType: type,
            suspensionType: suspensionType,
            oldValue: oldField?.value,
            newValue: newField?.value,
            oldEnabled: enabledChanged ? wasEnabled : null,
            newEnabled: enabledChanged ? isEnabled : null,
          ));
        }
      }

      setter(newField);
    }

    applyField(SettingType.airPressure, oldSettings?.airPressure,
        controller.airPressure, (f) => newSettings.airPressure = f);
    applyField(SettingType.sag, oldSettings?.sag,
        controller.sag, (f) => newSettings.sag = f);
    applyField(SettingType.volumeSpacer, oldSettings?.volumeSpacer,
        controller.volumeSpacer, (f) => newSettings.volumeSpacer = f);
    applyField(SettingType.lsc, oldSettings?.lsc,
        controller.lsc, (f) => newSettings.lsc = f);
    applyField(SettingType.hsc, oldSettings?.hsc,
        controller.hsc, (f) => newSettings.hsc = f);
    applyField(SettingType.lsr, oldSettings?.lsr,
        controller.lsr, (f) => newSettings.lsr = f);
    applyField(SettingType.hsr, oldSettings?.hsr,
        controller.hsr, (f) => newSettings.hsr = f);
  }

  void _updateTyreValues(
    TyresFormController controller,
    Tyres? oldTyres,
    SettingChanges settingChanges,
    Tyres newTyres,
  ) {
    final isEditing = oldTyres != null;

    void applyField(
      SettingType type,
      Field? oldField,
      FieldFormController ctrl,
      void Function(Field?) setter,
    ) {
      final newField = ctrl.enabled.value
          ? Field(value: num.parse(ctrl.value.text), unit: ctrl.unit.text)
          : null;

      if (isEditing) {
        final wasEnabled = oldField != null;
        final isEnabled = ctrl.enabled.value;
        final enabledChanged = wasEnabled != isEnabled;
        final valueChanged = oldField?.value != newField?.value;

        if (enabledChanged || valueChanged) {
          settingChanges.changes.add(SettingChange(
            settingType: type,
            suspensionType: SuspensionType.tyre,
            oldValue: oldField?.value,
            newValue: newField?.value,
            oldEnabled: enabledChanged ? wasEnabled : null,
            newEnabled: enabledChanged ? isEnabled : null,
          ));
        }
      }

      setter(newField);
    }

    applyField(SettingType.frontTyrePressure, oldTyres?.front,
        controller.front, (f) => newTyres.front = f);
    applyField(SettingType.rearTyrePressure, oldTyres?.rear,
        controller.rear, (f) => newTyres.rear = f);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setup?.name ?? 'New Setup'),
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
                _ComponentInfoFields(
                  serialNumberController: _setupFormController.fork.serialNumber,
                  infoUrlController: _setupFormController.fork.infoUrl,
                ),
                const TitleWithIcon(
                    title: 'Shock', icon: SuspensionIcons.shock),
                SettingTiles(
                  settings: widget.setup?.shock,
                  settingsFormController: _setupFormController.shock,
                ),
                _ComponentInfoFields(
                  serialNumberController: _setupFormController.shock.serialNumber,
                  infoUrlController: _setupFormController.shock.infoUrl,
                ),
                const TitleWithIcon(
                    title: 'Tyres', icon: SuspensionIcons.tyre),
                TyreTiles(
                  tyres: widget.setup?.tyres,
                  tyresFormController: _setupFormController.tyres,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: () => _onSetupChanged(context),
        tooltip: 'Save setup',
        child: const Icon(Icons.save),
      ),
    );
  }
}

String? validateInfoUrl(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value.trim());
  if (uri == null || !uri.hasScheme) {
    return 'Please enter a valid URL (e.g. https://...)';
  }
  return null;
}

class _ComponentInfoFields extends StatelessWidget {
  const _ComponentInfoFields({
    required this.serialNumberController,
    required this.infoUrlController,
  });

  final TextEditingController serialNumberController;
  final TextEditingController infoUrlController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('Product Information', style: theme.textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextFormField(
                  controller: serialNumberController,
                  decoration: const InputDecoration(labelText: 'Serial Number'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: infoUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Product Information URL',
                    helperText: "Link to the manufacturer's product page for this component",
                  ),
                  keyboardType: TextInputType.url,
                  validator: validateInfoUrl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
