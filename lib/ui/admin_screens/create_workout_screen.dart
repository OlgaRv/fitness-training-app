import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_book/ui/admin_screens/components/datetime_dropdown.dart';
import 'package:fitness_book/ui/admin_screens/components/status_dropdown.dart';
import 'package:fitness_book/ui/admin_screens/components/textfield_description.dart';
import 'package:fitness_book/ui/admin_screens/components/trainer_dropdown.dart';
import 'package:flutter/material.dart';
import 'components/specialization_dropdown.dart';

class CreateWorkoutScreen extends StatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  State<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends State<CreateWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final numberPlacesController = TextEditingController();
  // Убираем numberMembersController - участники будут добавляться через бронирование

  bool _isLoading = false;

  String? _selectedTrainingTypeId;
  String? _selectedDatetimeId;
  String? _selectedTrainerId;
  String? _selectedStatusId;

  // Валидатор для числовых полей
  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите количество мест';
    }
    final number = int.tryParse(value.trim());
    if (number == null || number <= 0) {
      return 'Введите корректное число (больше 0)';
    }
    return null;
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Получаем документы из коллекций по выбранным id
      final trainingTypeDoc = _selectedTrainingTypeId != null
          ? await _firestore
                .collection('training_types')
                .doc(_selectedTrainingTypeId)
                .get()
          : null;

      final trainerDoc = _selectedTrainerId != null
          ? await _firestore
                .collection('trainers')
                .doc(_selectedTrainerId)
                .get()
          : null;

      final datetimeDoc = _selectedDatetimeId != null
          ? await _firestore
                .collection('datetimes')
                .doc(_selectedDatetimeId)
                .get()
          : null;

      final statusDoc = _selectedStatusId != null
          ? await _firestore.collection('statuses').doc(_selectedStatusId).get()
          : null;

      if (trainingTypeDoc == null ||
          !trainingTypeDoc.exists ||
          trainerDoc == null ||
          !trainerDoc.exists ||
          datetimeDoc == null ||
          !datetimeDoc.exists ||
          statusDoc == null ||
          !statusDoc.exists) {
        _showErrorSnackBar('Выбраны некорректные значения');
        setState(() => _isLoading = false);
        return;
      }

      // Сохраняем тренировку в scheduled_workouts с новой структурой
      await _firestore.collection('scheduled_workouts').add({
        'type': {
          'id': trainingTypeDoc.id,
          'name': trainingTypeDoc.get('name'),
          'description': trainingTypeDoc.get('description'),
          'duration': trainingTypeDoc.get('duration'),
        },
        'trainer': {
          'id': trainerDoc.id,
          'name': trainerDoc.get('trainerName'),
          'specializations': trainerDoc.get('specializations'),
          'rating': trainerDoc.get('rating'),
        },
        'datetime': datetimeDoc.get('datetime'),
        'status': {'id': statusDoc.id, 'name': statusDoc.get('status')},
        'countPlaces': int.parse(numberPlacesController.text),

        // 🔹 Новые поля для системы бронирования
        'countMembers': 0, // начинаем с 0 участников
        'bookedUsers': [], // пустой массив для забронировавших пользователей

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(), // добавляем updatedAt
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Тренировка добавлена в расписание!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pushReplacementNamed(context, '/manage_schedule');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка сохранения: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    numberPlacesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Добавить тренировку'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SpecializationDropdown(
                title: 'Тип тренировки',
                selectedValue: _selectedTrainingTypeId,
                onChanged: (val) =>
                    setState(() => _selectedTrainingTypeId = val),
                validator: (val) =>
                    val == null ? 'Выберите тип тренировки' : null,
              ),

              DatetimeDropdown(
                title: 'Дата, время',
                selectedValue: _selectedDatetimeId,
                onChanged: (val) => setState(() => _selectedDatetimeId = val),
                validator: (val) =>
                    val == null ? 'Выберите дату и время' : null,
              ),

              TrainerDropdown(
                title: 'Тренер',
                selectedValue: _selectedTrainerId,
                onChanged: (val) => setState(() => _selectedTrainerId = val),
                validator: (val) => val == null ? 'Выберите тренера' : null,
              ),

              StatusDropdown(
                title: 'Статус',
                selectedValue: _selectedStatusId,
                onChanged: (val) => setState(() => _selectedStatusId = val),
                validator: (val) => val == null ? 'Выберите статус' : null,
              ),

              // 🔹 Показываем описание и длительность, если выбран тип тренировки
              if (_selectedTrainingTypeId != null)
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore
                      .collection('training_types')
                      .doc(_selectedTrainingTypeId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final duration = data['duration']?.toString() ?? '-';
                    final description = data['description'] ?? '-';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextfieldDescription(
                          title: "Длительность (минуты)",
                          hittext: duration,
                          controller: TextEditingController(text: duration),
                          isTextArea: false,
                        ),
                        TextfieldDescription(
                          title: "Описание тренировки",
                          hittext: description,
                          controller: TextEditingController(text: description),
                          isTextArea: true,
                        ),
                      ],
                    );
                  },
                ),

              TextfieldDescription(
                title: 'Количество мест',
                hittext: '5',
                controller: numberPlacesController,
                validator: _validateNumber,
              ),

              // Убираем поле ввода "Количество участников" - оно будет обновляться автоматически при бронировании
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveWorkout,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
