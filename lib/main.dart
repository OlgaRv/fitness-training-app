import 'package:firebase_core/firebase_core.dart';
import 'package:fitness_book/ui/admin_screens/create_status_screen.dart';
import 'package:fitness_book/ui/common_screens/manage_schedule_screen.dart';
import 'package:fitness_book/ui/theme.dart';
import 'package:fitness_book/ui/user_screens/available_workouts.dart';
import 'package:fitness_book/ui/user_screens/workout_user_detail_screen.dart';
import 'package:flutter/material.dart';

import 'package:fitness_book/ui/splash_screen.dart';
import 'package:fitness_book/ui/authorization/auth_screen.dart';

import 'package:fitness_book/ui/user_home_screen.dart';
import 'package:fitness_book/ui/user_screens/user_main_screen.dart';

import 'package:fitness_book/ui/admin_home_screen.dart';
import 'package:fitness_book/ui/admin_screens/admin_main_screen.dart';
import 'package:fitness_book/ui/admin_screens/manage_datetime_screen.dart';
import 'package:fitness_book/ui/admin_screens/create_trainer_screen.dart';
import 'package:fitness_book/ui/admin_screens/manage_type_training_screen.dart';
import 'package:fitness_book/ui/admin_screens/create_workout_screen.dart';
import 'package:fitness_book/ui/admin_screens/trainer_admin_details_screen.dart';
import 'package:fitness_book/ui/admin_screens/workout_admin_details_screen.dart';

import 'package:fitness_book/ui/common_screens/manage_trainers_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Book',

      // 👇 Настройка локализации здесь
      locale: const Locale('ru', 'RU'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU'), Locale('en', 'US')],

      debugShowCheckedModeBanner: false,
      theme: appTheme,
      darkTheme: darkAppTheme,
      themeMode: ThemeMode.system, // автопереключение
      // начинаем с SplashScreen, он сам решает куда дальше
      home: const SplashScreen(),
      routes: {
        '/auth': (_) => const AuthScreen(),

        // user flow
        '/user_home': (_) => const UserHomeScreen(),
        '/user_main': (_) => const UserMainScreen(),

        // admin flow
        '/admin_home': (_) => const AdminHomeScreen(),
        '/admin_main': (_) => const AdminMainScreen(),

        '/create_trainer': (_) => const CreateTrainerScreen(),
        '/manage_trainers': (_) => const ManageTrainersScreen(),
        '/edit_trainer': (_) => const TrainerAdminDetailsScreen(),

        '/manage_datetime': (_) => const ManageDatetimeScreen(),
        '/manage_type': (_) => const ManageTypeTrainingScreen(),

        '/create_workout': (_) => const CreateWorkoutScreen(),

        '/create_status': (_) => const CreateStatusScreen(),

        '/manage_schedule': (_) => const ManageScheduleScreen(),

        '/available_workouts': (_) => const AvailableWorkoutsScreen(),
      },

      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/edit_workout':
            final workoutId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => WorkoutAdminDetailesScreen(workoutId: workoutId),
            );

          case '/workout_details':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => WorkoutUserDetailScreen(
                workoutId: args['workoutId'],
                workoutData: args['workoutData'],
              ),
            );

          default:
            return null;
        }
      },
    );
  }
}
