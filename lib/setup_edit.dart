import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'draggable_grid.dart';
import 'models/setup_form_controller.dart';
import 'models/setup.dart';
import 'setting_tiles.dart';
import 'setup_commit.dart';
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

const _kEditGridHintSeen = 'edit_grid_hint_seen';

class _SetupEditState extends State<SetupEdit> {
  final _formKey = GlobalKey<FormState>();
  late final SetupFormController _controller;
  bool _showGridHint = false;

  @override
  void initState() {
    super.initState();
    _controller = SetupFormController(widget.setup);
    _initGridHint();
  }

  Future<void> _initGridHint() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kEditGridHintSeen) ?? false) return;
    final hasAnyField = _controller.fork.layout.isNotEmpty ||
        _controller.shock.layout.isNotEmpty ||
        _controller.tyres.layout.isNotEmpty;
    if (!hasAnyField) return;
    await prefs.setBool(_kEditGridHintSeen, true);
    if (mounted) setState(() => _showGridHint = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasNewlyAdded => _controller.hasNewlyAddedFields();

  List<FieldFormController> get _allFieldControllers => [
        ..._controller.fork.fields,
        ..._controller.shock.fields,
        ..._controller.tyres.fields,
      ];

  Future<void> _onSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    await commitSetup(
      context: context,
      controller: _controller,
      originalSetup: widget.setup,
      saveSetup: _saveSetup,
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

    final valueSnapshot = {
      for (final ctrl in _allFieldControllers) ctrl: ctrl.value.text,
    };

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ValueEdit(setup: widget.setup, controller: _controller),
      ),
    );

    if (saved == true) {
      if (context.mounted) Navigator.pop(context);
    } else {
      for (final entry in valueSnapshot.entries) {
        entry.key.value.text = entry.value;
      }
    }
  }

  void _showAddFieldDialog(
      BuildContext context, SectionFormController section) {
    showDialog<({String name, String unit})>(
      context: context,
      builder: (ctx) => const _AddFieldDialog(),
    ).then((result) {
      if (result != null) {
        section.addField(result.name, result.unit);
        setState(() {});
      }
    });
  }

  void _showEditFieldSheet(BuildContext context, SectionFormController section,
      FieldFormController fieldCtrl) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _EditFieldSheet(
        controller: fieldCtrl,
        onDelete: () => Navigator.pop(ctx, true),
      ),
    ).then((deleted) {
      if (deleted == true) {
        section.removeField(fieldCtrl.id);
      }
      setState(() {});
    });
  }

  Widget _buildSectionGrid(SectionFormController section) {
    if (section.layout.isEmpty) return const SizedBox.shrink();
    final ctrlMap = {for (final f in section.fields) f.id: f};
    return DraggableGrid(
      layout: section.layout,
      itemBuilder: (id) {
        final ctrl = ctrlMap[id];
        if (ctrl == null) return const SizedBox.shrink();
        return FieldConfigTile(controller: ctrl);
      },
      onLayoutChanged: (newLayout) =>
          setState(() => section.layout = newLayout),
      onItemTap: (id) {
        final ctrl = ctrlMap[id];
        if (ctrl == null) return;
        _showEditFieldSheet(context, section, ctrl);
      },
    );
  }

  Widget _buildSection(
    SectionFormController section, {
    bool showComponentInfo = false,
    bool showGridHint = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (showComponentInfo)
          _ComponentInfoFields(
            serialNumberController: section.serialNumber,
            infoUrlController: section.infoUrl,
          ),
        if (showGridHint && section.layout.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Tap to edit',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(width: 16),
                Icon(Icons.drag_indicator,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Hold to reorder',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        _buildSectionGrid(section),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: OutlinedButton.icon(
            onPressed: () => _showAddFieldDialog(context, section),
            icon: const Icon(Icons.add),
            label: const Text('Add field'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNewlyAdded = _hasNewlyAdded;

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
                _buildSection(_controller.fork,
                    showComponentInfo: true,
                    showGridHint:
                        _showGridHint && _controller.fork.layout.isNotEmpty),
                const TitleWithIcon(
                    title: 'Shock', icon: SuspensionIcons.shock),
                _buildSection(_controller.shock,
                    showComponentInfo: true,
                    showGridHint: _showGridHint &&
                        _controller.fork.layout.isEmpty &&
                        _controller.shock.layout.isNotEmpty),
                const TitleWithIcon(title: 'Tyres', icon: SuspensionIcons.tyre),
                _buildSection(_controller.tyres,
                    showGridHint: _showGridHint &&
                        _controller.fork.layout.isEmpty &&
                        _controller.shock.layout.isEmpty &&
                        _controller.tyres.layout.isNotEmpty),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: hasNewlyAdded
            ? () => _onForwardToValueEdit(context)
            : () => _onSave(context),
        tooltip: hasNewlyAdded ? 'Edit values' : 'Save setup',
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            final isEntering =
                (child.key as ValueKey<bool>).value == hasNewlyAdded;
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
            hasNewlyAdded ? Icons.arrow_forward : Icons.save,
            key: ValueKey(hasNewlyAdded),
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

class _AddFieldDialog extends StatefulWidget {
  const _AddFieldDialog();

  @override
  State<_AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<_AddFieldDialog> {
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add field'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Field name'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _unitCtrl,
            decoration: const InputDecoration(labelText: 'Unit (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, (name: name, unit: _unitCtrl.text.trim()));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _EditFieldSheet extends StatelessWidget {
  const _EditFieldSheet({
    required this.controller,
    required this.onDelete,
  });

  final FieldFormController controller;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit field', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: controller.name,
            decoration: const InputDecoration(labelText: 'Field name'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.unit,
            decoration: const InputDecoration(labelText: 'Unit (optional)'),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete),
            label: const Text('Delete field'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
