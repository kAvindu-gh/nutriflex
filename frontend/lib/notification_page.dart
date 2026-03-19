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
 
  late final List<Widget> _pages = [
    const _PlaceholderPage(label: 'Home'),
    const _PlaceholderPage(label: 'Meal Prep'),
    const _PlaceholderPage(label: 'BMI'),
    const NotificationsPage(),
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
//  Bottom navigation bar
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
 
  const _BottomNav({required this.currentIndex, required this.onTap});
 
  static const _items = [
    _NavItem(icon: Icons.home_outlined,           activeIcon: Icons.home,              label: 'Home'),
    _NavItem(icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu,   label: 'Meal Prep'),
    _NavItem(icon: Icons.calculate_outlined,       activeIcon: Icons.calculate,         label: 'BMI'),
    _NavItem(icon: Icons.notifications_outlined,   activeIcon: Icons.notifications,     label: 'Alerts'),
  ];
 
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.4),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final selected = i == currentIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? _items[i].activeIcon : _items[i].icon,
                        color: selected ? AppColors.green : AppColors.navUnselected,
                        size: 26,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].label,
                        style: TextStyle(
                          color: selected ? AppColors.green : AppColors.navUnselected,
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
}
 
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
 
// ─────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────
class _NotifData {
  final IconData icon;
  final Color    iconBg;
  final String   title;
  final String   body;
  final String   time;
  bool           isRead; // mutable so Mark All Read can update it
 
  _NotifData({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });
}
 
// ─────────────────────────────────────────────
//  Notifications Page
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
      icon:   Icons.timer_outlined,
      iconBg: AppColors.greenCard,
      title:  'New Recipe Available !',
      body:   'Try our new "super Green Smoothie" perfect for muscle recovery',
      time:   '5m ago',
      isRead: false,
    ),
    _NotifData(
      icon:   Icons.check_box_outlined,
      iconBg: AppColors.greenCard,
      title:  'Order Delivered',
      body:   'Your meal prep ingredients have been delivered',
      time:   '1h ago',
      isRead: false,
    ),
    _NotifData(
      icon:   Icons.military_tech_outlined,
      iconBg: AppColors.darkCard,
      title:  'Achievement Unlocked !',
      body:   '7-day streak ! Keep up the great work',
      time:   '4m ago',
      isRead: true,
    ),
    _NotifData(
      icon:   Icons.trending_up,
      iconBg: AppColors.darkCard,
      title:  'Weekly Progress',
      body:   'You hit 95% of your calorie goals this week',
      time:   '15m ago',
      isRead: true,
    ),
    _NotifData(
      icon:   Icons.local_dining_outlined,
      iconBg: AppColors.darkCard,
      title:  'Meal Reminder',
      body:   'Time for your post-workout protein shake !',
      time:   '8m ago',
      isRead: true,
    ),
  ];
 
  // Returns how many notifications are still unread
  int get _unreadCount => _notifications.where((n) => !n.isRead).length;
 
  // Marks every notification as read and rebuilds the UI
  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
  }
 
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
            // ── Header ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
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
 
            // ── Filter row ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildChip('All', 0),
                  const SizedBox(width: 10),
                  _buildChip('Unread', 1),
                  const Spacer(),
 
                  // ── Mark All Read button ─────────────
                  // Fades out when there is nothing left to mark
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: _unreadCount > 0 ? 1.0 : 0.35,
                    child: GestureDetector(
                      onTap: _unreadCount > 0 ? _markAllRead : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.border, width: 1),
                        ),
                        child: const Text(
                          'Mark All read',
                          style: TextStyle(
                            color: AppColors.subText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
 
            const SizedBox(height: 14),
 
            // ── List ─────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        ...filtered.map((n) => _NotifCard(data: n)),
                        const SizedBox(height: 12),
                        const _WeeklySummaryCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
 
  // Filter chip with optional unread badge
  Widget _buildChip(String label, int index) {
    final selected = _filterIndex == index;
    final showBadge = index == 1 && _unreadCount > 0;
 
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.darkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.green : AppColors.border,
              width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.bgDark : AppColors.subText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showBadge) ...[
              const SizedBox(width: 6),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected ? AppColors.bgDark : AppColors.green,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_unreadCount',
                  style: TextStyle(
                    color: selected ? AppColors.green : AppColors.bgDark,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
 
  // Empty state when Unread tab has nothing
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.notifications_none_outlined,
              color: AppColors.subText, size: 56),
          SizedBox(height: 12),
          Text('All caught up!',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('No unread notifications',
              style: TextStyle(color: AppColors.subText, fontSize: 13)),
        ],
      ),
    );
  }
}
 
// ─────────────────────────────────────────────
//  Notification card
//  KEY FIX: dot visibility is driven by isRead
// ─────────────────────────────────────────────
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
        border: Border.all(
          // Unread cards get a subtle green border glow
          color: !data.isRead
              ? AppColors.green.withAlpha(70)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
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
 
          // Title + body
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
                  style: const TextStyle(
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
                style: const TextStyle(
                    color: AppColors.subText, fontSize: 11),
              ),
              const SizedBox(height: 6),
              // ✅ THE FIX: dot only shows when isRead == false
              if (!data.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(width: 8, height: 8), // keeps alignment
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
  const _WeeklySummaryCard();
 
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
        children: const [
          Text(
            'Weekly Summary',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          _SummaryRow(label: 'Meals completed',     value: '24/30'),
          SizedBox(height: 10),
          _SummaryRow(label: 'Avg. daily calories', value: '2380'),
          SizedBox(height: 10),
          _SummaryRow(label: 'Goal achievement',    value: '85%'),
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
        Text(label,
            style: const TextStyle(color: AppColors.subText, fontSize: 13)),
        Text(value,
            style: const TextStyle(
              color: AppColors.green,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            )),
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
        child: Text(label,
            style: const TextStyle(
                color: AppColors.green, fontSize: 24)),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────
//  Colour palette
// ─────────────────────────────────────────────
abstract class AppColors {
  static const Color bgDark       = Color(0xFF0A1A0F);
  static const Color navBg        = Color(0xFF0D1F13);
  static const Color card         = Color(0xFF122218);
  static const Color darkCard     = Color(0xFF0F1C14);
  static const Color greenCard    = Color(0xFF1A3A22);
  static const Color summaryCard  = Color(0xFF133020);
  static const Color border       = Color(0xFF1E3A28);
  static const Color greenBorder  = Color(0xFF2A5E38);
  static const Color green        = Color(0xFF3DD68C);
  static const Color white        = Color(0xFFFFFFFF);
  static const Color subText      = Color(0xFF8CAD96);
  static const Color navUnselected= Color(0xFF5A7A64);
}


