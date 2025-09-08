import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Забронировать тренировку

  Future<void> bookWorkout(String workoutId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("Пользователь не авторизован");

    // ✅ Берём username из Firestore
    final userSnap = await _firestore.collection('users').doc(userId).get();
    final userName =
        (userSnap.data()?['username'] as String?)?.trim() ??
        _auth.currentUser?.displayName ??
        _auth.currentUser?.email?.split('@')[0] ??
        "Пользователь";

    final workoutDoc = _firestore
        .collection('scheduled_workouts')
        .doc(workoutId);
    final userWorkoutDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection('booked_workouts')
        .doc(workoutId);

    final snapshot = await workoutDoc.get();
    if (!snapshot.exists) throw Exception("Тренировка не найдена");

    final data = snapshot.data();
    if (data == null) throw Exception("Данные тренировки повреждены");

    final countMembers = (data['countMembers'] as int?) ?? 0;
    final countPlaces = (data['countPlaces'] as int?) ?? 0;
    if (countMembers >= countPlaces) {
      throw Exception(
        "Бронирование тренировки завершено, выберите другое время",
      );
    }

    // не даём бронировать повторно
    final List<dynamic> bookedUsers = data['bookedUsers'] ?? [];
    if (bookedUsers.any((u) => u is Map && u['userId'] == userId)) {
      throw Exception("Вы уже забронировали эту тренировку");
    }

    final newCount = countMembers + 1;

    // статус для расписания (НЕ для пользователя!)
    final scheduleStatusName = (newCount >= countPlaces)
        ? "Заполнено"
        : "Доступно";
    final scheduleStatusId = await _getStatusIdFromCollection(
      scheduleStatusName,
    );

    //debugPrint('➡️ bookWorkout: workoutId=$workoutId');
    //debugPrint('Данные тренировки: $data');
    //debugPrint('countMembers=$countMembers countPlaces=$countPlaces');
    //debugPrint('scheduleStatusName=$scheduleStatusName');

    await _firestore.runTransaction((tr) async {
      // 1) обновляем общую тренировку
      tr.update(workoutDoc, {
        'bookedUsers': FieldValue.arrayUnion([
          {'userId': userId, 'username': userName, 'bookedAt': Timestamp.now()},
        ]),
        'countMembers': newCount,
        'status': {'id': scheduleStatusId, 'name': scheduleStatusName},
        'updatedAt': Timestamp.now(),
      });

      // print("Документ бронируемой тренировки: ${snapshot.id}");
      // print("Данные: ${snapshot.data()}");

      // 2) создаём документ у пользователя — статус ВСЕГДА "Забронировано"
      tr.set(userWorkoutDoc, {
        'workoutId': workoutId,
        'type': _extractString(data['type'], 'name', 'Тренировка'),
        'trainerName': _extractString(data['trainer'], 'trainerName', 'Тренер'),
        'datetime': data['datetime'],
        'status': 'Забронировано',
        'duration': _extractString(data['type'], 'duration', '60 мин'),
        'description': _extractString(
          data['type'],
          'description',
          'Нет описания',
        ),
        'countPlaces': countPlaces,
        'bookedAt': Timestamp.now(),
        'createdAt': Timestamp.now(),
      });
    });
  }

  /// Отменить бронь с перемещением в историю
  Future<void> cancelBooking(String workoutId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("Пользователь не авторизован");

    final workoutRef = _firestore
        .collection('scheduled_workouts')
        .doc(workoutId);
    final userBookedRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('booked_workouts')
        .doc(workoutId);
    final userPastRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('past_workouts')
        .doc(workoutId);

    final workoutSnap = await workoutRef.get();
    final userBookedSnap = await userBookedRef.get();

    if (!workoutSnap.exists) throw Exception("Тренировка не найдена");
    if (!userBookedSnap.exists) {
      throw Exception("Вы не бронировали эту тренировку");
    }

    final workoutData = workoutSnap.data()!;
    final userWorkoutData = userBookedSnap.data()!;

    final int countMembers = (workoutData['countMembers'] as int?) ?? 0;
    final int countPlaces = (workoutData['countPlaces'] as int?) ?? 0;
    final int newCount = countMembers > 0 ? countMembers - 1 : 0;

    final String scheduleStatusName = (newCount >= countPlaces)
        ? "Заполнено"
        : "Доступно";
    final String scheduleStatusId = await _getStatusIdFromCollection(
      scheduleStatusName,
    );

    await _firestore.runTransaction((tr) async {
      // 1) обновляем тренировку
      tr.update(workoutRef, {
        'bookedUsers': FieldValue.arrayRemove([
          {'userId': userId},
        ]),
        'countMembers': newCount,
        'status': {'id': scheduleStatusId, 'name': scheduleStatusName},
        'updatedAt': Timestamp.now(),
      });

      // 2) удаляем из booked_workouts
      tr.delete(userBookedRef);

      // 3) переносим в past_workouts
      tr.set(userPastRef, {
        ...userWorkoutData,
        'status': 'Отменено',
        'cancelledAt': Timestamp.now(),
      });
    });
  }

  /// Отметить посещение тренировки
  Future<void> markWorkoutAttended(String workoutId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception("Пользователь не авторизован");

    final userWorkoutDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection('booked_workouts')
        .doc(workoutId);

    final snapshot = await userWorkoutDoc.get();
    if (!snapshot.exists) {
      throw Exception("Бронирование не найдено");
    }

    final userData = snapshot.data();
    if (userData == null) throw Exception("Данные повреждены");

    await _moveToPastWorkouts(userWorkoutDoc, userData, status: 'Посещено');
  }

  /// Универсальный метод для перемещения в историю
  Future<void> _moveToPastWorkouts(
    DocumentReference bookedWorkoutRef,
    Map<String, dynamic> workoutData, {
    required String status,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final pastWorkoutRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('past_workouts')
        .doc(bookedWorkoutRef.id);

    final updatedData = {
      ...workoutData,
      'status': status,
      'updatedAt': Timestamp.now(),
    };

    switch (status) {
      case 'Отменено':
        updatedData['cancelledAt'] = Timestamp.now();
        break;
      case 'Посещено':
        updatedData['attendedAt'] = Timestamp.now();
        break;
      case 'Пропущено':
        updatedData['missedAt'] = Timestamp.now();
        break;
    }

    await _firestore.runTransaction((transaction) async {
      transaction.set(pastWorkoutRef, updatedData);
      transaction.delete(bookedWorkoutRef);
    });
  }

  /// Автоматическое перемещение просроченных тренировок
  Future<void> moveExpiredWorkoutsToHistory() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final now = Timestamp.now();
    final bookedWorkouts = await _firestore
        .collection('users')
        .doc(userId)
        .collection('booked_workouts')
        .where('datetime', isLessThan: now)
        .get();

    final batch = _firestore.batch();

    for (final doc in bookedWorkouts.docs) {
      final data = doc.data();
      final pastWorkoutRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('past_workouts')
          .doc(doc.id);

      final pastData = {
        ...data,
        'status': 'Пропущено',
        'missedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      batch.set(pastWorkoutRef, pastData);
      batch.delete(doc.reference);

      // Обновляем статус тренировки в scheduled_workouts
      try {
        final finishedStatusId = await _getStatusIdFromCollection('Завершено');
        final workoutDoc = _firestore
            .collection('scheduled_workouts')
            .doc(doc.id);
        batch.update(workoutDoc, {
          'status': {'id': finishedStatusId, 'name': 'Завершено'},
          'updatedAt': Timestamp.now(),
        });
      } catch (e) {
        // Если статус не найден, пропускаем обновление
        print('Ошибка при поиске статуса "Завершено": $e');
      }
    }

    if (bookedWorkouts.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  /// Получить ID статуса из коллекции statuses
  Future<String> _getStatusIdFromCollection(String statusName) async {
    final query = await _firestore
        .collection('statuses')
        .where('status', isEqualTo: statusName)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Статус '$statusName' не найден в коллекции statuses");
    }

    return query.docs.first.id;
  }

  /// Безопасное извлечение строковых значений из вложенных Map
  String _extractString(dynamic source, String key, String defaultValue) {
    if (source is Map<String, dynamic> && source.containsKey(key)) {
      return source[key]?.toString() ?? defaultValue;
    }
    return defaultValue;
  }

  /// Проверить, может ли пользователь забронировать тренировку
  Future<BookingValidationResult> validateBooking(String workoutId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return BookingValidationResult(
        canBook: false,
        reason: "Пользователь не авторизован",
      );
    }

    final workoutDoc = _firestore
        .collection('scheduled_workouts')
        .doc(workoutId);
    final userWorkoutDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection('booked_workouts')
        .doc(workoutId);

    final workoutSnapshot = await workoutDoc.get();
    final userBookingSnapshot = await userWorkoutDoc.get();

    if (!workoutSnapshot.exists) {
      return BookingValidationResult(
        canBook: false,
        reason: "Тренировка не найдена",
      );
    }

    if (userBookingSnapshot.exists) {
      return BookingValidationResult(
        canBook: false,
        reason: "Вы уже забронировали эту тренировку",
      );
    }

    final data = workoutSnapshot.data();
    if (data == null) {
      return BookingValidationResult(
        canBook: false,
        reason: "Данные тренировки повреждены",
      );
    }

    final countMembers = (data['countMembers'] as int?) ?? 0;
    final countPlaces = (data['countPlaces'] as int?) ?? 0;
    final datetime = data['datetime'] as Timestamp?;

    // Проверка на прошедшее время
    if (datetime != null && datetime.toDate().isBefore(DateTime.now())) {
      return BookingValidationResult(
        canBook: false,
        reason: "Тренировка уже прошла",
      );
    }

    if (countMembers >= countPlaces) {
      return BookingValidationResult(
        canBook: false,
        reason: "Нет свободных мест",
        availablePlaces: 0,
      );
    }

    return BookingValidationResult(
      canBook: true,
      availablePlaces: countPlaces - countMembers,
    );
  }

  /// Пакетная отмена нескольких бронирований
  Future<List<String>> cancelMultipleBookings(List<String> workoutIds) async {
    final failedCancellations = <String>[];

    for (final workoutId in workoutIds) {
      try {
        await cancelBooking(workoutId);
      } catch (e) {
        failedCancellations.add(workoutId);
      }
    }

    return failedCancellations;
  }

  /// Получить детальную информацию о бронировании
  Future<BookingDetails?> getBookingDetails(String workoutId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final userWorkoutDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection('booked_workouts')
        .doc(workoutId);

    final snapshot = await userWorkoutDoc.get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    return BookingDetails.fromMap(data);
  }

  /// Получить статистику всех пользователей (для админа)
  Future<List<UserWorkoutStats>> getAllUsersWorkoutStats() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("Пользователь не авторизован");

    final currentUserId = currentUser.uid;

    // Получаем роль текущего пользователя
    final currentUserDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    final currentUserRole =
        currentUserDoc.data()?['role']?.toString() ?? 'user';

    final usersSnapshot = await _firestore.collection('users').get();
    final List<UserWorkoutStats> statsList = [];

    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final userData = userDoc.data();

      final username =
          userData['username'] ?? // ← сначала пробуем username
          userData['displayName'] ?? // ← fallback
          userData['email']?.split('@')[0] ??
          "Пользователь";
      final email = userData['email'] ?? "Нет email";
      final role = userData['role']?.toString() ?? 'user';

      // Пропускаем самого админа, если текущий — админ
      if (currentUserRole == 'admin' && userId == currentUserId) {
        continue;
      }

      // Если текущий пользователь — не админ, показываем только себя
      if (currentUserRole != 'admin' && userId != currentUserId) {
        continue;
      }

      // Получаем статистику
      final bookedSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('booked_workouts')
          .get();
      final bookedCount = bookedSnapshot.size;

      final cancelledSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('past_workouts')
          .where('status', isEqualTo: 'Отменено')
          .get();
      final cancelledCount = cancelledSnapshot.size;

      statsList.add(
        UserWorkoutStats(
          userId: userId,
          username: username,
          email: email,
          role: role,
          bookedCount: bookedCount,
          cancelledCount: cancelledCount,
        ),
      );
    }

    return statsList;
  }

  /// Получить список забронированных тренировок пользователя
  Future<List<SimpleWorkoutInfo>> getBookedWorkoutsForUser(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('booked_workouts')
        .get();

    return snapshot.docs
        .map((doc) => SimpleWorkoutInfo.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Получить список отменённых тренировок пользователя
  Future<List<SimpleWorkoutInfo>> getCancelledWorkoutsForUser(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('past_workouts')
        .where('status', isEqualTo: 'Отменено')
        .get();

    return snapshot.docs
        .map((doc) => SimpleWorkoutInfo.fromMap(doc.id, doc.data()))
        .toList();
  }
}

/// Результат валидации бронирования
class BookingValidationResult {
  final bool canBook;
  final String? reason;
  final int? availablePlaces;

  BookingValidationResult({
    required this.canBook,
    this.reason,
    this.availablePlaces,
  });
}

/// Детали бронирования
class BookingDetails {
  final String workoutId;
  final String type;
  final String trainerName;
  final Timestamp datetime;
  final String status;
  final String duration;
  final String description;
  final int? countPlaces;
  final Timestamp? bookedAt;

  BookingDetails({
    required this.workoutId,
    required this.type,
    required this.trainerName,
    required this.datetime,
    required this.status,
    required this.duration,
    required this.description,
    this.countPlaces,
    this.bookedAt,
  });

  factory BookingDetails.fromMap(Map<String, dynamic> data) {
    return BookingDetails(
      workoutId: data['workoutId'] ?? '',
      type: data['type'] ?? 'Тренировка',
      trainerName: data['trainerName'] ?? 'Тренер',
      datetime: data['datetime'] ?? Timestamp.now(),
      status: data['status'] ?? '',
      duration: data['duration'] ?? '60 мин',
      description: data['description'] ?? 'Нет описания',
      countPlaces: data['countPlaces'],
      bookedAt: data['bookedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'workoutId': workoutId,
      'type': type,
      'trainerName': trainerName,
      'datetime': datetime,
      'status': status,
      'duration': duration,
      'description': description,
      if (countPlaces != null) 'countPlaces': countPlaces,
      if (bookedAt != null) 'bookedAt': bookedAt,
    };
  }
}

/// Расширение для безопасной работы с Map
extension SafeMapAccess on Map<String, dynamic> {
  T? safeGet<T>(String key) {
    final value = this[key];
    return value is T ? value : null;
  }

  String getString(String key, [String defaultValue = '']) {
    return safeGet<String>(key) ?? defaultValue;
  }

  int getInt(String key, [int defaultValue = 0]) {
    return safeGet<int>(key) ?? defaultValue;
  }
}

/// Результат статистики пользователя
class UserWorkoutStats {
  final String userId;
  final String username;
  final String email;
  final String role; // Добавим роль
  final int bookedCount;
  final int cancelledCount;

  UserWorkoutStats({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
    required this.bookedCount,
    required this.cancelledCount,
  });

  // Для отладки
  @override
  String toString() {
    return 'UserWorkoutStats(userId: $userId, username: $username, email: $email, role: $role, bookedCount: $bookedCount, cancelledCount: $cancelledCount)';
  }
}

/// Детали тренировки для отображения в списке
class SimpleWorkoutInfo {
  final String workoutId;
  final String type;
  final DateTime datetime;
  final String status;

  SimpleWorkoutInfo({
    required this.workoutId,
    required this.type,
    required this.datetime,
    required this.status,
  });

  factory SimpleWorkoutInfo.fromMap(String id, Map<String, dynamic> data) {
    final datetime =
        (data['datetime'] as Timestamp?)?.toDate() ?? DateTime.now();
    return SimpleWorkoutInfo(
      workoutId: id,
      type: data['type'] ?? 'Тренировка',
      datetime: datetime,
      status: data['status'] ?? '',
    );
  }
}
