import 'dart:convert';
import 'package:http/http.dart' as http;

class OnboardingService {
  // ── Use your PC's actual local IP + port 8000 ──
  static const String _baseUrl = 'http://10.0.2.2:8000';

  // ── Hardcoded test user — swap for FirebaseAuth uid later ──
  static const String testUserId = 'Ghd8IfB4nEAgSxu4s9L4';

  static Future<bool> updateStep(Map<String, String> answer) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/onboarding/$testUserId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(answer),
      );
      print(
        '[NutriFlex] Step updated: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('[NutriFlex] Connection error: $e');
      return false;
    }
  }
}
