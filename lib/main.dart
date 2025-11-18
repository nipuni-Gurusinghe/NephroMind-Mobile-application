import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';   // ⭐ IMPORTANT
import 'package:nephrom /welcome_screen.dart';
import 'package:nephromind/dashboard_screen.dart';
import 'package:nephromind/registration_screen.dart';
import 'package:nephromind/login_screen.dart';
import 'package:nephromind/DialysisTrackerScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();     // ✔ Works now
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NephroMind Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF6A1B9A)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/login': (context) => const LoginScreen(),
        '/appointments': (context) => const DialysisTrackerScreen(),
      },
    );
  }
}
