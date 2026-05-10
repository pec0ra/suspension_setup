import 'package:flutter/material.dart';

import 'models/setup.dart';
import 'setup_edit.dart';
import 'setup_storage_model.dart';

Future<void> showCloneSetupDialog(
  BuildContext context,
  Setup setup, {
  required void Function(bool copyHistory) onConfirm,
}) async {
  var copyHistory = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Clone Setup \'${setup.name}\'?'),
      content: StatefulBuilder(
        builder: (context, setState) => CheckboxListTile(
          value: copyHistory,
          title: const Text('Copy history'),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) => setState(() => copyHistory = value ?? false),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            onConfirm(copyHistory);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> showDeleteSetupDialog(
  BuildContext context,
  Setup setup,
  SetupStorageModel model, {
  VoidCallback? onDeleted,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete Setup \'${setup.name}\'?'),
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
            await model.deleteSetup(setup);
            if (!dialogContext.mounted) return;
            Navigator.pop(dialogContext);
            onDeleted?.call();
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

void navigateToClone(BuildContext context, Setup setup, bool copyHistory,
    {bool replace = false}) {
  final route = MaterialPageRoute(
    builder: (context) => SetupEdit(setup: setup.clone(copyHistory)),
  );
  if (replace) {
    Navigator.pushReplacement(context, route);
  } else {
    Navigator.push(context, route);
  }
}
