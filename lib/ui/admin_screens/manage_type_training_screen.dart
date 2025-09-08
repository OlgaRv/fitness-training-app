import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_book/ui/admin_screens/components/textfield_description.dart';

class ManageTypeTrainingScreen extends StatefulWidget {
  const ManageTypeTrainingScreen({super.key});

  @override
  State<ManageTypeTrainingScreen> createState() =>
      _ManageTypeTrainingScreenState();
}

class _ManageTypeTrainingScreenState extends State<ManageTypeTrainingScreen> {
  final nameController = TextEditingController();
  final durationController = TextEditingController();
  final descriptionController = TextEditingController();

  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  String? _validateDuration(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле обязательно для заполнения';
    }
    final duration = int.tryParse(value.trim());
    if (duration == null || duration <= 0) {
      return 'Введите корректное число больше 0';
    }
    return null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле обязательно для заполнения';
    }
    return null;
  }

  Future<void> _saveTrainingType() async {
    final name = nameController.text.trim();
    final duration = durationController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty || duration.isEmpty || description.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Заполните все поля")));
      return;
    }

    final durationInt = int.tryParse(duration);
    if (durationInt == null || durationInt <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Продолжительность должна быть положительным числом"),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection('training_types').add({
        'name': name,
        'duration': durationInt,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      nameController.clear();
      durationController.clear();
      descriptionController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Тип тренировки успешно добавлен"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    } finally {
      // Проверяем mounted только перед setState
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteTrainingType(String docId, String name) async {
    try {
      await _firestore.collection('training_types').doc(docId).delete();

      if (!mounted) return; // проверяем, что экран ещё в дереве

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Тип '$name' удалён"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка при удалении: $e")));
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    durationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Управление типами тренировок")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextfieldDescription(
              title: 'Тип',
              hittext: 'Кардиотренировка',
              controller: nameController,
              validator: _validateRequired,
            ),
            TextfieldDescription(
              title: 'Продолжительность, мин',
              hittext: '30',
              controller: durationController,
              keyboardType: TextInputType.number,
              validator: _validateDuration,
            ),
            TextfieldDescription(
              title: 'Описание',
              hittext:
                  'Тренировки для развития выносливости и улучшения работы сердца',
              controller: descriptionController,
              validator: _validateRequired,
              isTextArea: true,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTrainingType,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 14,
                ),
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Сохранить",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('training_types')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Ошибка: ${snapshot.error}"),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("Пока нет добавленных типов"),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(data['name'] ?? ''),
                                subtitle: Text(
                                  "${data['duration']} мин\n${data['description'] ?? ''}",
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Удалить тип?"),
                                        content: Text(
                                          "Вы уверены, что хотите удалить '${data['name']}'?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text("Отмена"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _deleteTrainingType(
                                                doc.id,
                                                data['name'],
                                              );
                                            },
                                            child: const Text(
                                              "Удалить",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/create_workout');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical: 14,
                      ),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Добавить тренировку",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
