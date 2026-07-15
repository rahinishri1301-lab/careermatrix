// lib/services/auth_service.dart
//
// PHASE 2 NOTE: The Node.js + Express + MongoDB backend does not exist
// yet, so every method below simulates a network round trip and
// returns believable mock data. Each method already has the real
// `http` call written out in a comment directly above it — when the
// backend is ready, delete the mock body and uncomment the real one.
//
// No other file in the app needs to change: AuthRepository only talks
// to this class's public methods.

import 'dart:async';
import 'dart:math';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

class AuthService {
  // final String _baseUrl = AppConstants.baseUrl;

  Future<AuthResponseModel> login({
    required String identifier, // email or phone
    required String password,
  }) async {
    await _simulateLatency();

    // ---- REAL IMPLEMENTATION (uncomment when backend is live) ----
    // final res = await http.post(
    //   Uri.parse('$_baseUrl${AppConstants.loginEndpoint}'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'identifier': identifier, 'password': password}),
    // );
    // final body = jsonDecode(res.body);
    // if (res.statusCode == 200) return AuthResponseModel.fromJson(body);
    // return AuthResponseModel.failure(body['message'] ?? 'Login failed');

    if (password.length < 8) {
      return AuthResponseModel.failure('Invalid credentials');
    }

    final user = UserModel(
      id: _fakeId(),
      fullName: 'Career Matrix User',
      email: identifier.contains('@') ? identifier : 'user@example.com',
      phone: identifier.contains('@') ? '+910000000000' : identifier,
      role: UserRole.student,
      isVerified: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    return AuthResponseModel(
      success: true,
      message: 'Login successful',
      user: user,
      accessToken: _fakeJwt(),
      refreshToken: _fakeJwt(),
      expiresAt: DateTime.now().add(AppConstants.mockSessionLifetime),
    );
  }

  Future<AuthResponseModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    await _simulateLatency();

    // ---- REAL IMPLEMENTATION ----
    // final res = await http.post(
    //   Uri.parse('$_baseUrl${AppConstants.registerEndpoint}'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'fullName': fullName,
    //     'email': email,
    //     'phone': phone,
    //     'password': password,
    //     'role': role.apiValue,
    //   }),
    // );
    // final body = jsonDecode(res.body);
    // if (res.statusCode == 201) return AuthResponseModel.fromJson(body);
    // return AuthResponseModel.failure(body['message'] ?? 'Registration failed');

    final user = UserModel(
      id: _fakeId(),
      fullName: fullName,
      email: email,
      phone: phone,
      role: role,
      isVerified: false,
      createdAt: DateTime.now(),
    );

    return AuthResponseModel(
      success: true,
      message: 'Registration successful',
      user: user,
      accessToken: _fakeJwt(),
      refreshToken: _fakeJwt(),
      expiresAt: DateTime.now().add(AppConstants.mockSessionLifetime),
    );
  }

  /// Step 1 of forgot-password flow: request an OTP.
  Future<AuthResponseModel> sendOtp({required String identifier}) async {
    await _simulateLatency();

    // ---- REAL IMPLEMENTATION ----
    // final res = await http.post(
    //   Uri.parse('$_baseUrl${AppConstants.forgotPasswordEndpoint}'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'identifier': identifier}),
    // );
    // ...

    return AuthResponseModel(
      success: true,
      message: 'OTP sent to $identifier',
    );
  }

  /// Step 2: verify the OTP the user typed in.
  Future<AuthResponseModel> verifyOtp({
    required String identifier,
    required String otp,
  }) async {
    await _simulateLatency();

    // ---- REAL IMPLEMENTATION ----
    // final res = await http.post(
    //   Uri.parse('$_baseUrl${AppConstants.verifyOtpEndpoint}'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'identifier': identifier, 'otp': otp}),
    // );
    // ...

    // Mock rule: any 6-digit code works so the flow is demoable offline.
    if (otp.length != AppConstants.otpLength) {
      return AuthResponseModel.failure('Invalid OTP');
    }
    return const AuthResponseModel(success: true, message: 'OTP verified');
  }

  /// Step 3: set the new password once OTP is verified.
  Future<AuthResponseModel> resetPassword({
    required String identifier,
    required String newPassword,
  }) async {
    await _simulateLatency();

    // ---- REAL IMPLEMENTATION ----
    // final res = await http.post(
    //   Uri.parse('$_baseUrl${AppConstants.resetPasswordEndpoint}'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'identifier': identifier, 'newPassword': newPassword}),
    // );
    // ...

    return const AuthResponseModel(
      success: true,
      message: 'Password reset successful',
    );
  }

  Future<void> logout({String? refreshToken}) async {
    await _simulateLatency(short: true);
    // ---- REAL IMPLEMENTATION ----
    // await http.post(
    //   Uri.parse('$_baseUrl${AppConstants.logoutEndpoint}'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'refreshToken': refreshToken}),
    // );
  }

  Future<void> _simulateLatency({bool short = false}) {
    final ms = short ? 300 : 700 + Random().nextInt(400);
    return Future.delayed(Duration(milliseconds: ms));
  }

  String _fakeId() =>
      DateTime.now().millisecondsSinceEpoch.toRadixString(16);

  String _fakeJwt() {
    // Not a real JWT — just a plausible-looking opaque token for the
    // mock layer. Replace with the token the real backend returns.
    final rand = Random();
    final part = List.generate(16, (_) => rand.nextInt(16).toRadixString(16))
        .join();
    return 'mock.$part.token';
  }
}
