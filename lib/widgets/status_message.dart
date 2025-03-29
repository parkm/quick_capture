import 'package:flutter/material.dart';

class StatusMessage extends StatelessWidget {
  final String? message;

  const StatusMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color textColor;

    if (message!.startsWith('Error')) {
      backgroundColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
    } else if (message!.startsWith('Saved')) {
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
    } else {
      backgroundColor = colorScheme.tertiaryContainer;
      textColor = colorScheme.onTertiaryContainer;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message!,
        style: TextStyle(color: textColor),
      ),
    );
  }
}