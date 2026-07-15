// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../utils/app_constants.dart';

enum AuthStatus {
  uninitialized, // app just started, checking for saved session
  authenticating, // request in flight
  authenticated,
  unauthenticated,
  sessionExpired, // was logged in, session died -> show a message once
}

/// Single source of truth for auth state. Wire this into the existing
/// app's MultiProvider in main.dart (see README for the exact snippet)
/// — no existing providers need to be touched.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _currentUser;
  String? _errorMessage;
  bool _rememberMe = false;

  // Temporary holder for the multi-step forgot-password flow.
  String? _pendingIdentifier;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.authenticating;
  String? get pendingIdentifier => _pendingIdentifier;

  /// Call once from a splash screen / app root to silently restore a
  /// saved session, or fall through to the login screen.
  Future<void> tryAutoLogin() async {
    _status = AuthStatus.uninitialized;
    notifyListeners();

    final user = await _repository.restoreSession();
    if (user != null) {
      _currentUser = user;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Called by any screen/service if a protected call comes back
  /// unauthorized — clears state and routes back to login.
  Future<void> handleSessionExpired() async {
    await _repository.logout();
    _currentUser = null;
    _status = AuthStatus.sessionExpired;
    notifyListeners();
  }

  Future<bool> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    _setLoading();
    _rememberMe = rememberMe;

    final response = await _repository.login(
      identifier: identifier,
      password: password,
      rememberMe: rememberMe,
    );

    if (response.success && response.user != null) {
      _currentUser = response.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    _status = AuthStatus.unauthenticated;
    _errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Login failed. Please try again.';
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    _setLoading();

    final response = await _repository.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );

    if (response.success && response.user != null) {
      _currentUser = response.user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    _status = AuthStatus.unauthenticated;
    _errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Registration failed. Please try again.';
    notifyListeners();
    return false;
  }

  Future<bool> sendOtp(String identifier) async {
    _setLoading(keepStatusOnFail: true);
    final response = await _repository.sendOtp(identifier);
    _errorMessage = response.success ? null : response.message;
    if (response.success) _pendingIdentifier = identifier;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return response.success;
  }

  Future<bool> verifyOtp(String otp) async {
    if (_pendingIdentifier == null) return false;
    _setLoading(keepStatusOnFail: true);
    final response = await _repository.verifyOtp(
      identifier: _pendingIdentifier!,
      otp: otp,
    );
    _errorMessage = response.success ? null : response.message;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return response.success;
  }

  Future<bool> resetPassword(String newPassword) async {
    if (_pendingIdentifier == null) return false;
    _setLoading(keepStatusOnFail: true);
    final response = await _repository.resetPassword(
      identifier: _pendingIdentifier!,
      newPassword: newPassword,
    );
    _errorMessage = response.success ? null : response.message;
    _status = AuthStatus.unauthenticated;
    _pendingIdentifier = null;
    notifyListeners();
    return response.success;
  }

  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading({bool keepStatusOnFail = false}) {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
  }
}
