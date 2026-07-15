// lib/routes/auth_routes.dart
//
// Merge this map into the host app's existing MaterialApp `routes`
// (see README "Step 4"). Does not remove or override any existing
// route names.

import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/role_selection_screen.dart';

final Map<String, WidgetBuilder> authRoutes = {
  LoginScreen.routeName: (_) => const LoginScreen(),
  RegisterScreen.routeName: (_) => const RegisterScreen(),
  ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
  OtpVerificationScreen.routeName: (_) => const OtpVerificationScreen(),
  ResetPasswordScreen.routeName: (_) => const ResetPasswordScreen(),
  RoleSelectionScreen.routeName: (_) => const RoleSelectionScreen(),
};
