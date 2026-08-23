import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/score_gauge.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import '../resume/resume_hub_screen.dart';
import '../skills/skill_gap_screen.dart';
import '../placement/placement_history_screen.dart';
import '../mentor/mentorship_requests_screen.dart';
import '../jobs/my_applications_screen.dart';
import 'education_screen.dart';
import 'certificates_screen.dart';
import 'edit_profile_screen.dart';
import '../company/edit_company_profile_screen.dart';
import '../company/company_portal_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;
  bool _uploadingPhoto = false;
  late Future<AppUser> _userFuture;
  late Future<Map<String, dynamic>?> _profileRawFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _userFuture = BackendRepository.instance.getMyAppUser();
    _profileRawFuture = BackendRepository.instance.getMyProfileRaw();
  }

  Future<void> _pickAndUploadPhoto() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected image. Please try again.'), backgroundColor: AppColors.danger),
        );
      }
      return;
    }
    setState(() => _uploadingPhoto = true);
    try {
      try {
        await BackendRepository.instance.uploadProfileImage(file.bytes!, file.name);
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          await BackendRepository.instance.saveProfile(const <String, dynamic>{});
          await BackendRepository.instance.uploadProfileImage(file.bytes!, file.name);
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company logo updated'), backgroundColor: AppColors.success),
      );
      setState(() => _refreshData());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

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
    final role = AppState.instance.currentRole.value;

    return Stack(
      children: [
        SimpleScreenScaffold(
          title: role == UserRole.company ? 'Company Profile' : 'My Profile',
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Profile',
              onPressed: () async {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => role == UserRole.company
                        ? const EditCompanyProfileScreen()
                        : const EditProfileScreen(),
                  ),
                );
                if (updated == true) {
                  setState(() => _refreshData());
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
          body: FutureBuilder<AppUser>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() => _refreshData()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final user = snapshot.data!;
              final displayName = user.name;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _profileRawFuture,
                builder: (context, profileSnap) {
                  final profile = profileSnap.data;
                  final companyName = (profile?['company'] as String?)?.isNotEmpty == true
                      ? profile!['company'] as String
                      : displayName;
                  final industry = (profile?['industry'] as String?) ?? 'Company';
                  final location = (profile?['address'] as String?) ?? 'Location not specified';
                  final description = (profile?['description'] as String?) ?? (profile?['bio'] as String?) ?? 'No company description added yet.';
                  final website = (profile?['website'] as String?) ?? '';
                  final phone = (profile?['phone'] as String?) ?? '';
                  final email = AppState.instance.userEmail.value;

                  String? avatarUrl = user.avatarUrl;
                  final imgPath = profile?['profileImage'] as String?;
                  if (imgPath != null && imgPath.trim().isNotEmpty) {
                    final clean = imgPath.trim().replaceAll('\\', '/');
                    avatarUrl = clean.startsWith('http')
                        ? clean
                        : '${AppConfig.fileBaseUrl}/${clean.startsWith('/') ? clean.substring(1) : clean}';
                  }

                  if (role == UserRole.company) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  InitialsAvatar(
                                    initials: _initialsFor(companyName),
                                    imageUrl: avatarUrl,
                                    size: 90,
                                    gradient: AppColors.roleGradient('company'),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                                      child: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                        child: _uploadingPhoto
                                            ? const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                              )
                                            : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(companyName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppTag(label: industry, icon: Icons.business_rounded, bg: AppColors.primarySoft, fg: AppColors.primary),
                                  const SizedBox(width: 8),
                                  AppTag(label: 'Verified Employer', icon: Icons.verified_rounded, bg: AppColors.successSoft, fg: AppColors.success),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final updated = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(builder: (_) => const EditCompanyProfileScreen()),
                            );
                            if (updated == true) setState(() => _refreshData());
                          },
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text('Edit Company Details'),
                        ),
                        const SizedBox(height: 20),
                        const Text('About Company', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 10),
                        AppCard(
                          child: Text(
                            description,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.45),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text('Company Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 10),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              if (website.isNotEmpty)
                                _ProfileRow(
                                  icon: Icons.language_rounded,
                                  label: website,
                                  onTap: () {},
                                ),
                              if (website.isNotEmpty) const Divider(height: 1, indent: 56),
                              if (email.isNotEmpty)
                                _ProfileRow(
                                  icon: Icons.email_outlined,
                                  label: email,
                                  onTap: () {},
                                ),
                              if (email.isNotEmpty && phone.isNotEmpty) const Divider(height: 1, indent: 56),
                              if (phone.isNotEmpty)
                                _ProfileRow(
                                  icon: Icons.phone_outlined,
                                  label: phone,
                                  onTap: () {},
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text('Company Options', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 10),
                        AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _ProfileRow(
                                icon: Icons.business_center_outlined,
                                label: 'Company Portal & Candidate Search',
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompanyPortalScreen())),
                              ),
                              const Divider(height: 1, indent: 56),
                              _ProfileRow(
                                icon: Icons.post_add_rounded,
                                label: 'Post New Opportunity',
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompanyPortalScreen(initialTab: 1))),
                              ),
                              const Divider(height: 1, indent: 56),
                              _ProfileRow(
                                icon: Icons.settings_outlined,
                                label: 'Settings',
                                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                              ),
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
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                InitialsAvatar(
                                  initials: _initialsFor(displayName),
                                  imageUrl: avatarUrl,
                                  size: 88,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                      child: _uploadingPhoto
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            )
                                          : const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                            const SizedBox(height: 4),
                            Text(user.title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
                            const SizedBox(height: 10),
                            AppTag(label: role.label, icon: Icons.verified_rounded),
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
                            _ProfileRow(icon: Icons.workspace_premium_outlined, label: 'Placement History', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlacementHistoryScreen()))),
                            _ProfileRow(icon: Icons.diversity_3_rounded, label: 'Mentorship Requests', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentorshipRequestsScreen()))),
                            _ProfileRow(icon: Icons.history_rounded, label: 'My Applications', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyApplicationsScreen()))),
                            const Divider(height: 1, indent: 56),
                            _ProfileRow(icon: Icons.school_outlined, label: 'Education Details', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EducationScreen()))),
                            const Divider(height: 1, indent: 56),
                            _ProfileRow(icon: Icons.emoji_events_outlined, label: 'Certificates & Achievements', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CertificatesScreen()))),
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
                  );
                },
              );
            },
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
