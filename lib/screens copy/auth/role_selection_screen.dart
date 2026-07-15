// lib/screens/auth/role_selection_screen.dart
import 'package:flutter/material.dart';
import '../../config/auth_colors.dart';
import '../../utils/app_constants.dart';

/// Standalone role picker. Used by RegisterScreen (as a modal-style
/// push that returns a [UserRole]), but can also be pushed on its own
/// if the host app wants a dedicated "choose your role" step right
/// after signup / first launch.
class RoleSelectionScreen extends StatefulWidget {
  static const routeName = '/auth/role-selection';

  final UserRole? initialRole;

  const RoleSelectionScreen({super.key, this.initialRole});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;

  static const _roleInfo = <UserRole, ({IconData icon, String description})>{
    UserRole.student: (
      icon: Icons.school_outlined,
      description: 'Explore opportunities, courses, and mentors',
    ),
    UserRole.alumni: (
      icon: Icons.workspace_premium_outlined,
      description: 'Stay connected and support current students',
    ),
    UserRole.mentor: (
      icon: Icons.diversity_3_outlined,
      description: 'Guide students and share your expertise',
    ),
    UserRole.company: (
      icon: Icons.apartment_outlined,
      description: 'Post jobs and hire top talent',
    ),
    UserRole.administrator: (
      icon: Icons.admin_panel_settings_outlined,
      description: 'Manage users, content, and platform settings',
    ),
  };

  @override
  void initState() {
    super.initState();
    _selected = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.background,
      appBar: AppBar(
        backgroundColor: AuthColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AuthColors.textPrimary),
        title: const Text(
          'Select Your Role',
          style: TextStyle(color: AuthColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose how you\'ll use Career Matrix',
                  style: TextStyle(
                    fontSize: 14,
                    color: AuthColors.textSecondary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: UserRole.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final role = UserRole.values[index];
                  final info = _roleInfo[role]!;
                  final isSelected = _selected == role;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selected = role),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AuthColors.lightBlue
                            : AuthColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AuthColors.primaryBlue
                              : AuthColors.border,
                          width: isSelected ? 1.6 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AuthColors.primaryBlue
                                  : AuthColors.lightBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              info.icon,
                              color: isSelected
                                  ? AuthColors.white
                                  : AuthColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AuthColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  info.description,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AuthColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isSelected
                                ? AuthColors.primaryBlue
                                : AuthColors.border,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthColors.primaryBlue,
                    disabledBackgroundColor:
                        AuthColors.primaryBlue.withOpacity(0.4),
                    foregroundColor: AuthColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
