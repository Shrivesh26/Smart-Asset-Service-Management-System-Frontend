import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/admin_model.dart';
import '../models/service_provider_model.dart';
import '../models/tenant_model.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api;
  final SharedPreferences _prefs;

  UserModel? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  AuthService(this._api, this._prefs) {
    _loadFromPrefs();
  }

  // ── Getters ──────────────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentRole => _prefs.getString(AppConstants.keyRole);

  bool get isAdmin => currentRole == AppConstants.roleAdmin;
  bool get isTenant => currentRole == AppConstants.roleTenant;
  bool get isProvider => currentRole == AppConstants.roleProvider;
  bool get isUser => currentRole == AppConstants.roleUser;

  // ── Load session on app start ────────────────────────────────────────
  void _loadFromPrefs() {
    _isLoggedIn = _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
    if (_isLoggedIn) {
      final id = _prefs.getString(AppConstants.keyUserId) ?? '';
      final name = _prefs.getString(AppConstants.keyUserName) ?? '';
      final email = _prefs.getString(AppConstants.keyUserEmail) ?? '';
      final role = _prefs.getString(AppConstants.keyRole) ?? '';

      if (id.isNotEmpty && role.isNotEmpty) {
        _currentUser = _parseRoleUser({
          'id': id,
          'fullName': name,
          'email': email,
          'phone': '',
          'role': role,
        });
        refreshProfile();
      } else {
        _isLoggedIn = false;
      }
    }
    notifyListeners();
  }

  // ── Save session ─────────────────────────────────────────────────────
  Future<void> _saveSession(UserModel user, String token) async {
    await _prefs.setString(AppConstants.keyToken, token);
    await _prefs.setString(AppConstants.keyRole, user.role);
    await _prefs.setString(AppConstants.keyUserId, user.id);
    await _prefs.setString(AppConstants.keyUserName, user.fullName);
    await _prefs.setString(AppConstants.keyUserEmail, user.email);
    await _prefs.setBool(AppConstants.keyIsLoggedIn, true);
  }

  // ── Clear session ─────────────────────────────────────────────────────
  Future<void> _clearSession() async {
    await _prefs.remove(AppConstants.keyToken);
    await _prefs.remove(AppConstants.keyRole);
    await _prefs.remove(AppConstants.keyUserId);
    await _prefs.remove(AppConstants.keyUserName);
    await _prefs.remove(AppConstants.keyUserEmail);
    await _prefs.setBool(AppConstants.keyIsLoggedIn, false);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LOGIN
  // ═══════════════════════════════════════════════════════════════════
  Future<bool> login({
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.login(
        email: email,
        password: password,
        role: role,
      );

      final token = response['token'] as String? ?? '';
      final rawData =
          _readMap(response['data']) ?? _readMap(response['user']) ?? {};

      if (rawData.isEmpty) {
        _error = 'Invalid response from server.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = _parseRoleUser(rawData);

      if (!_rolesMatch(user.role, role)) {
        _error = 'Invalid credentials for selected role.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _saveSession(user, token);
      _currentUser = user;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool _rolesMatch(String returnedRole, String expectedRole) {
    final r = returnedRole.toLowerCase().trim();
    final e = expectedRole.toLowerCase().trim();
    if (r == e) return true;
    if (r == 'customer' && e == AppConstants.roleUser) return true;
    if (r == AppConstants.roleUser && e == 'customer') return true;
    return false;
  }

  Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════
  //  REGISTER
  // ═══════════════════════════════════════════════════════════════════
  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (data['role'] == AppConstants.roleProvider) {
      _error = 'Provider accounts can only be created by a Tenant.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await _api.register(data);
      final token = response['token'] as String? ?? '';
      final rawData =
          _readMap(response['data']) ?? _readMap(response['user']) ?? {};
      final user = _parseRoleUser(rawData);

      await _saveSession(user, token);
      _currentUser = user;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  FORGOT PASSWORD
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
    required String role,
  }) async {
    if (role == AppConstants.roleProvider) {
      return {
        'success': false,
        'isProviderRole': true,
        'message': AppConstants.providerForgotMsg,
      };
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.forgotPassword(email: email, role: role);
      _isLoading = false;
      notifyListeners();
      return {
        'success': true,
        'isProviderRole': false,
        'message':
            response['message'] ?? 'Password reset link sent to your email.',
      };
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'isProviderRole': false, 'message': e.message};
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  LOGOUT
  // ═══════════════════════════════════════════════════════════════════
  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
    try {
      await _api.logout();
    } catch (_) {}
    await _clearSession();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  UPDATE PROFILE
  // ═══════════════════════════════════════════════════════════════════
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.updateProfile(data);
      final rawData = _readMap(response['data']) ?? _readMap(response['user']);

      if (rawData != null && rawData.isNotEmpty) {
        _currentUser = _parseRoleUser(rawData);
        await _prefs.setString(
            AppConstants.keyUserName, _currentUser!.fullName);
      } else {
        await refreshProfile();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CHANGE PASSWORD
  // ═══════════════════════════════════════════════════════════════════
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Refresh profile ───────────────────────────────────────────────────
  Future<void> refreshProfile() async {
    try {
      final response = await _api.getProfile();
      final rawData =
          _readMap(response['data']) ?? _readMap(response['user']) ?? {};
      if (rawData.isNotEmpty) {
        _currentUser = _parseRoleUser(rawData);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Clear error ───────────────────────────────────────────────────────
  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  UserModel _parseRoleUser(Map<String, dynamic> rawData) {
    final normalizedRole = UserModel.fromJson(rawData).role;
    switch (normalizedRole) {
      case AppConstants.roleAdmin:
        return AdminModel.fromJson(rawData);
      case AppConstants.roleTenant:
        return TenantModel.fromJson(rawData);
      case AppConstants.roleProvider:
        return ServiceProviderModel.fromJson(rawData);
      case AppConstants.roleUser:
      default:
        return UserModel.fromJson(rawData);
    }
  }

  // ── Upload profile image  ──────────────────────────────────────────────
  Future<String?> uploadTenantProfileImage(
    Uint8List imageBytes,
    String imageName,
  ) async {
    try {
      final imageUrl = await _api.uploadTenantImage(
        imageBytes: imageBytes,
        imageName: imageName.isNotEmpty ? imageName : 'profile.jpg',
      );
      return imageUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadUserProfileImage(
    Uint8List imageBytes,
    String imageName,
  ) async {
    try {
      final imageUrl = await _api.uploadUserImage(
        imageBytes: imageBytes,
        imageName: imageName.isNotEmpty ? imageName : 'user-profile.jpg',
      );

      return imageUrl;
    } catch (e) {
      rethrow;
    }
  }
}
