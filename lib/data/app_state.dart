import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Minimal global app state — deliberately dependency-free (no provider /
/// riverpod) since this is a frontend-only scaffold. Swap for your preferred
/// state management solution when wiring up the backend.
class AppState {
  AppState._();
  static final AppState instance = AppState._();

  static const _kDarkModeKey = 'dark_mode_enabled';

  final ValueNotifier<UserRole> currentRole = ValueNotifier(UserRole.student);
  final ValueNotifier<bool> onboardingSeen = ValueNotifier(false);

  /// Real, persisted theme-mode state (see settings_screen.dart's Dark
  /// Mode toggle and main.dart's MaterialApp). Loaded from SharedPreferences
  /// on startup via [loadThemePreference], so it survives app restarts.
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  /// True once a session has been established (via login, registration, or
  /// auto-login on app start) and cleared again on logout. HomeShell (and
  /// anything reached through it) treats this as the source of truth for
  /// route protection.
  final ValueNotifier<bool> isAuthenticated = ValueNotifier(false);
  final ValueNotifier<String> userName = ValueNotifier('Guest User');
  final ValueNotifier<String> userEmail = ValueNotifier('');

  void applySession({required UserRole role, required String name, required String email}) {
    currentRole.value = role;
    userName.value = name;
    userEmail.value = email;
    isAuthenticated.value = true;
  }

  void clearSession() {
    isAuthenticated.value = false;
    userName.value = 'Guest User';
    userEmail.value = '';
  }

  /// Call once at app startup (before runApp, or in the splash screen)
  /// to restore the persisted dark-mode preference.
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kDarkModeKey) ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, enabled);
  }
}
