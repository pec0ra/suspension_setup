import 'package:flutter/material.dart';

// Width reserved on each side of a title so that an optional trailing [action]
// button can sit at the right edge while the title stays horizontally centered.
const double _kActionSlotWidth = 48;

class TitleWithIcon extends StatelessWidget {
  const TitleWithIcon({
    super.key,
    required this.title,
    this.icon,
    this.action,
  });

  final String title;
  final IconData? icon;

  /// Optional trailing widget (typically an [IconButton]) shown at the right
  /// edge of the header. The title remains centered regardless.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleContent = Wrap(
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
          style: theme.textTheme.titleLarge,
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: action == null
          ? titleContent
          : Row(
              children: [
                const SizedBox(width: _kActionSlotWidth),
                Expanded(child: Center(child: titleContent)),
                SizedBox(width: _kActionSlotWidth, child: action),
              ],
            ),
    );
  }
}
