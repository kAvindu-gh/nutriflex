import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ProfileApiService {
  //static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String baseUrl = 'http://192.168.8.132:8000/api/v1';

  // ── GET profile 
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load profile');
    }
  }

  // ── PATCH profile (update any field) 
  static Future<Map<String, dynamic>> updateProfile(
      String userId, Map<String, dynamic> fields) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/profile/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fields),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update profile');
    }
  }

  // ── DELETE a field (set to null) 
  static Future<Map<String, dynamic>> deleteField(
      String userId, String field) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/profile/$userId/field'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'field': field}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete field');
    }
  }

  // ── POST upload profile picture 
  static Future<Map<String, dynamic>> uploadProfilePicture(
      String userId, File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/$userId/upload-picture'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to upload picture');
    }
  }
}