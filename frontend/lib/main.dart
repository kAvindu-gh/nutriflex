import 'package:flutter/material.dart';
import 'package:frontend/notification_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const NotificationsPage(), // This ensures you don't see the placeholder
    );
  }
}