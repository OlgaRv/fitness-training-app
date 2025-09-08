import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_book/ui/admin_screens/components/textfield_description.dart';
import 'package:flutter/material.dart';

class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  final statusController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле обязательно для заполнения';
    }
    return null;
  }

  Future<void> _saveStatus() async {
    final status = statusController.text.trim();

    if (status.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Заполните поле")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('statuses').add({
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      statusController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Статус успешно добавлен"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteStatus(String docId, String status) async {
    try {
      await _firestore.collection('statuses').doc(docId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Статус '$status' удалён"),
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
    statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Управление\nстатусами тренировок",
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextfieldDescription(
              title: 'Статус',
              hittext: 'Доступно',
              controller: statusController,
              validator: _validateRequired,
            ),
            const SizedBox(height: 32),

            /// Кнопка добавления статуса
            ElevatedButton(
              onPressed: _isLoading ? null : _saveStatus,
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
                      "Добавить",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 32),

            /// Список статусов
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('statuses')
                          .orderBy('status', descending: true)
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
                            child: Text("Пока нет добавленных статусов"),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final status = data['status'] ?? '';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(status),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        title: const Text(
                                          "Удалить статус?",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Text(
                                          "Вы уверены, что хотите удалить '$status'?",
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        actionsAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        actions: [
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text("Отмена"),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _deleteStatus(doc.id, status);
                                            },
                                            child: const Text("Удалить"),
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
                  const SizedBox(height: 48),

                  /// Кнопка перехода к тренировкам
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
