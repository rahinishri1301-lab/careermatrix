// lib/models/auth_response_model.dart
import 'user_model.dart';

/// Wraps whatever the backend returns from login/register/refresh calls.
/// Once the Node/Express/MongoDB backend issues real JWTs, [fromJson]
/// is the only thing that needs to change.
class AuthResponseModel {
  final bool success;
  final String message;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const AuthResponseModel({
    required this.success,
    required this.message,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      accessToken: json['accessToken'] ?? json['token'],
      refreshToken: json['refreshToken'],
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'])
          : null,
    );
  }

  factory AuthResponseModel.failure(String message) {
    return AuthResponseModel(success: false, message: message);
  }
}
