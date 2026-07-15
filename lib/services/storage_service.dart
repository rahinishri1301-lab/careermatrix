// lib/services/storage_service.dart
//
// Thin wrapper around SharedPreferences so the rest of the app never
// talks to SharedPreferences directly. Swap the implementation for
// flutter_secure_storage later if you want tokens off plain prefs —
// nothing outside this file would need to change.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

class StorageService {
  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    required UserModel user,
    required bool rememberMe,
    DateTime? expiresAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyAuthToken, accessToken);
    if (refreshToken != null) {
      await prefs.setString(AppConstants.keyRefreshToken, refreshToken);
    }
    await prefs.setString(AppConstants.keyUser, jsonEncode(user.toJson()));
    await prefs.setBool(AppConstants.keyRememberMe, rememberMe);
    if (expiresAt != null) {
      await prefs.setString(
        AppConstants.keyTokenExpiry,
        expiresAt.toIso8601String(),
      );
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyAuthToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyRefreshToken);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyRememberMe) ?? false;
  }

  /// Returns true if a stored token exists and has not passed its
  /// expiry timestamp. With no real backend yet this is what powers
  /// the "auto redirect to login if session expires" requirement.
  Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAuthToken);
    if (token == null || token.isEmpty) return false;

    final expiryRaw = prefs.getString(AppConstants.keyTokenExpiry);
    if (expiryRaw == null) return true; // no expiry info -> assume valid
    final expiry = DateTime.tryParse(expiryRaw);
    if (expiry == null) return true;
    return DateTime.now().isBefore(expiry);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyAuthToken);
    await prefs.remove(AppConstants.keyRefreshToken);
    await prefs.remove(AppConstants.keyUser);
    await prefs.remove(AppConstants.keyTokenExpiry);
    // keyRememberMe is intentionally kept so the login screen can
    // pre-check "Remember Me" the next time the user visits.
  }
}
