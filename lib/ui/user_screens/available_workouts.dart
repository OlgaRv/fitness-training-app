import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fitness_book/services/workout_service.dart';

class AvailableWorkoutsScreen extends StatelessWidget {
  const AvailableWorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Доступные тренировки"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scheduled_workouts')
            .orderBy('datetime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          }

          final allWorkouts = snapshot.data?.docs ?? [];

          // Фильтруем только доступные
          final availableWorkouts = allWorkouts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // ИСПРАВЛЕНО: правильное чтение статуса
            final statusName = data['status']?['name'] as String?;
            return statusName == 'Доступно';
          }).toList();

          if (availableWorkouts.isEmpty) {
            return const Center(child: Text("Нет доступных тренировок"));
          }

          return ListView.builder(
            itemCount: availableWorkouts.length,
            itemBuilder: (context, index) {
              final data =
                  availableWorkouts[index].data() as Map<String, dynamic>;
              final docId = availableWorkouts[index].id;

              final type = data['type']?['name'] ?? "Без типа";
              final trainer = data['trainer']?['name'] ?? "Без тренера";
              final status = data['status']?['name'] ?? "Без статуса";

              final datetime = (data['datetime'] is Timestamp)
                  ? (data['datetime'] as Timestamp).toDate()
                  : DateTime.now();

              final countPlaces = (data['countPlaces'] ?? 0) as int;
              final countMembers = (data['countMembers'] ?? 0) as int;
              final placesLeft = countPlaces - countMembers;

              return _WorkoutItem(
                workoutId: docId,
                type: type,
                trainer: trainer,
                date: '${datetime.day}.${datetime.month}.${datetime.year}',
                time:
                    '${datetime.hour}:${datetime.minute.toString().padLeft(2, '0')}',
                status: status,
                placesLeft: placesLeft,
              );
            },
          );
        },
      ),
    );
  }
}

class _WorkoutItem extends StatelessWidget {
  final String workoutId;
  final String type;
  final String trainer;
  final String date;
  final String time;
  final String status;
  final int placesLeft;

  const _WorkoutItem({
    required this.workoutId,
    required this.type,
    required this.trainer,
    required this.date,
    required this.time,
    required this.status,
    required this.placesLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text('Тренер: $trainer'),
            Text('Дата: $date'),
            Text('Время: $time'),
            Text('Статус: $status'),
            Text('Свободных мест: $placesLeft'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: placesLeft > 0
                  ? () async {
                      final currentContext = context;

                      try {
                        await WorkoutService().bookWorkout(workoutId);

                        if (!currentContext.mounted) return;

                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          const SnackBar(
                            content: Text("✅ Тренировка забронирована!"),
                          ),
                        );
                      } on Exception catch (e, s) {
                        if (!currentContext.mounted) return;

                        // Печатаем в консоль — чтобы увидеть детали
                        debugPrint('Ошибка при бронировании: $e');
                        debugPrint('Стек вызовов: $s');

                        ScaffoldMessenger.of(currentContext).showSnackBar(
                          SnackBar(
                            content: Text("❌ ${e.toString()}"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  : null, // Отключаем кнопку если нет мест
              child: Text(placesLeft > 0 ? "Забронировать" : "Нет мест"),
            ),
          ],
        ),
      ),
    );
  }
}
