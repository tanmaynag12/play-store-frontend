import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const _tokenKey = 'jwt_token';
  static const _userKey = 'user_data';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      await _saveToken(data['token']);
      await _saveUser(data['user']);
      return {'success': true, 'user': UserModel.fromJson(data['user'])};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Login failed.'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<Map<String, dynamic>?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userStr = prefs.getString(_userKey);

    if (token == null || userStr == null) return null;

    return {'token': token, 'user': UserModel.fromJson(jsonDecode(userStr))};
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 201 || res.statusCode == 200) {
      await _saveToken(data['token']);
      await _saveUser(data['user']);
      return {'success': true, 'user': UserModel.fromJson(data['user'])};
    } else {
      return {
        'success': false,
        'error': data['error'] ?? 'Registration failed.',
      };
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }
}
