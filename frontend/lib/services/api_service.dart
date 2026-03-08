import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Data Models ────────────────────────────────────────────────────────────

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

  // Extracts calories string from USDA nutrition data
  String get caloriesDisplay {
    final keyNutrients = nutrition['key_nutrients'] as Map<String, dynamic>?;
    if (keyNutrients == null) return '—';
    for (final entry in keyNutrients.entries) {
      if (entry.key.toLowerCase().contains('energy') ||
          entry.key.toLowerCase().contains('calorie')) {
        final val = (entry.value['value'] ?? 0).toStringAsFixed(0);
        return '$val kcal';
      }
    }
    return '—';
  }

  // Extracts protein string from USDA nutrition data
  String get proteinDisplay {
    final keyNutrients = nutrition['key_nutrients'] as Map<String, dynamic>?;
    if (keyNutrients == null) return '—';
    for (final entry in keyNutrients.entries) {
      if (entry.key.toLowerCase().contains('protein')) {
        final val = (entry.value['value'] ?? 0).toStringAsFixed(1);
        return '${val}g';
      }
    }
    return '—';
  }
}

// ─── API Service ─────────────────────────────────────────────────────────────

class ApiService {
  static const String baseUrl = 'http://192.168.8.132:8000';
  //static const String baseUrl = 'http://10.0.2.2:8000';

  // Fetch trending recipes for home page
  static Future<List<TrendingRecipe>> getTrendingRecipes({int limit = 50}) async {
    try {
      final uri = Uri.parse('$baseUrl/recipes/trending?limit=$limit');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> recipesJson = data['recipes'] ?? [];
        return recipesJson.map((r) => TrendingRecipe.fromJson(r)).toList();
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load trending recipes: $e');
    }
  }

  // Search for a recipe by name
  static Future<SearchedRecipe> searchRecipe(String query) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/recipes/search?query=${Uri.encodeComponent(query)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SearchedRecipe.fromJson(data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }
}
