import 'package:fitness_book/ui/admin_screens/admin_main_screen.dart';
import 'package:fitness_book/ui/common_screens/manage_schedule_screen.dart';
import 'package:fitness_book/ui/common_screens/manage_trainers_screen.dart';
import 'package:fitness_book/ui/common_screens/manage_users_screen.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    AdminMainScreen(),
    ManageScheduleScreen(),
    ManageTrainersScreen(),
    ManageUsersScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Управление',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Расписание',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Тренеры'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Пользователи',
          ),
        ],
      ),
    );
  }
}
