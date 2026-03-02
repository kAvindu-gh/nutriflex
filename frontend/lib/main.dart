import 'package:flutter/material.dart';
import 'userProfile.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriFlex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF22C55E),
          surface: const Color(0xFF0F0F13),
        ),
        fontFamily: 'Roboto',
      ),
      home: const ProfileScreen(),
    );
  }
}