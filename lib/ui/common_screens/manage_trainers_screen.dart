import 'package:fitness_book/ui/common_screens/components/trainer_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'trainer_card.dart'; // Импорт вашего компонента

class ManageTrainersScreen extends StatefulWidget {
  const ManageTrainersScreen({super.key});

  @override
  State<ManageTrainersScreen> createState() => _ManageTrainersScreenState();
}

class _ManageTrainersScreenState extends State<ManageTrainersScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isCompactView = false; // Переключатель вида карточек
  String? _userRole;

  // Удаление тренера
  Future<void> _deleteTrainer(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text('Вы уверены, что хотите удалить тренера "$name"?'),
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
        await _firestore.collection('trainers').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Тренер "$name" удален'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при удалении: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Редактирование тренера
  void _editTrainer(String docId) {
    // Переход на экран редактирования
    Navigator.pushNamed(context, '/edit_trainer', arguments: docId);
  }

  // Просмотр детальной информации
  void _viewTrainerDetails(Map<String, dynamic> trainerData) {
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
                // Индикатор для drag
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

                // Имя тренера
                Text(
                  trainerData['trainerName'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Специализация
                _buildInfoRow(
                  'Специализация',
                  trainerData['specializations'] ?? '',
                  Icons.fitness_center,
                ),
                const SizedBox(height: 12),

                // Опыт
                _buildInfoRow(
                  'Опыт работы',
                  trainerData['experience'] ?? '',
                  Icons.work_outline,
                ),
                const SizedBox(height: 12),

                // Рейтинг
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFF666666), size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Рейтинг: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        final rating = trainerData['rating'] ?? 0;
                        return Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: index < rating
                              ? const Color(0xFFFFB800)
                              : const Color(0xFFE0E0E0),
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text('${trainerData['rating'] ?? 0}/5'),
                  ],
                ),
                const SizedBox(height: 16),

                // Описание
                const Text(
                  'Описание',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  trainerData['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF888888),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление тренерами'),
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
            .collection('trainers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Тренеры не найдены',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Добавьте первого тренера',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              if (_isCompactView) {
                return CompactTrainerCard(
                  name: data['trainerName'] ?? '',
                  specialization: data['specializations'] ?? '',
                  rating: data['rating'] ?? 0,
                  onTap: () => _viewTrainerDetails(data),
                );
              } else {
                return TrainerCard(
                  name: data['trainerName'] ?? '',
                  specialization: data['specializations'] ?? '',
                  experience: data['experience'] ?? '',
                  description: data['description'] ?? '',
                  rating: data['rating'] ?? 0,
                  onTap: () => _viewTrainerDetails(data),
                  onEdit: _userRole == 'admin'
                      ? () => _editTrainer(doc.id)
                      : null,
                  onDelete: _userRole == 'admin'
                      ? () => _deleteTrainer(doc.id, data['trainerName'] ?? '')
                      : null,
                );
              }
            },
          );
        },
      ),
      floatingActionButton: _userRole == 'admin'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/create_trainer'),
              backgroundColor: const Color(0xFF4ECDC4),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Добавить тренера',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
