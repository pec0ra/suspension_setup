import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

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
        backgroundColor: theme.colorScheme.background,
        title: Text(widget.title),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.save),
                  title: Text('Backup'),
                ),
                onTap: () => _backup(context),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.file_open),
                  title: Text('Restore'),
                ),
                onTap: () => _restore(context),
              ),
            ],
          )
        ],
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(14, 7, 0, 7),
          child: SvgPicture.asset("assets/icon/icon-white.svg", color: theme.colorScheme.onBackground,),
        ),
      ),
      body: Consumer<SetupStorageModel>(
        builder: (context, setupModel, child) {
          var setupList = setupModel.getSetupList();
          return ListView(
            padding: const EdgeInsets.all(8),
            children: <Widget>[
              if (setupList.isEmpty)
                Align(
                  heightFactor: 4,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Text(
                          'You have no setup yet',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      ElevatedButton(
                          onPressed: createSetup,
                          child: const Text('Add a setup'))
                    ],
                  ),
                ),
              for (Setup setup in setupList.reversed)
                ListTile(
                  title: Text(setup.name),
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
                )
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
            onPressed: () {
              setupModel.deleteSetup(setup);
              Navigator.pop(context, 'OK');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _backup(BuildContext context) async {
    await Provider.of<SetupStorageModel>(context, listen: false)
        .backup()
        .then((value) => {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup saved successfully')),
              )
            });
  }

  void _restore(BuildContext context) async {
    await Provider.of<SetupStorageModel>(context, listen: false)
        .restore()
        .then((value) => {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setups restored successfully')),
      )
    });
  }
}
