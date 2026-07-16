import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/score_gauge.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import '../resume/resume_hub_screen.dart';
import '../skills/skill_gap_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text(
          "You'll need to sign in again to access your dashboard.",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) _logout();
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await AuthService.instance.logout();
    AppState.instance.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = MockData.currentStudent;
    final role = AppState.instance.currentRole.value;
    final displayName = AppState.instance.userName.value;

    return Stack(
      children: [
        SimpleScreenScaffold(
          title: 'My Profile',
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              Center(
                child: Column(
                  children: [
                    InitialsAvatar(initials: _initialsFor(displayName), size: 88),
                    const SizedBox(height: 14),
                    Text(displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                    const SizedBox(height: 4),
                    Text(user.title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                    const SizedBox(height: 10),
                   AppTag(label: 'Student', icon: Icons.verified_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(children: [
                        ScoreGauge(score: user.careerHealthScore, size: 66, color: AppColors.primary),
                        const SizedBox(height: 8),
                        const Text('Career Health', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: Column(children: [
                        ScoreGauge(score: user.placementReadiness, size: 66, color: AppColors.success),
                        const SizedBox(height: 8),
                        const Text('Placement Ready', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text('Account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileRow(icon: Icons.description_outlined, label: 'Resume & Portfolio', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResumeHubScreen()))),
                    const Divider(height: 1, indent: 56),
                    _ProfileRow(icon: Icons.grid_view_rounded, label: 'Skill Matrix', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SkillGapScreen()))),
                    const Divider(height: 1, indent: 56),
                    _ProfileRow(icon: Icons.school_outlined, label: 'Education Details', onTap: () {}),
                    const Divider(height: 1, indent: 56),
                    _ProfileRow(icon: Icons.emoji_events_outlined, label: 'Certificates & Achievements', onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _ProfileRow(icon: Icons.settings_outlined, label: 'Settings', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                    const Divider(height: 1, indent: 56),
                    _ProfileRow(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}),
                    const Divider(height: 1, indent: 56),
                    _ProfileRow(
                      icon: Icons.logout_rounded,
                      label: 'Log Out',
                      color: AppColors.danger,
                      onTap: _loggingOut ? null : _confirmLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_loggingOut)
          Container(
            color: Colors.black.withOpacity(0.15),
            child: const Center(
              child: SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  const _ProfileRow({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color ?? AppColors.textPrimary))),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
