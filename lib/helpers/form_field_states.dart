import 'package:flutter/material.dart';

const double kFieldHeight = 60;

Widget buildLoadingField(BuildContext context) {
  final theme = Theme.of(context);
  return Container(
    height: kFieldHeight,
    decoration: BoxDecoration(
      border: Border.all(color: theme.dividerColor),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

Widget buildErrorField(
  BuildContext context, {
  String message = 'Ошибка загрузки',
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(
    height: kFieldHeight,
    decoration: BoxDecoration(
      border: Border.all(color: colorScheme.error),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Text(message, style: TextStyle(color: colorScheme.error)),
    ),
  );
}

Widget buildEmptyField(BuildContext context, {String message = 'Нет данных'}) {
  final textTheme = Theme.of(context).textTheme;
  final colorScheme = Theme.of(context).colorScheme;
  return Container(
    height: kFieldHeight,
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
