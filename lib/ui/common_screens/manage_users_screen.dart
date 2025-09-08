import 'package:fitness_book/services/workout_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final WorkoutService _workoutService = WorkoutService();
  List<UserWorkoutStats> _usersStats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsersStats();
    });
  }

  Future<void> _loadUsersStats() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final stats = await _workoutService.getAllUsersWorkoutStats();
      if (mounted) {
        setState(() {
          _usersStats = stats;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка загрузки: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // Показать список тренировок
  void _showWorkoutList(
    String title,
    Future<List<SimpleWorkoutInfo>> Function() loader,
  ) async {
    if (!mounted) return;

    final List<SimpleWorkoutInfo> workouts;
    try {
      workouts = await loader();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Ошибка загрузки: $e")));
      }
      return;
    }

    if (workouts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Список пуст")));
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title, style: Theme.of(dialogContext).textTheme.titleLarge),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final w = workouts[index];
              return ListTile(
                title: Text(
                  w.type,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${DateFormat('dd.MM.yyyy HH:mm').format(w.datetime)} • Статус: ${w.status}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                // trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Пользователи")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _usersStats.isEmpty
          ? Center(
              child: Text(
                "Пользователи не найдены",
                style: textTheme.bodyMedium,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUsersStats,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _usersStats.length,
                itemBuilder: (context, index) {
                  final user = _usersStats[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyLarge,
                              children: [
                                TextSpan(
                                  text: 'Участник: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                TextSpan(
                                  text: user.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87, // или onSurface
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge, // используем основной стиль
                              children: [
                                TextSpan(
                                  text: 'Email: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                                TextSpan(
                                  text: user.email,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Colors
                                        .black87, // или Theme.of(context).colorScheme.onSurface
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showWorkoutList(
                                      "Забронированные тренировки",
                                      () => _workoutService
                                          .getBookedWorkoutsForUser(
                                            user.userId,
                                          ),
                                    );
                                  },
                                  icon: const Icon(Icons.event, size: 16),
                                  label: Text(
                                    "Забронировано: ${user.bookedCount}",
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showWorkoutList(
                                      "Отменённые тренировки",
                                      () => _workoutService
                                          .getCancelledWorkoutsForUser(
                                            user.userId,
                                          ),
                                    );
                                  },
                                  icon: const Icon(Icons.cancel, size: 16),
                                  label: Text(
                                    "Отменено: ${user.cancelledCount}",
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
