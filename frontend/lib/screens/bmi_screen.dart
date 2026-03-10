import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/calorie_provider_service.dart';

// ─────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────
const kGreen = Color(0xFF14D97D);
const kCard  = Color(0xFF0D1610);
const kField = Color(0xFF111A13);

// ─────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────
class BMIResult {
  final double bmi, bmr, tdee, dailyCalories;
  final double proteinG, carbsG, fatG;
  final String category, goal, activityLevel, message;
  final List<String> conditions;

  BMIResult({
    required this.bmi,      required this.category,      required this.bmr,
    required this.tdee,     required this.dailyCalories,
    required this.proteinG, required this.carbsG,         required this.fatG,
    required this.goal,     required this.activityLevel,
    required this.message,  required this.conditions,
  });

  factory BMIResult.fromJson(Map<String, dynamic> j) => BMIResult(
    bmi:           (j['bmi']            as num).toDouble(),
    category:       j['category']        as String,
    bmr:           (j['bmr']            as num).toDouble(),
    tdee:          (j['tdee']           as num).toDouble(),
    dailyCalories: (j['daily_calories'] as num).toDouble(),
    proteinG:      (j['protein_g']      as num).toDouble(),
    carbsG:        (j['carbs_g']        as num).toDouble(),
    fatG:          (j['fat_g']          as num).toDouble(),
    goal:           j['goal']            as String,
    activityLevel:  j['activity_level']  as String,
    message:        j['message']         as String,
    conditions:    List<String>.from(j['conditions'] ?? []),
  );

  Color get categoryColor {
    switch (category) {
      case 'Underweight': return const Color(0xFF4FC3F7);
      case 'Normal':      return kGreen;
      case 'Overweight':  return const Color(0xFFFFA726);
      default:            return const Color(0xFFEF5350);
    }
  }

  double get bmiPosition => (bmi.clamp(10.0, 40.0) - 10) / 30;
}

// ─────────────────────────────────────────
// BMI SCREEN
// ─────────────────────────────────────────
class BMIScreen extends StatefulWidget {
  const BMIScreen({super.key});
  @override
  State<BMIScreen> createState() => _BMIScreenState();
}

class _BMIScreenState extends State<BMIScreen> {
  final _hCtrl = TextEditingController(text: '170');
  final _wCtrl = TextEditingController(text: '60');
  final _aCtrl = TextEditingController(text: '20');

  String _gender   = 'Male';
  String _goal     = 'Keep';
  String _activity = 'Moderate (3-5 days / week)';
  final List<String> _conditions = [];

  BMIResult? _result;
  bool _loading = false;
  String? _error;
  Key _scaleKey = UniqueKey();

  final ScrollController _scroll    = ScrollController();
  final GlobalKey        _resultsKey = GlobalKey();

  @override
  void dispose() {
    _hCtrl.dispose(); _wCtrl.dispose(); _aCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _goalEnum(String g) {
    switch (g) {
      case 'Loss': return 'weight_loss';
      case 'Gain': return 'muscle_gain';
      default:     return 'maintenance';
    }
  }

  String _activityEnum(String a) {
    if (a.contains('Sedentary')) return 'sedentary';
    if (a.contains('Light'))     return 'light';
    if (a.contains('Moderate'))  return 'moderate';
    if (a.contains('Very'))      return 'very_active';
    return 'active';
  }

  Future<void> _calculate() async {
    FocusScope.of(context).unfocus();

    final hText = _hCtrl.text.trim();
    final wText = _wCtrl.text.trim();
    final aText = _aCtrl.text.trim();
    final h = double.tryParse(hText);
    final w = double.tryParse(wText);
    final a = int.tryParse(aText);

    if (hText.isEmpty || h == null || h <= 0) {
      setState(() => _error = 'Please enter a valid height.'); return;
    }
    if (wText.isEmpty || w == null || w <= 0) {
      setState(() => _error = 'Please enter a valid weight.'); return;
    }
    if (h > 250) {
      setState(() => _error = 'Height must be 250 cm or under.'); return;
    }
    if (w > 300) {
      setState(() => _error = 'Weight must be 300 kg or under.'); return;
    }
    if (aText.isEmpty || a == null || a <= 0 || a > 120) {
      setState(() => _error = 'Please enter a valid age (1–120).'); return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      // Use ApiService — no IP address needed here
      final json = await ApiService.calculateBmi({
        'weight_kg':          w,
        'height_cm':          h,
        'age':                a,
        'gender':             _gender.toLowerCase(),
        'activity_level':     _activityEnum(_activity),
        'goal':               _goalEnum(_goal),
        'medical_conditions': _conditions.where((c) => c != 'None').toList(),
      });

      final result = BMIResult.fromJson(json);

      setState(() {
        _result   = result;
        _scaleKey = UniqueKey();
        _loading  = false;
      });

      // ── Push daily calories to CalorieProvider so home page shows it ──
      if (mounted) {
        context.read<CalorieProvider>().setDailyCalories(result.dailyCalories);
      }

      Future.delayed(const Duration(milliseconds: 120), () {
        if (_resultsKey.currentContext != null) {
          Scrollable.ensureVisible(
            _resultsKey.currentContext!,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          );
        }
      });

    } catch (e) {
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.6, 1.0],
            colors: [Color(0xFF0D2818), Color(0xFF103E23), Color(0xFF000302)],
          ),
        ),
      ),
      // ── Fixed header — does not scroll ────────────────────────────────────
      Positioned(
        top: 0, left: 0, right: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Advanced BMI Calculator',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Personalized nutrition planning',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ]),
        ),
      ),

      // ── Scrollable body — starts below header ──────────────────────────────
      Padding(
        padding: const EdgeInsets.only(top: 76),
        child: SingleChildScrollView(
          controller: _scroll,
          // 120 bottom padding so last card clears the floating navbar
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            _formCard(),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D1515),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_error!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                ]),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 32),
              _ResultsSection(key: _resultsKey, result: _result!, scaleKey: _scaleKey),
            ],
          ]),
        ),
      ),
    ]);
  }

  // ─────────────────────────────────────────
  // FORM CARD
  // ─────────────────────────────────────────
  Widget _formCard() => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1610).withOpacity(0.70),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kGreen.withOpacity(0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: _inputField('Height (cm)', _hCtrl, Icons.straighten)),
            const SizedBox(width: 14),
            Expanded(child: _inputField('Weight (kg)', _wCtrl, Icons.monitor_weight_outlined)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _inputField('Age', _aCtrl, Icons.cake_outlined)),
            const SizedBox(width: 14),
            Expanded(child: _roundedDropdown(
              value: _gender,
              icon: Icons.person_outline,
              items: ['Male', 'Female'],
              onChanged: (v) => setState(() => _gender = v!),
            )),
          ]),
          const SizedBox(height: 24),

          _sectionLabel(Icons.track_changes, 'Fitness Goal'),
          const SizedBox(height: 12),
          Row(children: [
            _goalBtn('Loss', '🔥', _goal == 'Loss', () => setState(() => _goal = 'Loss')),
            const SizedBox(width: 10),
            _goalBtn('Keep', '⚖️', _goal == 'Keep', () => setState(() => _goal = 'Keep')),
            const SizedBox(width: 10),
            _goalBtn('Gain', '💪', _goal == 'Gain', () => setState(() => _goal = 'Gain')),
          ]),
          const SizedBox(height: 24),

          _sectionLabel(Icons.monitor_heart_outlined, 'Activity Level'),
          const SizedBox(height: 12),
          _roundedDropdown(
            value: _activity,
            items: [
              'Sedentary (little/no exercise)',
              'Light (1-3 days / week)',
              'Moderate (3-5 days / week)',
              'Active (6-7 days / week)',
              'Very Active (physical job)',
            ],
            onChanged: (v) => setState(() => _activity = v!),
          ),
          const SizedBox(height: 24),

          _sectionLabel(Icons.favorite_border, 'Health Conditions (Optional)'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: ['Diabetes', 'Blood Pressure', 'Cholesterol', 'None']
                .map((c) => _conditionChip(c, _conditions.contains(c), () => setState(() {
                      if (c == 'None') {
                        _conditions..clear()..add('None');
                      } else {
                        _conditions.remove('None');
                        _conditions.contains(c)
                            ? _conditions.remove(c)
                            : _conditions.add(c);
                      }
                    })))
                .toList(),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity, height: 58,
            child: ElevatedButton(
              onPressed: _loading ? null : _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                disabledBackgroundColor: kGreen.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : const Text('Calculate My Stats',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
            ),
          ),
        ]),
      ),
    ),
  );

  Widget _roundedDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    decoration: BoxDecoration(
      color: kField,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: kGreen.withOpacity(0.25)),
    ),
    child: Row(children: [
      if (icon != null) ...[Icon(icon, color: kGreen, size: 18), const SizedBox(width: 6)],
      Expanded(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value, isExpanded: true,
            dropdownColor: const Color(0xFF1A2E1E),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kGreen, size: 20),
            items: items.map((e) => DropdownMenuItem(
              value: e, child: Text(e, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]),
  );

  Widget _sectionLabel(IconData icon, String label) => Row(children: [
    Icon(icon, color: kGreen, size: 20),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
  ]);

  Widget _inputField(String label, TextEditingController ctrl, IconData icon) => TextField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    style: const TextStyle(color: Colors.white, fontSize: 16),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: kGreen, size: 20),
      filled: true, fillColor: kField,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: kGreen.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kGreen, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    ),
  );

  Widget _goalBtn(String label, String emoji, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A3825) : kField,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? kGreen : Colors.transparent, width: 1.5),
          boxShadow: active ? [BoxShadow(color: kGreen.withOpacity(0.18), blurRadius: 12)] : [],
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal),
            child: Text(label),
          ),
        ]),
      ),
    ),
  );

  Widget _conditionChip(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1A3825) : kField,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: active ? kGreen : Colors.transparent, width: 1.5),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: TextStyle(color: active ? kGreen : Colors.white, fontSize: 14),
        child: Text(label),
      ),
    ),
  );
}

// ─────────────────────────────────────────
// RESULTS SECTION
// ─────────────────────────────────────────
class _ResultsSection extends StatelessWidget {
  final BMIResult result;
  final Key scaleKey;
  const _ResultsSection({super.key, required this.result, required this.scaleKey});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _card(child: Column(children: [
        const Text('Your BMI', style: TextStyle(color: Colors.grey, fontSize: 15)),
        const SizedBox(height: 8),
        Text(result.bmi.toStringAsFixed(1),
            style: TextStyle(color: result.categoryColor, fontSize: 56, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
          decoration: BoxDecoration(color: result.categoryColor, borderRadius: BorderRadius.circular(30)),
          child: Text(result.category,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ])),
      const SizedBox(height: 16),

      _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('BMI Scale',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 18),
        _AnimatedBmiScaleBar(key: scaleKey, position: result.bmiPosition),
        const SizedBox(height: 12),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _ScaleLabel('<18.5',   'Under',  Color(0xFF4FC3F7)),
          _ScaleLabel('18.5-25', 'Normal', kGreen),
          _ScaleLabel('25-30',   'Over',   Color(0xFFFFA726)),
          _ScaleLabel('>30',     'Obese',  Color(0xFFEF5350)),
        ]),
      ])),
      const SizedBox(height: 16),

      _GlowingIntakeCard(result: result),
      const SizedBox(height: 16),

      _card(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💡', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Personalized Plan',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Text(result.message, textAlign: TextAlign.justify,
              style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.6)),
        ])),
      ])),
    ]);
  }

  static Widget _card({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1610).withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.30), width: 1),
        ),
        child: child,
      ),
    ),
  );
}

// ─────────────────────────────────────────
// GLOWING INTAKE CARD
// ─────────────────────────────────────────
class _GlowingIntakeCard extends StatefulWidget {
  final BMIResult result;
  const _GlowingIntakeCard({required this.result});
  @override
  State<_GlowingIntakeCard> createState() => _GlowingIntakeCardState();
}

class _GlowingIntakeCardState extends State<_GlowingIntakeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: kGreen.withOpacity(0.25 * _glow.value), blurRadius: 10, spreadRadius: 0),
            BoxShadow(color: kGreen.withOpacity(0.35 * _glow.value), blurRadius: 22, spreadRadius: 2),
            BoxShadow(color: kGreen.withOpacity(0.12 * (1 - _glow.value)), blurRadius: 4, spreadRadius: 1),
          ],
        ),
        child: child,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1610).withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kGreen.withOpacity(0.5)),
            ),
            child: Column(children: [
              const Row(children: [
                Text('🎯', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Recommended Daily Intake',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ]),
              const SizedBox(height: 14),
              Text('${widget.result.dailyCalories.toInt()}',
                  style: const TextStyle(color: kGreen, fontSize: 50, fontWeight: FontWeight.bold)),
              const Text('calories per day',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              if (widget.result.conditions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: widget.result.conditions.map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Text('⚕ $c',
                        style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _MacroStat('${widget.result.proteinG.toInt()}g', 'Protein'),
                Container(height: 36, width: 1, color: Colors.white12),
                _MacroStat('${widget.result.carbsG.toInt()}g', 'Carbs'),
                Container(height: 36, width: 1, color: Colors.white12),
                _MacroStat('${widget.result.fatG.toInt()}g', 'Fats'),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// ANIMATED BMI SCALE BAR
// ─────────────────────────────────────────
class _AnimatedBmiScaleBar extends StatefulWidget {
  final double position;
  const _AnimatedBmiScaleBar({super.key, required this.position});
  @override
  State<_AnimatedBmiScaleBar> createState() => _AnimatedBmiScaleBarState();
}

class _AnimatedBmiScaleBarState extends State<_AnimatedBmiScaleBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = Tween<double>(begin: 0.0, end: widget.position)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      return AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Stack(clipBehavior: Clip.none, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 18,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color(0xFF4FC3F7), Color(0xFF14D97D),
                  Color(0xFFFFA726), Color(0xFFEF5350),
                ]),
              ),
            ),
          ),
          Positioned(
            left: (w * _anim.value.clamp(0.0, 1.0)) - 11,
            top: -5,
            child: Container(
              width: 22, height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6, offset: const Offset(0, 2))],
              ),
            ),
          ),
        ]),
      );
    });
  }
}

// ─────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────
class _ScaleLabel extends StatelessWidget {
  final String range, label;
  final Color color;
  const _ScaleLabel(this.range, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(range, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
  ]);
}

class _MacroStat extends StatelessWidget {
  final String value, label;
  const _MacroStat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
  ]);
}