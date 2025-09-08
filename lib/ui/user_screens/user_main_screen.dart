import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_book/ui/user_screens/components/user_schedule_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  final _firestore = FirebaseFirestore.instance;

  late String currentUserId;
  late String currentUserName;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  bool _askedForName = false; // чтобы не показывать диалог лишний раз

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      currentUserId = user.uid;
      // временное значение: displayName/email, пока не получим Firestore
      currentUserName =
          user.displayName ?? user.email?.split('@')[0] ?? "Пользователь";

      final userRef = _firestore.collection('users').doc(currentUserId);

      // 2.1 Первое чтение строго с сервера, чтобы обойти устаревший кэш
      userRef
          .get(const GetOptions(source: Source.server))
          .then((snap) {
            if (!mounted) return;
            final name = (snap.data()?['username'] as String?)?.trim();
            if (name != null && name.isNotEmpty) {
              setState(() => currentUserName = name);
              _askedForName = true; // имя уже есть — диалог не нужен
            }
          })
          .catchError((_) {
            /* игнорируем, оставим fallback */
          });

      // 2.2 Постоянная подписка: любые изменения username подтянутся сразу
      _userSub = userRef.snapshots().listen((snap) {
        final name = (snap.data()?['username'] as String?)?.trim();
        if (!mounted) return;
        if (name != null && name.isNotEmpty && name != currentUserName) {
          setState(() => currentUserName = name);
          _askedForName = true;
        }
      });
    } else {
      currentUserId = "unknown_user";
      currentUserName = "Гость";
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  // Диалог: "Хотите указать имя?"
  void _showNameSuggestionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Персонализация"),
        content: const Text(
          "Хотите указать своё имя? Это сделает приложение удобнее и приятнее.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Позже"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditUsernameDialog();
            },
            child: const Text("Указать имя"),
          ),
        ],
      ),
    );
  }

  // Диалог: ввод имени
  void _showEditUsernameDialog() {
    String newName = currentUserName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Изменить имя"),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: "Ваше имя",
            hintText: "Иван Иванов",
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => newName = value.trim(),
          onSubmitted: (_) => _saveUsername(context, newName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () => _saveUsername(context, newName),
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  // Сохраняем имя в Firestore + FirebaseAuth
  Future<void> _saveUsername(BuildContext dialogContext, String newName) async {
    if (newName.isEmpty) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(content: Text("Имя не может быть пустым")),
        );
      }
      return;
    }

    try {
      // ✅ Firestore
      await _firestore.collection('users').doc(currentUserId).set({
        'username': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ FirebaseAuth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        await user.reload();
      }

      // ✅ Локально
      if (mounted) {
        setState(() {
          currentUserName = newName;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Имя успешно обновлено")));
      }

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(
          dialogContext,
        ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
      }
      debugPrint("Ошибка при сохранении username: $e");
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Подтверждение"),
        content: const Text("Вы действительно хотите выйти из аккаунта?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/auth',
                (route) => false,
              );
            },
            child: const Text("Выйти"),
          ),
        ],
      ),
    );
  }

  void _navigateToAddWorkout() {
    Navigator.pushNamed(context, '/available_workouts');
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // ✅ Проверка имени только если список тренировок пуст
    Future.microtask(() {
      if (_askedForName) return; // уже есть валидное имя или уже спрашивали
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || !mounted) return;

      final emailPrefix = user.email?.split('@')[0];
      final isDefaultName =
          currentUserName == emailPrefix ||
          currentUserName == 'Пользователь' ||
          currentUserName.trim().isEmpty;

      if (isDefaultName) {
        _askedForName = true;
        _showNameSuggestionDialog();
      }
    });

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.fitness_center,
                size: 60,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Здесь будут ваши тренировки",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Выберите тренировку и забронируйте время с тренером",
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToAddWorkout,
                icon: const Icon(Icons.add),
                label: const Text("Добавить тренировку"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Мои тренировки"),
        actions: [
          TextButton(
            onPressed: () => _showLogoutDialog(context),
            child: Text(
              "Выйти",
              style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Привет, $currentUserName",
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "тебя ждёт встреча с тренером",
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(currentUserId)
                    .collection('booked_workouts')
                    .orderBy('datetime', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Ошибка загрузки: ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    );
                  }

                  final workouts = snapshot.data?.docs ?? [];

                  if (workouts.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: workouts.length,
                          itemBuilder: (context, index) {
                            final workoutData =
                                workouts[index].data() as Map<String, dynamic>;

                            return UserScheduleItem(
                              title: workoutData['type'] ?? 'Тренировка',
                              date: _formatDate(workoutData['datetime']),
                              time: _formatTime(workoutData['datetime']),
                              trainer: workoutData['trainerName'] ?? 'Тренер',
                              status: workoutData['status'] ?? 'Забронировано',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/workout_details',
                                  arguments: {
                                    'workoutId': workouts[index].id,
                                    'workoutData': workoutData,
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _navigateToAddWorkout,
                            icon: const Icon(Icons.add),
                            label: const Text("Добавить тренировку"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 60,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
