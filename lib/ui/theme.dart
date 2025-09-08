// theme.dart
import 'package:flutter/material.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  primarySwatch: Colors.teal,
  scaffoldBackgroundColor: Colors.white,

  /// AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.teal,
    foregroundColor: Colors.white,
    centerTitle: true,
    elevation: 2,
    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),

  /// Кнопки
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
    ),
  ),

  /// Тексты
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
  ),

  /// Иконки
  iconTheme: const IconThemeData(color: Colors.teal),
);

final darkAppTheme = ThemeData.dark().copyWith(
  colorScheme: const ColorScheme.dark(
    primary: Colors.teal,
    secondary: Colors.tealAccent,
  ),
);
