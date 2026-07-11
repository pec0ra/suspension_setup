import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:suspension_setup/error_screen.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/suspension_icons.dart';
import 'package:suspension_setup/text_with_icon.dart';
import 'package:url_launcher/url_launcher.dart';

import 'comment_dialog.dart';
import 'models/setting_change.dart';
import 'models/settings.dart';
import 'setting_tiles.dart';
import 'setup_actions.dart';
import 'setup_edit.dart';
import 'setup_snapshot.dart';
import 'setup_storage_model.dart';
import 'title_with_icon.dart';
import 'value_edit.dart';

class SetupDetail extends StatelessWidget {
  const SetupDetail({
    super.key,
    required this.setupId,
  });

  final String setupId;

  @override
  Widget build(BuildContext context) {
    return Consumer<SetupStorageModel>(builder: (context, setupModel, child) {
      var setup = setupModel.getSetup(setupId);
      if (setup == null) {
        return const ErrorScreenWidget(message: 'Setup not found');
      } else {
        final hasValueFields = setup.fork.activeFields.isNotEmpty ||
            setup.shock.activeFields.isNotEmpty ||
            setup.tyres.activeFields.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(setup.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Configure setup',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SetupEdit(setup: setup)),
                ),
              ),
              OverflowMenu(setup: setup)
            ],
          ),
          floatingActionButton: hasValueFields
              ? FloatingActionButton(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ValueEdit(setup: setup)),
                  ),
                  tooltip: 'Edit values',
                  child: const Icon(Icons.tune),
                )
              : null,
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
                    _ComponentInfo(section: setup.fork),
                    SettingTiles(section: setup.fork),
                  ],
                  if (setup.shock.hasAnyField) ...[
                    const TitleWithIcon(
                        title: 'Shock', icon: SuspensionIcons.shock),
                    _ComponentInfo(section: setup.shock),
                    SettingTiles(section: setup.shock),
                  ],
                  if (setup.tyres.hasAnyField) ...[
                    const TitleWithIcon(
                        title: 'Tyres', icon: SuspensionIcons.tyre),
                    SettingTiles(section: setup.tyres),
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

class _ComponentInfo extends StatelessWidget {
  const _ComponentInfo({required this.section});

  final SectionSettings section;

  @override
  Widget build(BuildContext context) {
    final sn = section.serialNumber;
    final url = section.infoUrl;
    if (sn == null && url == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title:
                Text('Product Information', style: theme.textTheme.titleMedium),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (sn != null) ...[
                  Icon(Icons.tag,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serial Number',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(sn, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
                if (url != null)
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Manufacturer Page'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
              'No fields configured yet. Add fields in the setup configuration.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.settings),
              label: const Text('Configure setup'),
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
    final section = switch (change.suspensionType) {
      SuspensionType.fork => setup.fork,
      SuspensionType.shock => setup.shock,
      SuspensionType.tyre => setup.tyres,
    };
    final field = section.fieldById(change.fieldId);
    final label = field?.name ?? 'Unknown field';
    final unit = field?.unit ?? '';

    if (change.newEnabled == true) {
      return '$label: enabled (${change.newValue} $unit)'.trim();
    }
    if (change.newEnabled == false) {
      return '$label: disabled (was ${change.oldValue} $unit)'.trim();
    }
    return '$label: ${change.oldValue} → ${change.newValue} $unit'.trim();
  }

  IconData _iconFor(SuspensionType type) => switch (type) {
        SuspensionType.fork => SuspensionIcons.fork,
        SuspensionType.shock => SuspensionIcons.shock,
        SuspensionType.tyre => SuspensionIcons.tyre,
      };

  Future<void> _performUndo(
    BuildContext context,
    SettingChanges historyEntry,
    List<SettingChange> actualChanges,
  ) async {
    final newSetup = setup.copyMutable();
    newSetup.applyChanges(actualChanges);

    final originalComment = historyEntry.comment;
    final String autoComment;
    if (originalComment != null && originalComment.isNotEmpty) {
      autoComment = 'Undo: $originalComment';
    } else {
      autoComment =
          'Undo: ${DateFormat.yMMMd().add_Hm().format(historyEntry.date)}';
    }

    newSetup.history.add(SettingChanges(
      changes: actualChanges,
      date: DateTime.now(),
      comment: autoComment,
    ));

    await Provider.of<SetupStorageModel>(context, listen: false)
        .upsertSetup(newSetup);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Changes undone'),
      ),
    );
  }

  void _handleUndo(BuildContext context, SettingChanges historyEntry) {
    final actualChanges = setup.computeUndo(historyEntry);

    if (actualChanges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content:
              Text('Nothing to undo — values are already at those settings'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Undo change?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The following values will be reverted:'),
              const SizedBox(height: 8),
              for (final change in actualChanges)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextWithIcon(
                    text: _changeText(change, setup),
                    icon: _iconFor(change.suspensionType),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _performUndo(context, historyEntry, actualChanges);
            },
            child: const Text('Undo'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddNoteDialog(BuildContext context) async {
    final model = Provider.of<SetupStorageModel>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final note = await showCommentDialog(
      context,
      title: 'Add note',
      hintText: 'Add a note',
      requireNonEmpty: true,
    );
    if (note == null) return;
    final newSetup = setup.copyMutable();
    newSetup.history.add(SettingChanges(
      changes: [],
      date: DateTime.now(),
      comment: note,
    ));
    await model.upsertSetup(newSetup);
    messenger.showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Note added'),
      ),
    );
  }

  Future<void> _showEditCommentDialog(
      BuildContext context, SettingChanges entry) async {
    final model = Provider.of<SetupStorageModel>(context, listen: false);
    final newComment = await showCommentDialog(
      context,
      title: 'Edit comment',
      initialText: entry.comment ?? '',
      hintText: 'Add a comment',
      // A comment-only entry (note or creation) would become a blank card if
      // its comment were cleared, so require text in that case.
      requireNonEmpty: entry.changes.isEmpty,
    );
    if (newComment == null) return;
    final newSetup = setup.copyMutable();
    final target = newSetup.history.firstWhere((e) => e.id == entry.id);
    target.comment = newComment.isEmpty ? null : newComment;
    await model.upsertSetup(newSetup);
  }

  void _showHistoryItemSheet(BuildContext context, SettingChanges entry) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                DateFormat.yMMMd().add_Hm().format(entry.date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: (entry.comment != null && entry.comment!.isNotEmpty)
                  ? Text(entry.comment!)
                  : null,
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.history_toggle_off),
              title: const Text('View snapshot'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SetupSnapshotPage(
                      snapshot: setup.snapshotAt(entry),
                      date: entry.date,
                      comment: entry.comment,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit comment'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditCommentDialog(context, entry);
              },
            ),
            if (entry.changes.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.undo),
                title: const Text('Undo this change'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _handleUndo(context, entry);
                },
              ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
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
        TitleWithIcon(
          title: 'History',
          action: IconButton(
            icon: const Icon(Icons.add_comment),
            tooltip: 'Add note',
            onPressed: () => _showAddNoteDialog(context),
          ),
        ),
        for (SettingChanges settingChange in setup.history.reversed)
          Card(
            color: Color.alphaBlend(
              theme.colorScheme.secondary.withValues(alpha: 0.05),
              theme.colorScheme.surfaceContainerLow,
            ),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: InkWell(
              onTap: () => _showHistoryItemSheet(context, settingChange),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(DateFormat.yMMMd()
                                .add_Hm()
                                .format(settingChange.date)),
                          ),
                          if (settingChange.comment != null &&
                              settingChange.comment!.isNotEmpty) ...[
                            Divider(
                              color: theme.colorScheme.secondary
                                  .withValues(alpha: 0.3),
                              height: 0,
                            ),
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
                          ],
                          if (settingChange.changes.isNotEmpty)
                            Divider(
                              color: theme.colorScheme.secondary
                                  .withValues(alpha: 0.3),
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
                        icon: _iconFor(change.suspensionType),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class OverflowMenu extends StatelessWidget {
  const OverflowMenu({super.key, required this.setup});

  final Setup setup;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () => showCloneSetupDialog(context, setup,
              onConfirm: (copyHistory) =>
                  navigateToClone(context, setup, copyHistory, replace: true)),
          child: const Row(
            spacing: 12,
            children: [Icon(Icons.copy), Text('Clone')],
          ),
        ),
        PopupMenuItem(
          onTap: () => showDeleteSetupDialog(
            context,
            setup,
            Provider.of<SetupStorageModel>(context, listen: false),
            onDeleted: () {
              if (!context.mounted) return;
              Navigator.pop(context);
            },
          ),
          child: const Row(
            spacing: 12,
            children: [Icon(Icons.delete), Text('Delete')],
          ),
        ),
      ],
    );
  }
}
