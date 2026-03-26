import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';

// ── Quantity control button ───────────────────────────────────────────────────
class _QtyButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });
  @override
  State<_QtyButton> createState() => _QtyButtonState();
}

class _QtyButtonState extends State<_QtyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.85,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() async {
    await _ctrl.reverse();
    widget.onTap();
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 6,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

// ── Animated cart item card ───────────────────────────────────────────────────
class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final String imagePath;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartItemCard({
    required this.item,
    required this.imagePath,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final price = (item.pricePerItem * item.quantity).toStringAsFixed(2);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D2818).withOpacity(0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.green.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Recipe image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    widget.imagePath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.green,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + price per meal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.recipeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${item.pricePerItem.toStringAsFixed(2)} per meal',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Nutrition chips
                      Row(
                        children: [
                          _NutriBadge(
                            '🔥 ${item.calories.toStringAsFixed(0)}',
                          ),
                          const SizedBox(width: 6),
                          _NutriBadge(
                            '💪 ${item.proteinG.toStringAsFixed(0)}g',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Controls column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Price
                    Text(
                      '\$$price',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Qty controls
                    Row(
                      children: [
                        _QtyButton(
                          icon: Icons.remove,
                          color: const Color(0xFF1A3A25),
                          onTap: widget.onDecrement,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _QtyButton(
                          icon: Icons.add,
                          color: Colors.green,
                          onTap: widget.onIncrement,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Delete
                    GestureDetector(
                      onTap: widget.onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tiny nutrition badge ──────────────────────────────────────────────────────
class _NutriBadge extends StatelessWidget {
  final String label;
  const _NutriBadge(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF69F0AE), fontSize: 10),
      ),
    );
  }
}

// ── Order summary card ────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double total;
  final double? discount;

  const _SummaryCard({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.discount,
  });

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? Colors.white : Colors.white60,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 15 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? (bold ? const Color(0xFF00E676) : Colors.white70),
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818).withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _row('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          _row('Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
          if (discount != null && discount! > 0)
            _row(
              'Discount',
              '-\$${discount!.toStringAsFixed(2)}',
              color: Colors.redAccent,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: Colors.white12),
          ),
          _row(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );
  }
}

// ── Main Cart Screen ──────────────────────────────────────────────────────────
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _promoCtrl = TextEditingController();
  bool _applyingPromo = false;
  String? _promoMessage;
  bool _promoValid = false;
  double _discountPercent = 0;

  // Animate the summary section in
  late final AnimationController _summaryCtrl;
  late final Animation<double> _summaryFade;

  @override
  void initState() {
    super.initState();
    _summaryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _summaryFade = CurvedAnimation(parent: _summaryCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().fetchCart().then((_) {
        if (mounted) _summaryCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  String _recipeImage(String name) {
    final n = name.toLowerCase();
    if (n.contains('beef') || n.contains('stew') || n.contains('burger') ||
        n.contains('steak') || n.contains('meatball'))
      return 'lib/assets/beef_stew.jpg';
    if (n.contains('chicken') || n.contains('turkey'))
      return 'lib/assets/grilled_chicken.jpg';
    if (n.contains('fish') || n.contains('salmon') || n.contains('tuna') ||
        n.contains('shrimp') || n.contains('seafood'))
      return 'lib/assets/fish_pate.jpg';
    if (n.contains('pasta') || n.contains('spaghetti') || n.contains('lasagna'))
      return 'lib/assets/pasta.jpg';
    if (n.contains('salad') || n.contains('noodle'))
      return 'lib/assets/noodles.jpg';
    if (n.contains('soup') || n.contains('chili') || n.contains('broth'))
      return 'lib/assets/lentil_soup.jpg';
    if (n.contains('rice') || n.contains('biryani'))
      return 'lib/assets/fried_rice.jpg';
    if (n.contains('pizza') || n.contains('vegan') || n.contains('vegetable'))
      return 'lib/assets/cheese_pizza.jpg';
    if (n.contains('mutton')) return 'lib/assets/mutton_curry.jpg';
    if (n.contains('pork')) return 'lib/assets/pork_marinade.jpg';
    if (n.contains('smoothie') || n.contains('juice') || n.contains('drink'))
      return 'lib/assets/grilled_chicken.jpg';
    return 'lib/assets/pork_marinade.jpg';
  }

  Future<void> _applyPromo() async {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _applyingPromo = true;
      _promoMessage = null;
    });
    try {
      final result = await ApiService.applyPromoCode(code);
      setState(() {
        _promoValid = result['valid'] ?? false;
        _promoMessage = result['message'] ?? '';
        _discountPercent = (_promoValid
            ? (result['discount_percent'] ?? 0).toDouble()
            : 0);
      });
    } catch (_) {
      setState(() {
        _promoValid = false;
        _promoMessage = 'Could not apply promo code.';
        _discountPercent = 0;
      });
    } finally {
      setState(() => _applyingPromo = false);
    }
  }

  double _computeDiscount(double subtotal) {
    if (!_promoValid || _discountPercent == 0) return 0;
    return subtotal * (_discountPercent / 100);
  }

  Future<void> _confirmClear(CartProvider cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D2818),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Clear cart?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'All items will be removed.',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cart.clearCart();
      setState(() {
        _promoMessage = null;
        _promoValid = false;
        _discountPercent = 0;
        _promoCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
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
          body: Consumer<CartProvider>(
            builder: (context, cart, _) {
              return SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, cart),
                    Expanded(
                      child: cart.loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            )
                          : cart.items.isEmpty
                              ? _buildEmptyState()
                              : _buildBody(cart),
                    ),
                    if (!cart.loading && cart.items.isNotEmpty)
                      _buildFindStoresButton(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1F12).withOpacity(0.6),
        border: Border(
          bottom: BorderSide(color: Colors.green.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.35)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.green,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shopping Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${cart.itemCount} item(s)',
                style: const TextStyle(
                  color: Color(0xFF69F0AE),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (cart.items.isNotEmpty)
            GestureDetector(
              onTap: () => _confirmClear(cart),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.35)),
                ),
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.withOpacity(0.2)),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.green,
              size: 52,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add meals from the home screen',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Scrollable body ────────────────────────────────────────────────────────

  Widget _buildBody(CartProvider cart) {
    final discount = _computeDiscount(cart.subtotal);
    final finalTotal = cart.total - discount;

    return FadeTransition(
      opacity: _summaryFade,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Cart items
          ...cart.items.map((item) {
            return _CartItemCard(
              item: item,
              imagePath: _recipeImage(item.recipeName),
              onRemove: () => cart.removeFromCart(item.recipeId),
              onIncrement: () =>
                  cart.updateQuantity(item.recipeId, item.quantity + 1),
              onDecrement: () =>
                  cart.updateQuantity(item.recipeId, item.quantity - 1),
            );
          }),

          const SizedBox(height: 8),

          // Promo code row
          _buildPromoRow(),
          const SizedBox(height: 16),

          // Order summary
          _SummaryCard(
            subtotal: cart.subtotal,
            deliveryFee: cart.deliveryFee,
            total: finalTotal > 0 ? finalTotal : 0,
            discount: discount > 0 ? discount : null,
          ),
        ],
      ),
    );
  }

  // ── Promo code ─────────────────────────────────────────────────────────────

  Widget _buildPromoRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Promo code',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0D2818).withOpacity(0.85),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.green.withOpacity(0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _applyingPromo ? null : _applyPromo,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color:
                      _applyingPromo ? Colors.green.withOpacity(0.4) : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: _applyingPromo
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Apply',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
        if (_promoMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _promoValid ? Icons.check_circle_outline : Icons.error_outline,
                size: 15,
                color: _promoValid ? Colors.green : Colors.redAccent,
              ),
              const SizedBox(width: 6),
              Text(
                _promoMessage!,
                style: TextStyle(
                  color: _promoValid ? Colors.green : Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Find Nearby Stores button ──────────────────────────────────────────────

  Widget _buildFindStoresButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: _AnimatedStoresButton(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Finding nearby stores... 📍'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

// ── Animated "Find Nearby Stores" button ──────────────────────────────────────
class _AnimatedStoresButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedStoresButton({required this.onTap});

  @override
  State<_AnimatedStoresButton> createState() => _AnimatedStoresButtonState();
}

class _AnimatedStoresButtonState extends State<_AnimatedStoresButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glow, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) => GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF00E676)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.35 + _glowAnim.value * 0.3),
                blurRadius: 16 + _glowAnim.value * 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_outlined, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Find Nearby Stores',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}