import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'Welcome to NutriFlex 🎉',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}

