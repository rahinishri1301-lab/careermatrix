import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../widgets/app_bottom_nav.dart';
import '../auth/login_screen.dart';
import 'student_dashboard.dart';
import 'alumni_dashboard.dart';
import 'mentor_dashboard.dart';
import 'company_dashboard.dart';
import 'admin_dashboard.dart';
import '../jobs/job_portal_screen.dart';
import '../mentor/mentor_connect_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import '../company/company_portal_screen.dart';

/// The root shell shown after login/registration. Provides a role-aware
/// bottom navigation bar so every core feature is reachable in 1 tap from
/// here (2-3 taps from anywhere in the app).
///
/// Also acts as the app's protected-route boundary: every dashboard and
/// everything reachable from it lives behind this widget, and this widget
/// refuses to render dashboard content unless [AppState.isAuthenticated] is
/// true — falling back to [LoginScreen] otherwise. In normal use this guard
/// never fires (Splash/Login/Register all set the session before navigating
/// here), but it protects against any future code path reaching this route
/// without an active session.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppState.instance.isAuthenticated,
      builder: (context, authenticated, _) {
        if (!authenticated) {
          // No active session — redirect to Login instead of exposing any
          // dashboard content.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildShell(context);
      },
    );
  }

  Widget _buildShell(BuildContext context) {
    return ValueListenableBuilder<UserRole>(
      valueListenable: AppState.instance.currentRole,
      builder: (context, role, _) {
        final config = _shellFor(role);
        final safeIndex = _index < config.pages.length ? _index : 0;
        return Scaffold(
          body: IndexedStack(index: safeIndex, children: config.pages),
          bottomNavigationBar: AppBottomNav(
            currentIndex: safeIndex,
            items: config.items,
            onTap: (i) => setState(() => _index = i),
          ),
        );
      },
    );
  }

  _ShellConfig _shellFor(UserRole role) {
    switch (role) {
      case UserRole.student:
        return _ShellConfig(
          pages: const [
            StudentDashboard(),
            JobPortalScreen(),
            MentorConnectScreen(),
            CommunityScreen(),
            ProfileScreen(),
          ],
          items: const [
            NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
            NavItem(icon: Icons.work_outline_rounded, activeIcon: Icons.work_rounded, label: 'Opportunities'),
            NavItem(icon: Icons.diversity_3_outlined, activeIcon: Icons.diversity_3_rounded, label: 'Mentors'),
            NavItem(icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Community'),
            NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ],
        );
      case UserRole.alumni:
        return _ShellConfig(
          pages: const [
            AlumniDashboard(),
            MentorConnectScreen(),
            CommunityScreen(),
            ProfileScreen(),
          ],
          items: const [
            NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
            NavItem(icon: Icons.diversity_3_outlined, activeIcon: Icons.diversity_3_rounded, label: 'Mentees'),
            NavItem(icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Community'),
            NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ],
        );
      case UserRole.mentor:
        return _ShellConfig(
          pages: const [
            MentorDashboard(),
            CommunityScreen(),
            ProfileScreen(),
          ],
          items: const [
            NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
            NavItem(icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Community'),
            NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ],
        );
      case UserRole.company:
        return _ShellConfig(
          pages: const [
            CompanyDashboard(),
            CompanyPortalScreen(),
            CommunityScreen(),
            ProfileScreen(),
          ],
          items: const [
            NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
            NavItem(icon: Icons.business_center_outlined, activeIcon: Icons.business_center_rounded, label: 'Portal'),
            NavItem(icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Community'),
            NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ],
        );
      case UserRole.admin:
        return _ShellConfig(
          pages: const [
            AdminDashboard(),
            CommunityScreen(),
            ProfileScreen(),
          ],
          items: const [
            NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
            NavItem(icon: Icons.forum_outlined, activeIcon: Icons.forum_rounded, label: 'Community'),
            NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
          ],
        );
    }
  }
}

class _ShellConfig {
  final List<Widget> pages;
  final List<NavItem> items;
  const _ShellConfig({required this.pages, required this.items});
}
