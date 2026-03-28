import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

// ── Main widget — drop this between _buildInfoCard() and _buildLogoutButton() ─
class UserSummarySection extends StatefulWidget {
  const UserSummarySection({super.key});
  @override
  State<UserSummarySection> createState() => _UserSummarySectionState();
}

class _UserSummarySectionState extends State<UserSummarySection>
    with TickerProviderStateMixin {
  static const kGreen  = Color(0xFF22C55E);
  static const kBg     = Color(0xFF000000);
  static const kCard   = Color(0xFF0D2818);

  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;

  late AnimationController _fadeCtrl;
  late AnimationController _barCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<double>   _barAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _barCtrl  = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _barAnim  = CurvedAnimation(parent: _barCtrl,  curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _barCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final data = await ApiService.getUserSummary(uid);
      if (mounted) {
        setState(() {
          _summary = data;
          _loading = false;
        });
        _fadeCtrl.forward(from: 0);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _barCtrl.forward(from: 0);
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 14),
          child: Row(
            children: [
              Text('MY HEALTH SUMMARY',
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6)),
              const Spacer(),
              GestureDetector(
                onTap: _load,
                child: Icon(Icons.refresh_rounded,
                    color: Colors.grey.shade700, size: 18),
              ),
            ],
          ),
        ),

        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(
                  color: kGreen, strokeWidth: 2),
            ),
          )
        else if (_error != null)
          _buildError()
        else if (_summary != null)
          FadeTransition(
            opacity: _fadeAnim,
            child: _buildSummaryContent(_summary!),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Could not load summary.',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
            ),
            GestureDetector(
              onTap: _load,
              child: const Text('Retry',
                  style: TextStyle(
                      color: kGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryContent(Map<String, dynamic> s) {
    final history = (s['nutrients_history'] as List<dynamic>?) ?? [];
    final orders  = (s['recent_orders']     as List<dynamic>?) ?? [];
    final meals   = (s['recent_meals']      as List<dynamic>?) ?? [];

    return Column(
      children: [
        // ── Row 1: BMI + Goal cards ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _BmiCard(summary: s)),
              const SizedBox(width: 12),
              Expanded(child: _GoalCard(summary: s)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Nutrition bar chart (last 7 days) ─────────────────────────────
        if (history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _NutritionChart(
              history:  history,
              barAnim:  _barAnim,
              tdee:     (s['tdee'] as num?)?.toDouble() ?? 2000,
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ── Macro averages ring ────────────────────────────────────────────
        if (s['avg_calories'] != null && (s['avg_calories'] as num) > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MacroCard(summary: s),
          ),
          const SizedBox(height: 14),
        ],

        // ── Recent orders ─────────────────────────────────────────────────
        if (orders.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _RecentOrdersCard(orders: orders),
          ),
          const SizedBox(height: 14),
        ],

        // ── Meal history count ─────────────────────────────────────────────
        if (meals.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MealStatsCard(summary: s),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

// ── BMI card ──────────────────────────────────────────────────────────────────
class _BmiCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _BmiCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final bmi    = (summary['bmi'] as num?)?.toDouble() ?? 0;
    final status = summary['bmi_status'] as String? ?? '—';
    final Color statusColor = status == 'Normal'
        ? const Color(0xFF22C55E)
        : status == 'Overweight' || status == 'Underweight'
            ? Colors.orange
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined,
                  color: Color(0xFF22C55E), size: 16),
              const SizedBox(width: 6),
              const Text('BMI',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bmi > 0 ? bmi.toStringAsFixed(1) : '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary['weight'] ?? '—'} kg  •  '
            '${summary['height'] ?? '—'} cm',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Goal card ─────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _GoalCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final goal     = summary['goal']           as String? ?? '—';
    final tdee     = (summary['tdee'] as num?)?.toDouble() ?? 0;
    final activity = summary['activity_level'] as String? ?? '—';
    final age      = summary['age'];
    final gender   = summary['gender']         as String? ?? '—';

    final goalIcon = goal.toLowerCase().contains('loss')
        ? Icons.trending_down_rounded
        : goal.toLowerCase().contains('gain')
            ? Icons.trending_up_rounded
            : Icons.balance_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined,
                  color: const Color(0xFF22C55E), size: 16),
              const SizedBox(width: 6),
              const Text('Goal',
                  style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(goalIcon, color: const Color(0xFF22C55E), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal[0].toUpperCase() + goal.substring(1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (tdee > 0)
            _miniRow('TDEE', '${tdee.toStringAsFixed(0)} kcal'),
          _miniRow('Activity', activity),
          _miniRow('Age / Sex', '$age · $gender'),
        ],
      ),
    );
  }

  Widget _miniRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style:
                  const TextStyle(color: Colors.white38, fontSize: 10)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Nutrition bar chart ───────────────────────────────────────────────────────
class _NutritionChart extends StatelessWidget {
  final List<dynamic>      history;
  final Animation<double>  barAnim;
  final double             tdee;

  const _NutritionChart({
    required this.history,
    required this.barAnim,
    required this.tdee,
  });

  @override
  Widget build(BuildContext context) {
    final maxCal = history
        .map((d) => (d['calories'] as num?)?.toDouble() ?? 0)
        .fold(0.0, (a, b) => b > a ? b : a);
    final cap = math.max(maxCal, tdee > 0 ? tdee : 2000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF22C55E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_outlined,
                  color: Color(0xFF22C55E), size: 16),
              const SizedBox(width: 6),
              const Text('Calories — Last 7 Days',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  )),
              const Spacer(),
              if (tdee > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Target ${tdee.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: history.map((day) {
                final cal  = (day['calories'] as num?)?.toDouble() ?? 0;
                final date = (day['date'] as String? ?? '').split('-');
                final label = date.length >= 3 ? '${date[2]}/${date[1]}' : '';
                final ratio = cap > 0 ? (cal / cap).clamp(0.0, 1.0) : 0.0;
                final overTarget = tdee > 0 && cal > tdee;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          cal > 0 ? '${(cal / 1000).toStringAsFixed(1)}k' : '',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 8),
                        ),
                        const SizedBox(height: 4),
                        AnimatedBuilder(
                          animation: barAnim,
                          builder: (_, __) => Container(
                            height: 80 * ratio * barAnim.value,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: overTarget
                                    ? [
                                        Colors.orange.withOpacity(0.9),
                                        Colors.orange.withOpacity(0.5),
                                      ]
                                    : [
                                        const Color(0xFF22C55E).withOpacity(0.9),
                                        const Color(0xFF22C55E).withOpacity(0.4),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(label,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 9)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Macro averages card ───────────────────────────────────────────────────────
class _MacroCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _MacroCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cal    = (summary['avg_calories'] as num?)?.toDouble() ?? 0;
    final prot   = (summary['avg_protein']  as num?)?.toDouble() ?? 0;
    final carbs  = (summary['avg_carbs']    as num?)?.toDouble() ?? 0;
    final fat    = (summary['avg_fat']      as num?)?.toDouble() ?? 0;
    final total  = prot + carbs + fat;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF22C55E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded,
                  color: Color(0xFF22C55E), size: 16),
              SizedBox(width: 6),
              Text('Average Macros / Day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Macro pie (simple stacked bar)
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      '${cal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('kcal / day',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 12),
                    if (total > 0)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              _macroSegment(prot / total, Colors.blue),
                              _macroSegment(carbs / total,
                                  const Color(0xFF22C55E)),
                              _macroSegment(fat / total, Colors.orange),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _macroLegend('Protein',   '${prot.toStringAsFixed(1)}g',  Colors.blue),
                    const SizedBox(height: 8),
                    _macroLegend('Carbs',     '${carbs.toStringAsFixed(1)}g', const Color(0xFF22C55E)),
                    const SizedBox(height: 8),
                    _macroLegend('Fat',       '${fat.toStringAsFixed(1)}g',   Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroSegment(double ratio, Color color) {
    return Expanded(
      flex: (ratio * 100).round().clamp(1, 100),
      child: Container(color: color),
    );
  }

  Widget _macroLegend(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 12)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Recent orders card ────────────────────────────────────────────────────────
class _RecentOrdersCard extends StatelessWidget {
  final List<dynamic> orders;
  const _RecentOrdersCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF22C55E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: Color(0xFF22C55E), size: 16),
              SizedBox(width: 6),
              Text('Recent Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ...orders.take(3).map((order) {
            final store    = order['store_name']  as String? ?? 'Store';
            final total    = (order['total'] as num?)?.toDouble() ?? 0;
            final items    = order['item_count']  as int? ?? 0;
            final status   = order['status']      as String? ?? 'confirmed';
            final created  = order['created_at']  as String? ?? '';

            final date = created.isNotEmpty
                ? DateTime.tryParse(created)?.toLocal()
                : null;
            final dateStr = date != null
                ? '${date.day}/${date.month}/${date.year}'
                : '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.store_outlined,
                        color: Color(0xFF22C55E), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        Text('$items item${items != 1 ? 's' : ''}'
                            '${dateStr.isNotEmpty ? '  •  $dateStr' : ''}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(status,
                            style: const TextStyle(
                                color: Color(0xFF22C55E),
                                fontSize: 9,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Meal stats card ───────────────────────────────────────────────────────────
class _MealStatsCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _MealStatsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final totalMeals  = summary['total_meals_logged'] as int? ?? 0;
    final totalOrders = summary['total_orders']       as int? ?? 0;
    final meals       = (summary['recent_meals'] as List<dynamic>?) ?? [];

    // Count unique meal items from Meal_history
    final Set<String> uniqueItems = {};
    for (final meal in meals) {
      if (meal is Map<String, dynamic>) {
        meal.forEach((key, val) {
          if (key != 'timestamp' && val != null && val.toString().isNotEmpty) {
            uniqueItems.add(val.toString());
          }
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFF22C55E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.restaurant_menu_outlined,
                  color: Color(0xFF22C55E), size: 16),
              SizedBox(width: 6),
              Text('Activity Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('Meal Preps', '$totalMeals', Icons.rice_bowl_outlined),
              const SizedBox(width: 10),
              _statBox('Orders', '$totalOrders', Icons.shopping_bag_outlined),
              const SizedBox(width: 10),
              _statBox('Unique Foods', '${uniqueItems.length}',
                  Icons.set_meal_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF22C55E), size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}