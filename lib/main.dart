import 'package:flutter/material.dart';
import 'package:nephromind/welcome_screen.dart'; // NEW: Import WelcomeScreen
import 'package:nephromind/dashboard_screen.dart';
import 'package:nephromind/registration_screen.dart'; // NEW: Import RegistrationScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NephroMind Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A1B9A)),
        useMaterial3: true,
      ),
      // NEW: Define routes for navigation
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(), // The starting screen
        '/dashboard': (context) => const DashboardScreen(),
        '/register': (context) => const RegistrationScreen(),
      },
      // You can remove the 'home' property now that 'initialRoute' is set
      // home: const DashboardScreen(), // Removed
    );
  }
}

// NOTE: The Counter logic (MyHomePage, _MyHomePageState) is assumed to be deleted
// or kept only if still used for other purposes, as noted in your original main.dart.