import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Widget _sectionRows(SectionFormController section) {
    final rows = section.layoutControllers;
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final row in rows)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final ctrl in row)
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: FieldValueCard(controller: ctrl),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = _controller;
    final hasFork = ctrl.fork.layoutControllers.isNotEmpty;
    final hasShock = ctrl.shock.layoutControllers.isNotEmpty;
    final hasTyres = ctrl.tyres.layoutControllers.isNotEmpty;

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
                  _sectionRows(ctrl.fork),
                ],
                if (hasShock) ...[
                  const TitleWithIcon(
                      title: 'Shock', icon: SuspensionIcons.shock),
                  _sectionRows(ctrl.shock),
                ],
                if (hasTyres) ...[
                  const TitleWithIcon(
                      title: 'Tyres', icon: SuspensionIcons.tyre),
                  _sectionRows(ctrl.tyres),
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
