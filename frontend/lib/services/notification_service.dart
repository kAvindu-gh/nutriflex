import 'dart:convert';
import 'package:http/http.dart' as http;

/// Change this to your machine's IP when running on a physical device.
/// Use http://10.0.2.2:8000 for Android emulator,
/// or http://localhost:8000 for web/desktop.
const String _baseUrl = 'http://192.168.1.3:8000';

// ─── Response wrapper ─────────────────────────────────────────────────────────
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  const ApiResponse.ok(this.data)
      : success = true,
        error = null;

  const ApiResponse.err(this.error)
      : success = false,
        data = null;
}

// ─── Notification model (matches backend response) ────────────────────────────
class NotificationItem {
  final String type;        // e.g. "add_to_cart", "save_recipe" …
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

  /// Build from the FCM data payload returned by the backend.
  factory NotificationItem.fromData(Map<String, dynamic> data) {
    return NotificationItem(
      type: data['type'] ?? 'general',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      time: data['time'] ?? 'just now',
    );
  }
}

// ─── NutriFlexNotificationService ─────────────────────────────────────────────
class NutriFlexNotificationService {
  static const _headers = {'Content-Type': 'application/json'};

  // ── helpers ──────────────────────────────────────────────────────────────────

  Future<ApiResponse<Map<String, dynamic>>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return ApiResponse.ok(json);
      }
      return ApiResponse.err(json['detail']?.toString() ?? 'Unknown error');
    } catch (e) {
      return ApiResponse.err('Network error: $e');
    }
  }

  // ── Health check ─────────────────────────────────────────────────────────────
  Future<bool> isBackendReachable() async {
    try {
      final res = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── 1. Register FCM token ─────────────────────────────────────────────────────
  /// Call on every app launch / after login.
  Future<ApiResponse<Map<String, dynamic>>> registerToken({
    required String userId,
    required String fcmToken,
  }) =>
      _post('/notifications/register-token', {
        'user_id': userId,
        'fcm_token': fcmToken,
      });

  // ── 2. Add-to-cart notification ───────────────────────────────────────────────
  /// Call when user adds an ingredient to the cart.
  Future<ApiResponse<Map<String, dynamic>>> notifyAddToCart({
    required String userId,
    required String ingredientName,
    String? recipeName,
  }) =>
      _post('/notifications/add-to-cart', {
        'user_id': userId,
        'ingredient_name': ingredientName,
        if (recipeName != null) 'recipe_name': recipeName,
      });

  // ── 3. Save-recipe notification ───────────────────────────────────────────────
  /// Call when user saves / favourites a recipe.
  Future<ApiResponse<Map<String, dynamic>>> notifySaveRecipe({
    required String userId,
    required String recipeName,
    required String recipeId,
  }) =>
      _post('/notifications/save-recipe', {
        'user_id': userId,
        'recipe_name': recipeName,
        'recipe_id': recipeId,
      });

  // ── 4. Trending-recipe notification ───────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> notifyTrendingRecipe({
    required String userId,
    required String recipeName,
    required String recipeId,
    int? trendingRank,
  }) =>
      _post('/notifications/trending-recipe', {
        'user_id': userId,
        'recipe_name': recipeName,
        'recipe_id': recipeId,
        if (trendingRank != null) 'trending_rank': trendingRank,
      });

  // ── 5. Order-confirmed notification ───────────────────────────────────────────
  /// Call automatically when an order is confirmed on the map page.
  Future<ApiResponse<Map<String, dynamic>>> notifyOrderConfirmed({
    required String userId,
    required String orderId,
    required String storeName,
    required int itemCount,
  }) =>
      _post('/notifications/order-confirmed', {
        'user_id': userId,
        'order_id': orderId,
        'store_name': storeName,
        'item_count': itemCount,
      });

  // ── 6. Fitness-details notification ───────────────────────────────────────────
  /// Call when the user completes a workout or hits a daily goal.
  Future<ApiResponse<Map<String, dynamic>>> notifyFitnessDetails({
    required String userId,
    double? caloriesBurned,
    int? steps,
    String? workoutName,
    bool goalReached = false,
  }) =>
      _post('/notifications/fitness-details', {
        'user_id': userId,
        if (caloriesBurned != null) 'calories_burned': caloriesBurned,
        if (steps != null) 'steps': steps,
        if (workoutName != null) 'workout_name': workoutName,
        'goal_reached': goalReached,
      });

  // ── 7. Weekly-progress notification ───────────────────────────────────────────
  /// Typically triggered by a backend scheduler, but can be called manually.
  Future<ApiResponse<Map<String, dynamic>>> notifyWeeklyProgress({
    required String userId,
    required int weekNumber,
    double? caloriesAvg,
    int? workoutsCompleted,
    bool goalAchieved = false,
  }) =>
      _post('/notifications/weekly-progress', {
        'user_id': userId,
        'week_number': weekNumber,
        if (caloriesAvg != null) 'calories_avg': caloriesAvg,
        if (workoutsCompleted != null) 'workouts_completed': workoutsCompleted,
        'goal_achieved': goalAchieved,
      });

  // ── 8. Broadcast to all users ─────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> broadcast({
    required String title,
    required String body,
    required String notificationType,
  }) =>
      _post('/notifications/broadcast', {
        'title': title,
        'body': body,
        'notification_type': notificationType,
      });
}