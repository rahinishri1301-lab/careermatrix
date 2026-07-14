import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/listing_cards.dart';

class JobPortalScreen extends StatefulWidget {
  final int initialTab;
  const JobPortalScreen({super.key, this.initialTab = 0});

  @override
  State<JobPortalScreen> createState() => _JobPortalScreenState();
}

class _JobPortalScreenState extends State<JobPortalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Opportunity Center',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: const AppSearchField(hint: 'Search jobs, companies, skills...'),
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: const [Tab(text: 'Full-time Jobs'), Tab(text: 'Internships')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _JobList(jobs: MockData.jobs),
                _JobList(jobs: MockData.internships),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  final List<JobListing> jobs;
  const _JobList({required this.jobs});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final job = jobs[i];
        return JobCard(
          job: job,
          onTap: () => _showJobDetail(context, job),
        );
      },
    );
  }

  void _showJobDetail(BuildContext context, JobListing job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _JobDetailSheet(job: job),
    );
  }
}

class _JobDetailSheet extends StatelessWidget {
  final JobListing job;
  const _JobDetailSheet({required this.job});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
            children: [
              Center(
                child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.business_center_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        Text('${job.company} · ${job.location}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _InfoChip(icon: Icons.payments_outlined, label: job.salary)),
                  const SizedBox(width: 10),
                  Expanded(child: _InfoChip(icon: Icons.work_outline_rounded, label: job.type)),
                  const SizedBox(width: 10),
                  Expanded(child: _InfoChip(icon: Icons.bolt_rounded, label: '${job.matchPercent}% match')),
                ],
              ),
              const SizedBox(height: 22),
              const Text('About the Role', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                'We are looking for a driven ${job.title} to join our team at ${job.company}. '
                'You will collaborate with cross-functional teams to deliver impactful, data-driven outcomes '
                'while growing your career in a fast-paced environment.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.55),
              ),
              const SizedBox(height: 18),
              const Text('Required Skills', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.tags.map((t) => AppTag(label: t)).toList(),
              ),
              const SizedBox(height: 26),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Applied to ${job.title} at ${job.company}!'), backgroundColor: AppColors.success),
                  );
                },
                child: const Text('Apply Now'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
