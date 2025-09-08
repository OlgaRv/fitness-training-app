import 'package:fitness_book/ui/admin_screens/components/specialization_dropdown.dart';
import 'package:fitness_book/ui/admin_screens/components/textfield_description.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTrainerScreen extends StatefulWidget {
  const CreateTrainerScreen({super.key});

  @override
  State<CreateTrainerScreen> createState() => _CreateTrainerScreenState();
}

class _CreateTrainerScreenState extends State<CreateTrainerScreen> {
  final trainerNameController = TextEditingController();
  final experienceController = TextEditingController();
  final ratingController = TextEditingController();
  final descriptionController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  String? _selectedSpecialization; // вот тут вместо контроллера

  // Валидатор для обязательных полей
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле обязательно для заполнения';
    }
    return null;
  }

  // Валидатор для рейтинга
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

  Future<void> _saveTrainer() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final rating = int.parse(ratingController.text.trim());

      await _firestore.collection('trainers').add({
        'trainerName': trainerNameController.text.trim(),
        'specializations': _selectedSpecialization,
        'experience': experienceController.text.trim(),
        'description': descriptionController.text.trim(),
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Очищаем поля только при успешном сохранении
      trainerNameController.clear();
      experienceController.clear();
      ratingController.clear();
      descriptionController.clear();
      setState(() {
        _selectedSpecialization = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Тренер успешно добавлен"),
            backgroundColor: Colors.green,
          ),
        );

        // Переходим на экран управления тренерами
        Navigator.pushReplacementNamed(context, '/manage_trainers');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ошибка при сохранении: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    trainerNameController.dispose();
    experienceController.dispose();
    ratingController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Добавить тренера'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextfieldDescription(
                  title: 'ФИО тренера',
                  hittext: 'Олег Котов',
                  controller: trainerNameController,
                  validator: _validateRequired,
                ),
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

                TextfieldDescription(
                  title: 'Опыт работы',
                  hittext: '3 года',
                  controller: experienceController,
                  validator: _validateRequired,
                ),
                TextfieldDescription(
                  title: 'Рейтинг',
                  hittext: '4',
                  controller: ratingController,
                  keyboardType: TextInputType.number,
                  validator: _validateRating,
                ),
                TextfieldDescription(
                  title: 'Личные достижения',
                  hittext:
                      'Разработка эффективных программ тренировок - способность создавать индивидуальные планы тренировок, учитывающие цели, физическую подготовку и потребности клиентов',
                  controller: descriptionController,
                  validator: _validateRequired,
                  isTextArea: true,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTrainer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF4ECDC4,
                      ), // Точный цвет как в макете
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Сохранить',
                            style: TextStyle(
                              color: Colors.white,
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
    );
  }
}
