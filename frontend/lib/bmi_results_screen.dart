import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '.bmi_calculator.dart';

class BMIResultsScreen extends StatelessWidget {
  const BMIResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<BMIData>(context);
    const green = Color(0xFF14D97D);

    return Scaffold(
      backgroundColor: const Color(0xFF080D0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("BMI Results", style: const TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // BMI DISPLAY CARD
            _card(
              child: Column(
                children: [
                  const Text("Your BMI", style: const TextStyle(color: Colors.grey)),
                  Text(
                    data.bmi.toStringAsFixed(1),
                    style: const TextStyle(color: green, fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  Chip(
                    label: Text(data.category),
                    backgroundColor: green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // CALORIE INTAKE CARD
            _card(
              child: Column(
                children: [
                  const Text("Recommended Daily Intake", style: const TextStyle(color: Colors.white)),
                  Text(
                    "${data.calories}",
                    style: const TextStyle(color: green, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const Text("calories per day", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to keep the dark UI consistent
  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D120E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: child,
      );
}