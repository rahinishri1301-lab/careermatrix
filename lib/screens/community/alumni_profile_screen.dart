import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

/// Views ANOTHER user's (alumni) profile — never the logged-in student's
/// own cached profile. Always fetches fresh via GET /api/profile/:userId
/// using the alumni's real User._id passed in from the directory list.
class AlumniProfileScreen extends StatefulWidget {
  final String userId;
  final String name;
  const AlumniProfileScreen({super.key, required this.userId, required this.name});

  @override
  State<AlumniProfileScreen> createState() => _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends State<AlumniProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = BackendRepository.instance.getUserProfileRaw(widget.userId);
  }

  void _reload() {
    setState(() => _profileFuture = BackendRepository.instance.getUserProfileRaw(widget.userId));
  }

  Future<void> _sendMessage() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Message ${widget.name}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ask about their career path, request guidance, etc.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true || controller.text.trim().isEmpty) return;

    setState(() => _sending = true);
    try {
      final conversationId = await BackendRepository.instance.startConversation(widget.userId);
      await BackendRepository.instance.sendChatMessage(conversationId, controller.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message sent to ${widget.name}'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: widget.name,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
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
                    ElevatedButton(onPressed: _reload, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data;
          final currentPosition = profile?['currentPosition'] as String? ?? '';
          final company = profile?['company'] as String? ?? '';
          final bio = profile?['bio'] as String? ?? '';
          final graduationYear = (profile?['graduationYear'] as num?)?.toString();
          final linkedin = profile?['linkedin'] as String?;
          final github = profile?['github'] as String?;
          final titleLine = [currentPosition, company].where((s) => s.isNotEmpty).join(' at ');
          final initials = _initialsFor(widget.name);

          final userObj = profile?['user'] as Map<String, dynamic>?;
          final roleKey = userObj?['role'] as String? ?? 'alumni';
          final role = UserRoleX.fromKey(roleKey);

          String? profileImageUrl;
          final imgPath = profile?['profileImage'] as String? ?? '';
          if (imgPath.isNotEmpty) {
            final cleanPath = imgPath.startsWith('/') ? imgPath : '/$imgPath';
            profileImageUrl = '${AppConfig.fileBaseUrl}$cleanPath';
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              Center(
                child: Column(
                  children: [
                    ProfileAvatar(initials: initials, imageUrl: profileImageUrl, size: 88),
                    const SizedBox(height: 14),
                    Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                    const SizedBox(height: 4),
                    Text(
                      titleLine.isNotEmpty ? titleLine : 'Career Matrix ${role.label}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                    ),
                    const SizedBox(height: 10),
                    AppTag(label: role.label, icon: Icons.verified_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (profile == null)
                EmptyState(
                  icon: Icons.person_outline_rounded,
                  title: 'No profile details yet',
                  subtitle: 'This ${role.key} hasn\'t filled in their profile yet — you can still send them a message.',
                )
              else ...[
                if (bio.isNotEmpty) ...[
                  const Text('About', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  AppCard(child: Text(bio, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.5))),
                  const SizedBox(height: 20),
                ],
                const Text('Professional Info', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _InfoRow(icon: Icons.business_center_outlined, label: 'Position', value: currentPosition.isNotEmpty ? currentPosition : '—'),
                      const Divider(height: 1, indent: 56),
                      _InfoRow(icon: Icons.apartment_rounded, label: 'Company', value: company.isNotEmpty ? company : '—'),
                      if (graduationYear != null) ...[
                        const Divider(height: 1, indent: 56),
                        _InfoRow(icon: Icons.school_outlined, label: 'Graduation Year', value: graduationYear),
                      ],
                    ],
                  ),
                ),
                if (linkedin != null || github != null) ...[
                  const SizedBox(height: 20),
                  const Text('Links', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        if (linkedin != null) _InfoRow(icon: Icons.link_rounded, label: 'LinkedIn', value: linkedin),
                        if (linkedin != null && github != null) const Divider(height: 1, indent: 56),
                        if (github != null) _InfoRow(icon: Icons.code_rounded, label: 'GitHub', value: github),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 26),
              LoadingElevatedButton(
                loading: _sending,
                onPressed: _sendMessage,
                child: const Text('Send Message'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
