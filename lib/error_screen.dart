import 'package:flutter/material.dart';

class ErrorScreenWidget extends StatelessWidget {
  final String title;

  final String message;

  const ErrorScreenWidget({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        title: Text(title),
      ),
      body: Align(
        child: Text(
          message,
          style: theme.textTheme.headlineLarge,
        ),
      ),
    );
  }
}
