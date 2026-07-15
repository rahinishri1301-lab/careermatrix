// lib/widgets/auth/logout_button.dart
//
// The only widget from this module meant to be placed inside an
// EXISTING dashboard/profile screen (e.g. in a drawer, app bar menu,
// or settings list). It does not alter any dashboard layout — you
// place it wherever a logout action already belongs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/auth_colors.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';

Future<void> _performLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Log out',
              style: TextStyle(color: AuthColors.error)),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  await context.read<AuthProvider>().logout();
  if (!context.mounted) return;

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// Icon-button variant, e.g. for an AppBar action.
class LogoutIconButton extends StatelessWidget {
  const LogoutIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded),
      tooltip: 'Logout',
      onPressed: () => _performLogout(context),
    );
  }
}

/// ListTile variant, e.g. for a Drawer or settings screen.
class LogoutListTile extends StatelessWidget {
  const LogoutListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout_rounded, color: AuthColors.error),
      title: const Text('Logout', style: TextStyle(color: AuthColors.error)),
      onTap: () => _performLogout(context),
    );
  }
}
