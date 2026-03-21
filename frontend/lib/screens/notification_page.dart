import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'userProfile.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Colour palette
// ─────────────────────────────────────────────────────────────────────────────
abstract class AppColors {
  static const Color bgDark        = Color(0xFF0A1A0F);
  static const Color navBg         = Color(0xFF0D1F13);
  static const Color card          = Color(0xFF122218);
  static const Color darkCard      = Color(0xFF0F1C14);
  static const Color greenCard     = Color(0xFF1A3A22);
  static const Color summaryCard   = Color(0xFF133020);
  static const Color border        = Color(0xFF1E3A28);
  static const Color greenBorder   = Color(0xFF2A5E38);
  static const Color green         = Color(0xFF3DD68C);
  static const Color white         = Color(0xFFFFFFFF);
  static const Color subText       = Color(0xFF8CAD96);
  static const Color navUnselected = Color(0xFF5A7A64);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Notification data model
// ─────────────────────────────────────────────────────────────────────────────
class _NotifData {
  final String   id;       // stable key used to persist read-state
  final IconData icon;
  Color          iconBg;
  final String   tag;
  final String   title;
  final String   body;
  final String   time;
  bool           isRead;

  _NotifData({
    required this.id,
    required this.icon,
    required this.iconBg,
    required this.tag,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
  });

  // Build from a seed NotificationItem, applying persisted read state
  factory _NotifData.fromItem(NotificationItem item, Set<String> readIds) {
    final id = '${item.type}_${item.title.hashCode}';
    final alreadyRead = readIds.contains(id);
    return _NotifData(
      id:     id,
      icon:   _iconFor(item.type),
      iconBg: alreadyRead ? AppColors.darkCard : AppColors.greenCard,
      tag:    _tagFor(item.type),
      title:  item.title,
      body:   item.body,
      time:   item.time,
      isRead: alreadyRead,
    );
  }

  // Build from a live FCM RemoteMessage
  factory _NotifData.fromFcm(RemoteMessage msg, Set<String> readIds) {
    final type  = msg.data['type'] ?? 'general';
    final title = msg.notification?.title ?? msg.data['title'] ?? 'Notification';
    final body  = msg.notification?.body  ?? msg.data['body']  ?? '';
    final id    = '${type}_${title.hashCode}';
    return _NotifData(
      id:     id,
      icon:   _iconFor(type),
      iconBg: AppColors.greenCard,
      tag:    _tagFor(type),
      title:  title,
      body:   body,
      time:   'Just now',
      isRead: readIds.contains(id),
    );
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'add_to_cart':     return Icons.shopping_cart_outlined;
      case 'save_recipe':     return Icons.favorite_outline;
      case 'trending_recipe': return Icons.local_fire_department_outlined;
      case 'order_confirmed': return Icons.check_circle_outline;
      case 'fitness_details': return Icons.fitness_center_outlined;
      case 'weekly_progress': return Icons.bar_chart_rounded;
      default:                return Icons.notifications_outlined;
    }
  }

  static String _tagFor(String type) {
    switch (type) {
      case 'add_to_cart':     return 'Cart';
      case 'save_recipe':     return 'Recipe';
      case 'trending_recipe': return 'Trending';
      case 'order_confirmed': return 'Order';
      case 'fitness_details': return 'Fitness';
      case 'weekly_progress': return 'Progress';
      default:                return 'Alert';
    }
  }

  Map<String, dynamic> toJson() => {
    'id':    id,
    'type':  tag.toLowerCase(),
    'title': title,
    'body':  body,
    'time':  time,
  };

  factory _NotifData.fromJson(Map<String, dynamic> j, Set<String> readIds) {
    final type = j['type'] as String? ?? 'general';
    final title = j['title'] as String? ?? '';
    final id = j['id'] as String? ?? '${type}_${title.hashCode}';
    final alreadyRead = readIds.contains(id);
    return _NotifData(
      id:     id,
      icon:   _iconFor(type),
      iconBg: alreadyRead ? AppColors.darkCard : AppColors.greenCard,
      tag:    _tagFor(type),
      title:  title,
      body:   j['body'] as String? ?? '',
      time:   j['time'] as String? ?? '',
      isRead: alreadyRead,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SharedPreferences keys
// ─────────────────────────────────────────────────────────────────────────────
const _kNotifList = 'nutriflex_notifications';
const _kReadIds   = 'nutriflex_read_ids';

// ─────────────────────────────────────────────────────────────────────────────
//  NotificationsPage
// ─────────────────────────────────────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  // ── Replace with real logged-in user ID from your auth layer ──────────────
  static const String _userId = 'user_demo_001';

  final _svc = NutriFlexNotificationService();

  int  _filterIndex = 0;
  bool _loading     = true;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  final List<_NotifData> _notifications = [];
  Set<String> _readIds = {};

  // ── Default seed notifications shown on first install ─────────────────────
  List<NotificationItem> get _defaultSeeds => [
    NotificationItem(
      type:   'trending_recipe',
      title:  '🔥 Trending Recipe Alert!',
      body:   '"Super Green Smoothie" is trending right now — #1 this week. '
              'Packed with spinach, banana, and protein, it\'s a must-try!',
      time:   '5m ago',
      isRead: false,
    ),
    NotificationItem(
      type:   'order_confirmed',
      title:  '✅ Order Confirmed!',
      body:   'Your order of 5 items from NutriStore has been confirmed and '
              'is being prepared. Estimated pickup: 20 min.',
      time:   '1h ago',
      isRead: false,
    ),
    NotificationItem(
      type:   'fitness_details',
      title:  '💪 Morning Run Complete!',
      body:   'Great job finishing your Morning Run! You burned 420 kcal and '
              'logged 6,240 steps. Keep it up — you\'re 78 % to your daily goal!',
      time:   '8m ago',
      isRead: false,
    ),
    NotificationItem(
      type:   'add_to_cart',
      title:  '🛒 Added to Cart!',
      body:   'Protein Powder has been added to your cart for '
              '"Post-Workout Shake". You now have 3 items ready to order.',
      time:   '2m ago',
      isRead: false,
    ),
    NotificationItem(
      type:   'save_recipe',
      title:  '❤️ Recipe Saved!',
      body:   '"Avocado Chicken Bowl" has been saved to your favourites. '
              'Find it anytime under Meal Prep › Saved Recipes.',
      time:   '3h ago',
      isRead: false,
    ),
    NotificationItem(
      type:   'weekly_progress',
      title:  '📊 Weekly Progress Report!',
      body:   'Week 12 recap: avg 2,380 kcal/day · 5 workouts completed · '
              '85 % goal achievement. You\'re on track — great week! 🎯',
      time:   'Yesterday',
      isRead: false,
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _initPage();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Boot sequence ──────────────────────────────────────────────────────────
  Future<void> _initPage() async {
    await _loadFromPrefs();                  // restore list + read-ids
    _registerFcmToken();                     // silent — no error if offline
    _triggerBackendNotifications();          // silent — no error if offline
    FirebaseMessaging.onMessage.listen(_onForegroundMessage); // live FCM

    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl.forward(from: 0);
    }
  }

  // ── SharedPreferences ──────────────────────────────────────────────────────

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Restore read-ids first
    _readIds = (prefs.getStringList(_kReadIds) ?? []).toSet();

    // Try to restore persisted notification list
    final raw = prefs.getString(_kNotifList);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _notifications.clear();
        for (final item in list) {
          _notifications.add(
              _NotifData.fromJson(item as Map<String, dynamic>, _readIds));
        }
        return; // Use persisted list — skip seeding
      } catch (_) {
        // Corrupted data — fall through to seed
      }
    }

    // First run: populate with default seeds
    _notifications.clear();
    for (final seed in _defaultSeeds) {
      _notifications.add(_NotifData.fromItem(seed, _readIds));
    }
    await _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kNotifList,
      jsonEncode(_notifications.map((n) => n.toJson()).toList()),
    );
    await prefs.setStringList(_kReadIds, _readIds.toList());
  }

  // ── FCM token registration — totally silent ────────────────────────────────
  Future<void> _registerFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _svc.registerToken(userId: _userId, fcmToken: token);
      }
    } catch (_) {
      // Network unavailable — retried automatically next launch
    }
  }

  // ── Backend notification triggers — totally silent ─────────────────────────
  // These tell the server to queue FCM pushes. If the server is unreachable
  // (e.g. dev machine off) we just skip — no error is ever shown to the user.
  Future<void> _triggerBackendNotifications() async {
    try {
      await Future.wait([
        _svc.notifyTrendingRecipe(
          userId: _userId, recipeName: 'Super Green Smoothie',
          recipeId: 'recipe_001', trendingRank: 1,
        ),
        _svc.notifyOrderConfirmed(
          userId: _userId, orderId: 'order_042',
          storeName: 'NutriStore', itemCount: 5,
        ),
        _svc.notifyFitnessDetails(
          userId: _userId, workoutName: 'Morning Run',
          caloriesBurned: 420, steps: 6240,
        ),
        _svc.notifyAddToCart(
          userId: _userId, ingredientName: 'Protein Powder',
          recipeName: 'Post-Workout Shake',
        ),
        _svc.notifySaveRecipe(
          userId: _userId, recipeName: 'Avocado Chicken Bowl',
          recipeId: 'recipe_007',
        ),
        _svc.notifyWeeklyProgress(
          userId: _userId, weekNumber: 12,
          caloriesAvg: 2380, workoutsCompleted: 5, goalAchieved: false,
        ),
      ]);
    } catch (_) {
      // Silently ignore — server offline or unreachable
    }
  }

  // ── Real-time foreground FCM listener ─────────────────────────────────────
  // When the app is open and Firebase delivers a push, this appends it to
  // the top of the list and persists it immediately.
  void _onForegroundMessage(RemoteMessage msg) {
    if (!mounted) return;
    final incoming = _NotifData.fromFcm(msg, _readIds);
    // Avoid duplicates
    if (_notifications.any((n) => n.id == incoming.id)) return;
    setState(() => _notifications.insert(0, incoming));
    _saveToPrefs();
  }

  // ── Read-state helpers ─────────────────────────────────────────────────────

  void _markRead(_NotifData n) {
    if (n.isRead) return;
    setState(() {
      n.isRead = true;
      n.iconBg = AppColors.darkCard;
      _readIds.add(n.id);
    });
    _saveToPrefs();
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
        n.iconBg = AppColors.darkCard;
        _readIds.add(n.id);
      }
    });
    _saveToPrefs();
  }

 void _openProfile(BuildContext context) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, a, __) => const ProfileScreen(),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: a, curve: Curves.easeInOutCubic)),
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ),
  );
}

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<_NotifData> get _filtered => _filterIndex == 1
      ? _notifications.where((n) => !n.isRead).toList()
      : List.from(_notifications);

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 18),
            _buildFilterRow(),
            const SizedBox(height: 14),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_unreadCount > 0) ...[
                      const SizedBox(width: 10),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_unreadCount new',
                          style: const TextStyle(
                            color: AppColors.bgDark,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Stay updated with your fitness journey',
                  style: TextStyle(color: AppColors.subText, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _openProfile(context),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.greenCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.greenBorder, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: const Center(
                  child: Icon(Icons.person_outline_rounded,
                      color: AppColors.green, size: 26),
                  // Swap the Icon for a real photo:
                  // Image.network(profileImageUrl, fit: BoxFit.cover)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter row ─────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildChip('All', 0),
          const SizedBox(width: 10),
          _buildChip('Unread', 1),
          const Spacer(),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _unreadCount > 0 ? 1.0 : 0.35,
            child: GestureDetector(
              onTap: _unreadCount > 0 ? _markAllRead : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int index) {
    final selected  = _filterIndex == index;
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
              color: selected ? AppColors.green : AppColors.border, width: 1),
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

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
              color: AppColors.green, strokeWidth: 2));
    }

    final list = _filtered;
    if (list.isEmpty) return _buildEmptyState();

    return FadeTransition(
      opacity: _fadeAnim,
      child: RefreshIndicator(
        color: AppColors.green,
        backgroundColor: AppColors.card,
        onRefresh: () async => _triggerBackendNotifications(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          itemCount: list.length + 1,
          itemBuilder: (context, i) {
            if (i < list.length) {
              return _NotifCard(
                data:  list[i],
                onTap: () => _markRead(list[i]),
              );
            }
            return const Column(children: [
              SizedBox(height: 4),
              _WeeklySummaryCard(),
              SizedBox(height: 16),
            ]);
          },
        ),
      ),
    );
  }

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

// ─────────────────────────────────────────────────────────────────────────────
//  Notification card
// ─────────────────────────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final _NotifData    data;
  final VoidCallback? onTap;
  const _NotifCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: !data.isRead
                ? AppColors.green.withAlpha(90)
                : AppColors.border,
            width: 1.2,
          ),
          boxShadow: !data.isRead
              ? [
                  BoxShadow(
                    color: AppColors.green.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: data.iconBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.greenBorder.withOpacity(0.5),
                        width: 1),
                  ),
                  child: Icon(data.icon, color: AppColors.green, size: 24),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.greenCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data.tag,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          style: TextStyle(
                            color: data.isRead
                                ? AppColors.white.withOpacity(0.85)
                                : AppColors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!data.isRead)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(width: 9, height: 9),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.body,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.navUnselected, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        data.time,
                        style: const TextStyle(
                            color: AppColors.navUnselected, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Weekly summary card
// ─────────────────────────────────────────────────────────────────────────────
class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.summaryCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.greenBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded,
                  color: AppColors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Weekly Summary',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenCard,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Week 12',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SummaryRow(
            icon: Icons.restaurant_outlined,
            label: 'Meals completed',
            value: '24 / 30',
          ),
          const _Divider(),
          const _SummaryRow(
            icon: Icons.local_fire_department_outlined,
            label: 'Avg. daily calories',
            value: '2,380 kcal',
          ),
          const _Divider(),
          const _SummaryRow(
            icon: Icons.fitness_center_outlined,
            label: 'Workouts done',
            value: '5 sessions',
          ),
          const _Divider(),
          const _SummaryRow(
            icon: Icons.flag_outlined,
            label: 'Goal achievement',
            value: '85 %',
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Divider(color: AppColors.border, height: 1, thickness: 1),
      );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _SummaryRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.navUnselected, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(color: AppColors.subText, fontSize: 13)),
        ),
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