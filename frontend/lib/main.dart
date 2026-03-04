import 'package:flutter/material.dart';
import '.bmi_screen.dart';

void main() => runApp(const NutriFlexApp());

class NutriFlexApp extends StatelessWidget {
  const NutriFlexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriFlex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF080D0A),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF14D97D)),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 2; // BMI tab active by default

  // Swap placeholders with your real screens as you build them
  final List<Widget> _screens = [
    const _PlaceholderScreen('Home'),
    const _PlaceholderScreen('Meal Prep'),
    const BMIScreen(),                    // ← your BMI screen
    const _PlaceholderScreen('Alerts'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D0A),
      body: SafeArea(child: _screens[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1610),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF14D97D),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined),        activeIcon: Icon(Icons.home),            label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined),  activeIcon: Icon(Icons.restaurant),      label: 'Meal Prep'),
            BottomNavigationBarItem(icon: Icon(Icons.calculate_outlined),   activeIcon: Icon(Icons.calculate),       label: 'BMI'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined),activeIcon: Icon(Icons.notifications),  label: 'Alerts'),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String name;
  const _PlaceholderScreen(this.name);
  @override
  Widget build(BuildContext context) => Center(
    child: Text(name, style: const TextStyle(color: Colors.white54, fontSize: 20)));
}
