import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleCard extends StatelessWidget {
  final DocumentSnapshot schedule;

  const ScheduleCard({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final data = schedule.data() as Map<String, dynamic>;

    final DateTime dateTime = (data['datetime'] as Timestamp).toDate();
    final String trainer = data['trainer'] ?? 'Без тренера';
    final String status = data['status'] ?? 'Не указано';
    final int countMembers = data['countMembers'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dateTime.day}.${dateTime.month}.${dateTime.year}  ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Тренер: $trainer'),
            Text('Статус: $status'),
            Text('Записано участников: $countMembers'),
          ],
        ),
      ),
    );
  }
}
