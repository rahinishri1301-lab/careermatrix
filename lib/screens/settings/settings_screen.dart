import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _push = true;
  bool _email = true;
  bool _jobAlerts = true;
  bool _mentorAlerts = false;

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SwitchRow(title: 'Push Notifications', value: _push, onChanged: (v) => setState(() => _push = v)),
                const Divider(height: 1, indent: 16),
                _SwitchRow(title: 'Email Updates', value: _email, onChanged: (v) => setState(() => _email = v)),
                const Divider(height: 1, indent: 16),
                _SwitchRow(title: 'Job & Internship Alerts', value: _jobAlerts, onChanged: (v) => setState(() => _jobAlerts = v)),
                const Divider(height: 1, indent: 16),
                _SwitchRow(title: 'Mentor Session Reminders', value: _mentorAlerts, onChanged: (v) => setState(() => _mentorAlerts = v)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            // Real, persisted theme toggle — see AppState.themeMode /
            // setDarkMode, applied globally via the MaterialApp in
            // main.dart. Note: most screens in this app read colors from
            // the static AppColors class directly rather than
            // Theme.of(context), so this correctly switches default
            // Material chrome (buttons, inputs, app bars, dividers) but
            // most custom-styled screens will keep their light-mode look
            // until they're migrated to theme-driven colors.
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: AppState.instance.themeMode,
              builder: (context, mode, _) {
                final isDark = mode == ThemeMode.dark;
                return _SwitchRow(
                  title: 'Dark Mode',
                  subtitle: isDark
                      ? 'Applies to system UI elements app-wide'
                      : 'Career Matrix looks best in Light mode',
                  value: isDark,
                  onChanged: (v) => AppState.instance.setDarkMode(v),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text('About', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: _NavRow(title: 'App Version', trailing: 'v1.0.0', onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Career Matrix',
              applicationVersion: '1.0.0',
              applicationLegalese: 'AI-Based Alumni Mentorship and Placement Support Platform',
            )),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({required this.title, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: AppColors.primary),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _NavRow({required this.title, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
            if (trailing != null) Text(trailing!, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
