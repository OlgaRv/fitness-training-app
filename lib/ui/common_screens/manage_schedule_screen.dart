// manage_schedule_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_book/ui/common_screens/components/admin_schedule_card.dart';
import 'package:fitness_book/ui/common_screens/components/compact_admin_schedule_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isCompactView = false;

  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final doc = await _firestore.collection('users').doc(userId).get();

    if (doc.exists) {
      setState(() {
        _userRole = doc.data()?['role'] ?? 'user';
      });
    } else {
      setState(() {
        _userRole = 'user';
      });
    }
  }

  Future<void> _deleteTraining(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text('Вы уверены, что хотите удалить тренировку "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('scheduled_workouts').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Тренировка удалена'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _editTraining(String docId) {
    Navigator.pushNamed(context, '/edit_workout', arguments: docId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление расписанием'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isCompactView = !_isCompactView;
              });
            },
            icon: Icon(_isCompactView ? Icons.view_agenda : Icons.view_list),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('scheduled_workouts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Тренировки не найдены'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final typeMap = data['type'] as Map<String, dynamic>?;
              final name = typeMap?['name'] ?? 'Тренировка';

              if (_isCompactView) {
                return CompactAdminScheduleCard(
                  scheduledWorkoutId: doc.id,
                  onTap: () => _viewTrainingDetails(doc.id),
                );
              } else {
                return AdminScheduleCard(
                  scheduledWorkoutId: doc.id,
                  onEdit: _userRole == 'admin'
                      ? () => _editTraining(doc.id)
                      : null,
                  onDelete: _userRole == 'admin'
                      ? () => _deleteTraining(doc.id, name)
                      : null,
                  onTap: () => _viewTrainingDetails(doc.id),
                );
              }
            },
          );
        },
      ),

      // 🔹 Плавающая кнопка только для admin
      floatingActionButton: _userRole == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/create_workout'),
              backgroundColor: const Color(0xFF4ECDC4),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Добавить тренировку',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  // Модальное окно с деталями
  Future<void> _viewTrainingDetails(String scheduledWorkoutId) async {
    try {
      final workoutDoc = await FirebaseFirestore.instance
          .collection('scheduled_workouts')
          .doc(scheduledWorkoutId)
          .get();

      if (!workoutDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Тренировка не найдена')),
          );
        }
        return;
      }

      final data = workoutDoc.data() as Map<String, dynamic>;

      final typeMap = data['type'] as Map<String, dynamic>?;
      final trainerMap = data['trainer'] as Map<String, dynamic>?;
      final statusMap = data['status'] as Map<String, dynamic>?;
      final datetimeTimestamp = data['datetime'] as Timestamp?;

      final String workoutType = typeMap?['name'] ?? 'Неизвестно';
      final String description =
          typeMap?['description'] ?? 'Описание отсутствует';
      final int duration = typeMap?['duration'] as int? ?? 0;

      final String trainer = trainerMap?['name'] ?? 'Не назначен';
      final String status = statusMap?['name'] ?? 'Без статуса';

      final String dateTimeFormatted = datetimeTimestamp != null
          ? DateFormat('dd.MM.yyyy HH:mm').format(datetimeTimestamp.toDate())
          : 'Дата не указана';

      final int countMembers = data['countMembers'] as int? ?? 0;
      final int countPlaces = data['countPlaces'] as int? ?? 0;

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      workoutType,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Тип', workoutType, Icons.fitness_center),
                    const SizedBox(height: 12),
                    _buildInfoRow('Описание', description, Icons.list),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Продолжительность, мин',
                      duration.toString(),
                      Icons.lock_clock,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Статус', status, Icons.flag),
                    const SizedBox(height: 12),
                    _buildInfoRow('Тренер', trainer, Icons.person_2_rounded),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Дата и время',
                      dateTimeFormatted,
                      Icons.lock_clock_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Участники',
                      '$countMembers / $countPlaces',
                      Icons.group_outlined,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF666666), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
