// lib/repositories/auth_repository.dart
//
// Clean-architecture boundary: providers/UI never talk to AuthService
// or StorageService directly, only to this repository. This keeps the
// eventual swap to a real backend isolated to services/, and keeps
// providers/ free of any storage or networking detail.

import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';

class AuthRepository {
  final AuthService _authService;
  final StorageService _storageService;

  AuthRepository({
    AuthService? authService,
    StorageService? storageService,
  })  : _authService = authService ?? AuthService(),
        _storageService = storageService ?? StorageService();

  Future<AuthResponseModel> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) async {
    final response =
        await _authService.login(identifier: identifier, password: password);

    if (response.success &&
        response.user != null &&
        response.accessToken != null) {
      await _storageService.saveSession(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken,
        user: response.user!,
        rememberMe: rememberMe,
        expiresAt: response.expiresAt,
      );
    }
    return response;
  }

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    final response = await _authService.register(
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
      role: role,
    );

    if (response.success &&
        response.user != null &&
        response.accessToken != null) {
      await _storageService.saveSession(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken,
        user: response.user!,
        rememberMe: true,
        expiresAt: response.expiresAt,
      );
    }
    return response;
  }

  Future<AuthResponseModel> sendOtp(String identifier) =>
      _authService.sendOtp(identifier: identifier);

  Future<AuthResponseModel> verifyOtp({
    required String identifier,
    required String otp,
  }) =>
      _authService.verifyOtp(identifier: identifier, otp: otp);

  Future<AuthResponseModel> resetPassword({
    required String identifier,
    required String newPassword,
  }) =>
      _authService.resetPassword(
        identifier: identifier,
        newPassword: newPassword,
      );

  Future<void> logout() async {
    final refreshToken = await _storageService.getRefreshToken();
    await _authService.logout(refreshToken: refreshToken);
    await _storageService.clearSession();
  }

  /// Called on app startup. Returns the persisted user if the session
  /// is still valid, otherwise clears storage and returns null so the
  /// UI can redirect to the login screen.
  Future<UserModel?> restoreSession() async {
    final isValid = await _storageService.isSessionValid();
    if (!isValid) {
      await _storageService.clearSession();
      return null;
    }
    return _storageService.getUser();
  }

  Future<bool> hasRememberedSession() => _storageService.getRememberMe();

  Future<int> get otpLength async => AppConstants.otpLength;
}
