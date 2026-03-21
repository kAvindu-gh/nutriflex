import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'profile_api_service.dart';

class UserSession {
  static const _keyUserId = 'user_id';

  // Save user_id after login/signup
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
  }

  // Get saved user_id
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  // Call backend logout then clear local storage
  static Future<void> logout(String userId) async {
    // Call backend logout endpoint
    try {
      await http.post(
        Uri.parse('${ProfileApiService.baseUrl}/profile/$userId/logout'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {
      // Even if backend call fails, still clear local session
    }
    // Clear local storage regardless
    await clear();
  }

  // Clear local storage only
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}