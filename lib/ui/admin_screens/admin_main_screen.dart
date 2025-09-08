import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonLabels = [
      "Добавить тренера",
      "Добавить дату/время",
      "Добавить тип",
      "Добавить статус",
      "Добавить тренировку",
    ];

    // вычисляем ширину текста для всех кнопок
    final textStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      letterSpacing: 0.2,
    );

    double maxWidth = 0;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final label in buttonLabels) {
      textPainter.text = TextSpan(text: label, style: textStyle);
      textPainter.layout();
      if (textPainter.width > maxWidth) {
        maxWidth = textPainter.width;
      }
    }

    // добавим немного паддинга по бокам
    final buttonWidth = maxWidth + 48; // 24px padding слева + справа

    return Scaffold(
      appBar: AppBar(
        title: const Text("Панель администратора"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => _signOut(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, color: Colors.redAccent),
                  SizedBox(height: 2),
                  Text(
                    "Выйти",
                    style: TextStyle(fontSize: 12, color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center, // центрируем всё по вертикали
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Обновить\nинформацию\nо тренировках",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Группа кнопок
              Column(
                mainAxisSize: MainAxisSize.min, // под размер содержимого
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildActionButton(
                    context,
                    text: "Добавить тренера",
                    route: "/create_trainer",
                    width: buttonWidth,
                  ),
                  SizedBox(height: buttonWidth * 0.3),
                  _buildActionButton(
                    context,
                    text: "Добавить дату/время",
                    route: "/manage_datetime",
                    width: buttonWidth,
                  ),
                  SizedBox(height: buttonWidth * 0.3),
                  _buildActionButton(
                    context,
                    text: "Добавить тип",
                    route: "/manage_type",
                    width: buttonWidth,
                  ),
                  SizedBox(height: buttonWidth * 0.3),
                  _buildActionButton(
                    context,
                    text: "Добавить статус",
                    route: "/create_status",
                    width: buttonWidth,
                  ),
                  SizedBox(height: buttonWidth * 0.3),
                  _buildActionButton(
                    context,
                    text: "Добавить тренировку",
                    route: "/create_workout",
                    width: buttonWidth,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Создает кнопку действия
  Widget _buildActionButton(
    BuildContext context, {
    required String text,
    required String route,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, route),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2DD4BF),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold, // потолще
            color: Colors.white, // белый
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
