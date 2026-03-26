import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _loading = false;
  double _subtotal = 0;
  double _deliveryFee = 0;
  double _total = 0;
  int _itemCount = 0;

  List<CartItem> get items => _items;
  bool get loading => _loading;
  double get subtotal => _subtotal;
  double get deliveryFee => _deliveryFee;
  double get total => _total;
  int get itemCount => _itemCount;

  void _updateFromResponse(Map<String, dynamic> data) {
    final rawItems = data['items'] as List<dynamic>? ?? [];
    _items = rawItems.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
    _itemCount = data['item_count'] ?? 0;
    _subtotal = (data['subtotal'] ?? 0).toDouble();
    _deliveryFee = (data['delivery_fee'] ?? 0).toDouble();
    _total = (data['total'] ?? 0).toDouble();
    notifyListeners();
  }

  Future<void> fetchCart() async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService.getCart();
      _updateFromResponse(data);
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<bool> addToCart(TrendingRecipe recipe) async {
    try {
      final data = await ApiService.addToCart(recipe);
      _updateFromResponse(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> removeFromCart(String recipeId) async {
    try {
      final data = await ApiService.removeFromCart(recipeId);
      _updateFromResponse(data);
    } catch (_) {}
  }

  Future<void> updateQuantity(String recipeId, int quantity) async {
    try {
      final data = await ApiService.updateCartQuantity(recipeId, quantity);
      _updateFromResponse(data);
    } catch (_) {}
  }

  Future<void> clearCart() async {
    try {
      final data = await ApiService.clearCart();
      _updateFromResponse(data);
    } catch (_) {}
  }
}