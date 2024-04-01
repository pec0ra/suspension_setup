import 'package:flutter/material.dart';

class TitleWithIcon extends StatelessWidget {
  const TitleWithIcon({
    super.key,
    required this.title,
    this.icon,
  });

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                icon,
                size: 24,
              ),
            ),
          Text(
            title,
            style: theme.textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}
