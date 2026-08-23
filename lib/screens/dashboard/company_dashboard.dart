import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../company/company_portal_screen.dart';
import '../company/manage_postings_screen.dart';
import '../company/company_applications_screen.dart';
import '../company/company_messages_screen.dart';
import '../company/company_documents_screen.dart';
import '../interview/scheduled_interviews_screen.dart';

class CompanyDashboard extends StatefulWidget {
  const CompanyDashboard({super.key});

  @override
  State<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboard> {
  late Future<List<CandidateProfile>> _candidatesFuture;
  late Future<CompanyStats> _statsFuture;
  late Future<AppUser> _userFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _candidatesFuture = BackendRepository.instance.getCandidates();
    _statsFuture = BackendRepository.instance.getCompanyStats();
    _userFuture = BackendRepository.instance.getMyAppUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _loadData());
          },
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  // Header Row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.roleGradient('company'),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.apartment_rounded, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FutureBuilder<AppUser>(
                          future: _userFuture,
                          builder: (context, snapshot) {
                            final name = snapshot.data?.name ?? 'Company';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Company Portal 👋',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Tooltip(
                        message: 'Company Documents',
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CompanyDocumentsScreen()),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.folder_open_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Scheduled Interviews',
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ScheduledInterviewsScreen(isCompany: true)),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.calendar_month_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Messages',
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CompanyMessagesScreen()),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Notifications',
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                          ),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.notifications_none_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Section 1: Postings & Opportunities Overview
                  const Text(
                    'Opportunity Overview',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<dynamic>(
                    future: _statsFuture,
                    builder: (context, snapshot) {
                      final rawData = snapshot.data;
                      CompanyStats? stats;
                      if (rawData is CompanyStats) {
                        stats = rawData;
                      } else if (rawData != null) {
                        try {
                          final dynamic d = rawData;
                          stats = CompanyStats(
                            totalJobsPosted: 0,
                            totalInternshipsPosted: 0,
                            activeOpportunities: (d.activePostings as num?)?.toInt() ?? 0,
                            totalApplications: (d.totalApplications as num?)?.toInt() ?? 0,
                            pendingApplications: 0,
                            shortlistedCandidates: 0,
                            selectedCandidates: 0,
                            rejectedApplications: 0,
                          );
                        } catch (_) {}
                      }
                      final isLoading = snapshot.connectionState == ConnectionState.waiting;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _MetricCard(
                                  value: isLoading ? '—' : '${stats?.totalJobsPosted ?? 0}',
                                  label: 'Total Jobs',
                                  icon: Icons.work_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricCard(
                                  value: isLoading ? '—' : '${stats?.totalInternshipsPosted ?? 0}',
                                  label: 'Internships',
                                  icon: Icons.school_rounded,
                                  color: AppColors.accentIndigo,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricCard(
                                  value: isLoading ? '—' : '${stats?.activeOpportunities ?? 0}',
                                  label: 'Active Ops',
                                  icon: Icons.local_fire_department_rounded,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MetricCard(
                                  value: isLoading ? '—' : '${stats?.totalApplications ?? 0}',
                                  label: 'Total Apps',
                                  icon: Icons.description_rounded,
                                  color: AppColors.accentIndigo,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CompanyApplicationsScreen(initialStatusFilter: 'All')),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Section 2: Application Pipeline / Candidate Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Candidate Pipeline',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                onPressed: () => setState(() => _loadData()),
                                tooltip: 'Refresh Stats',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth >= 800;
                              final isTablet = constraints.maxWidth >= 550;
                              final cols = isDesktop ? 4 : (isTablet ? 2 : 2);
                              final ratio = isDesktop ? 1.9 : (isTablet ? 2.4 : 1.8);

                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: cols,
                                childAspectRatio: ratio,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                children: [
                                  _StatusCard(
                                    value: isLoading ? '—' : '${stats?.pendingApplications ?? 0}',
                                    label: 'Pending Applications',
                                    icon: Icons.hourglass_empty_rounded,
                                    color: Colors.amber.shade800,
                                    bg: Colors.amber.shade50,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const CompanyApplicationsScreen(initialStatusFilter: 'Pending')),
                                    ),
                                  ),
                                  _StatusCard(
                                    value: isLoading ? '—' : '${stats?.shortlistedCandidates ?? 0}',
                                    label: 'Shortlisted Candidates',
                                    icon: Icons.star_rounded,
                                    color: AppColors.primary,
                                    bg: AppColors.primarySoft,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const CompanyApplicationsScreen(initialStatusFilter: 'Shortlisted')),
                                    ),
                                  ),
                                  _StatusCard(
                                    value: isLoading ? '—' : '${stats?.selectedCandidates ?? 0}',
                                    label: 'Selected Candidates',
                                    icon: Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    bg: AppColors.successSoft,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const CompanyApplicationsScreen(initialStatusFilter: 'Selected')),
                                    ),
                                  ),
                                  _StatusCard(
                                    value: isLoading ? '—' : '${stats?.rejectedApplications ?? 0}',
                                    label: 'Rejected Applications',
                                    icon: Icons.cancel_rounded,
                                    color: AppColors.danger,
                                    bg: AppColors.dangerSoft,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const CompanyApplicationsScreen(initialStatusFilter: 'Rejected')),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
              const SizedBox(height: 22),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.post_add_rounded,
                      title: 'Post Job',
                      color: AppColors.primary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CompanyPortalScreen(initialTab: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.work_history_rounded,
                      title: 'Manage All',
                      color: AppColors.warning,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManagePostingsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.person_search_rounded,
                      title: 'Candidates',
                      color: AppColors.accentIndigo,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CompanyPortalScreen(initialTab: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Top Candidates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Top Matching Candidates',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CompanyPortalScreen(initialTab: 0),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<CandidateProfile>>(
                future: _candidatesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        snapshot.error.toString(),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                      ),
                    );
                  }
                  final candidates = snapshot.data ?? const [];
                  if (candidates.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No candidates found yet.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                      ),
                    );
                  }
                  return Column(
                    children: candidates
                        .take(3)
                        .map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CompanyPortalScreen(initialTab: 0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  InitialsAvatar(initials: c.initials, size: 46),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${c.course} · ${c.college}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppTag(
                                    label: '${c.matchPercent}%',
                                    bg: AppColors.successSoft,
                                    fg: AppColors.success,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;

  const _StatusCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.arrow_forward_rounded, size: 16, color: color.withValues(alpha: 0.6)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
