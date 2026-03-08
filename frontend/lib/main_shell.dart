import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_page.dart';
import 'screens/bmi_screen.dart';
import 'widgets/bottom_nav.dart';

// ── Placeholder screens for tabs not yet built ───────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String name;
  final IconData icon;
  const _PlaceholderScreen({required this.name, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.6, 1.0],
          colors: [Color(0xFF0D2818), Color(0xFF103E23), Color(0xFF000302)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.green.withOpacity(0.4), size: 52),
            const SizedBox(height: 16),
            Text(name,
                style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Coming soon',
                style: TextStyle(color: Colors.green, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── BMI shell — wraps BMIScreen in a Scaffold + gradient ─────────────────────
class _BmiShell extends StatelessWidget {
  const _BmiShell();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.6, -0.85),
              radius: 1.2,
              colors: [Color(0xFF103E23), Color(0xFF000302), Color(0xFF000503)],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
        ),
        const SafeArea(child: BMIScreen()),
      ]),
    );
  }
}

// ── Main shell ────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomePage(),
    _PlaceholderScreen(name: 'Meal Prep', icon: Icons.restaurant_menu),
    _BmiShell(),
    _PlaceholderScreen(name: 'Alerts',    icon: Icons.notifications_none),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF000302),
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 2,
              ),
              child: AppBottomNav(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
            ),
    );
  }
}