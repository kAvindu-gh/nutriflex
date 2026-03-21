import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'map_page.dart';
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken('pk.YOUR_TOKEN_HERE');
  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A1F0A),
        colorScheme: ColorScheme.dark(primary: const Color(0xFF1DB954)),
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
  int _currentIndex = 0;
 
  final List<Widget> _pages = const [
    _PlaceholderPage(icon: Icons.home_rounded, label: 'Home'),
    _PlaceholderPage(icon: Icons.restaurant_menu_rounded, label: 'Meal Prep'),
    _PlaceholderPage(icon: Icons.calculate_rounded, label: 'BMI'),
    MapPage(),
    _PlaceholderPage(icon: Icons.notifications_rounded, label: 'Alerts\nComing soon'),
  ];
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}
 
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
 
  const _BottomNav({required this.currentIndex, required this.onTap});
 
  @override
  Widget build(BuildContext context) {
    const active = Color(0xFF2ECC71);
    const inactive = Color(0xFF4A7A4A);
    const bg = Color(0xFF0D1F0D);
 
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.restaurant_menu_rounded, 'Meal Prep'),
      (Icons.calculate_rounded, 'BMI'),
      (Icons.map_rounded, 'Map'),
      (Icons.notifications_rounded, 'Alerts'),
    ];
 
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12)],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(items[i].$1, color: selected ? active : inactive, size: 26),
                const SizedBox(height: 4),
                Text(
                  items[i].$2,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? active : inactive,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
 
class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String label;
 
  const _PlaceholderPage({required this.icon, required this.label});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: const Color(0xFF2ECC71).withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF2ECC71), fontSize: 18),
          ),
        ],
      ),
    );
  }
}