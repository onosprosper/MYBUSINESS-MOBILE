import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();
  static final instance = ApiService._();

  static const baseUrl = 'https://mybusiness-ng.onrender.com';
  static const _tokenKey = 'mybusiness_access_token';

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _token();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
    final data = body is Map<String, dynamic> ? body : <String, dynamic>{'data': body};

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? data['message'] ?? 'Login failed');
    }

    final token = (data['access_token'] ?? data['token'])?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Login succeeded but no access token was returned.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    return data;
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String businessName,
    required String email,
    required String password,
    required String businessType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'business_name': businessName,
        'email': email,
        'password': password,
        'business_type': businessType,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Could not create account');
    }
    final token = data['access_token']?.toString();
    if (token == null || token.isEmpty) throw Exception('Account created; please log in.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    return data;
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final token = await _token();
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    if (response.statusCode == 401) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? 'Request failed (${response.statusCode})');
    }
    return data;
  }

  Future<dynamic> getJson(String path) async {
    final token = await _token();
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      await logout();
      throw Exception('Session expired. Please log in again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed (${response.statusCode})');
    }
    if (response.body.isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final data = await getJson(path);
    if (data is Map<String, dynamic>) return data;
    return {'data': data};
  }

  List<dynamic> extractList(dynamic data, List<String> possibleKeys) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        final value = data[key];
        if (value is List) return value;
      }
      final nested = data['data'];
      if (nested is List) return nested;
      if (nested is Map<String, dynamic>) {
        for (final key in possibleKeys) {
          final value = nested[key];
          if (value is List) return value;
        }
      }
    }
    return [];
  }
}
