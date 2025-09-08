import 'package:fitness_book/ui/admin_screens/components/specialization_dropdown.dart';
import 'package:fitness_book/ui/admin_screens/components/textfield_description.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainerAdminDetailsScreen extends StatefulWidget {
  const TrainerAdminDetailsScreen({super.key});

  @override
  State<TrainerAdminDetailsScreen> createState() =>
      _TrainerAdminDetailsScreenState();
}

class _TrainerAdminDetailsScreenState extends State<TrainerAdminDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Контроллеры для полей
  final _trainerNameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _ratingController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedSpecialization;
  String? _trainerId;
  bool _isLoading = true;
  bool _isSaving = false;

  // Данные тренера для сравнения изменений
  Map<String, dynamic>? _originalTrainerData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Получаем ID тренера из аргументов маршрута
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _trainerId != args) {
      _trainerId = args;
      _loadTrainerData();
    }
  }

  // Загрузка данных тренера
  Future<void> _loadTrainerData() async {
    if (_trainerId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await _firestore.collection('trainers').doc(_trainerId).get();

      if (doc.exists) {
        final data = doc.data()!;
        _originalTrainerData = Map<String, dynamic>.from(data);

        // Заполняем контроллеры данными
        _trainerNameController.text = data['trainerName'] ?? '';
        _experienceController.text = data['experience'] ?? '';
        _ratingController.text = (data['rating'] ?? 0).toString();
        _descriptionController.text = data['description'] ?? '';

        setState(() {
          _selectedSpecialization = data['specializations'];
        });
      } else {
        _showError('Тренер не найден');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showError('Ошибка при загрузке данных: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Валидаторы
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле обязательно для заполнения';
    }
    return null;
  }

  String? _validateRating(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите рейтинг тренера';
    }

    final rating = int.tryParse(value.trim());
    if (rating == null) {
      return 'Введите корректное число';
    }

    if (rating < 1 || rating > 5) {
      return 'Рейтинг должен быть от 1 до 5';
    }

    return null;
  }

  // Проверка наличия изменений
  bool _hasChanges() {
    if (_originalTrainerData == null) return false;

    return _originalTrainerData!['experience'] !=
            _experienceController.text.trim() ||
        _originalTrainerData!['description'] !=
            _descriptionController.text.trim() ||
        _originalTrainerData!['specializations'] != _selectedSpecialization ||
        _originalTrainerData!['rating'] !=
            int.tryParse(_ratingController.text.trim());
  }

  // Сохранение изменений
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasChanges()) {
      _showMessage('Нет изменений для сохранения', Colors.orange);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final rating = int.parse(_ratingController.text.trim());

      await _firestore.collection('trainers').doc(_trainerId).update({
        'specializations': _selectedSpecialization,
        'experience': _experienceController.text.trim(),
        'description': _descriptionController.text.trim(),
        'rating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Обновляем оригинальные данные
      _originalTrainerData = {
        ..._originalTrainerData!,
        'specializations': _selectedSpecialization,
        'experience': _experienceController.text.trim(),
        'description': _descriptionController.text.trim(),
        'rating': rating,
      };

      _showMessage('Данные тренера успешно обновлены', Colors.green);
    } catch (e) {
      _showError('Ошибка при сохранении: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Показ сообщений
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

  void _showError(String message) {
    _showMessage(message, Colors.red);
  }

  // Подтверждение выхода с несохраненными изменениями
  Future<bool> _onWillPop() async {
    if (!_hasChanges()) return true;

    if (!mounted) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Несохраненные изменения'),
        content: const Text(
          'У вас есть несохраненные изменения. Выйти без сохранения?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context, false);
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  void dispose() {
    _trainerNameController.dispose();
    _experienceController.dispose();
    _ratingController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (await _onWillPop()) {
          if (mounted) Navigator.of(this.context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.of(this.context).pop();
              }
            },
          ),
          title: const Text(
            'Информация о тренере',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_hasChanges())
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: const Icon(Icons.circle, color: Colors.orange, size: 12),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4ECDC4)),
                    SizedBox(height: 16),
                    Text('Загрузка данных тренера...'),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // ФИО тренера (только для чтения)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ФИО тренера',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: const Color(0xFFF5F5F5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF666666),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _trainerNameController.text,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                        // Специализация тренера (редактируемая)
                        SpecializationDropdown(
                          title: 'СПЕЦИАЛИЗАЦИЯ тренера',
                          selectedValue: _selectedSpecialization,
                          onChanged: (val) {
                            setState(() {
                              _selectedSpecialization = val;
                            });
                          },
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Выберите специализацию';
                            }
                            return null;
                          },
                        ),

                        // Опыт работы
                        TextfieldDescription(
                          title: 'Опыт работы',
                          hittext: '3 года',
                          controller: _experienceController,
                          validator: _validateRequired,
                        ),

                        // Рейтинг
                        TextfieldDescription(
                          title: 'Рейтинг',
                          hittext: '4',
                          controller: _ratingController,
                          keyboardType: TextInputType.number,
                          validator: _validateRating,
                        ),

                        // Личные достижения
                        TextfieldDescription(
                          title: 'Личные достижения',
                          hittext:
                              'Разработка эффективных программ тренировок - способность создавать индивидуальные планы тренировок, учитывающие цели, физическую подготовку и потребности клиентов',
                          controller: _descriptionController,
                          validator: _validateRequired,
                          isTextArea: true,
                        ),

                        const SizedBox(height: 40),

                        // Кнопка сохранения
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_isSaving || !_hasChanges())
                                ? null
                                : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasChanges()
                                  ? const Color(0xFF4ECDC4)
                                  : const Color(0xFFE0E0E0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _hasChanges()
                                        ? 'Сохранить'
                                        : 'Нет изменений',
                                    style: TextStyle(
                                      color: _hasChanges()
                                          ? Colors.white
                                          : const Color(0xFF888888),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
