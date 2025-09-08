import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_book/helpers/form_field_states.dart';

class SpecializationDropdown extends StatelessWidget {
  const SpecializationDropdown({
    required this.title,
    required this.selectedValue,
    required this.onChanged,
    this.validator,
    super.key,
  });

  final String title;
  final String? selectedValue; // здесь id документа
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('training_types')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return buildLoadingField(context);
            }
            if (snapshot.hasError) return buildErrorField(context);

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return buildEmptyField(
                context,
                message: 'Сначала добавьте типы тренировок',
              );
            }

            final items = docs.map((doc) {
              final name = doc.get('name') as String? ?? '';
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(name, style: textTheme.bodyMedium),
              );
            }).toList();

            final safeValue = items.any((item) => item.value == selectedValue)
                ? selectedValue
                : null;

            return DropdownButtonFormField<String>(
              key: ValueKey<String?>(safeValue),
              initialValue: safeValue,
              items: items,
              onChanged: onChanged,
              validator: validator,
              decoration: InputDecoration(
                hintText: 'Выберите специализацию',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              isExpanded: true,
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
