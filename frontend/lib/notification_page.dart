import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  Entry point – wrap in your existing app
// ─────────────────────────────────────────────
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainScaffold(),
    );
  }
}

// ─────────────────────────────────────────────
//  MainScaffold – bottom nav with 4 tabs
// ─────────────────────────────────────────────
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Pages list – only Alerts is fully implemented here.
  // Replace the placeholders with your real pages.
  late final List<Widget> _pages = [
    const _PlaceholderPage(label: 'Home'),
    const _PlaceholderPage(label: 'Meal Prep'),
    const _PlaceholderPage(label: 'BMI'),
    const NotificationsPage(), // index 3 → Alerts
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_outlined, label: 'Home'),
      _NavItem(icon: Icons.restaurant_menu_outlined, label: 'Meal Prep'),
      _NavItem(icon: Icons.calculate_outlined, label: 'BMI'),
      _NavItem(icon: Icons.notifications_outlined, label: 'Alerts'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            // Original: color: Colors.black.withOpacity(0.4),
            // Fix: Use Color.fromRGBO or Colors.black.withAlpha instead of deprecated withOpacity.
            color: Color.fromRGBO(0, 0, 0, 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? _activeIcon(i)
                            : items[i].icon,
                        color:
                            selected ? AppColors.green : AppColors.navUnselected,
                        size: 26,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          color: selected
                              ? AppColors.green
                              : AppColors.navUnselected,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  IconData _activeIcon(int i) {
    switch (i) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.restaurant_menu;
      case 2:
        return Icons.calculate;
      case 3:
        return Icons.notifications;
      default:
        return Icons.circle;
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─────────────────────────────────────────────
//  Notifications Page  (matches screenshot 1)
// ─────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _filterIndex = 0; // 0 = All, 1 = Unread

  final List<_NotifData> _notifications = [
    _NotifData(
      icon: Icons.timer_outlined,
      iconBg: AppColors.greenCard,
      title: 'New Recipe Available !',
      body: 'Try our new "super Green Smoothie" perfect for muscle recovery',
      time: '5m ago',
      isRead: false,
    ),
    _NotifData(
      icon: Icons.check_box_outlined,
      iconBg: AppColors.greenCard,
      title: 'Order Delivered',
      body: 'Your meal prep ingredients have been delivered',
      time: '1h ago',
      isRead: false,
    ),
    _NotifData(
      icon: Icons.military_tech_outlined,
      iconBg: AppColors.darkCard,
      title: 'Achievement Unlocked !',
      body: '7-day streak ! Keep up the great work',
      time: '4m ago',
      isRead: true,
    ),
    _NotifData(
      icon: Icons.trending_up,
      iconBg: AppColors.darkCard,
      title: 'Weekly Progress',
      body: 'You hit 95% of your calorie goals this weak',
      time: '15m ago',
      isRead: true,
    ),
    _NotifData(
      icon: Icons.local_dining_outlined,
      iconBg: AppColors.darkCard,
      title: 'Meal Reminder',
      body: 'Time for your post-workout protein shake !',
      time: '8m ago',
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filterIndex == 1
        ? _notifications.where((n) => !n.isRead).toList()
        : _notifications;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stay updated with your\nfitness journey',
                          style: TextStyle(
                            color: AppColors.subText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.greenCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.green,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Filter Tabs ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filterIndex == 0,
                    onTap: () => setState(() => _filterIndex = 0),
                  ),
                  const SizedBox(width: 10),
                  _FilterChip(
                    label: 'Unread',
                    selected: _filterIndex == 1,
                    onTap: () => setState(() => _filterIndex = 1),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        for (final n in _notifications) {
                          n.isRead = true;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Text(
                        'Mark All read',
                        style: TextStyle(
                          color: AppColors.subText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Notification cards list ──────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ...filtered.map((n) => _NotifCard(data: n)),
                  const SizedBox(height: 12),

                  // ── Weekly Summary card ──────────────────
                  _WeeklySummaryCard(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Filter chip widget
// ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.bgDark : AppColors.subText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Individual notification card
// ─────────────────────────────────────────────
class _NotifData {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String body;
  final String time;
  bool isRead;

  _NotifData({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });
}

class _NotifCard extends StatelessWidget {
  final _NotifData data;
  const _NotifCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.body,
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Time + dot
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.time,
                style: TextStyle(color: AppColors.subText, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Weekly Summary card
// ─────────────────────────────────────────────
class _WeeklySummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.summaryCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.greenBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Summary',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Meals completed', value: '24/30'),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Avg. daily calories', value: '2380'),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Goal achievement', value: '85%'),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.subText, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Placeholder pages for other tabs
// ─────────────────────────────────────────────
class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.green, fontSize: 24),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Colour palette  (dark green fitness theme)
// ─────────────────────────────────────────────
abstract class AppColors {
  static const Color bgDark = Color(0xFF0A1A0F);       // deepest bg
  static const Color navBg = Color(0xFF0D1F13);        // bottom nav bg
  static const Color card = Color(0xFF122218);         // notification card
  static const Color darkCard = Color(0xFF0F1C14);     // icon bg for grey cards
  static const Color greenCard = Color(0xFF1A3A22);    // icon bg for green cards
  static const Color summaryCard = Color(0xFF133020);  // weekly summary card
  static const Color border = Color(0xFF1E3A28);       // card border
  static const Color greenBorder = Color(0xFF2A5E38);  // summary card border

  static const Color green = Color(0xFF3DD68C);        // primary accent green
  static const Color white = Colors.white;
  static const Color subText = Color(0xFF8CAD96);      // muted text
  static const Color navUnselected = Color(0xFF5A7A64);
}

