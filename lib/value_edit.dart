import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/setting_change.dart';
import 'models/setup_form_controller.dart';
import 'models/setup.dart';
import 'setting_tiles.dart';
import 'setup_commit.dart';
import 'setup_storage_model.dart';
import 'suspension_icons.dart';
import 'title_with_icon.dart';

class ValueEdit extends StatefulWidget {
  const ValueEdit({
    super.key,
    required this.setup,
    this.controller,
  });

  final Setup? setup;
  final SetupFormController? controller;

  @override
  State<ValueEdit> createState() => _ValueEditState();
}

class _ValueEditState extends State<ValueEdit> {
  final _formKey = GlobalKey<FormState>();
  late final SetupFormController _controller;
  late final bool _ownsController;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = SetupFormController(widget.setup);
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _onSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    await commitSetup(
      context: context,
      controller: _controller,
      originalSetup: widget.setup,
      commentController: _commentController,
      saveSetup: _saveSetup,
    );
  }

  Future<void> _saveSetup(BuildContext context, Setup newSetup) async {
    await Provider.of<SetupStorageModel>(context, listen: false)
        .upsertSetup(newSetup);
    if (!context.mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Setup saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = _controller;

    Widget group(List<({String name, FieldFormController ctrl})> specs) {
      final enabled = specs.where((e) => e.ctrl.enabled.value).toList();
      if (enabled.isEmpty) return const SizedBox.shrink();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in enabled)
            Expanded(
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: FieldValueCard(name: e.name, controller: e.ctrl),
                ),
              ),
            ),
        ],
      );
    }

    final hasFork = ctrl.fork.airPressure.enabled.value ||
        ctrl.fork.sag.enabled.value ||
        ctrl.fork.volumeSpacer.enabled.value ||
        ctrl.fork.lsc.enabled.value ||
        ctrl.fork.hsc.enabled.value ||
        ctrl.fork.lsr.enabled.value ||
        ctrl.fork.hsr.enabled.value;

    final hasShock = ctrl.shock.airPressure.enabled.value ||
        ctrl.shock.sag.enabled.value ||
        ctrl.shock.volumeSpacer.enabled.value ||
        ctrl.shock.lsc.enabled.value ||
        ctrl.shock.hsc.enabled.value ||
        ctrl.shock.lsr.enabled.value ||
        ctrl.shock.hsr.enabled.value;

    final hasTyres =
        ctrl.tyres.front.enabled.value || ctrl.tyres.rear.enabled.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setup?.name ?? ctrl.name.text),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
            child: Column(
              children: [
                if (hasFork) ...[
                  const TitleWithIcon(
                      title: 'Fork', icon: SuspensionIcons.fork),
                  group([
                    (
                      name: SettingType.airPressure.label,
                      ctrl: ctrl.fork.airPressure
                    ),
                    (name: SettingType.sag.label, ctrl: ctrl.fork.sag),
                    (
                      name: SettingType.volumeSpacer.label,
                      ctrl: ctrl.fork.volumeSpacer
                    ),
                  ]),
                  group([
                    (name: SettingType.lsc.label, ctrl: ctrl.fork.lsc),
                    (name: SettingType.hsc.label, ctrl: ctrl.fork.hsc),
                  ]),
                  group([
                    (name: SettingType.lsr.label, ctrl: ctrl.fork.lsr),
                    (name: SettingType.hsr.label, ctrl: ctrl.fork.hsr),
                  ]),
                ],
                if (hasShock) ...[
                  const TitleWithIcon(
                      title: 'Shock', icon: SuspensionIcons.shock),
                  group([
                    (
                      name: SettingType.airPressure.label,
                      ctrl: ctrl.shock.airPressure
                    ),
                    (name: SettingType.sag.label, ctrl: ctrl.shock.sag),
                    (
                      name: SettingType.volumeSpacer.label,
                      ctrl: ctrl.shock.volumeSpacer
                    ),
                  ]),
                  group([
                    (name: SettingType.lsc.label, ctrl: ctrl.shock.lsc),
                    (name: SettingType.hsc.label, ctrl: ctrl.shock.hsc),
                  ]),
                  group([
                    (name: SettingType.lsr.label, ctrl: ctrl.shock.lsr),
                    (name: SettingType.hsr.label, ctrl: ctrl.shock.hsr),
                  ]),
                ],
                if (hasTyres) ...[
                  const TitleWithIcon(
                      title: 'Tyres', icon: SuspensionIcons.tyre),
                  group([
                    (
                      name: SettingType.frontTyrePressure.label,
                      ctrl: ctrl.tyres.front
                    ),
                    (
                      name: SettingType.rearTyrePressure.label,
                      ctrl: ctrl.tyres.rear
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: () => _onSave(context),
        tooltip: 'Save values',
        child: const Icon(Icons.save),
      ),
    );
  }
}
