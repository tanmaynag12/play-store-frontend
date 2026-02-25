import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  String? _token;
  bool _loading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get loading => _loading;

  bool get isLoggedIn => _token != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  Future<void> restoreSession() async {
    final session = await _authService.restoreSession();
    if (session != null) {
      _token = session['token'];
      _user = session['user'];
      notifyListeners();
    }
  }

  Future<String?> login(String email, String password) async {
    _loading = true;
    notifyListeners();

    final result = await _authService.login(email, password);

    _loading = false;

    if (result['success']) {
      _user = result['user'];
      _token = await _authService.getToken();
      notifyListeners();
      return null;
    } else {
      notifyListeners();
      return result['error'];
    }
  }

  Future<String?> register(String name, String email, String password) async {
    _loading = true;
    notifyListeners();

    final result = await _authService.register(name, email, password);

    _loading = false;

    if (result['success']) {
      _user = result['user'];
      _token = await _authService.getToken();
      notifyListeners();
      return null;
    } else {
      notifyListeners();
      return result['error'];
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _token = null;
    notifyListeners();
  }
}
