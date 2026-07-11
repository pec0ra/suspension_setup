import 'package:flutter/material.dart';

/// Shows a dialog with a single text field for entering or editing a comment.
///
/// Returns the trimmed text on save, or `null` if the dialog was dismissed.
/// When [requireNonEmpty] is true, the save action stays disabled until the
/// field contains non-whitespace text (used for entries that only carry a
/// comment, such as notes, where an empty comment would be meaningless).
Future<String?> showCommentDialog(
  BuildContext context, {
  required String title,
  String? initialText,
  String? hintText,
  bool requireNonEmpty = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _CommentDialog(
      title: title,
      initialText: initialText,
      hintText: hintText,
      requireNonEmpty: requireNonEmpty,
    ),
  );
}

class _CommentDialog extends StatefulWidget {
  const _CommentDialog({
    required this.title,
    this.initialText,
    this.hintText,
    required this.requireNonEmpty,
  });

  final String title;
  final String? initialText;
  final String? hintText;
  final bool requireNonEmpty;

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSave =>
      !widget.requireNonEmpty || _controller.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSave) return;
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hintText),
        // Only rebuild to re-evaluate the save button when emptiness matters.
        onChanged: widget.requireNonEmpty ? (_) => setState(() {}) : null,
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canSave ? _submit : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
