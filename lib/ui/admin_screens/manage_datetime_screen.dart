import 'package:fitness_book/ui/admin_screens/components/custom_input_field.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDatetimeScreen extends StatefulWidget {
  const ManageDatetimeScreen({super.key});

  @override
  State<ManageDatetimeScreen> createState() => _ManageDatetimeScreenState();
}

class _ManageDatetimeScreenState extends State<ManageDatetimeScreen> {
  final _firestore = FirebaseFirestore.instance;
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime? fromDate;
  DateTime? toDate;
  bool _isAdding = false;
  bool _isCompactView = false;

  /// Валидация даты
  String? _validateDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите дату';
    }

    try {
      DateTime.parse(value.trim());
      return null;
    } catch (e) {
      return 'Неверный формат даты (ГГГГ-ММ-ДД)';
    }
  }

  /// Валидация времени
  String? _validateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите время';
    }

    final timeParts = value.trim().split(':');
    if (timeParts.length != 2) {
      return 'Неверный формат времени (ЧЧ:ММ)';
    }

    try {
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (hour < 0 || hour > 23) {
        return 'Часы должны быть от 0 до 23';
      }
      if (minute < 0 || minute > 59) {
        return 'Минуты должны быть от 0 до 59';
      }

      return null;
    } catch (e) {
      return 'Неверный формат времени';
    }
  }

  /// Сохранение даты+времени в Firebase
  Future<void> _saveDatetime() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      final selectedDate = DateTime.parse(dateController.text.trim());
      final timeParts = timeController.text.trim().split(':');
      final selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      // Проверка на дублирование
      final existingQuery = await _firestore
          .collection('datetimes')
          .where('datetime', isEqualTo: Timestamp.fromDate(selectedDateTime))
          .get();

      if (existingQuery.docs.isNotEmpty) {
        _showMessage('Это время уже существует в расписании', Colors.orange);
        return;
      }

      await _firestore.collection('datetimes').add({
        'datetime': Timestamp.fromDate(selectedDateTime),
        'createdAt': FieldValue.serverTimestamp(),
      });

      dateController.clear();
      timeController.clear();

      _showMessage('Время успешно добавлено в расписание', Colors.green);
    } catch (e) {
      _showMessage('Ошибка при сохранении: $e', Colors.red);
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
  }

  /// Удаление записи
  Future<void> _deleteDateTime(String docId, String formattedDateTime) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтвердите удаление'),
        content: Text('Удалить время "$formattedDateTime" из расписания?'),
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
        await _firestore.collection('datetimes').doc(docId).delete();
        _showMessage('Время удалено из расписания', Colors.green);
      } catch (e) {
        _showMessage('Ошибка при удалении: $e', Colors.red);
      }
    }
  }

  /// Показ сообщений
  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => fromDate = picked);
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => toDate = picked);
  }

  /// Поток данных с фильтрацией по периоду
  Stream<QuerySnapshot> _getDatetimesStream() {
    Query query = _firestore
        .collection('datetimes')
        .orderBy('datetime', descending: false);

    if (fromDate != null) {
      query = query.where(
        'datetime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate!),
      );
    }
    if (toDate != null) {
      final endOfDay = DateTime(
        toDate!.year,
        toDate!.month,
        toDate!.day,
        23,
        59,
        59,
      );
      query = query.where(
        'datetime',
        isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
      );
    }

    return query.snapshots();
  }

  void _clearPeriod() {
    setState(() {
      fromDate = null;
      toDate = null;
    });
  }

  /// Форматирование даты-времени
  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} "
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  /// Автозаполнение текущей даты и времени
  void _fillCurrentDateTime() {
    final now = DateTime.now();
    dateController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    timeController.text =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: Column(
        children: [
          /// Форма добавления
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomInputField(
                          controller: dateController,
                          label: "Дата (ГГГГ-ММ-ДД)",
                          validator: _validateDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomInputField(
                          controller: timeController,
                          label: "Время (ЧЧ:ММ)",
                          validator: _validateTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isAdding ? null : _saveDatetime,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isAdding
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Добавить время',
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _fillCurrentDateTime,
                        icon: const Icon(
                          Icons.access_time,
                          color: Color(0xFF4ECDC4),
                        ),
                        tooltip: 'Текущее время',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// Фильтр по периоду
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Период:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: _pickFromDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          fromDate != null
                              ? "${fromDate!.toLocal()}".split(' ')[0]
                              : "С даты",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const Text(' - '),
                      TextButton.icon(
                        onPressed: _pickToDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          toDate != null
                              ? "${toDate!.toLocal()}".split(' ')[0]
                              : "До даты",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                if (fromDate != null || toDate != null)
                  IconButton(
                    onPressed: _clearPeriod,
                    icon: const Icon(Icons.clear, color: Colors.red, size: 20),
                    tooltip: 'Очистить период',
                  ),
              ],
            ),
          ),

          /// Список временных слотов
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getDatetimesStream(),
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
                        Icon(Icons.schedule, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Расписание пусто',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Добавьте время для тренировок',
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
                    final DateTime dateTime = (data['datetime'] as Timestamp)
                        .toDate();
                    final formattedDateTime = _formatDateTime(dateTime);

                    if (_isCompactView) {
                      // Компактный вид
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 16,
                        ),
                        child: ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF4ECDC4),
                            child: Text(
                              dateTime.day.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          title: Text(
                            formattedDateTime,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            onPressed: () =>
                                _deleteDateTime(doc.id, formattedDateTime),
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Полный вид
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Row(
                            children: [
                              // Иконка времени
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF4ECDC4,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.schedule,
                                  color: Color(0xFF4ECDC4),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Информация о времени
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${dateTime.toLocal()}".split(' ')[0],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4ECDC4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Кнопка удаления
                              IconButton(
                                onPressed: () =>
                                    _deleteDateTime(doc.id, formattedDateTime),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Удалить',
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create_workout'),
        backgroundColor: const Color(0xFF4ECDC4),
        icon: const Icon(Icons.fitness_center, color: Colors.white),
        label: const Text(
          'Добавить тренировку',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
