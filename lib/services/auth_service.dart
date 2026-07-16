import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Handles authentication session persistence.
///
/// This is a frontend-only mock: `login()`/`register()` simulate a network
/// call with a short delay and always succeed once form validation passes.
/// Swap the body of [login]/[register] for real API calls when the backend
/// is ready — the session-persistence contract (save/restore/clear) stays
/// the same.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kLoggedIn = 'auth_logged_in';
  static const _kRole = 'auth_role';
  static const _kName = 'auth_name';
  static const _kEmail = 'auth_email';

  /// Simulates an authentication call. Returns after a short delay so the
  /// UI can show a loading state, matching a real network round-trip.
  Future<void> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final name = _nameFromEmail(email);
    await _saveSession(role: role, name: name, email: email);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    await _saveSession(role: role, name: name, email: email);
  }

  /// Clears the persisted session. Called on logout.
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kRole);
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
  }

  /// Restores a previously persisted session, if any. Used for auto-login
  /// on app start.
  Future<AuthSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_kLoggedIn) ?? false;
    if (!loggedIn) return null;

    final roleKey = prefs.getString(_kRole);
    final role = UserRole.values.firstWhere(
      (r) => r.key == roleKey,
      orElse: () => UserRole.student,
    );
    final name = prefs.getString(_kName) ?? 'Guest User';
    final email = prefs.getString(_kEmail) ?? '';
    return AuthSession(role: role, name: name, email: email);
  }

  Future<void> _saveSession({
    required UserRole role,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kRole, role.key);
    await prefs.setString(_kName, name);
    await prefs.setString(_kEmail, email);
  }

  String _nameFromEmail(String email) {
    final handle = email.split('@').first.replaceAll(RegExp(r'[._]'), ' ').trim();
    if (handle.isEmpty) return 'Guest User';
    return handle
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class AuthSession {
  final UserRole role;
  final String name;
  final String email;
  const AuthSession({required this.role, required this.name, required this.email});
}
