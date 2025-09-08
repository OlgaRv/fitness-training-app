import 'package:fitness_book/ui/admin_screens/components/datetime_dropdown.dart';
import 'package:fitness_book/ui/admin_screens/components/status_dropdown.dart';
import 'package:fitness_book/ui/admin_screens/components/textfield_description.dart';
import 'package:fitness_book/ui/admin_screens/components/trainer_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutAdminDetailesScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutAdminDetailesScreen({required this.workoutId, super.key});

  @override
  State<WorkoutAdminDetailesScreen> createState() =>
      _WorkoutAdminDetailesScreenState();
}

class _WorkoutAdminDetailesScreenState
    extends State<WorkoutAdminDetailesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final numberPlacesController = TextEditingController();
  final numberMembersController = TextEditingController();

  // Для отображения неизменяемого типа тренировки
  String _workoutTypeName = '';
  String _workoutTypeDescription = '';
  int _workoutTypeDuration = 0;

  String? _selectedDatetimeId;
  String? _selectedTrainerId;
  String? _selectedStatusId;

  bool _isLoading = false;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
  }

  // Храним исходные данные type для сохранения структуры
  Map<String, dynamic>? _originalTypeData;

  Future<void> _loadWorkout() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore
          .collection('scheduled_workouts')
          .doc(widget.workoutId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Тренировка не найдена')),
          );
          Navigator.pop(context);
        }
        return;
      }

      final data = doc.data()!;

      // Извлекаем данные в соответствии с реальной структурой
      final typeMap = data['type'] as Map<String, dynamic>?;
      final trainerMap = data['trainer'] as Map<String, dynamic>?;
      final statusMap = data['status'] as Map<String, dynamic>?;
      final datetimeTimestamp = data['datetime'] as Timestamp?;

      setState(() {
        // Сохраняем исходные данные типа тренировки
        _originalTypeData = typeMap;

        // Тип тренировки - только для отображения (не редактируется)
        _workoutTypeName = typeMap?['name'] ?? 'Неизвестно';
        _workoutTypeDescription = typeMap?['description'] ?? '';
        _workoutTypeDuration = typeMap?['duration'] as int? ?? 0;

        // ID для dropdown'ов - берем из вложенных объектов
        _selectedTrainerId = trainerMap?['id'] as String?;
        _selectedStatusId = statusMap?['id'] as String?;

        // Для datetime нужно найти соответствующий документ
        if (datetimeTimestamp != null) {
          _findDatetimeId(datetimeTimestamp);
        }

        numberPlacesController.text = (data['countPlaces'] ?? 0).toString();
        numberMembersController.text = (data['countMembers'] ?? 0).toString();

        _isDataLoaded = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _findDatetimeId(Timestamp datetime) async {
    try {
      final datetimeDocs = await _firestore.collection('datetimes').get();
      final targetDate = datetime.toDate();

      for (final doc in datetimeDocs.docs) {
        final docDatetime = doc.data()['datetime'] as Timestamp?;
        if (docDatetime != null) {
          final docDate = docDatetime.toDate();
          // Сравниваем с точностью до минуты
          if (targetDate.year == docDate.year &&
              targetDate.month == docDate.month &&
              targetDate.day == docDate.day &&
              targetDate.hour == docDate.hour &&
              targetDate.minute == docDate.minute) {
            setState(() {
              _selectedDatetimeId = doc.id;
            });
            break;
          }
        }
      }
    } catch (e) {
      print('Ошибка поиска datetime ID: $e');
    }
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Введите число';
    if (int.tryParse(value.trim()) == null) return 'Введите корректное число';
    return null;
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Получаем документы для обновляемых полей
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

      if (trainerDoc == null ||
          !trainerDoc.exists ||
          datetimeDoc == null ||
          !datetimeDoc.exists ||
          statusDoc == null ||
          !statusDoc.exists) {
        _showErrorSnackBar('Выбраны некорректные значения');
        return;
      }

      // Обновляем только изменяемые поля, точно копируя структуру из CreateWorkoutScreen
      final updateData = <String, dynamic>{
        'countPlaces': int.parse(numberPlacesController.text),
        'countMembers': int.parse(numberMembersController.text),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Сохраняем исходную структуру type без изменений
      if (_originalTypeData != null) {
        updateData['type'] = _originalTypeData;
      }

      // Обновляем datetime как простой Timestamp
      updateData['datetime'] = datetimeDoc.get('datetime');

      // Обновляем trainer в том же формате, что и в CreateWorkoutScreen
      updateData['trainer'] = {
        'id': trainerDoc.id,
        'name': trainerDoc.get('trainerName'),
        'specializations': trainerDoc.get('specializations'),
        'rating': trainerDoc.get('rating'),
      };

      // Обновляем status в том же формате, что и в CreateWorkoutScreen
      updateData['status'] = {
        'id': statusDoc.id,
        'name': statusDoc.get('status'),
      };

      await _firestore
          .collection('scheduled_workouts')
          .doc(widget.workoutId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Тренировка обновлена!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context);
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
    numberMembersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_isDataLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Редактировать тренировку'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Неизменяемая информация о типе тренировки
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Тип тренировки (не изменяется)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _workoutTypeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_workoutTypeDescription.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _workoutTypeDescription,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Длительность: $_workoutTypeDuration мин',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Редактируемые поля
              DatetimeDropdown(
                title: 'Дата и время',
                selectedValue: _selectedDatetimeId,
                onChanged: (val) => setState(() => _selectedDatetimeId = val),
                validator: (val) => val == null ? 'Выберите дату/время' : null,
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

              TextfieldDescription(
                title: 'Количество мест',
                hittext: '5',
                controller: numberPlacesController,
                validator: _validateNumber,
              ),

              TextfieldDescription(
                title: 'Количество участников',
                hittext: '5',
                controller: numberMembersController,
                validator: _validateNumber,
              ),

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
                      : const Text('Сохранить изменения'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
