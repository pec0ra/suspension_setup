import 'package:flutter/material.dart';

class TextWithIcon extends StatelessWidget {
  const TextWithIcon({
    super.key,
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(icon),
        ),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }
}
