import 'package:flutter/material.dart';

class TextfieldDescription extends StatelessWidget {
  const TextfieldDescription({
    required this.title,
    required this.hittext,
    required this.controller,
    this.validator, // Сделал опциональным
    this.keyboardType, // Добавил как поле класса
    this.isTextArea = false, // Добавил параметр для textarea
    super.key,
  });

  final String title;
  final String hittext;
  final TextEditingController controller;
  final String? Function(String?)? validator; // Опциональный
  final TextInputType? keyboardType; // Опциональный
  final bool isTextArea; // Новый параметр

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          validator: validator,
          controller: controller,
          keyboardType: keyboardType,
          maxLines: isTextArea ? 5 : 1, // Увеличил для textarea
          minLines: isTextArea ? 4 : 1,
          decoration: InputDecoration(
            hintText: hittext,
            hintStyle: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
            alignLabelWithHint: isTextArea,
          ),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
