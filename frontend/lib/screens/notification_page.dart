import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import 'userProfile.dart';

// ── Colour palette ────────────────────────────────────────────────────────────
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

// ── Notification data model ───────────────────────────────────────────────────
class _NotifData {
  final String   id;
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

  factory _NotifData.fromFirestore(Map<String, dynamic> data) {
    final type    = data['type'] as String? ?? 'general';
    final id      = data['notification_id'] as String? ?? '';
    final isRead  = data['is_read'] as bool? ?? false;
    final created = data['created_at'] as String? ?? '';

    return _NotifData(
      id:     id,
      icon:   _iconFor(type),
      iconBg: isRead ? AppColors.darkCard : AppColors.greenCard,
      tag:    _tagFor(type),
      title:  data['title'] as String? ?? '',
      body:   data['body']  as String? ?? '',
      time:   _formatTime(created),
      isRead: isRead,
    );
  }

  factory _NotifData.fromFcm(RemoteMessage msg) {
    final type  = msg.data['type'] ?? 'general';
    final title = msg.notification?.title ?? msg.data['title'] ?? 'Notification';
    final body  = msg.notification?.body  ?? msg.data['body']  ?? '';
    return _NotifData(
      id:     '${type}_${DateTime.now().millisecondsSinceEpoch}',
      icon:   _iconFor(type),
      iconBg: AppColors.greenCard,
      tag:    _tagFor(type),
      title:  title,
      body:   body,
      time:   'Just now',
      isRead: false,
    );
  }

  static String _formatTime(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt   = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours   < 24) return '${diff.inHours}h ago';
      if (diff.inDays    < 7)  return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  static IconData _iconFor(String type) {
    switch (type) {
      case 'add_to_cart':       return Icons.shopping_cart_outlined;
      case 'save_recipe':       return Icons.favorite_outline;
      case 'trending_recipe':   return Icons.local_fire_department_outlined;
      case 'order_confirmed':   return Icons.check_circle_outline;
      case 'order_placed':      return Icons.inventory_2_outlined;
      case 'fitness_details':   return Icons.fitness_center_outlined;
      case 'weekly_progress':   return Icons.bar_chart_rounded;
      case 'bmi_calculated':    return Icons.monitor_weight_outlined;
      case 'meal_prep_updated': return Icons.restaurant_menu_outlined;
      case 'recipe_searched':   return Icons.search_rounded;
      default:                  return Icons.notifications_outlined;
    }
  }

  static String _tagFor(String type) {
    switch (type) {
      case 'add_to_cart':       return 'Cart';
      case 'save_recipe':       return 'Recipe';
      case 'trending_recipe':   return 'Trending';
      case 'order_confirmed':
      case 'order_placed':      return 'Order';
      case 'fitness_details':   return 'Fitness';
      case 'weekly_progress':   return 'Progress';
      case 'bmi_calculated':    return 'BMI';
      case 'meal_prep_updated': return 'Meal Prep';
      case 'recipe_searched':   return 'Recipe';
      default:                  return 'Alert';
    }
  }
}

// ── NotificationsPage ─────────────────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  int  _filterIndex = 0;
  bool _loading     = true;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  final List<_NotifData> _notifications = [];

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

  // ── Boot ───────────────────────────────────────────────────────────────────
  Future<void> _initPage() async {
    await _loadFromFirestore();
    _registerFcmToken();
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    if (mounted) {
      setState(() => _loading = false);
      _fadeCtrl.forward(from: 0);
    }
  }

  // ── Load real notifications from Firestore ────────────────────────────────
  Future<void> _loadFromFirestore() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final data = await ApiService.getNotifications(uid);
      final list = data['notifications'] as List<dynamic>? ?? [];
      _notifications.clear();
      for (final item in list) {
        _notifications.add(
          _NotifData.fromFirestore(item as Map<String, dynamic>));
      }
    } catch (e) {
      // Network unavailable — show empty state
      debugPrint('Notification load error: $e');
    }
  }

  // ── FCM token ─────────────────────────────────────────────────────────────
  Future<void> _registerFcmToken() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService.registerToken(userId: uid, fcmToken: token);
      }
    } catch (_) {}
  }

  // ── Foreground FCM ────────────────────────────────────────────────────────
  void _onForegroundMessage(RemoteMessage msg) {
    if (!mounted) return;
    final incoming = _NotifData.fromFcm(msg);
    setState(() => _notifications.insert(0, incoming));
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────────
  Future<void> _refresh() async {
    await _loadFromFirestore();
    if (mounted) setState(() {});
  }

  // ── Mark one read ─────────────────────────────────────────────────────────
  Future<void> _markRead(_NotifData n) async {
    if (n.isRead) return;
    final uid = _userId;
    if (uid == null) return;
    setState(() {
      n.isRead = true;
      n.iconBg = AppColors.darkCard;
    });
    try {
      await ApiService.markNotificationRead(uid, n.id);
    } catch (_) {}
  }

  // ── Mark all read ─────────────────────────────────────────────────────────
  Future<void> _markAllRead() async {
    final uid = _userId;
    if (uid == null) return;
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
        n.iconBg = AppColors.darkCard;
      }
    });
    try {
      await ApiService.markAllNotificationsRead(uid);
    } catch (_) {}
  }

  // ── Clear all notifications ───────────────────────────────────────────────
  Future<void> _clearAll() async {
    final uid = _userId;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2818),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear all notifications?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'All notifications will be permanently deleted.',
          style: TextStyle(color: AppColors.subText, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.subText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _notifications.clear());

    // Delete all from Firestore
    try {
      await ApiService.clearAllNotifications(uid);
    } catch (_) {}
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
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeInOutCubic)),
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

  // ── Build ──────────────────────────────────────────────────────────────────
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

  // ── Header ────────────────────────────────────────────────────────────────
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter row ────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildChip('All', 0),
          const SizedBox(width: 10),
          _buildChip('Unread', 1),
          const Spacer(),
          // Mark all read
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
          // Clear all
          if (_notifications.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _clearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.red.withOpacity(0.3), width: 1),
                ),
                child: const Icon(
                  Icons.delete_sweep_outlined,
                  color: Colors.redAccent,
                  size: 16,
                ),
              ),
            ),
          ],
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
            Text(label,
                style: TextStyle(
                  color: selected ? AppColors.bgDark : AppColors.subText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                )),
            if (showBadge) ...[
              const SizedBox(width: 6),
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: selected ? AppColors.bgDark : AppColors.green,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('$_unreadCount',
                    style: TextStyle(
                      color: selected ? AppColors.green : AppColors.bgDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
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
        onRefresh: _refresh,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          itemCount: list.length,
          itemBuilder: (context, i) => _NotifCard(
            data:  list[i],
            onTap: () => _markRead(list[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none_outlined,
              color: AppColors.subText, size: 56),
          const SizedBox(height: 12),
          const Text('All caught up!',
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'Notifications will appear here when you\nsearch recipes, update meals, or place orders.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.subText, fontSize: 13),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _refresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.greenCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greenBorder),
              ),
              child: const Text('Refresh',
                  style: TextStyle(
                      color: AppColors.green, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification card ─────────────────────────────────────────────────────────
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
                  width: 50, height: 50,
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
                  child: Text(data.tag,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      )),
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
                        child: Text(data.title,
                            style: TextStyle(
                              color: data.isRead
                                  ? AppColors.white.withOpacity(0.85)
                                  : AppColors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            )),
                      ),
                      const SizedBox(width: 8),
                      if (!data.isRead)
                        Container(
                          width: 9, height: 9,
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
                  Text(data.body,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 13,
                        height: 1.5,
                      )),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.navUnselected, size: 12),
                      const SizedBox(width: 4),
                      Text(data.time,
                          style: const TextStyle(
                              color: AppColors.navUnselected, fontSize: 11)),
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