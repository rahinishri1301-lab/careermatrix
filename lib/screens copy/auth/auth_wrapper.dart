// lib/screens/auth/auth_wrapper.dart
//
// Drop this in as (or wrap) the app's initial widget so Career Matrix
// automatically:
//   - shows a splash/loading state while a saved session is checked
//   - goes straight to the existing dashboard if a valid session exists
//   - redirects to LoginScreen if not logged in, or if the session
//     has expired while the app was running
//
// This widget does NOT touch or redefine any existing dashboard code —
// it only decides which existing route/widget to show.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/auth_colors.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  /// Pass in the host app's existing dashboard/home widget so this
  /// module never needs to know its implementation details.
  final Widget dashboard;

  const AuthWrapper({super.key, required this.dashboard});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().tryAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.uninitialized:
        return const _SplashLoader();

      case AuthStatus.authenticated:
        return widget.dashboard;

      case AuthStatus.sessionExpired:
        // Show the message once, then fall through to login.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session has expired. Please log in again.'),
            ),
          );
        });
        return const LoginScreen();

      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
        return const LoginScreen();
    }
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AuthColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AuthColors.primaryBlue),
      ),
    );
  }
}
