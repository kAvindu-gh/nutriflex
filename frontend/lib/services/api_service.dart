import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Base URL — change ONLY this one line when your IP changes ───────────────
// Physical device : your machine's IPv4 (e.g. 192.168.8.132)
// Emulator        : 10.0.2.2
const String kBaseUrl = 'http://192.168.8.132:8000';

// ─── Data Models ─────────────────────────────────────────────────────────────

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
      id:          json['id']           ?? '',
      name:        json['name']         ?? 'Unknown',
      calories:   (json['calories']     ?? 0).toDouble(),
      proteinG:   (json['protein_g']    ?? 0).toDouble(),
      fatG:       (json['fat_g']        ?? 0).toDouble(),
      carbsG:     (json['carbs_g']      ?? 0).toDouble(),
      imageUrl:    json['image_url'],
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
      name:            json['name']               ?? '',
      ingredients:     List<String>.from(json['ingredients']  ?? []),
      instructions:    List<String>.from(json['instructions'] ?? []),
      nutrition:       json['nutrition']           ?? {},
      savedToFirebase: json['saved_to_firebase']   ?? false,
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

// ─── API Service ──────────────────────────────────────────────────────────────

class ApiService {
  // All pages reference kBaseUrl — only update the const above
  static String get baseUrl => kBaseUrl;

  // Trending recipes — home page
  static Future<List<TrendingRecipe>> getTrendingRecipes({int limit = 50}) async {
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

  // Recipe search — home page
  static Future<SearchedRecipe> searchRecipe(String query) async {
    try {
      final uri = Uri.parse(
          '$kBaseUrl/recipes/search?query=${Uri.encodeComponent(query)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return SearchedRecipe.fromJson(jsonDecode(response.body));
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // BMI calculation — bmi_screen.dart
  static Future<Map<String, dynamic>> calculateBmi(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/bmi/calculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final detail = jsonDecode(response.body)['detail'] ?? 'Unknown error';
      throw Exception(detail);
    } catch (e) {
      throw Exception('$e');
    }
  }
}