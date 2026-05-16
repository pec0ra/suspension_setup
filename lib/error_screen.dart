import 'package:flutter/material.dart';
import 'package:suspension_setup/setup_file_utils.dart';

class ErrorScreenWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRestore;

  const ErrorScreenWidget({
    super.key,
    required this.message,
    this.onRestore,
  });

  ErrorScreenWidget.fromLoadError({
    super.key,
    required SetupLoadException error,
    VoidCallback? onRestore,
  })  : message = error.message,
        onRestore = switch (error) {
          SetupCorruptFileException() => onRestore,
          SetupVersionTooNewException() => null,
        };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (onRestore != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.file_open),
                label: const Text('Restore from backup'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
