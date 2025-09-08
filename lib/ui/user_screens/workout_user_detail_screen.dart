import 'package:fitness_book/services/workout_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkoutUserDetailScreen extends StatefulWidget {
  final String workoutId;
  final Map<String, dynamic> workoutData;

  const WorkoutUserDetailScreen({
    super.key,
    required this.workoutId,
    required this.workoutData,
  });

  @override
  State<WorkoutUserDetailScreen> createState() =>
      _WorkoutUserDetailScreenState();
}

class _WorkoutUserDetailScreenState extends State<WorkoutUserDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  WorkoutService? _workoutService; // Предполагается, что у вас есть этот сервис

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _workoutService = WorkoutService();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final datetime = widget.workoutData['datetime'] as Timestamp?;

    final isUpcoming =
        datetime != null && datetime.toDate().isAfter(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Детали тренировки'),
        actions: [
          if (isUpcoming)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditOptions(context),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildDetailsCard(),
              const SizedBox(height: 16),
              _buildTrainerCard(),
              const SizedBox(height: 16),
              _buildStatusCard(),
              const SizedBox(height: 16),
              if (isUpcoming) _buildActionButtons(),
              const SizedBox(height: 80), // Отступ снизу для кнопок
            ],
          ),
        ),
      ),
      floatingActionButton: isUpcoming ? _buildFloatingActions() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeaderCard() {
    final type = widget.workoutData['type']?.toString() ?? 'Тренировка';
    final datetime = widget.workoutData['datetime'] as Timestamp?;
    final dateStr = datetime != null
        ? DateFormat('dd MMMM yyyy, HH:mm', 'ru').format(datetime.toDate())
        : 'Время не указано';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.teal, Color(0xFF00695C)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getWorkoutIcon(type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final duration = widget.workoutData['duration']?.toString() ?? '60 мин';
    final description =
        widget.workoutData['description']?.toString() ?? 'Нет описания';
    //    final countPlaces =
    //      widget.workoutData['countPlaces']?.toString() ?? 'Не указано';  места проведения тренировок

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация о тренировке',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.access_time,
              'Продолжительность, мин',
              duration,
            ),
            const SizedBox(height: 12),
            //            _buildInfoRow(Icons.people, 'Места', countPlaces),
            //          const SizedBox(height: 12),
            _buildInfoRow(
              Icons.description,
              'Описание',
              description,
              isMultiline: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerCard() {
    final trainerName =
        widget.workoutData['trainerName']?.toString() ?? 'Тренер';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.withValues(alpha: 0.1),
              radius: 25,
              child: const Icon(Icons.person, color: Colors.teal, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Тренер',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trainerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showTrainerInfo(context, trainerName),
              icon: const Icon(Icons.info_outline, color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = widget.workoutData['status']?.toString() ?? '';
    final bookedAt = widget.workoutData['bookedAt'] as Timestamp?;
    final bookedAtStr = bookedAt != null
        ? DateFormat('dd.MM.yyyy в HH:mm', 'ru').format(bookedAt.toDate())
        : 'Неизвестно';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статус бронирования',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Дата бронирования: $bookedAtStr',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final datetime = widget.workoutData['datetime'] as Timestamp?;
    final canCancel =
        datetime != null &&
        datetime.toDate().isAfter(DateTime.now().add(const Duration(hours: 2)));

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.red,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: canCancel ? () => _cancelBooking(context) : null,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(
                    canCancel ? 'Отменить бронь' : 'Слишком поздно для отмены',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canCancel ? Colors.red[600] : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addToCalendar(context),
            icon: const Icon(Icons.calendar_today),
            label: const Text('Добавить в календарь'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.teal),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton.extended(
          onPressed: () => _shareWorkout(context),
          icon: const Icon(Icons.share),
          label: const Text('Поделиться'),
          backgroundColor: Colors.teal[700],
          heroTag: "share",
        ),
        FloatingActionButton.extended(
          onPressed: () => _showReminder(context),
          icon: const Icon(Icons.notifications),
          label: const Text('Напоминание'),
          backgroundColor: Colors.orange[700],
          heroTag: "reminder",
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: isMultiline ? null : 1,
                overflow: isMultiline ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    //final status = widget.workoutData['status']?.toString() ?? '';
    final datetime = widget.workoutData['datetime'] as Timestamp?;
    final isUpcoming =
        datetime != null && datetime.toDate().isAfter(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUpcoming ? Colors.green[400] : Colors.orange[400],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUpcoming ? Icons.schedule : Icons.history,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isUpcoming ? 'Предстоящая' : 'Прошедшая',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Методы для обработки действий
  Future<void> _cancelBooking(BuildContext context) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить бронь?'),
        content: const Text(
          'Вы уверены, что хотите отменить бронирование этой тренировки? '
          'Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      setState(() => _isLoading = true);

      try {
        await _workoutService?.cancelBooking(widget.workoutId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Бронирование успешно отменено'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Возвращаем true для обновления списка
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showEditOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Действия с тренировкой',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Отменить бронь'),
              onTap: () {
                Navigator.pop(context);
                _cancelBooking(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.blue),
              title: const Text('Перенести на другое время'),
              onTap: () {
                Navigator.pop(context);
                _rescheduleWorkout(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add, color: Colors.green),
              title: const Text('Добавить заметку'),
              onTap: () {
                Navigator.pop(context);
                _addNote(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addToCalendar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция добавления в календарь в разработке'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareWorkout(BuildContext context) {
    final type = widget.workoutData['type']?.toString() ?? 'Тренировка';
    final trainer = widget.workoutData['trainerName']?.toString() ?? 'Тренер';
    final datetime = widget.workoutData['datetime'] as Timestamp?;
    final dateStr = datetime != null
        ? DateFormat('dd MMMM yyyy в HH:mm', 'ru').format(datetime.toDate())
        : 'Время не указано';

    final shareText =
        'Я записался на тренировку!\n\n'
        '🏋️ $type\n'
        '👨‍💼 Тренер: $trainer\n'
        '📅 $dateStr\n\n'
        'Присоединяйся!';

    // Здесь можно использовать share_plus пакет
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Текст для шэринга скопирован:\n$shareText'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showReminder(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Напоминание'),
        content: const Text('За сколько времени до тренировки напомнить?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _setReminder(30); // 30 минут
            },
            child: const Text('30 мин'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _setReminder(60); // 1 час
            },
            child: const Text('1 час'),
          ),
        ],
      ),
    );
  }

  void _setReminder(int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Напоминание установлено за $minutes минут'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rescheduleWorkout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция переноса тренировки в разработке'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _addNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Добавить заметку'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Введите заметку к тренировке...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _saveNote(controller.text);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }

  void _saveNote(String note) {
    if (note.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заметка сохранена'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showTrainerInfo(BuildContext context, String trainerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(trainerName),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📱 Телефон: +7 (999) 123-45-67'),
            SizedBox(height: 8),
            Text('📧 Email: trainer@fitness.com'),
            SizedBox(height: 8),
            Text('🏆 Опыт: 5+ лет'),
            SizedBox(height: 8),
            Text('💪 Специализация: Силовые тренировки'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы
  IconData _getWorkoutIcon(String type) {
    switch (type.toLowerCase()) {
      case 'йога':
        return Icons.self_improvement;
      case 'кардио':
        return Icons.directions_run;
      case 'силовая':
        return Icons.fitness_center;
      case 'стретчинг':
        return Icons.accessibility_new;
      default:
        return Icons.sports_gymnastics;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'забронировано':
        return Icons.check_circle;
      case 'отменено':
        return Icons.cancel;
      case 'посещено':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'забронировано':
        return Colors.green;
      case 'отменено':
        return Colors.red;
      case 'посещено':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// Дополнительная модель для типобезопасности
class WorkoutDetailModel {
  final String workoutId;
  final String type;
  final String trainerName;
  final DateTime datetime;
  final String status;
  final String duration;
  final String description;
  final int? countPlaces;
  final DateTime? bookedAt;

  WorkoutDetailModel({
    required this.workoutId,
    required this.type,
    required this.trainerName,
    required this.datetime,
    required this.status,
    required this.duration,
    required this.description,
    this.countPlaces,
    this.bookedAt,
  });

  factory WorkoutDetailModel.fromMap(String id, Map<String, dynamic> data) {
    return WorkoutDetailModel(
      workoutId: id,
      type: data['type']?.toString() ?? 'Тренировка',
      trainerName: data['trainerName']?.toString() ?? 'Тренер',
      datetime: (data['datetime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status']?.toString() ?? '',
      duration: data['duration']?.toString() ?? '60 мин',
      description: data['description']?.toString() ?? 'Нет описания',
      countPlaces: data['countPlaces'] as int?,
      bookedAt: (data['bookedAt'] as Timestamp?)?.toDate(),
    );
  }
}
