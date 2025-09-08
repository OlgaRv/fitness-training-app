import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_book/helpers/form_field_states.dart';

class StatusDropdown extends StatelessWidget {
  const StatusDropdown({
    required this.title,
    required this.selectedValue,
    required this.onChanged,
    this.validator,
    super.key,
  });

  final String title;
  final String? selectedValue; // id документа
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
              .collection('statuses')
              .orderBy('status')
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
                message: 'Сначала добавьте статус',
              );
            }

            final items = docs.map((doc) {
              final name = doc.get('status') as String? ?? '';
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text(name, style: textTheme.bodyMedium),
              );
            }).toList();

            final safeValue = items.any((item) => item.value == selectedValue)
                ? selectedValue
                : null;

            return DropdownButtonFormField<String>(
              value: safeValue,
              items: items,
              onChanged: onChanged,
              validator: validator,
              decoration: InputDecoration(
                hintText: 'Выберите статус',
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
