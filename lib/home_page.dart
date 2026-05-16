import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'error_screen.dart';
import 'setup_file_utils.dart';
import 'models/setup.dart';
import 'setup_actions.dart';
import 'setup_detail.dart';
import 'setup_edit.dart';
import 'setup_storage_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    Provider.of<SetupStorageModel>(context, listen: false).initSetups();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => _backup(context),
                child: const Row(
                  spacing: 12,
                  children: [
                    Icon(Icons.save),
                    Text('Backup'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => _restore(context),
                child: const Row(
                  spacing: 12,
                  children: [
                    Icon(Icons.file_open),
                    Text('Restore'),
                  ],
                ),
              ),
            ],
          )
        ],
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(14, 7, 0, 7),
          child: SvgPicture.asset("assets/icon/icon-white.svg",
              colorFilter: ColorFilter.mode(
                  theme.colorScheme.onSurface, BlendMode.srcIn)),
        ),
      ),
      body: Consumer<SetupStorageModel>(
        builder: (context, setupModel, child) {
          if (setupModel.loadError != null) {
            return ErrorScreenWidget.fromLoadError(
              error: setupModel.loadError!,
              onRestore: () => _restore(context),
            );
          }
          var setupList = setupModel.getSetupList();
          if (setupList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    "assets/icon/icon-white.svg",
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      BlendMode.srcIn,
                    ),
                    width: 80,
                    height: 80,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'You have no setup yet',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: createSetup,
                    icon: const Icon(Icons.add),
                    label: const Text('Add a setup'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              for (Setup setup in setupList.reversed)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    title: Text(setup.name),
                    subtitle: setup.history.isNotEmpty
                        ? Row(
                            spacing: 4,
                            children: [
                              Icon(Icons.history, size: 14),
                              Text(DateFormat.yMMMd()
                                  .format(setup.history.last.date)),
                            ],
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SetupDetail(
                                  setupId: setup.id,
                                )),
                      );
                    },
                    onLongPress: () =>
                        _showSetupSheet(context, setup, setupModel),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        onPressed: createSetup,
        tooltip: 'Add setup',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _showSetupSheet(
      BuildContext context, Setup setup, SetupStorageModel setupModel) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(setup.name, style: theme.textTheme.titleMedium),
              subtitle: setup.history.isNotEmpty
                  ? Text(DateFormat.yMMMd().format(setup.history.last.date))
                  : null,
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Clone'),
              onTap: () {
                Navigator.pop(sheetContext);
                showCloneSetupDialog(context, setup,
                    onConfirm: (copyHistory) =>
                        navigateToClone(context, setup, copyHistory));
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.error),
              title: Text('Delete',
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () {
                Navigator.pop(sheetContext);
                showDeleteSetupDialog(context, setup, setupModel);
              },
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void createSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SetupEdit()),
    );
  }

  Future<void> _backup(BuildContext context) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _showBackupBottomSheet(context);
    } else {
      await _saveToDevice(context);
    }
  }

  void _showBackupBottomSheet(BuildContext context) {
    final model = Provider.of<SetupStorageModel>(context, listen: false);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Save backup',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('Save to device'),
            onTap: () {
              Navigator.pop(sheetContext);
              _saveToDevice(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(sheetContext);
              model.shareBackup();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _saveToDevice(BuildContext context) async {
    final success = await Provider.of<SetupStorageModel>(context, listen: false)
        .saveBackupToDevice();
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Backup saved successfully')),
      );
    }
  }

  Future<void> _restore(BuildContext context) async {
    final model = Provider.of<SetupStorageModel>(context, listen: false);
    final filePath = await model.pickBackupFile();
    if (filePath == null) return;
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
            'This will replace all your current setups with the backup. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await model.restoreFromFile(filePath);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Setups restored successfully')),
      );
    } on SetupLoadException catch (e) {
      if (!context.mounted) return;
      final colors = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.errorContainer,
          content:
              Text(e.message, style: TextStyle(color: colors.onErrorContainer)),
        ),
      );
    }
  }
}
