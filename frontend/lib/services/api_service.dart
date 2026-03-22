import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const kBaseUrl = 'http://localhost:8000';

class ApiService {
  // ── Add saveMealPrep INSIDE the class ──
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
} // ← closing brace of ApiService class
