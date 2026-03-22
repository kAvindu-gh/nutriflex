import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class MealPrepPage extends StatefulWidget {
  const MealPrepPage({super.key});
  @override
  State<MealPrepPage> createState() => _MealPrepPageState();
}

class _MealPrepPageState extends State<MealPrepPage>
    with TickerProviderStateMixin {

  final GlobalKey<_MealCardState> _riceKey   = GlobalKey();
  final GlobalKey<_MealCardState> _mallumKey = GlobalKey();
  final GlobalKey<_MealCardState> _veg1Key   = GlobalKey();
  final GlobalKey<_MealCardState> _veg2Key   = GlobalKey();
  final GlobalKey<_MealCardState> _meatKey   = GlobalKey();
  final GlobalKey<_MealCardState> _saladKey  = GlobalKey();

  // ── Nutrition state ───────────────────────────────────────────────────────
  double consumedCalories = 0;
  double maxCalories      = 2400;
  double consumedProtein  = 0;
  double maxProtein       = 150;
  double consumedCarbs    = 0;
  double maxCarbs         = 620;
  double consumedFat      = 0;
  double maxFat           = 220;
  bool _saving            = false;
  bool _hasSaved          = false;

  // ── Animated progress values ──────────────────────────────────────────────
  late AnimationController _progressCtrl;
  late Animation<double> _calAnim;
  late Animation<double> _protAnim;
  late Animation<double> _carbAnim;
  late Animation<double> _fatAnim;

  double _prevCalPct  = 0;
  double _prevProtPct = 0;
  double _prevCarbPct = 0;
  double _prevFatPct  = 0;

  // ── Page entrance animation ───────────────────────────────────────────────
  late AnimationController _pageCtrl;
  late Animation<double> _pageFade;

  static const kGreen      = Color(0xFF14D97D);
  static const kGreenDim   = Color(0xFF0D2818);
  static const kBg         = Color(0xFF000302);

  @override
  void initState() {
    super.initState();

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _calAnim  = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _protAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _carbAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _fatAnim  = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));

    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageCtrl.forward();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _animateBars({
    required double calPct,
    required double protPct,
    required double carbPct,
    required double fatPct,
  }) {
    _progressCtrl.reset();
    _calAnim  = Tween<double>(begin: _prevCalPct,  end: calPct)
        .animate(CurvedAnimation(parent: _progressCtrl,
            curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic)));
    _protAnim = Tween<double>(begin: _prevProtPct, end: protPct)
        .animate(CurvedAnimation(parent: _progressCtrl,
            curve: const Interval(0.05, 1.0, curve: Curves.easeOutCubic)));
    _carbAnim = Tween<double>(begin: _prevCarbPct, end: carbPct)
        .animate(CurvedAnimation(parent: _progressCtrl,
            curve: const Interval(0.10, 1.0, curve: Curves.easeOutCubic)));
    _fatAnim  = Tween<double>(begin: _prevFatPct,  end: fatPct)
        .animate(CurvedAnimation(parent: _progressCtrl,
            curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic)));

    _prevCalPct  = calPct;
    _prevProtPct = protPct;
    _prevCarbPct = carbPct;
    _prevFatPct  = fatPct;

    _progressCtrl.forward();
  }

  double _parseValue(dynamic raw) {
    if (raw == null) return 0;
    final match = RegExp(r'[\d.]+').firstMatch(raw.toString());
    if (match == null) return 0;
    return double.tryParse(match.group(0)!) ?? 0;
  }

  // ── Save meal ─────────────────────────────────────────────────────────────
  Future<void> _onSave() async {
    final names = [
      _riceKey.currentState?.selectedName,
      _mallumKey.currentState?.selectedName,
      _veg1Key.currentState?.selectedName,
      _veg2Key.currentState?.selectedName,
      _meatKey.currentState?.selectedName,
      _saladKey.currentState?.selectedName,
    ];

    if (names.any((s) => s == null)) {
      _showToast('Please select all 6 food items', isError: true);
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      final result = await ApiService.saveMealPrep(
        rice:           _riceKey.currentState!.selectedName!,
        riceSize:       _riceKey.currentState!.weight,
        meat:           _meatKey.currentState!.selectedName!,
        meatSize:       _meatKey.currentState!.weight,
        vegetable1:     _veg1Key.currentState!.selectedName!,
        vegetable1Size: _veg1Key.currentState!.weight,
        vegetable2:     _veg2Key.currentState!.selectedName!,
        vegetable2Size: _veg2Key.currentState!.weight,
        mallum:         _mallumKey.currentState!.selectedName!,
        mallumSize:     _mallumKey.currentState!.weight,
        salad:          _saladKey.currentState!.selectedName!,
        saladSize:      _saladKey.currentState!.weight,
      );

      // ── Parse consumed values ─────────────────────────────────────────
      final newCalConsumed  = _parseValue(result["Calory consumed: "]);
      final newCalReq       = _parseValue(result["Calory requirement: "]);
      final newProtConsumed = _parseValue(result["Protein consumed: "]);
      final newProtReq      = _parseValue(result["Protein requirement: "]);
      final newCarbConsumed = _parseValue(result["Carbohydrate consumed: "]);
      final newCarbReq      = _parseValue(result["Carbohydrate requirement: "]);
      final newFatConsumed  = _parseValue(result["Fat consumed: "]);
      final newFatReq       = _parseValue(result["Fat requirement: "]);

      setState(() {
        // consumed = what user ate, max = daily requirement
        consumedCalories = newCalConsumed;
        maxCalories      = newCalReq > 0 ? newCalReq : 2400;
        consumedProtein  = newProtConsumed;
        maxProtein       = newProtReq > 0 ? newProtReq : 150;
        consumedCarbs    = newCarbConsumed;
        maxCarbs         = newCarbReq > 0 ? newCarbReq : 620;
        consumedFat      = newFatConsumed;
        maxFat           = newFatReq > 0 ? newFatReq : 220;
        _hasSaved        = true;
      });

      // ── Animate bars to new percentages ──────────────────────────────
      _animateBars(
        calPct:  (newCalConsumed  / (newCalReq  > 0 ? newCalReq  : 2400)).clamp(0, 1),
        protPct: (newProtConsumed / (newProtReq > 0 ? newProtReq : 150)).clamp(0, 1),
        carbPct: (newCarbConsumed / (newCarbReq > 0 ? newCarbReq : 620)).clamp(0, 1),
        fatPct:  (newFatConsumed  / (newFatReq  > 0 ? newFatReq  : 220)).clamp(0, 1),
      );

      HapticFeedback.lightImpact();
      _showToast('Meal saved successfully!', isError: false);

    } catch (e) {
      _showToast('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showToast(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
              style: const TextStyle(color: Colors.white, fontSize: 13))),
        ]),
        backgroundColor:
            isError ? const Color(0xFF3A0A0A) : const Color(0xFF0D2818),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: isError
                    ? Colors.redAccent.withOpacity(0.6)
                    : kGreen.withOpacity(0.6))),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _pageFade,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.55, 1.0],
            colors: [Color(0xFF0D2818), Color(0xFF103E23), Color(0xFF000302)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kGreen.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: kGreen.withOpacity(0.3), width: 1),
                            ),
                            child: const Icon(Icons.restaurant_menu,
                                color: kGreen, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Meal Prep Builder',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3)),
                              Text('Build your Sri Lankan meal plate',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Scrollable content ────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 120),
                    child: Column(children: [
                      // ROW 1
                      _row([
                        _MealCard(key: _riceKey, title: "Steamed Rice",
                            imagePath: "lib/assets/rice.jpg",
                            items: const ["Rice, Basmati, Boiled","Fried Rice",
                              "Milk Rice, Red","Milk Rice, White",
                              "Rice, Keeri Samba, Boiled","Rice, Red Kekulu, Boiled",
                              "Rice, Samba, Boiled","Rice, White Kekulu, Boiled",
                              "Rice, White Nadu, Boiled","Yellow Rice"]),
                        _MealCard(key: _mallumKey, title: "Mallum (Greens)",
                            imagePath: "lib/assets/mallum.jpg",
                            items: const ["Mallum"]),
                      ]),
                      const SizedBox(height: 10),

                      // ROW 2
                      _row([
                        _MealCard(key: _veg1Key, title: "Vegetable Curry 1",
                            imagePath: "lib/assets/veg1.jpg",
                            items: const ["Ash Plantain, White Curry","Baby Jackfruit Curry",
                              "Beans Curry","Beetroot Curry","Bittergourd Curry",
                              "Breadfruit Curry","Brinjal Curry","Cabbage White Curry",
                              "Carrot Curry","Cashew Curry","Dhal Curry, Spinach",
                              "Dhal Curry, Thick","Dhal Curry, Watery",
                              "Drumstick (Muranga) Curry","Kohila Curry","Leeks Curry",
                              "Mushroom Curry","Okra White Curry","Potato Curry, White",
                              "Pumpkin Curry","Radish Curry","Snakegourd Curry",
                              "Soya Curry","Sweet Potato Curry"]),
                        _MealCard(key: _veg2Key, title: "Vegetable Curry 2",
                            imagePath: "lib/assets/veg2.jpg",
                            items: const ["Ash Plantain, White Curry","Baby Jackfruit Curry",
                              "Beans Curry","Beetroot Curry","Bittergourd Curry",
                              "Breadfruit Curry","Brinjal Curry","Cabbage White Curry",
                              "Carrot Curry","Cashew Curry","Dhal Curry, Spinach",
                              "Dhal Curry, Thick","Dhal Curry, Watery",
                              "Drumstick (Muranga) Curry","Kohila Curry","Leeks Curry",
                              "Mushroom Curry","Okra White Curry","Potato Curry, White",
                              "Pumpkin Curry","Radish Curry","Snakegourd Curry",
                              "Soya Curry","Sweet Potato Curry"]),
                      ]),
                      const SizedBox(height: 10),

                      // ROW 3
                      _row([
                        _MealCard(key: _meatKey, title: "Meat",
                            imagePath: "lib/assets/meat.jpg",
                            items: const ["Beef Curry","Canned Salmon (Mackeral) Curry",
                              "Chicken Curry","Chili Fish Curry","Cuttlefish Curry",
                              "Devilled Chicken","Devilled Fish","Dry Fish Curry",
                              "Fish Ambul Thiyal","Fish, White Curry",
                              "Meat Balls Curry","Prawn Curry","Sprats Curry"]),
                        _MealCard(key: _saladKey, title: "Fresh Salad",
                            imagePath: "lib/assets/salad.jpg",
                            items: const ["Cucumber Salad","Fruit Salad","Parsley",
                              "Snake Gourd And Onion Salad","Tomato Salad",
                              "Vegetable Salad"]),
                      ]),
                      const SizedBox(height: 20),

                      // ── Nutrition summary ─────────────────────────────
                      _buildNutritionCard(),
                      const SizedBox(height: 16),

                      // ── Save button ───────────────────────────────────
                      _buildSaveButton(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) => Row(
        children: children
            .expand((w) => [Expanded(child: w), const SizedBox(width: 10)])
            .toList()
          ..removeLast(),
      );

  // ── Nutrition card ────────────────────────────────────────────────────────
  Widget _buildNutritionCard() {
    return AnimatedBuilder(
      animation: _progressCtrl,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1A0F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kGreen.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                  color: kGreen.withOpacity(0.06),
                  blurRadius: 20,
                  spreadRadius: 2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bar_chart_rounded,
                      color: kGreen, size: 16),
                ),
                const SizedBox(width: 10),
                const Text("Your Custom Plate",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_hasSaved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Updated",
                        style: TextStyle(color: kGreen, fontSize: 10)),
                  ),
              ]),
              const SizedBox(height: 18),
              _nutrientBar("Calories", consumedCalories, maxCalories,
                  _calAnim.value, "kcal", kGreen),
              _nutrientBar("Protein",  consumedProtein,  maxProtein,
                  _protAnim.value, "g", Colors.redAccent),
              _nutrientBar("Carbs",    consumedCarbs,    maxCarbs,
                  _carbAnim.value, "g", Colors.amber),
              _nutrientBar("Fat",      consumedFat,      maxFat,
                  _fatAnim.value, "g", Colors.blueAccent),
            ],
          ),
        );
      },
    );
  }

  Widget _nutrientBar(String label, double consumed, double max,
      double animPct, String unit, Color color) {
    final pct = (consumed / max).clamp(0.0, 1.0);
    final displayPct = (animPct * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
            Row(children: [
              Text(
                "${consumed.toStringAsFixed(consumed == consumed.roundToDouble() ? 0 : 1)}",
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                " / ${max.toStringAsFixed(max == max.roundToDouble() ? 0 : 1)} $unit",
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("$displayPct%",
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 8),
        Stack(children: [
          // Background track
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Animated fill
          FractionallySizedBox(
            widthFactor: animPct,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.6), color],
                ),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 0),
                ],
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Save button ───────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: _saving
              ? [kGreen.withOpacity(0.4), kGreen.withOpacity(0.4)]
              : [const Color(0xFF14D97D), const Color(0xFF0DBF6A)],
        ),
        boxShadow: _saving
            ? []
            : [
                BoxShadow(
                    color: kGreen.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4)),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _saving ? null : _onSave,
          child: Center(
            child: _saving
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_alt_rounded,
                          color: Colors.black, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _hasSaved ? "Update My Recipe" : "Save My Recipe",
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Meal card ─────────────────────────────────────────────────────────────────
class _MealCard extends StatefulWidget {
  final String title;
  final String imagePath;
  final List<String> items;

  const _MealCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.items,
  });

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard>
    with SingleTickerProviderStateMixin {
  String? _selected;
  final TextEditingController _weightCtrl =
      TextEditingController(text: "100");

  late AnimationController _selectCtrl;
  late Animation<double> _selectAnim;

  static const kGreen = Color(0xFF14D97D);

  String? get selectedName => _selected;
  int get weight => int.tryParse(_weightCtrl.text) ?? 100;

  @override
  void initState() {
    super.initState();
    _selectCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _selectAnim = CurvedAnimation(parent: _selectCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _selectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _selected != null;

    return AnimatedBuilder(
      animation: _selectAnim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D2818),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? kGreen.withOpacity(0.3 + _selectAnim.value * 0.2)
                : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: kGreen.withOpacity(0.08 * _selectAnim.value),
                      blurRadius: 12,
                      spreadRadius: 1),
                ]
              : [],
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────────────────────────
          Stack(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                widget.imagePath,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: kGreen.withOpacity(0.08),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant_menu,
                        color: kGreen, size: 30),
                  ),
                ),
              ),
            ),
            // Selected badge
            if (isSelected)
              Positioned(
                top: 8, right: 8,
                child: FadeTransition(
                  opacity: _selectAnim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.black, size: 12),
                  ),
                ),
              ),
          ]),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2)),
                const SizedBox(height: 8),

                // Dropdown
                DropdownButtonFormField<String>(
                  value: _selected,
                  hint: const Text("Select food",
                      style: TextStyle(color: Colors.white38, fontSize: 10)),
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0D2818),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: kGreen, size: 16),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.08))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.08))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: kGreen, width: 1.5)),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.2),
                  ),
                  items: widget.items
                      .map((name) => DropdownMenuItem(
                            value: name,
                            child: Text(name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selected = val);
                    if (val != null) {
                      _selectCtrl.forward(from: 0);
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Weight row
                Row(children: [
                  const Icon(Icons.scale_outlined,
                      color: Colors.white38, size: 12),
                  const SizedBox(width: 4),
                  const Text("Weight:",
                      style:
                          TextStyle(color: Colors.white38, fontSize: 10)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _weightCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        hintText: "100",
                        hintStyle: const TextStyle(
                            color: Colors.white24, fontSize: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.08))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.08))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: kGreen, width: 1.5)),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text("g",
                      style: TextStyle(
                          color: Colors.white38, fontSize: 10)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}