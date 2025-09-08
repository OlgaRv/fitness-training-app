import 'package:flutter/material.dart';

class TrainerCard extends StatelessWidget {
  const TrainerCard({
    required this.name,
    required this.specialization,
    required this.experience,
    required this.description,
    required this.rating,
    this.onTap,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final String name;
  final String specialization;
  final String experience;
  final String description;
  final int rating;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  // Виджет для отображения звездочек рейтинга
  Widget _buildRatingStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating
              ? const Color(0xFFFFB800)
              : const Color(0xFFE0E0E0),
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Верхняя строка: имя и действия
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Кнопки действий
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          IconButton(
                            onPressed: onEdit,
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xFF4ECDC4),
                              size: 20,
                            ),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete,
                              color: Color(0xFFFF6B6B),
                              size: 20,
                            ),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        if (onTap != null)
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF999999),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Специализация с иконкой
                Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        specialization,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Опыт работы с иконкой
                Row(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      size: 16,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Опыт: $experience',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Рейтинг
                Row(
                  children: [
                    _buildRatingStars(),
                    const SizedBox(width: 8),
                    Text(
                      '$rating/5',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Описание (сокращенное)
                Text(
                  description.length > 80
                      ? '${description.substring(0, 80)}...'
                      : description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Альтернативный компактный вариант карточки
class CompactTrainerCard extends StatelessWidget {
  const CompactTrainerCard({
    required this.name,
    required this.specialization,
    required this.rating,
    this.onTap,
    super.key,
  });

  final String name;
  final String specialization;
  final int rating;
  final VoidCallback? onTap;

  Widget _buildRatingStars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating
              ? const Color(0xFFFFB800)
              : const Color(0xFFE0E0E0),
          size: 14,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Аватар с первой буквой имени
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF4ECDC4),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'T',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Информация о тренере
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialization,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildRatingStars(),
                  ],
                ),
              ),

              // Стрелка
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF999999),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
