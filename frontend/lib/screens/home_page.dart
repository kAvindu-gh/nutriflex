import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/calorie_provider_service.dart';

// ── Animated + button widget (boxed, 360° spin on tap) ──────────────────────
class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});
  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _rot;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _rot = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _rot,
        builder: (_, child) =>
            Transform.rotate(angle: _rot.value * 2 * math.pi, child: child),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.45),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ── Pulsing/glitch highlight for calorie stat card ──────────────────────────
class _PulsingStatCard extends StatefulWidget {
  final String value;
  final String label;
  final bool pulse;
  const _PulsingStatCard({
    required this.value,
    required this.label,
    this.pulse = false,
  });
  @override
  State<_PulsingStatCard> createState() => _PulsingStatCardState();
}

class _PulsingStatCardState extends State<_PulsingStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _glow = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.pulse) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) {
          final glowOpacity = widget.pulse ? (0.25 + _glow.value * 0.55) : 0.6;
          final borderOpacity = widget.pulse ? (0.4 + _glow.value * 0.6) : 0.6;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                207,
                25,
                66,
                45,
              ).withOpacity(glowOpacity),
              border: Border.all(
                color: Colors.green.withOpacity(borderOpacity),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: widget.pulse
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(_glow.value * 0.25),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 52, 246, 129),
              ),
            ),
            Text(widget.label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Main page ────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final List<TrendingRecipe> _cartItems = [];

  // ── Trending state
  List<TrendingRecipe> _trendingRecipes = [];
  bool _loadingTrending = true;
  String? _trendingError;

  // ── Search state
  SearchedRecipe? _searchResult;
  bool _loadingSearch = false;
  String? _searchError;
  bool _hasSearched = false;

  // ── Suggestion state (filters trending recipes while typing)
  String _typingQuery = '';

  // ── Fade animation for trending list (refresh)
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fetchTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────

  /// Returns the best-matching local asset path for a recipe name.
  String _recipeImage(String name, {bool isSearchResult = false}) {
    if (isSearchResult) return 'lib/assets/grilled_chicken.jpg';

    final n = name.toLowerCase();

    if (n.contains('beef') ||
        n.contains('stew') ||
        n.contains('burger') ||
        n.contains('meatball') ||
        n.contains('meatloaf') ||
        n.contains('steak'))
      return 'lib/assets/beef_stew.jpg';

    if (n.contains('chicken') || n.contains('turkey') || n.contains('poultry'))
      return 'lib/assets/grilled_chicken.jpg';

    if (n.contains('fish') ||
        n.contains('salmon') ||
        n.contains('tuna') ||
        n.contains('shrimp') ||
        n.contains('prawn') ||
        n.contains('seafood') ||
        n.contains('crab') ||
        n.contains('lobster') ||
        n.contains('tilapia'))
      return 'lib/assets/fish_pate.jpg';

    if (n.contains('pasta') ||
        n.contains('spaghetti') ||
        n.contains('lasagna') ||
        n.contains('fettuccine') ||
        n.contains('penne') ||
        n.contains('macaroni') ||
        n.contains('ramen'))
      return 'lib/assets/pasta.jpg';

    if (n.contains('salad') ||
        n.contains('coleslaw') ||
        n.contains('slaw') ||
        n.contains('noodle'))
      return 'lib/assets/noodles.jpg';

    if (n.contains('soup') ||
        n.contains('broth') ||
        n.contains('chowder') ||
        n.contains('bisque') ||
        n.contains('chili'))
      return 'lib/assets/lentil_soup.jpg';

    if (n.contains('rice') ||
        n.contains('pilaf') ||
        n.contains('risotto') ||
        n.contains('fried rice') ||
        n.contains('biryani') ||
        n.contains('grain'))
      return 'lib/assets/fried_rice.jpg';

    if (n.contains('egg') ||
        n.contains('pancake') ||
        n.contains('waffle') ||
        n.contains('omelette') ||
        n.contains('omelet') ||
        n.contains('breakfast') ||
        n.contains('oatmeal') ||
        n.contains('toast') ||
        n.contains('bacon'))
      return 'lib/assets/cuttlefish.jpg';

    if (n.contains('cake') ||
        n.contains('cookie') ||
        n.contains('brownie') ||
        n.contains('pie') ||
        n.contains('pudding') ||
        n.contains('dessert') ||
        n.contains('ice cream') ||
        n.contains('chocolate') ||
        n.contains('muffin'))
      return 'lib/assets/seafood_cake.jpg';

    if (n.contains('pizza') ||
        n.contains('vegan') ||
        n.contains('tofu') ||
        n.contains('lentil') ||
        n.contains('bean') ||
        n.contains('vegetable') ||
        n.contains('mushroom') ||
        n.contains('spinach') ||
        n.contains('broccoli'))
      return 'lib/assets/cheese_pizza.jpg';

    if (n.contains('mutton')) return 'lib/assets/mutton_curry.jpg';
    if (n.contains('pork')) return 'lib/assets/pork_marinade.jpg';
    if (n.contains('kottu')) return 'lib/assets/kottu.jpg';

    return 'lib/assets/pork_marinade.jpg';
  }

  String _recipeTag(TrendingRecipe recipe) {
    if (recipe.proteinG >= 20 || recipe.calories >= 450) return 'Muscle Gain';
    return 'Weight Loss';
  }

  Color _tagColor(String tag) =>
      tag == 'Muscle Gain' ? Colors.green : Colors.red;

  Map<String, String> _parseIngredient(String raw) {
    final nameMatch = RegExp(r"'name':\s*'([^']+)'").firstMatch(raw);
    final qtyMatch = RegExp(r"'quantity':\s*([\d.]+)").firstMatch(raw);
    final unitMatch = RegExp(r"'unit':\s*'([^']+)'").firstMatch(raw);
    if (nameMatch != null) {
      return {
        'name': nameMatch.group(1) ?? raw,
        'qty': qtyMatch?.group(1) ?? '—',
        'unit': unitMatch?.group(1) ?? '—',
      };
    }
    return {'name': raw, 'qty': '—', 'unit': '—'};
  }

  // ── Cart ─────────────────────────────────────────────────────────

  void _addToCart(TrendingRecipe recipe) {
    if (_cartItems.any((r) => r.id == recipe.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.name} is already in cart'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() => _cartItems.add(recipe));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${recipe.name} added to cart ✓'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A1F12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Cart',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (_cartItems.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() => _cartItems.clear());
                          setModal(() {});
                        },
                        child: const Text(
                          'Clear all',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_cartItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Your cart is empty',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _cartItems.length,
                      itemBuilder: (_, i) {
                        final item = _cartItems[i];
                        final tag = _recipeTag(item);
                        final tc = tag == 'Muscle Gain'
                            ? Colors.green
                            : Colors.red;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              _recipeImage(item.name),
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                color: Colors.green.withOpacity(0.15),
                                child: const Icon(
                                  Icons.restaurant_menu,
                                  color: Colors.green,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${item.calories.toStringAsFixed(0)} Cal  •  ${item.proteinG.toStringAsFixed(1)}g Protein',
                            style: const TextStyle(
                              color: Color(0xFFB0C4B8),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: tc.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: tc.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(color: tc, fontSize: 10),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() => _cartItems.removeAt(i));
                                  setModal(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── API calls ─────────────────────────────────────────────────────

  Future<void> _fetchTrending() async {
    setState(() {
      _loadingTrending = true;
      _trendingError = null;
    });
    _fadeCtrl.reset();
    try {
      final recipes = await ApiService.getTrendingRecipes();
      setState(() {
        _trendingRecipes = recipes;
        _loadingTrending = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      setState(() {
        _trendingError = e.toString();
        _loadingTrending = false;
      });
    }
  }

  Future<void> _searchRecipe(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loadingSearch = true;
      _searchError = null;
      _searchResult = null;
      _hasSearched = true;
    });
    try {
      final result = await ApiService.searchRecipe(query.trim());
      setState(() {
        _searchResult = result;
        _loadingSearch = false;
      });
    } catch (e) {
      setState(() {
        _searchError = 'Recipe not found. Try another name.';
        _loadingSearch = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _hasSearched = false;
      _searchResult = null;
      _searchError = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.6, 1.0],
            colors: [Color(0xFF0D2818), Color(0xFF103E23), Color(0xFF000302)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // ── FIXED top section (not scrollable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                      const SizedBox(height: 20),
                      _buildStats(),
                      const SizedBox(height: 24),
                      if (!_hasSearched) _buildTrendingHeader(),
                      if (_hasSearched) _buildSearchResultHeader(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                // ── SCROLLABLE content below
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _hasSearched
                        ? _buildSearchResultBody()
                        : _buildTrendingBody(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NutriFlex',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Discover premium meals',
              style: TextStyle(color: Color(0xFFB0C4B8)),
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                  width: 1.2,
                ),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.shopping_cart,
                  color: Colors.green,
                  size: 22,
                ),
                onPressed: _openCart,
                padding: EdgeInsets.zero,
              ),
            ),
            if (_cartItems.isNotEmpty)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${_cartItems.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Search Bar ───────────────────────────────────────────────────

  Widget _buildSearchBar() {
    // Filter trending recipes by the current typed query
    final suggestions = _typingQuery.trim().isEmpty
        ? <TrendingRecipe>[]
        : _trendingRecipes
              .where(
                (r) => r.name.toLowerCase().contains(
                  _typingQuery.trim().toLowerCase(),
                ),
              )
              .toList();

    final showDropdown = _typingQuery.trim().isNotEmpty && !_hasSearched;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF000302).withOpacity(0.6),
            border: Border.all(
              color: const Color.fromARGB(255, 155, 156, 155).withOpacity(0.8),
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(showDropdown ? 0 : 16),
              bottomRight: Radius.circular(showDropdown ? 0 : 16),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) => setState(() => _typingQuery = val),
                  onSubmitted: (val) {
                    setState(() => _typingQuery = '');
                    _searchRecipe(val);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search recipes...',
                    hintStyle: TextStyle(color: Color(0xFF7A9E8A)),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_hasSearched)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () {
                    setState(() => _typingQuery = '');
                    _clearSearch();
                  },
                ),
            ],
          ),
        ),

        // Suggestion dropdown
        if (showDropdown)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D2818),
              border: Border(
                left: BorderSide(
                  color: const Color.fromARGB(
                    255,
                    155,
                    156,
                    155,
                  ).withOpacity(0.8),
                ),
                right: BorderSide(
                  color: const Color.fromARGB(
                    255,
                    155,
                    156,
                    155,
                  ).withOpacity(0.8),
                ),
                bottom: BorderSide(
                  color: const Color.fromARGB(
                    255,
                    155,
                    156,
                    155,
                  ).withOpacity(0.8),
                ),
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: suggestions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_off,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'No matching recipes found',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.06),
                    ),
                    itemBuilder: (_, i) {
                      final r = suggestions[i];
                      return InkWell(
                        onTap: () {
                          // Tap on suggestion → open detail sheet, clear dropdown
                          setState(() => _typingQuery = '');
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                          _showRecipeDetailSheet(r);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  _recipeImage(r.name),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.green.withOpacity(0.15),
                                    child: const Icon(
                                      Icons.restaurant_menu,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${r.calories.toStringAsFixed(0)} cal  •  ${r.proteinG.toStringAsFixed(1)}g protein',
                                      style: const TextStyle(
                                        color: Color(0xFF7A9E8A),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.green,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  // ── Stats ────────────────────────────────────────────────────────

  Widget _buildStats() {
    final calorieDisplay = context.watch<CalorieProvider>().displayValue;
    return Row(
      children: [
        _PulsingStatCard(
          value: calorieDisplay,
          label: 'Daily Calories',
          pulse: true,
        ),
        const SizedBox(width: 16),
        _PulsingStatCard(
          value: _trendingRecipes.length.toString(),
          label: 'Recipes Found',
        ),
      ],
    );
  }

  // ── Trending header ───────────────────────────────────────────────

  Widget _buildTrendingHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Trending Recipes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        InkWell(
          onTap: _fetchTrending,
          child: const Text(
            'Refresh',
            style: TextStyle(color: Color.fromARGB(255, 53, 203, 85)),
          ),
        ),
      ],
    );
  }

  // ── Trending body ─────────────────────────────────────────────────

  Widget _buildTrendingBody() {
    if (_loadingTrending) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }
    if (_trendingError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              const Icon(Icons.wifi_off, color: Colors.grey, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Could not connect to server',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchTrending,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_trendingRecipes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text(
            'No trending recipes yet.\nSearch for a recipe to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      );
    }
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: _trendingRecipes.map((r) => _trendingRecipeCard(r)).toList(),
      ),
    );
  }

  // ── Trending card ─────────────────────────────────────────────────

  Widget _trendingRecipeCard(TrendingRecipe recipe) {
    final tag = _recipeTag(recipe);
    final tagColor = _tagColor(tag);

    return GestureDetector(
      onTap: () => _showRecipeDetailSheet(recipe),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF000302).withOpacity(0.55),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image banner
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.asset(
                _recipeImage(recipe.name),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.green.withOpacity(0.1),
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: Colors.green,
                    size: 52,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _AddButton(onTap: () => _addToCart(recipe)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${recipe.calories.toStringAsFixed(0)} Cal  •  ${recipe.proteinG.toStringAsFixed(1)}g Protein',
                    style: const TextStyle(
                      color: Color(0xFFB0C4B8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tagColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: tagColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: tagColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${recipe.searchCount}',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        ' searches',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
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

  // ── Detail sheet ──────────────────────────────────────────────────

  void _showRecipeDetailSheet(TrendingRecipe recipe) {
    final tag = _recipeTag(recipe);
    final tagColor = _tagColor(tag);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1F12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => _TrendingDetailSheet(
          recipe: recipe,
          tag: tag,
          tagColor: tagColor,
          imagePath: _recipeImage(recipe.name),
          scrollController: scrollCtrl,
          onAddToCart: () {
            Navigator.pop(ctx);
            _addToCart(recipe);
          },
          buildIngredientsTable: _buildIngredientsTable,
          buildInstructionsBox: _buildInstructionsBox,
          buildSectionTitle: _buildSectionTitle,
          nutritionChip: _nutritionChip,
        ),
      ),
    );
  }

  // ── Search result header ──────────────────────────────────────────

  Widget _buildSearchResultHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Search Result',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        InkWell(
          onTap: _clearSearch,
          child: const Text('← Back', style: TextStyle(color: Colors.green)),
        ),
      ],
    );
  }

  // ── Search result body ────────────────────────────────────────────

  Widget _buildSearchResultBody() {
    if (_loadingSearch) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Column(
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Fetching recipe & nutrition data...',
                style: TextStyle(color: Color(0xFFB0C4B8)),
              ),
            ],
          ),
        ),
      );
    }
    if (_searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              const Icon(Icons.search_off, color: Colors.grey, size: 40),
              const SizedBox(height: 12),
              Text(
                _searchError!,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_searchResult == null) return const SizedBox();

    final recipe = _searchResult!;

    final keyNutrients =
        recipe.nutrition['key_nutrients'] as Map<String, dynamic>?;
    double protein = 0, calories = 0;
    if (keyNutrients != null) {
      for (final e in keyNutrients.entries) {
        if (e.key.toLowerCase().contains('protein'))
          protein = (e.value['value'] ?? 0).toDouble();
        if (e.key.toLowerCase().contains('energy') ||
            e.key.toLowerCase().contains('calorie'))
          calories = (e.value['value'] ?? 0).toDouble();
      }
    }
    final tag = (protein >= 20 || calories >= 450)
        ? 'Muscle Gain'
        : 'Weight Loss';
    final tagColor = tag == 'Muscle Gain' ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card with image banner
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF000302).withOpacity(0.55),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.asset(
                  _recipeImage(recipe.name, isSearchResult: true),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: Colors.green.withOpacity(0.1),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.green,
                      size: 52,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recipe.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _nutritionChip('🔥 ${recipe.caloriesDisplay}'),
                        const SizedBox(width: 8),
                        _nutritionChip('💪 ${recipe.proteinDisplay} protein'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: tagColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: tagColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (recipe.savedToFirebase) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.cloud_done, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Saved to database',
                            style: TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionTitle('Ingredients'),
        const SizedBox(height: 10),
        _buildIngredientsTable(recipe.ingredients),
        const SizedBox(height: 20),

        _buildSectionTitle('Instructions'),
        const SizedBox(height: 8),
        _buildInstructionsBox(recipe.instructions),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────

  Widget _buildIngredientsTable(List<String> ingredients) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF000302).withOpacity(0.55),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.18),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'Name',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Qty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Unit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...ingredients.asMap().entries.map((entry) {
            final idx = entry.key;
            final parsed = _parseIngredient(entry.value);
            final isLast = idx == ingredients.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: idx % 2 == 0
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.03),
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(16))
                    : null,
                border: !isLast
                    ? Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      parsed['name']!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      parsed['qty']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB0C4B8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      parsed['unit']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFB0C4B8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInstructionsBox(List<String> instructions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF000302).withOpacity(0.55),
        border: Border.all(color: Colors.green.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: instructions.isEmpty
          ? Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'No instructions found for this recipe.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            )
          : Column(
              children: instructions.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 10, top: 1),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Color(0xFFB0C4B8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _nutritionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}

// ── Trending recipe detail sheet ──────────────────────────────────────────────
class _TrendingDetailSheet extends StatefulWidget {
  final TrendingRecipe recipe;
  final String tag;
  final Color tagColor;
  final String imagePath;
  final ScrollController scrollController;
  final VoidCallback onAddToCart;
  final Widget Function(List<String>) buildIngredientsTable;
  final Widget Function(List<String>) buildInstructionsBox;
  final Widget Function(String) buildSectionTitle;
  final Widget Function(String) nutritionChip;

  const _TrendingDetailSheet({
    required this.recipe,
    required this.tag,
    required this.tagColor,
    required this.imagePath,
    required this.scrollController,
    required this.onAddToCart,
    required this.buildIngredientsTable,
    required this.buildInstructionsBox,
    required this.buildSectionTitle,
    required this.nutritionChip,
  });

  @override
  State<_TrendingDetailSheet> createState() => _TrendingDetailSheetState();
}

class _TrendingDetailSheetState extends State<_TrendingDetailSheet> {
  SearchedRecipe? _full;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ApiService.searchRecipe(widget.recipe.name);
      if (mounted)
        setState(() {
          _full = result;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _error = 'Could not load full recipe.';
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final tag = widget.tag;
    final tagColor = widget.tagColor;

    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Summary card with image
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF000302).withOpacity(0.55),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image banner
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.asset(
                      widget.imagePath,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: Colors.green.withOpacity(0.1),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.green,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.restaurant_menu,
                              color: Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recipe.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            widget.nutritionChip(
                              '🔥 ${recipe.calories.toStringAsFixed(0)} kcal',
                            ),
                            widget.nutritionChip(
                              '💪 ${recipe.proteinG.toStringAsFixed(1)}g protein',
                            ),
                            widget.nutritionChip(
                              '🥑 ${recipe.fatG.toStringAsFixed(1)}g fat',
                            ),
                            widget.nutritionChip(
                              '🌾 ${recipe.carbsG.toStringAsFixed(1)}g carbs',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: tagColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: tagColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: tagColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Add to cart
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onAddToCart,
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Add to Cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 20),
                child: Text(
                  'Searched ${recipe.searchCount} times',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),

            // Ingredients + Instructions (fetched from API)
            if (_loading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 12),
                      Text(
                        'Loading ingredients & instructions...',
                        style: TextStyle(
                          color: Color(0xFFB0C4B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_error != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ] else if (_full != null) ...[
              widget.buildSectionTitle('Ingredients'),
              const SizedBox(height: 10),
              widget.buildIngredientsTable(_full!.ingredients),
              const SizedBox(height: 20),
              widget.buildSectionTitle('Instructions'),
              const SizedBox(height: 8),
              widget.buildInstructionsBox(_full!.instructions),
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
