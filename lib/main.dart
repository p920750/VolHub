// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/app_opening.dart';

void main() {
  runApp(const VolHubApp());
}

class VolHubApp extends StatelessWidget {
  const VolHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VolHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD91A46)),
        useMaterial3: true,
      ),
      home: const AppOpeningPage(),
    );
  }
}
