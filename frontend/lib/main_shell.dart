import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/notification_page.dart';
import 'widgets/bottom_nav.dart';

// ── Coming-soon placeholder (used for Home, Meal Prep, BMI in this branch) ────
class _PlaceholderScreen extends StatelessWidget {
  final String   name;
  final IconData icon;
  final String?  subtitle;
  const _PlaceholderScreen({
    required this.name,
    required this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.55, 1.0],
            colors: [
              Color(0xFF0D2818),
              Color(0xFF0A1A0F),
              Color(0xFF000302),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing icon container
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A22),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: const Color(0xFF2A5E38), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3DD68C).withOpacity(0.15),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(icon,
                      color: const Color(0xFF3DD68C), size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3A22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF3DD68C).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.access_time_rounded,
                          color: Color(0xFF3DD68C), size: 13),
                      SizedBox(width: 5),
                      Text(
                        'Coming soon',
                        style: TextStyle(
                          color: Color(0xFF3DD68C),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                        color: Color(0xFF8CAD96), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Main shell ─────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // ── Four tabs: Home | Meal Prep | BMI | Alerts ───────────────────────────
  final List<Widget> _screens = const [
    _PlaceholderScreen(
      name:     'Home',
      icon:     Icons.home_outlined,
      subtitle: 'Your dashboard is being built.',
    ),
    _PlaceholderScreen(
      name:     'Meal Prep',
      icon:     Icons.restaurant_menu_outlined,
      subtitle: 'Recipe planning & cart features\nare on the way.',
    ),
    _PlaceholderScreen(
      name:     'BMI',
      icon:     Icons.monitor_weight_outlined,
      subtitle: 'Fitness tracking & BMI calculator\ncoming soon.',
    ),
    NotificationsPage(),  // ← live in this branch
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor:           Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarColor:                     Colors.transparent,
      statusBarIconBrightness:            Brightness.light,
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