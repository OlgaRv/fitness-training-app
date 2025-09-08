// admin_schedule_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminScheduleCard extends StatelessWidget {
  const AdminScheduleCard({
    required this.scheduledWorkoutId,
    this.onEdit,
    this.onDelete,
    this.onTap,
    super.key,
  });

  final String scheduledWorkoutId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('scheduled_workouts')
          .doc(scheduledWorkoutId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildErrorCard('Тренировка не найдена');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        // Безопасное извлечение вложенных объектов
        final typeMap = data['type'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['type'] as Map)
            : null;
        final trainerMap = data['trainer'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['trainer'] as Map)
            : null;
        final statusMap = data['status'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['status'] as Map)
            : null;

        final datetimeTimestamp = data['datetime'] is Timestamp
            ? data['datetime'] as Timestamp
            : null;

        // Извлекаем значения с fallback
        final workoutType = typeMap?['name'] ?? 'Неизвестно';
        final description = typeMap?['description'] ?? 'Описание отсутствует';
        final duration = typeMap?['duration'] as int? ?? 0;

        final trainerName = trainerMap?['name'] ?? 'Не назначен';
        final status = statusMap?['name'] ?? 'Без статуса';

        final formattedDateTime = datetimeTimestamp != null
            ? DateFormat('dd.MM.yyyy HH:mm').format(datetimeTimestamp.toDate())
            : 'Дата не указана';

        final countPlaces = (data['countPlaces'] as num?)?.toInt() ?? 0;
        final countMembers = (data['countMembers'] as num?)?.toInt() ?? 0;

        return _buildCard(
          context,
          workoutType: workoutType,
          status: status,
          trainer: trainerName,
          description: description,
          duration: duration,
          dateTime: formattedDateTime,
          countPlaces: countPlaces,
          countMembers: countMembers,
        );
      },
    );
  }

  Widget _buildLoadingCard() => Card(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  Widget _buildErrorCard(String message) => Card(
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    color: Colors.red[50],
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Ошибка: $message',
        style: const TextStyle(color: Colors.red),
      ),
    ),
  );

  Widget _buildCard(
    BuildContext context, {
    required String workoutType,
    required String status,
    required String trainer,
    required String description,
    required int duration,
    required String dateTime,
    required int countPlaces,
    required int countMembers,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workoutType,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
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
                          tooltip: 'Редактировать',
                          padding: const EdgeInsets.all(4),
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(
                            Icons.delete,
                            color: Color(0xFFFF6B6B),
                            size: 20,
                          ),
                          tooltip: 'Удалить',
                          padding: const EdgeInsets.all(4),
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
              _buildInfoRow(
                Icons.timer_outlined,
                'Длительность: $duration мин',
              ),
              _buildInfoRow(
                Icons.stadium_outlined,
                'Статус: $status',
                isBold: true,
              ),
              _buildInfoRow(Icons.person_2_rounded, 'Тренер: $trainer'),
              _buildInfoRow(Icons.lock_clock_outlined, 'Дата/время: $dateTime'),
              _buildInfoRow(
                Icons.group_outlined,
                'Участники: $countMembers / $countPlaces',
              ),
              const SizedBox(height: 8),
              Text(
                description.length > 100
                    ? '${description.substring(0, 100)}...'
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
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF666666)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF666666),
              fontWeight: isBold ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
