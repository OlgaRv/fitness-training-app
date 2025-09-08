import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _fadeIn;

  int _currentTextIndex = 0;
  Timer? _textTimer;

  final List<String> _motivationalTexts = [
    'Готовим тренировки...',
    'Подбираем лучших тренеров...',
    'Твоя сила ждет тебя...',
    'Почти готово!',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _checkAuthAndNavigate();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween<double>(begin: -math.pi, end: 0.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
  }

  void _startAnimations() {
    _logoController.forward();
    Timer(const Duration(milliseconds: 800), () {
      _textController.forward();
      _startTextRotation();
    });
  }

  void _startTextRotation() {
    _textTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_currentTextIndex < _motivationalTexts.length - 1) {
        setState(() => _currentTextIndex++);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3)); // имитация загрузки

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
      return;
    }

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      // создаём запись для нового пользователя
      await userDoc.set({
        'email': user.email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/user_home');
      }
      return;
    }

    final data = snapshot.data()!;
    final role = data['role'] ?? 'user';

    if (mounted) {
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_home');
      } else {
        Navigator.pushReplacementNamed(context, '/user_home');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3F51B5), Color(0xFF5C6BC0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _logoController,
                builder: (_, _) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Transform.rotate(
                      angle: _logoRotation.value,
                      child: const Text('💪', style: TextStyle(fontSize: 72)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _textController,
                builder: (_, _) {
                  return Opacity(
                    opacity: _fadeIn.value,
                    child: Text(
                      _motivationalTexts[_currentTextIndex],
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
