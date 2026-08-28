import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

/// Combines GET /api/jobs/applications/me and
/// GET /api/internships/applications/me into a single, real, persisted
/// applications list — no hardcoded statuses.
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);
  late Future<List<ApplicationRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<List<ApplicationRecord>> _load() async {
    // Independent calls, fired together.
    final results = await Future.wait([
      BackendRepository.instance.getMyJobApplications(),
      BackendRepository.instance.getMyInternshipApplications(),
    ]);
    final all = [...results[0], ...results[1]];
    return all;
  }

  void _reload() => setState(() => _future = _load());

  Color _statusColor(String status) {
    switch (status) {
      case 'Selected':
        return AppColors.success;
      case 'Shortlisted':
        return AppColors.primary;
      case 'Rejected':
        return AppColors.danger;
      default: // Applied
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'My Applications',
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: const [Tab(text: 'All'), Tab(text: 'Jobs'), Tab(text: 'Internships')],
          ),
          Expanded(
            child: FutureBuilder<List<ApplicationRecord>>(
              future: _future,
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
                final all = snapshot.data ?? const [];
                return TabBarView(
                  controller: _tab,
                  children: [
                    _ApplicationsList(applications: all, statusColor: _statusColor),
                    _ApplicationsList(applications: all.where((a) => !a.isInternship).toList(), statusColor: _statusColor),
                    _ApplicationsList(applications: all.where((a) => a.isInternship).toList(), statusColor: _statusColor),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationsList extends StatelessWidget {
  final List<ApplicationRecord> applications;
  final Color Function(String) statusColor;
  const _ApplicationsList({required this.applications, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_outlined,
        title: 'No applications yet',
        subtitle: 'Jobs and internships you apply to will show up here',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final a = applications[i];
        final color = statusColor(a.status);
        return AppCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                child: Icon(a.isInternship ? Icons.school_rounded : Icons.work_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                    const SizedBox(height: 2),
                    Text(a.company, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                    const SizedBox(height: 2),
                    Text(a.appliedAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              AppTag(label: a.status, bg: color.withOpacity(0.12), fg: color),
            ],
          ),
        );
      },
    );
  }
}
