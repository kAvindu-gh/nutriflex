import 'package:flutter/material.dart';

// The main entry point for the Flutter application.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping Cart',
      theme: ThemeData(
        primarySwatch: Colors.green, // A general theme color
      ),
      home: const ShoppingCartPage(),
    );
  }
}

class ShoppingCartPage extends StatefulWidget {
  const ShoppingCartPage({super.key});

  @override
  State<ShoppingCartPage> createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  int quantity = 1;

  final double itemPrice = 4.99;
  final double deliveryFee = 1.99;

  double get subtotal => itemPrice * quantity;
  double get total => subtotal + deliveryFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1512),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1512),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Shopping Cart",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _cartItem(),
            const SizedBox(height: 16),
            _promoCode(),
            const SizedBox(height: 16),
            _orderSummary(),
            const Spacer(),
            // _findStoresButton() was removed from here to be used in bottomNavigationBar
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0), // Add padding consistent with body
        child:
            _findStoresButton(), // Use the existing button for the bottom nav bar
      ),
    );
  }

  // ---------------- CART ITEM ----------------
  Widget _cartItem() {
    // FIX: Replace Colors.red.withOpacity(0.15) with HSVColor.withValues as suggested by the error message.
    // 1. Convert Colors.red (ARGB Color) to HSVColor.
    final hsvRed = HSVColor.fromColor(Colors.red);
    // 2. Use withValues to set the alpha (opacity) component.
    // The HSVColor class does not have a `withValues` method.
    // To create a new HSVColor with a modified alpha, instantiate a new HSVColor
    // with the desired values.
    // The `HSVColor` constructor that takes hue, saturation, value, and alpha directly is `HSVColor.fromAHSV`.
    final Color redWithOpacity = HSVColor.fromAHSV(
      0.15, // 15% opacity (alpha)
      hsvRed.hue,
      hsvRed.saturation,
      hsvRed.value,
    ).toColor(); // 3. Convert the modified HSVColor back to ARGB Color.

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13261D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Energy Smoothie",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "\$4.99 per meal",
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            children: [
              _qtyButton(
                icon: Icons.remove,
                onTap: () {
                  if (quantity > 1) {
                    setState(() => quantity--);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  quantity.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              _qtyButton(
                icon: Icons.add,
                onTap: () {
                  setState(() => quantity++);
                },
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Delete button
          Container(
            decoration: BoxDecoration(
              color:
                  redWithOpacity, // Replaced `Colors.red.withOpacity(0.15)` with `redWithOpacity`
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() => quantity = 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- PROMO CODE ----------------
  Widget _promoCode() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Promo code",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF13261D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1ED760),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {},
          child: const Text("Apply"),
        ),
      ],
    );
  }

  // ---------------- ORDER SUMMARY ----------------
  Widget _orderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13261D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Order Summary",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow("Subtotal", subtotal),
          _summaryRow("Delivery Fee", deliveryFee),
          const Divider(color: Colors.white24),
          _summaryRow("Total", total, isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "\$${amount.toStringAsFixed(2)}",
            style: TextStyle(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for quantity buttons
  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    // To fix the deprecation warning for `withOpacity` here as well,
    // we can use `Color.fromARGB`. `Color.fromARGB` is not deprecated.
    // The original color is (0xFF1ED760).
    // An opacity of 0.2 means 20% alpha.
    // 0.2 * 255 = 51. So, the alpha component would be 51.
    const Color greenWithOpacity = Color.fromARGB(
      51,
      30,
      215,
      96,
    ); // Calculated from 0xFF1ED760 with 0.2 opacity

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: greenWithOpacity, // Replaced with `Color.fromARGB`
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1ED760)),
      ),
    );
  }

  // ---------------- FIND STORES BUTTON ----------------
  Widget _findStoresButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1ED760),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.location_on), // Fixed incomplete icon name
        label: const Text(
          "Find Nearby Stores",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () {
          // Add navigation or action here
        },
      ),
    );
  }
}
