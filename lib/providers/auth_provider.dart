import 'package:flutter/material.dart';
import 'package:service_app/models/user.dart';
import 'package:service_app/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  String? _token;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  // Инициализация при старте приложения
  Future<void> initialize() async {
    final token = await ApiService.getToken();
    print('AuthProvider initialize: token=$token');
    if (token != null) {
      try {
        _token = token;
        _user = await ApiService.getProfile();
        _isAuthenticated = true;
        print('AuthProvider initialized: userId=${_user?.id}, isAuthenticated=$_isAuthenticated');
      } catch (e) {
        print('Ошибка восстановления сессии: $e');
        await ApiService.removeToken();
        _token = null;
        _user = null;
        _isAuthenticated = false;
      }
    } else {
      _isAuthenticated = false;
      _token = null;
      _user = null;
    }
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final response = await ApiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      if (response['token'] != null) {
        _token = response['token'];
        await ApiService.saveToken(_token!);
        _user = await ApiService.getProfile();
        _isAuthenticated = true;
        print('Register success: userId=${_user?.id}, token=$_token');
      } else {
        throw Exception('Токен не получен после регистрации');
      }
      notifyListeners();
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await ApiService.login(email: email, password: password);
      print('Login response: $response');
      if (response['token'] != null) {
        _token = response['token'];
        await ApiService.saveToken(_token!);
        _user = await ApiService.getProfile();
        _isAuthenticated = true;
        print('Login success: userId=${_user?.id}, token=$_token');
      } else {
        throw Exception('Токен не получен после входа');
      }
      notifyListeners();
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> loadProfile() async {
    try {
      _user = await ApiService.getProfile();
      _isAuthenticated = true;
      print('Profile loaded: userId=${_user?.id}');
      notifyListeners();
    } catch (e) {
      print('Load profile error: $e');
      _isAuthenticated = false;
      _token = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? password,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) throw Exception('Не авторизован');

      final response = await ApiService.updateProfile(
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
      );

      final updatedUser = await ApiService.getProfile();
      _user = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Update profile error: $e');
      rethrow;
    }
  }
  Future<void> deleteProfile() async {
    try {
      await ApiService.deleteProfile();
      _user = null;
      _token = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await ApiService.removeToken();
    _user = null;
    _token = null;
    _isAuthenticated = false;
    print('Logout: isAuthenticated=$_isAuthenticated');
    notifyListeners();
  }
}