import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../community/community_screen.dart';
import '../mentor/mentorship_requests_screen.dart';

class _MentorDashboardData {
  final List<MentorshipRequestItem> pendingRequests;
  final double rating;
  final int activeMentees;
  final List<_UpcomingSession> upcomingSessions;
  const _MentorDashboardData({
    required this.pendingRequests,
    required this.rating,
    required this.activeMentees,
    required this.upcomingSessions,
  });
}

class _UpcomingSession {
  final String studentName;
  final String topic;
  final String time;
  const _UpcomingSession({required this.studentName, required this.topic, required this.time});
}

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  late Future<_MentorDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _reload() => setState(() => _future = _load());

  Future<_MentorDashboardData> _load() async {
    // Independent calls fired together (not sequentially) for a fast
    // dashboard load. Each has its own fallback so one failing endpoint
    // (e.g. "not registered as a mentor yet" -> 404) doesn't blank the
    // whole dashboard.
    final results = await Future.wait([
      BackendRepository.instance.getReceivedMentorshipRequests().catchError((_) => <MentorshipRequestItem>[]),
      BackendRepository.instance.getMyMentorProfile().catchError((_) => <String, dynamic>{}),
      BackendRepository.instance.getBookingHistory().catchError((_) => <String, List<Map<String, dynamic>>>{}),
    ]);

    final allRequests = results[0] as List<MentorshipRequestItem>;
    final mentorProfile = results[1] as Map<String, dynamic>;
    final bookings = results[2] as Map<String, List<Map<String, dynamic>>>;

    final pending = allRequests.where((r) => r.status == 'Pending').take(3).toList();
    final activeMentees = allRequests.where((r) => r.status == 'Accepted').length;
    final rating = (mentorProfile['rating'] as num?)?.toDouble() ?? 0.0;

    final asMentor = bookings['asMentor'] ?? const [];
    final now = DateTime.now();
    final upcoming = asMentor
        .where((b) => b['status'] != 'Cancelled' && b['status'] != 'Completed')
        .map((b) {
          final student = b['student'] as Map<String, dynamic>?;
          final dateStr = b['sessionDate'] as String?;
          final date = dateStr != null ? DateTime.tryParse(dateStr) : null;
          return (
            date: date,
            session: _UpcomingSession(
              studentName: student?['name'] as String? ?? 'Student',
              topic: (b['topic'] as String?)?.trim().isNotEmpty == true ? b['topic'] as String : 'Mentorship session',
              time: b['sessionTime'] as String? ?? '',
            ),
          );
        })
        .where((e) => e.date == null || !e.date!.isBefore(DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => (a.date ?? now).compareTo(b.date ?? now));

    return _MentorDashboardData(
      pendingRequests: pending,
      rating: rating,
      activeMentees: activeMentees,
      upcomingSessions: upcoming.take(3).map((e) => e.session).toList(),
    );
  }

  Future<void> _respond(String id, bool accept) async {
    try {
      if (accept) {
        await BackendRepository.instance.acceptMentorshipRequest(id);
      } else {
        await BackendRepository.instance.rejectMentorshipRequest(id);
      }
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MentorDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
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
            ),
          );
        }

        final data = snapshot.data!;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: AppState.instance.userName,
                    builder: (context, name, _) {
                      final initials = _initialsFor(name);
                      return Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                            child: InitialsAvatar(initials: initials, size: 48, gradient: AppColors.roleGradient('mentor')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Welcome back 👋', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
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
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _Stat(value: '${data.activeMentees}', label: 'Active Mentees', icon: Icons.groups_rounded, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: _Stat(value: data.rating > 0 ? data.rating.toStringAsFixed(1) : '—', label: 'Rating', icon: Icons.star_rounded, color: AppColors.warning)),
                      const SizedBox(width: 12),
                      Expanded(child: _Stat(value: '${data.pendingRequests.length}', label: 'Pending Requests', icon: Icons.pending_actions_rounded, color: AppColors.accentIndigo)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Upcoming Sessions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 14),
                  if (data.upcomingSessions.isEmpty)
                    const EmptyState(icon: Icons.event_available_outlined, title: 'No upcoming sessions', subtitle: 'Confirmed bookings will appear here')
                  else
                    AppCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < data.upcomingSessions.length; i++) ...[
                            if (i > 0) const Divider(height: 24),
                            _SessionRow(
                              name: data.upcomingSessions[i].studentName,
                              topic: data.upcomingSessions[i].topic,
                              time: data.upcomingSessions[i].time,
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(child: Text('Mentorship Requests', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const MentorshipRequestsScreen()))
                            .then((_) => _reload()),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  if (data.pendingRequests.isEmpty)
                    const EmptyState(icon: Icons.mark_email_read_outlined, title: 'No pending requests', subtitle: "You're all caught up")
                  else
                    ...data.pendingRequests.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: Row(
                            children: [
                              InitialsAvatar(initials: _initialsFor(r.menteeName), size: 44),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.menteeName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                    Text(r.message ?? 'Requested mentorship', style: const TextStyle(color: AppColors.textMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              if (r.id != null) ...[
                                SizedBox(
                                  height: 34,
                                  child: TextButton(
                                    style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 10)),
                                    onPressed: () => _respond(r.id!, false),
                                    child: const Text('Reject', style: TextStyle(fontSize: 12.5)),
                                  ),
                                ),
                                SizedBox(
                                  height: 34,
                                  child: ElevatedButton(
                                    onPressed: () => _respond(r.id!, true),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      textStyle: const TextStyle(fontSize: 12.5),
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  AppCard(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityScreen())),
                    child: const Row(
                      children: [
                        Icon(Icons.forum_rounded, color: AppColors.accentIndigo),
                        SizedBox(width: 12),
                        Expanded(child: Text('Share an interview experience with the community', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
                        Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'M';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _Stat({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String name;
  final String topic;
  final String time;
  const _SessionRow({required this.name, required this.topic, required this.time});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InitialsAvatar(initials: _initialsFor(name), size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(topic, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        if (time.isNotEmpty) AppTag(label: time, bg: AppColors.primarySoft),
      ],
    );
  }
}
