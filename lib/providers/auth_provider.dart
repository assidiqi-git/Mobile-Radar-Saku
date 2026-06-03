import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/widget_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _token;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Initialize: try to restore session from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.authTokenKey);
    final userJson = prefs.getString(AppConstants.userDataKey);

    if (_token != null && userJson != null) {
      try {
        _user = UserModel.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>);
        ApiService.instance.setToken(_token);
        _status = AuthStatus.authenticated;
      } catch (_) {
        await _clearSession();
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await ApiService.instance.login(email, password);
      final data = response['data'] as Map<String, dynamic>;
      _token = data['token'] as String;
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _persistSession();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ValidationException catch (e) {
      _errorMessage = e.message;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke server. Periksa koneksi Anda.';
    }
    _setLoading(false);
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await ApiService.instance.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      final data = response['data'] as Map<String, dynamic>;
      _token = data['token'] as String;
      _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _persistSession();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ValidationException catch (e) {
      _errorMessage = e.message;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke server. Periksa koneksi Anda.';
    }
    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    _setLoading(true);
    await ApiService.instance.logout();
    await _clearSession();
    await DatabaseHelper.instance.clearAllUserData();
    // Clear home screen widget data saat logout
    await WidgetService.clearWidget();
    _status = AuthStatus.unauthenticated;
    _user = null;
    _setLoading(false);
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.authTokenKey, _token!);
    await prefs.setString(AppConstants.userDataKey, jsonEncode(_user!.toJson()));
    ApiService.instance.setToken(_token);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authTokenKey);
    await prefs.remove(AppConstants.userDataKey);
    ApiService.instance.setToken(null);
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
