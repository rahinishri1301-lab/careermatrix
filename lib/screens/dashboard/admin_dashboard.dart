import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(gradient: AppColors.roleGradient('admin'), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ecosystem Overview', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                      Text('Admin Console', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Notifications',
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: const [
                _StatBlock(value: '12.4K', label: 'Students', icon: Icons.school_rounded, color: AppColors.primary),
                _StatBlock(value: '3.1K', label: 'Alumni', icon: Icons.workspace_premium_rounded, color: AppColors.accentIndigo),
                _StatBlock(value: '640', label: 'Mentors', icon: Icons.diversity_3_rounded, color: AppColors.accentCyan),
                _StatBlock(value: '218', label: 'Companies', icon: Icons.apartment_rounded, color: AppColors.success),
              ],
            ),
            const SizedBox(height: 22),
            const Text('Platform Health', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  _MetricRow(label: 'Placement Success Rate', value: 0.78, color: AppColors.success),
                  const SizedBox(height: 14),
                  _MetricRow(label: 'Mentor Session Completion', value: 0.86, color: AppColors.primary),
                  const SizedBox(height: 14),
                  _MetricRow(label: 'Avg. Career Health Score', value: 0.72, color: AppColors.accentIndigo),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('Management', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 14),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ManageRow(icon: Icons.people_alt_rounded, label: 'Manage Users & Roles'),
                  const Divider(height: 1, indent: 56),
                  _ManageRow(icon: Icons.verified_user_rounded, label: 'Verify Alumni & Mentors'),
                  const Divider(height: 1, indent: 56),
                  _ManageRow(icon: Icons.flag_rounded, label: 'Content Moderation'),
                  const Divider(height: 1, indent: 56),
                  _ManageRow(
                    icon: Icons.bar_chart_rounded,
                    label: 'Analytics & Reports',
                  ),
                  const Divider(height: 1, indent: 56),
                  _ManageRow(icon: Icons.settings_rounded, label: 'System Settings', isNav: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatBlock({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _MetricRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text('${(value * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(value: value, minHeight: 8, backgroundColor: AppColors.surfaceMuted, valueColor: AlwaysStoppedAnimation(color)),
        ),
      ],
    );
  }
}

class _ManageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isNav;
  const _ManageRow({required this.icon, required this.label, this.isNav = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (isNav) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
