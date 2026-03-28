import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/map_screen.dart';

// ─── Base URL — change ONLY this one line when your IP changes ────────────────
const String kBaseUrl = 'http://192.168.1.3:8000';

// ─── Data Models ──────────────────────────────────────────────────────────────

class TrendingRecipe {
  final String id;
  final String name;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final String? imageUrl;
  final int searchCount;

  TrendingRecipe({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    this.imageUrl,
    required this.searchCount,
  });

  factory TrendingRecipe.fromJson(Map<String, dynamic> json) {
    return TrendingRecipe(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      calories: (json['calories'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      imageUrl: json['image_url'],
      searchCount: json['search_count'] ?? 0,
    );
  }
}

class SearchedRecipe {
  final String name;
  final List<String> ingredients;
  final List<String> instructions;
  final Map<String, dynamic> nutrition;
  final bool savedToFirebase;

  SearchedRecipe({
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.nutrition,
    required this.savedToFirebase,
  });

  factory SearchedRecipe.fromJson(Map<String, dynamic> json) {
    return SearchedRecipe(
      name: json['name'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      nutrition: json['nutrition'] ?? {},
      savedToFirebase: json['saved_to_firebase'] ?? false,
    );
  }

  String get caloriesDisplay {
    final keyNutrients = nutrition['key_nutrients'] as Map<String, dynamic>?;
    if (keyNutrients == null) return '—';
    for (final entry in keyNutrients.entries) {
      if (entry.key.toLowerCase().contains('energy') ||
          entry.key.toLowerCase().contains('calorie')) {
        return '${(entry.value['value'] ?? 0).toStringAsFixed(0)} kcal';
      }
    }
    return '—';
  }

  String get proteinDisplay {
    final keyNutrients = nutrition['key_nutrients'] as Map<String, dynamic>?;
    if (keyNutrients == null) return '—';
    for (final entry in keyNutrients.entries) {
      if (entry.key.toLowerCase().contains('protein')) {
        return '${(entry.value['value'] ?? 0).toStringAsFixed(1)}g';
      }
    }
    return '—';
  }
}

// ─── Cart Item Model ──────────────────────────────────────────────────────────

class CartItem {
  final String recipeId;
  final String recipeName;
  final double calories;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final String? imagePath;
  final int quantity;
  final double pricePerItem;

  CartItem({
    required this.recipeId,
    required this.recipeName,
    required this.calories,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    this.imagePath,
    required this.quantity,
    required this.pricePerItem,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      recipeId: json['recipe_id'] ?? '',
      recipeName: json['recipe_name'] ?? '',
      calories: (json['calories'] ?? 0).toDouble(),
      proteinG: (json['protein_g'] ?? 0).toDouble(),
      fatG: (json['fat_g'] ?? 0).toDouble(),
      carbsG: (json['carbs_g'] ?? 0).toDouble(),
      imagePath: json['image_path'],
      quantity: json['quantity'] ?? 1,
      pricePerItem: (json['price_per_item'] ?? 4.99).toDouble(),
    );
  }
}

// ─── Notification response wrapper ────────────────────────────────────────────

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  const ApiResponse.ok(this.data) : success = true, error = null;

  const ApiResponse.err(this.error) : success = false, data = null;
}

// ─── Notification model ───────────────────────────────────────────────────────

class NotificationItem {
  final String type;
  final String title;
  final String body;
  final String time;
  bool isRead;

  NotificationItem({
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  factory NotificationItem.fromData(Map<String, dynamic> data) {
    return NotificationItem(
      type: data['type'] ?? 'general',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      time: data['time'] ?? 'just now',
    );
  }
}

// ─── API Service ───────────────────────────────────────────────────────────────

class ApiService {
  static String get baseUrl => kBaseUrl;
  static const _headers = {'Content-Type': 'application/json'};

  // ── Gets real Firebase uid ─────────────────────────────────────────────────
  static String get _userId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('No logged-in user found');
    return uid;
  }

  // ── Internal POST helper for notification endpoints ────────────────────────
  static Future<ApiResponse<Map<String, dynamic>>> _notifPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) return ApiResponse.ok(json);
      return ApiResponse.err(json['detail']?.toString() ?? 'Unknown error');
    } catch (e) {
      return ApiResponse.err('Network error: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ONBOARDING
  // ───────────────────────────────────────────────────────────────────────────

  static Future<bool> updateOnboardingStep(Map<String, String> answer) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/onboarding/$_userId'),
            headers: _headers,
            body: jsonEncode(answer),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RECIPES
  // ───────────────────────────────────────────────────────────────────────────

  static Future<List<TrendingRecipe>> getTrendingRecipes({
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('$kBaseUrl/recipes/trending?limit=$limit');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> recipesJson = data['recipes'] ?? [];
        return recipesJson.map((r) => TrendingRecipe.fromJson(r)).toList();
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load trending recipes: $e');
    }
  }

  static Future<SearchedRecipe> searchRecipe(String query) async {
    try {
      final uri = Uri.parse(
        '$kBaseUrl/recipes/search?query=${Uri.encodeComponent(query)}',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return SearchedRecipe.fromJson(jsonDecode(response.body));
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CART
  // ───────────────────────────────────────────────────────────────────────────

  static const String _cartBase = '$kBaseUrl/api/v1/cart';

  static Future<Map<String, dynamic>> getCart() async {
    final res = await http
        .get(Uri.parse('$_cartBase/$_userId'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to load cart');
  }

  static Future<Map<String, dynamic>> addToCart(TrendingRecipe recipe) async {
    final body = {
      'recipe_id': recipe.id.isNotEmpty
          ? recipe.id
          : recipe.name.toLowerCase().replaceAll(' ', '_'),
      'recipe_name': recipe.name,
      'calories': recipe.calories,
      'protein_g': recipe.proteinG,
      'fat_g': recipe.fatG,
      'carbs_g': recipe.carbsG,
      'quantity': 1,
      'price_per_item': 4.99,
    };
    final res = await http
        .post(
          Uri.parse('$_cartBase/$_userId/add'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to add to cart');
  }

  static Future<Map<String, dynamic>> removeFromCart(String recipeId) async {
    final res = await http
        .delete(
          Uri.parse('$_cartBase/$_userId/remove/$recipeId'),
          headers: _headers,
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to remove from cart');
  }

  static Future<Map<String, dynamic>> updateCartQuantity(
    String recipeId,
    int quantity,
  ) async {
    final res = await http
        .patch(
          Uri.parse('$_cartBase/$_userId/quantity/$recipeId'),
          headers: _headers,
          body: jsonEncode({'quantity': quantity}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to update quantity');
  }

  static Future<Map<String, dynamic>> clearCart() async {
    final res = await http
        .delete(Uri.parse('$_cartBase/$_userId/clear'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to clear cart');
  }

  static Future<Map<String, dynamic>> applyPromoCode(String code) async {
    final res = await http
        .post(
          Uri.parse('$_cartBase/$_userId/promo'),
          headers: _headers,
          body: jsonEncode({'promo_code': code}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to apply promo code');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BMI
  // ───────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> calculateBmi(
    Map<String, dynamic> body,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/bmi/calculate?user_id=${user?.uid}'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
      final detail = jsonDecode(response.body)['detail'] ?? 'Unknown error';
      throw Exception(detail);
    } catch (e) {
      throw Exception('$e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MEAL PREP
  // ───────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> saveMealPrep({
    required String rice,
    required int riceSize,
    required String meat,
    required int meatSize,
    required String vegetable1,
    required int vegetable1Size,
    required String vegetable2,
    required int vegetable2Size,
    required String mallum,
    required int mallumSize,
    required String salad,
    required int saladSize,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final uri = Uri.parse('$kBaseUrl/Meal_Prep_With_Five_Cards').replace(
      queryParameters: {
        'access_token': user.uid,
        'rice': rice,
        'rice_size': riceSize.toString(),
        'meat': meat,
        'meat_size': meatSize.toString(),
        'vegetable1': vegetable1,
        'vegetable1_size': vegetable1Size.toString(),
        'vegetable2': vegetable2,
        'vegetable2_size': vegetable2Size.toString(),
        'mallum': mallum,
        'mallum_size': mallumSize.toString(),
        'salad': salad,
        'salad_size': saladSize.toString(),
      },
    );

    final response = await http.post(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) return jsonDecode(response.body);
    if (response.body.isEmpty)
      throw Exception('Server error (${response.statusCode})');
    final detail = jsonDecode(response.body)['detail'] ?? 'Unknown error';
    throw Exception(detail);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PROFILE
  // ───────────────────────────────────────────────────────────────────────────

  static const String _profileBase = '$kBaseUrl/api/v1';

  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await http.get(
      Uri.parse('$_profileBase/profile/$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to load profile');
  }

  static Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    final response = await http.patch(
      Uri.parse('$_profileBase/profile/$userId'),
      headers: _headers,
      body: jsonEncode(fields),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to update profile');
  }

  static Future<Map<String, dynamic>> deleteField(
    String userId,
    String field,
  ) async {
    final response = await http.delete(
      Uri.parse('$_profileBase/profile/$userId/field'),
      headers: _headers,
      body: jsonEncode({'field': field}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to delete field');
  }

  static Future<Map<String, dynamic>> uploadProfilePicture(
    String userId,
    File imageFile,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_profileBase/profile/$userId/upload-picture'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) return jsonDecode(response.body);
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to upload picture');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS
  // ───────────────────────────────────────────────────────────────────────────

  static Future<bool> isBackendReachable() async {
    try {
      final res = await http
          .get(Uri.parse(kBaseUrl))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<ApiResponse<Map<String, dynamic>>> registerToken({
    required String userId,
    required String fcmToken,
  }) => _notifPost('/notifications/register-token', {
    'user_id': userId,
    'fcm_token': fcmToken,
  });

  static Future<ApiResponse<Map<String, dynamic>>> notifyAddToCart({
    required String userId,
    required String ingredientName,
    String? recipeName,
  }) => _notifPost('/notifications/add-to-cart', {
    'user_id': userId,
    'ingredient_name': ingredientName,
    if (recipeName != null) 'recipe_name': recipeName,
  });

  static Future<ApiResponse<Map<String, dynamic>>> notifySaveRecipe({
    required String userId,
    required String recipeName,
    required String recipeId,
  }) => _notifPost('/notifications/save-recipe', {
    'user_id': userId,
    'recipe_name': recipeName,
    'recipe_id': recipeId,
  });

  static Future<ApiResponse<Map<String, dynamic>>> notifyTrendingRecipe({
    required String userId,
    required String recipeName,
    required String recipeId,
    int? trendingRank,
  }) => _notifPost('/notifications/trending-recipe', {
    'user_id': userId,
    'recipe_name': recipeName,
    'recipe_id': recipeId,
    if (trendingRank != null) 'trending_rank': trendingRank,
  });

  static Future<ApiResponse<Map<String, dynamic>>> notifyOrderConfirmed({
    required String userId,
    required String orderId,
    required String storeName,
    required int itemCount,
  }) => _notifPost('/notifications/order-confirmed', {
    'user_id': userId,
    'order_id': orderId,
    'store_name': storeName,
    'item_count': itemCount,
  });

  static Future<ApiResponse<Map<String, dynamic>>> notifyFitnessDetails({
    required String userId,
    double? caloriesBurned,
    int? steps,
    String? workoutName,
    bool goalReached = false,
  }) => _notifPost('/notifications/fitness-details', {
    'user_id': userId,
    if (caloriesBurned != null) 'calories_burned': caloriesBurned,
    if (steps != null) 'steps': steps,
    if (workoutName != null) 'workout_name': workoutName,
    'goal_reached': goalReached,
  });

  static Future<ApiResponse<Map<String, dynamic>>> notifyWeeklyProgress({
    required String userId,
    required int weekNumber,
    double? caloriesAvg,
    int? workoutsCompleted,
    bool goalAchieved = false,
  }) => _notifPost('/notifications/weekly-progress', {
    'user_id': userId,
    'week_number': weekNumber,
    if (caloriesAvg != null) 'calories_avg': caloriesAvg,
    if (workoutsCompleted != null) 'workouts_completed': workoutsCompleted,
    'goal_achieved': goalAchieved,
  });

  static Future<ApiResponse<Map<String, dynamic>>> broadcast({
    required String title,
    required String body,
    required String notificationType,
  }) => _notifPost('/notifications/broadcast', {
    'title': title,
    'body': body,
    'notification_type': notificationType,
  });

  // ───────────────────────────────────────────────────────────────────────────
  //  MAP
  // ───────────────────────────────────────────────────────────────────────────

  static const String _mapBase = '$kBaseUrl/api/v1/map';
 
  // ── Nearby stores via Geoapify (called through backend) ───────────────────
  static Future<List<NearbyStore>> getNearbyStores(
    double lat,
    double lng, {
    int radiusM = 5000,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_mapBase/nearby-stores'),
            headers: _headers,
            body: jsonEncode({'lat': lat, 'lng': lng, 'radius_m': radiusM}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List stores = data['stores'] ?? [];
        return stores.map((s) => NearbyStore.fromJson(s)).toList();
      }
    } catch (e) {
      print('getNearbyStores error: $e');
    }
    return []; // map_screen handles empty with its own fallback
  }
 
  // ── Reverse geocode via backend Nominatim ─────────────────────────────────
  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final res = await http
          .get(
            Uri.parse('$_mapBase/reverse-geocode?lat=$lat&lng=$lng'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)['location_name'] ?? '$lat, $lng';
      }
    } catch (_) {}
    return '$lat, $lng';
  }
 
  // ── Place order — saves to Firestore, clears cart ─────────────────────────
  static Future<Map<String, dynamic>> placeOrder({
    required NearbyStore store,
    required List<CartItem> cartItems,
    required double subtotal,
    required double deliveryFee,
    required double total,
    double discount = 0,
    String? promoCode,
  }) async {
    final body = {
      'store_id': store.id,
      'store_name': store.name,
      'store_address': store.address,
      'items': cartItems
          .map((i) => {
                'recipe_id': i.recipeId,
                'recipe_name': i.recipeName,
                'quantity': i.quantity,
                'price_per_item': i.pricePerItem,
              })
          .toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'discount': discount,
      if (promoCode != null) 'promo_code': promoCode,
    };
 
    final res = await http
        .post(
          Uri.parse('$_mapBase/$_userId/place-order'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Failed to place order: ${res.statusCode}');
  }
}
