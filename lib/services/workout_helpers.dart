// workout_helpers.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Получение списка типов тренировок
Future<List<Map<String, dynamic>>> fetchTrainingTypes() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('type_trainings')
      .orderBy('name')
      .get();

  return snapshot.docs
      .map((doc) => {'id': doc.id, 'name': doc['name']})
      .toList();
}

/// Получение списка тренеров
Future<List<Map<String, dynamic>>> fetchTrainers() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('trainers')
      .orderBy('name')
      .get();

  return snapshot.docs
      .map((doc) => {'id': doc.id, 'name': doc['name']})
      .toList();
}

/// Получение списка доступных дат/времени
Future<List<Map<String, dynamic>>> fetchDatetimes() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('datetimes')
      .orderBy('datetime')
      .get();

  return snapshot.docs
      .map(
        (doc) => {
          'id': doc.id,
          'datetime': (doc['datetime'] as Timestamp).toDate(),
        },
      )
      .toList();
}

/// Получение списка залов
Future<List<Map<String, dynamic>>> fetchHalls() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('halls')
      .orderBy('name')
      .get();

  return snapshot.docs
      .map((doc) => {'id': doc.id, 'name': doc['name']})
      .toList();
}
