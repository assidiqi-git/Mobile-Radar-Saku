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
  bool _isGuest = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _isGuest;

  /// Initialize: try to restore session from SharedPreferences.
  Future<void> init() async {
    // Load custom server URL first so all subsequent API calls use it
    await ApiService.instance.loadCustomUrl();

    final prefs = await SharedPreferences.getInstance();

    // Check guest flag first (from prefs or if it was hardcoded to true)
    final isGuest = prefs.getBool(AppConstants.isGuestKey) ?? _isGuest;
    if (isGuest) {
      _isGuest = true;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return;
    }

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
      _isGuest = false;
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
    if (!_isGuest) {
      await ApiService.instance.logout();
    }
    await _clearSession();
    if (!_isGuest) {
      await DatabaseHelper.instance.clearAllUserData();
    }
    // Selalu hapus home screen widget data saat logout (termasuk Guest)
    await WidgetService.clearWidget();
    _isGuest = false;
    _status = AuthStatus.unauthenticated;
    _user = null;
    _setLoading(false);
  }

  /// Login as guest — offline-only mode, no token required.
  Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isGuestKey, true);
    _isGuest = true;
    _token = null;
    _user = null;
    _status = AuthStatus.authenticated;
    notifyListeners();
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
    await prefs.remove(AppConstants.isGuestKey);
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
