// compact_admin_schedule_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CompactAdminScheduleCard extends StatelessWidget {
  const CompactAdminScheduleCard({
    required this.scheduledWorkoutId,
    this.onTap,
    super.key,
  });

  final String scheduledWorkoutId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('scheduled_workouts')
          .doc(scheduledWorkoutId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard('Ошибка загрузки: ${snapshot.error}');
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const SizedBox.shrink();
        }

        // Читаем данные согласно структуре из ManageScheduleScreen
        String workoutType = 'Тренировка';
        String status = 'Статус';

        try {
          // Проверяем, как хранятся данные - как ссылки или как объекты
          final typeData = data['type'];
          final statusData = data['status'];

          if (typeData is Map<String, dynamic>) {
            // Данные хранятся как вложенные объекты
            workoutType = typeData['name'] ?? 'Тренировка';
          } else if (typeData is String) {
            // Данные хранятся как ссылки на документы
            return _buildWithReferences(data);
          }

          if (statusData is Map<String, dynamic>) {
            // Данные хранятся как вложенные объекты
            status = statusData['name'] ?? 'Статус';
          }
        } catch (e) {
          debugPrint('Error parsing workout data: $e');
          return _buildErrorCard('Ошибка чтения данных');
        }

        return _buildCard(workoutType, status);
      },
    );
  }

  // Метод для случая, когда данные хранятся как ссылки
  Widget _buildWithReferences(Map<String, dynamic> data) {
    final typeId = data['type'] as String?;
    final statusId = data['status'] as String?;

    return FutureBuilder<List<DocumentSnapshot?>>(
      future: Future.wait([
        typeId != null
            ? FirebaseFirestore.instance
                  .collection('training_types')
                  .doc(typeId)
                  .get()
            : Future.value(null),
        statusId != null
            ? FirebaseFirestore.instance
                  .collection('statuses')
                  .doc(statusId)
                  .get()
            : Future.value(null),
      ]),
      builder: (context, nestedSnapshot) {
        if (nestedSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (nestedSnapshot.hasError) {
          return _buildErrorCard('Ошибка загрузки связанных данных');
        }

        String workoutType = 'Тренировка';
        String status = 'Статус';

        try {
          final typeDoc = nestedSnapshot.data?[0];
          final statusDoc = nestedSnapshot.data?[1];

          if (typeDoc != null && typeDoc.exists) {
            final typeData = typeDoc.data() as Map<String, dynamic>?;
            workoutType = typeData?['name'] ?? 'Тренировка';
          }

          if (statusDoc != null && statusDoc.exists) {
            final statusData = statusDoc.data() as Map<String, dynamic>?;
            status = statusData?['status'] ?? statusData?['name'] ?? 'Статус';
          }
        } catch (e) {
          debugPrint('Error getting workout type or status: $e');
        }

        return _buildCard(workoutType, status);
      },
    );
  }

  Widget _buildCard(String workoutType, String status) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF4ECDC4),
                  child: Text(
                    workoutType.isNotEmpty ? workoutType[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        workoutType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
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
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      height: 68, // Фиксированная высота для предотвращения скачков
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: const TextStyle(fontSize: 14, color: Colors.red),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
