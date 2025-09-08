import 'package:flutter/material.dart';

class UserScheduleItem extends StatelessWidget {
  final String title;
  final String date;
  final String time;
  final String trainer;
  final String status; // "Забронировано", "Отменено"
  final String? notes;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const UserScheduleItem({
    super.key,
    required this.title,
    required this.date,
    required this.time,
    required this.trainer,
    required this.status,
    this.notes,
    required this.onTap,
    this.onCancel,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'забронировано':
        return const Color(0xFF2196F3); // Blue
      case 'отменено':
        return const Color(0xFFF44336); // Red
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status.toLowerCase()) {
      case 'забронировано':
        return 'Забронировано';
      case 'отменено':
        return 'Отменено';
      default:
        return 'Неизвестно';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final isCancelled = status.toLowerCase() == 'отменено';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: InkWell(
          onTap: isCancelled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок и статус
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Дата и стрелочка
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        date,
                        style: TextStyle(
                          fontSize: 14,
                          color: isCancelled
                              ? Colors.grey[500]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                    if (!isCancelled)
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Время
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 14,
                        color: isCancelled
                            ? Colors.grey[500]
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Тренер и кнопка отмены в одной строке
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trainer,
                      style: TextStyle(
                        fontSize: 14,
                        color: isCancelled
                            ? Colors.grey[500]
                            : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    // Кнопка "Отменить" справа в той же строке
                    if (!isCancelled && onCancel != null)
                      GestureDetector(
                        onTap: onCancel,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cancel,
                              size: 16,
                              color: Colors.red[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Отменить',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Заметки (если есть)
                if (notes != null && notes!.isNotEmpty && !isCancelled) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 14,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notes!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
