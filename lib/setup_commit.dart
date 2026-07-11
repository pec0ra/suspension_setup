import 'package:flutter/material.dart';

import 'comment_dialog.dart';
import 'models/setting_change.dart';
import 'models/setup.dart';
import 'models/setup_form_controller.dart';

Future<void> commitSetup({
  required BuildContext context,
  required SetupFormController controller,
  required Setup? originalSetup,
  required Future<void> Function(BuildContext, Setup) saveSetup,
}) async {
  final (newSetup, changes) = controller.buildResult(originalSetup);

  if (originalSetup != null && changes.changes.isNotEmpty) {
    final comment = await showCommentDialog(
      context,
      title: 'Comment',
      hintText: 'Add a comment to your changes (optional)',
    );
    if (comment == null) return; // Dismissed without saving.
    if (comment.isNotEmpty) {
      changes.comment = comment;
    }
    newSetup.history.add(changes);
    if (!context.mounted) return;
    await saveSetup(context, newSetup);
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
