import 'package:flutter/material.dart';

import 'models/setting_change.dart';
import 'models/setup.dart';
import 'models/setup_form_controller.dart';

Future<void> commitSetup({
  required BuildContext context,
  required SetupFormController controller,
  required Setup? originalSetup,
  required TextEditingController commentController,
  required Future<void> Function(BuildContext, Setup) saveSetup,
}) async {
  final (newSetup, changes) = controller.buildResult(originalSetup);

  if (originalSetup != null && changes.changes.isNotEmpty) {
    showSetupCommentDialog(context, commentController, () async {
      if (commentController.text.isNotEmpty) {
        changes.comment = commentController.text;
      }
      newSetup.history.add(changes);
      await saveSetup(context, newSetup);
    });
  } else {
    if (originalSetup == null || originalSetup.history.isEmpty) {
      newSetup.history.add(SettingChanges(
        changes: [],
        date: changes.date,
        comment: 'Setup creation',
        isCreationEntry: true,
      ));
    }
    await saveSetup(context, newSetup);
  }
}

void showSetupCommentDialog(
  BuildContext context,
  TextEditingController commentController,
  Future<void> Function() onSave,
) {
  commentController.clear();
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Comment'),
        content: TextField(
          controller: commentController,
          decoration: const InputDecoration(
              hintText: 'Add a comment to your changes (optional)'),
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
