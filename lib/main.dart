import 'package:flutter/material.dart';
import 'package:nephromind/dashboard_screen.dart'; // Import the new file

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
        // Set your main app theme here
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A1B9A)), // Using the deep purple color
        useMaterial3: true,
      ),
      // Use your new dashboard screen as the home page
      home: const DashboardScreen(),
    );
  }
}

// The MyHomePage, _MyHomePageState, and the main.dart counter logic
// are no longer needed if this screen is the new home.
// You can delete them, or keep them if you plan to use them elsewhere.
// But for the purpose of the new UI, you only need MyApp() and DashboardScreen().