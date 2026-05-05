import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'error_screen.dart';
import 'models/setup.dart';
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
          child: SvgPicture.asset("assets/icon/icon-white.svg", colorFilter: ColorFilter.mode(theme.colorScheme.onSurface, BlendMode.srcIn)),
        ),
      ),
      body: Consumer<SetupStorageModel>(
        builder: (context, setupModel, child) {
          if (setupModel.loadError != null) {
            return ErrorScreenWidget(
              title: 'Error',
              message: setupModel.loadError!,
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
                              Text(DateFormat.yMMMd().format(setup.history.last.date)),
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
                    // TODO: add context menu in addition to dialog
                    onLongPress: () => deleteSetup(context, setup, setupModel),
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

  void createSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SetupEdit()),
    );
  }

  Future<String?> deleteSetup(
      BuildContext context, Setup setup, SetupStorageModel setupModel) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Delete Setup ${setup.name} ?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'Cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              await setupModel.deleteSetup(setup);
              if (!context.mounted) return;
              Navigator.pop(context, 'OK');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _backup(BuildContext context) async {
    final success = await Provider.of<SetupStorageModel>(context, listen: false)
        .backup();
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Backup saved successfully')),
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
            style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    await model.restoreFromFile(filePath);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Setups restored successfully')),
    );
  }
}
