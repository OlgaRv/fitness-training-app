import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  AuthMode _mode = AuthMode.login; // по умолчанию активен Login
  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---- Бизнес-логика --------------------------------------------------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_mode == AuthMode.login) {
        await _handleLogin(email, password);
      } else {
        await _handleRegistration(email, password);
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    final uid = userCredential.user!.uid;

    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await docRef.get();

    // если документа нет → создаём новый
    if (!doc.exists) {
      final username = email.split('@')[0]; // <-- берём всё до @
      await docRef.set({
        'email': userCredential.user!.email,
        'role': 'user',
        'username': username, // <-- сохраняем
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // читаем свежие данные (или берём из doc, если ты не хочешь перезапрашивать)
    final userData = (await docRef.get()).data() as Map<String, dynamic>;
    final role = userData['role'] as String;

    await _saveUserData(uid, role);
    _navigateToRoleScreen(role);
  }

  Future<void> _handleRegistration(String email, String password) async {
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final uid = userCredential.user!.uid;
    final username = email.split('@')[0]; // имя по умолчанию

    // создаём документ в Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email,
      'role': 'user',
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // сохраняем в SharedPreferences
    await _saveUserData(uid, 'user');

    // показать уведомление
    _showSuccessSnackBar('Account created successfully!');

    // и сразу отправляем на экран пользователя
    _navigateToRoleScreen('user');
  }

  Future<void> _saveUserData(String uid, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', uid);
    await prefs.setString('role', role);
  }

  void _navigateToRoleScreen(String role) {
    if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin_home');
    } else {
      Navigator.pushReplacementNamed(context, '/user_home');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Authentication'),
        centerTitle: true,
        elevation: 0,
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              Icon(
                Icons.fitness_center,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),

              Text(
                'Fitness Book',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // --- Переключатель режима (Login / Register) ---
              _ModeSwitcher(
                mode: _mode,
                enabled: !_isLoading,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                validator: _validatePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Основная кнопка действия
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_mode == AuthMode.login ? 'Login' : 'Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Небольшой виджет-переключатель: две «кнопки» в одной строке.
class _ModeSwitcher extends StatelessWidget {
  final AuthMode mode;
  final bool enabled;
  final ValueChanged<AuthMode> onChanged;

  const _ModeSwitcher({
    required this.mode,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == AuthMode.login;

    ButtonStyle style(bool selected) => selected
        ? ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          )
        : OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: isLogin
                ? ElevatedButton(
                    onPressed: enabled ? null : null, // уже выбран
                    style: style(true),
                    child: const Text('Login'),
                  )
                : OutlinedButton(
                    onPressed: enabled ? () => onChanged(AuthMode.login) : null,
                    style: style(false),
                    child: const Text('Login'),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 44,
            child: !isLogin
                ? ElevatedButton(
                    onPressed: enabled ? null : null, // уже выбран
                    style: style(true),
                    child: const Text('Register'),
                  )
                : OutlinedButton(
                    onPressed: enabled
                        ? () => onChanged(AuthMode.register)
                        : null,
                    style: style(false),
                    child: const Text('Register'),
                  ),
          ),
        ),
      ],
    );
  }
}
