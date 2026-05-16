import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:suspension_setup/models/setup.dart';
import 'package:suspension_setup/suspension_icons.dart';

import 'setting_tiles.dart';
import 'title_with_icon.dart';

class SetupSnapshotPage extends StatelessWidget {
  const SetupSnapshotPage({
    super.key,
    required this.snapshot,
    required this.date,
    this.comment,
  });

  final Setup snapshot;
  final DateTime date;
  final String? comment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMd().add_Hm().format(date)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              if (comment != null && comment!.isNotEmpty)
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(
                          'Comment',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Divider(height: 0),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Text(comment!),
                      ),
                    ],
                  ),
                ),
              if (!snapshot.fork.hasAnyField &&
                  !snapshot.shock.hasAnyField &&
                  !snapshot.tyres.hasAnyField)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No settings were recorded at this point',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              if (snapshot.fork.hasAnyField) ...[
                const TitleWithIcon(title: 'Fork', icon: SuspensionIcons.fork),
                SettingTiles(settings: snapshot.fork),
              ],
              if (snapshot.shock.hasAnyField) ...[
                const TitleWithIcon(
                    title: 'Shock', icon: SuspensionIcons.shock),
                SettingTiles(settings: snapshot.shock),
              ],
              if (snapshot.tyres.hasAnyField) ...[
                const TitleWithIcon(title: 'Tyres', icon: SuspensionIcons.tyre),
                TyreTiles(tyres: snapshot.tyres),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
