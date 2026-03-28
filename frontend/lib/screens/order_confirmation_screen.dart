import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderConfirmationScreen({super.key, required this.order});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkCtrl;
  late final AnimationController _contentCtrl;
  late final Animation<double> _checkScale;
  late final Animation<double> _checkFade;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  bool _payPressed = false;

  @override
  void initState() {
    super.initState();

    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _checkScale = CurvedAnimation(
        parent: _checkCtrl, curve: Curves.elasticOut);
    _checkFade = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut);

    _contentFade =
        CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    // Sequence: check animates first, then content
    _checkCtrl.forward().then((_) => _contentCtrl.forward());
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = (order['items'] as List<dynamic>?) ?? [];
    final storeName = order['store_name'] ?? '';
    final storeAddress = order['store_address'] ?? '';
    final orderId = order['order_id'] ?? '';
    final subtotal = (order['subtotal'] ?? 0).toDouble();
    final deliveryFee = (order['delivery_fee'] ?? 0).toDouble();
    final discount = (order['discount'] ?? 0).toDouble();
    final total = (order['total'] ?? 0).toDouble();
    final eta = order['estimated_delivery'] ?? '30-45 min';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF000302),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.55, 1.0],
              colors: [
                Color(0xFF0D2818),
                Color(0xFF060F08),
                Color(0xFF000302),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      children: [
                        // ── Animated check ────────────────────────
                        ScaleTransition(
                          scale: _checkScale,
                          child: FadeTransition(
                            opacity: _checkFade,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF00E676).withOpacity(0.12),
                                border: Border.all(
                                  color: const Color(0xFF00E676),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E676).withOpacity(0.3),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF00E676),
                                size: 46,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        FadeTransition(
                          opacity: _checkFade,
                          child: Column(
                            children: [
                              const Text(
                                'Order Confirmed!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Order #$orderId',
                                style: const TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Content ───────────────────────────────
                        SlideTransition(
                          position: _contentSlide,
                          child: FadeTransition(
                            opacity: _contentFade,
                            child: Column(
                              children: [
                                // Store info card
                                _InfoCard(
                                  icon: Icons.store_outlined,
                                  title: storeName,
                                  subtitle: storeAddress,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time,
                                          color: Color(0xFF00E676), size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ETA: $eta',
                                        style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Order items
                                _buildItemsCard(items),
                                const SizedBox(height: 14),

                                // Price summary
                                _buildPriceSummary(
                                    subtotal, deliveryFee, discount, total),
                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Pay Now button ────────────────────────────────
                FadeTransition(
                  opacity: _contentFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      children: [
                        _PayNowButton(
                          total: total,
                          onTap: _payPressed
                              ? null
                              : () {
                                  setState(() => _payPressed = true);
                                  _showPaymentSuccess(context);
                                },
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context, '/home', (r) => false),
                          child: const Text(
                            'Back to Home',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsCard(List<dynamic> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818).withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined,
                    color: Color(0xFF00E676), size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Order Items',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length} item${items.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          ...items.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            final isLast = entry.key == items.length - 1;
            final qty = item['quantity'] ?? 1;
            final price = (item['price_per_item'] ?? 0).toDouble();

            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom:
                            BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF00E676).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.restaurant_menu,
                        color: Color(0xFF00E676), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['recipe_name'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'x$qty  •  \$${price.toStringAsFixed(2)} each',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(price * qty).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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

  Widget _buildPriceSummary(
      double subtotal, double deliveryFee, double discount, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818).withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _PriceRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          _PriceRow(
              'Delivery Fee', '\$${deliveryFee.toStringAsFixed(2)}'),
          if (discount > 0)
            _PriceRow(
              'Discount',
              '-\$${discount.toStringAsFixed(2)}',
              valueColor: Colors.redAccent,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white10),
          ),
          _PriceRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  void _showPaymentSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentSuccessDialog(
        onDone: () {
          Navigator.pop(context); // close dialog
          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
        },
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2818).withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00E676), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Price row ─────────────────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _PriceRow(this.label, this.value,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: bold ? Colors.white : Colors.white60,
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 15 : 13,
              )),
          Text(value,
              style: TextStyle(
                color: valueColor ??
                    (bold ? const Color(0xFF00E676) : Colors.white70),
                fontWeight:
                    bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 13,
              )),
        ],
      ),
    );
  }
}

// ── Pay Now button ────────────────────────────────────────────────────────────
class _PayNowButton extends StatefulWidget {
  final double total;
  final VoidCallback? onTap;
  const _PayNowButton({required this.total, this.onTap});
  @override
  State<_PayNowButton> createState() => _PayNowButtonState();
}

class _PayNowButtonState extends State<_PayNowButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _glowAnim =
        CurvedAnimation(parent: _glow, curve: Curves.easeInOut);
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
      builder: (_, __) => GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: widget.onTap == null ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
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
                  color: const Color(0xFF00E676).withOpacity(
                      0.3 + _glowAnim.value * 0.3),
                  blurRadius: 14 + _glowAnim.value * 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment_outlined,
                    color: Colors.black, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Pay Now  •  \$${widget.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Payment success dialog ────────────────────────────────────────────────────
class _PaymentSuccessDialog extends StatefulWidget {
  final VoidCallback onDone;
  const _PaymentSuccessDialog({required this.onDone});
  @override
  State<_PaymentSuccessDialog> createState() =>
      _PaymentSuccessDialogState();
}

class _PaymentSuccessDialogState extends State<_PaymentSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale =
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D2818),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E676).withOpacity(0.12),
                  border: Border.all(
                      color: const Color(0xFF00E676), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(0xFF00E676).withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Color(0xFF00E676), size: 36),
              ),
              const SizedBox(height: 18),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your order has been placed.\nExpect delivery in 30-45 min.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back to Home',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}