import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/setup_form_controller.dart';
import 'models/setting_change.dart';
import 'models/setup.dart';
import 'setting_tiles.dart';
import 'setup_storage_model.dart';
import 'suspension_icons.dart';
import 'title_with_icon.dart';
import 'value_edit.dart';

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
  late final SetupFormController _controller;
  final TextEditingController _commentController = TextEditingController();

  List<FieldFormController> get _allFieldControllers => [
        _controller.fork.airPressure,
        _controller.fork.sag,
        _controller.fork.volumeSpacer,
        _controller.fork.lsc,
        _controller.fork.hsc,
        _controller.fork.lsr,
        _controller.fork.hsr,
        _controller.shock.airPressure,
        _controller.shock.sag,
        _controller.shock.volumeSpacer,
        _controller.shock.lsc,
        _controller.shock.hsc,
        _controller.shock.lsr,
        _controller.shock.hsr,
        _controller.tyres.front,
        _controller.tyres.rear,
      ];

  @override
  void initState() {
    super.initState();
    _controller = SetupFormController(widget.setup);
    for (final field in _allFieldControllers) {
      field.enabled.addListener(_onEnabledChanged);
    }
  }

  void _onEnabledChanged() => setState(() {});

  @override
  void dispose() {
    for (final field in _allFieldControllers) {
      field.enabled.removeListener(_onEnabledChanged);
    }
    _commentController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _hasNewlyEnabled => _controller.hasNewlyEnabledFields(widget.setup);

  Future<void> _onSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final (newSetup, changes) = _controller.buildResult(widget.setup);

    if (widget.setup != null && changes.changes.isNotEmpty) {
      _showCommentDialog(context, () async {
        if (_commentController.text.isNotEmpty) {
          changes.comment = _commentController.text;
        }
        newSetup.history.add(changes);
        await _saveSetup(context, newSetup);
      });
    } else {
      if (widget.setup == null || widget.setup!.history.isEmpty) {
        newSetup.history.add(SettingChanges(
          changes: [],
          date: changes.date,
          comment: 'Setup creation',
          isCreationEntry: true,
        ));
      }
      await _saveSetup(context, newSetup);
    }
  }

  void _showCommentDialog(
      BuildContext context, Future<void> Function() onSave) {
    _commentController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Comment'),
          content: TextField(
            controller: _commentController,
            decoration: const InputDecoration(
                hintText: 'Add a comment to your changes'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await onSave();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSetup(BuildContext context, Setup newSetup) async {
    await Provider.of<SetupStorageModel>(context, listen: false)
        .upsertSetup(newSetup);
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Setup saved successfully')),
    );
  }

  Future<void> _onForwardToValueEdit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ValueEdit(setup: widget.setup, controller: _controller),
      ),
    );

    if (saved == true && context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNewlyEnabled = _hasNewlyEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setup == null ? 'New Setup' : 'Configure Setup'),
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
                  controller: _controller.name,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Setup name cannot be empty';
                    }
                    return null;
                  },
                ),
                const TitleWithIcon(title: 'Fork', icon: SuspensionIcons.fork),
                _ComponentInfoFields(
                  serialNumberController: _controller.fork.serialNumber,
                  infoUrlController: _controller.fork.infoUrl,
                ),
                FieldConfigCard(
                    name: SettingType.airPressure.label,
                    controller: _controller.fork.airPressure),
                FieldConfigCard(
                    name: SettingType.sag.label,
                    controller: _controller.fork.sag),
                FieldConfigCard(
                    name: SettingType.volumeSpacer.label,
                    controller: _controller.fork.volumeSpacer),
                FieldConfigCard(
                    name: SettingType.lsc.label,
                    controller: _controller.fork.lsc),
                FieldConfigCard(
                    name: SettingType.hsc.label,
                    controller: _controller.fork.hsc),
                FieldConfigCard(
                    name: SettingType.lsr.label,
                    controller: _controller.fork.lsr),
                FieldConfigCard(
                    name: SettingType.hsr.label,
                    controller: _controller.fork.hsr),
                const TitleWithIcon(
                    title: 'Shock', icon: SuspensionIcons.shock),
                _ComponentInfoFields(
                  serialNumberController: _controller.shock.serialNumber,
                  infoUrlController: _controller.shock.infoUrl,
                ),
                FieldConfigCard(
                    name: SettingType.airPressure.label,
                    controller: _controller.shock.airPressure),
                FieldConfigCard(
                    name: SettingType.sag.label,
                    controller: _controller.shock.sag),
                FieldConfigCard(
                    name: SettingType.volumeSpacer.label,
                    controller: _controller.shock.volumeSpacer),
                FieldConfigCard(
                    name: SettingType.lsc.label,
                    controller: _controller.shock.lsc),
                FieldConfigCard(
                    name: SettingType.hsc.label,
                    controller: _controller.shock.hsc),
                FieldConfigCard(
                    name: SettingType.lsr.label,
                    controller: _controller.shock.lsr),
                FieldConfigCard(
                    name: SettingType.hsr.label,
                    controller: _controller.shock.hsr),
                const TitleWithIcon(title: 'Tyres', icon: SuspensionIcons.tyre),
                FieldConfigCard(
                    name: SettingType.frontTyrePressure.label,
                    controller: _controller.tyres.front),
                FieldConfigCard(
                    name: SettingType.rearTyrePressure.label,
                    controller: _controller.tyres.rear),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: hasNewlyEnabled
            ? () => _onForwardToValueEdit(context)
            : () => _onSave(context),
        tooltip: hasNewlyEnabled ? 'Edit values' : 'Save setup',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            final isEntering =
                (child.key as ValueKey<bool>).value == hasNewlyEnabled;
            // Exiting: 0.0→0.5 turns (0°→180°), Entering: 0.5→1.0 (180°→360°)
            // Both clockwise — exit hands off seamlessly to the entering icon.
            final rotateTween = isEntering
                ? Tween(begin: 0.5, end: 1.0)
                : Tween(begin: 0.5, end: 0.0);
            return ScaleTransition(
              scale: animation,
              child: RotationTransition(
                turns: rotateTween.animate(animation),
                child: child,
              ),
            );
          },
          child: Icon(
            hasNewlyEnabled ? Icons.arrow_forward : Icons.save,
            key: ValueKey(hasNewlyEnabled),
          ),
        ),
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
            title:
                Text('Product Information', style: theme.textTheme.titleMedium),
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
                    helperText:
                        "Link to the manufacturer's product page for this component",
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
