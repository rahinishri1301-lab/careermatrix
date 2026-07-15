// lib/widgets/auth/social_login_button.dart
//
// Placeholders only, per Phase 2 scope. When Google / LinkedIn OAuth
// is wired up, replace the onPressed body with the real sign-in call
// and route the resulting token through AuthRepository the same way
// email/password login does.

import 'package:flutter/material.dart';
import '../../config/auth_colors.dart';

enum SocialProvider { google, linkedin }

class SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback? onPressed;

  const SocialLoginButton({
    super.key,
    required this.provider,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isGoogle = provider == SocialProvider.google;
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${isGoogle ? "Google" : "LinkedIn"} login coming soon',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AuthColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isGoogle ? Icons.g_mobiledata_rounded : Icons.business_center_rounded,
              color: isGoogle ? AuthColors.error : AuthColors.primaryBlue,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              isGoogle ? 'Google' : 'LinkedIn',
              style: const TextStyle(
                color: AuthColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
