import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class CompanyPortalScreen extends StatefulWidget {
  final int initialTab;
  const CompanyPortalScreen({super.key, this.initialTab = 0});

  @override
  State<CompanyPortalScreen> createState() => _CompanyPortalScreenState();
}

class _CompanyPortalScreenState extends State<CompanyPortalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Company Portal',
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            tabs: const [Tab(text: 'Find Candidates'), Tab(text: 'Post a Job')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [_CandidateSearchTab(), _PostJobTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateSearchTab extends StatelessWidget {
  const _CandidateSearchTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const AppSearchField(hint: 'Search by skill, college, role...'),
        const SizedBox(height: 16),
        ...MockData.candidates.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CandidateCard(candidate: c),
            )),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final CandidateProfile candidate;
  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialsAvatar(initials: candidate.initials, size: 50),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(candidate.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                    AppTag(label: '${candidate.matchPercent}%', bg: AppColors.successSoft, fg: AppColors.success),
                  ],
                ),
                const SizedBox(height: 3),
                Text('${candidate.course} · ${candidate.college}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidate.skills.map((s) => AppTag(label: s, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary)).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(38), textStyle: const TextStyle(fontSize: 12.5)),
                        child: const Text('View Profile'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invited ${candidate.name} to apply!'), backgroundColor: AppColors.success),
                          );
                        },
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(38), textStyle: const TextStyle(fontSize: 12.5)),
                        child: const Text('Invite'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostJobTab extends StatefulWidget {
  const _PostJobTab();

  @override
  State<_PostJobTab> createState() => _PostJobTabState();
}

class _PostJobTabState extends State<_PostJobTab> {
  String _type = 'Full-time';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const Text('Role Title', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        const TextField(decoration: InputDecoration(hintText: 'e.g. Data Analyst')),
        const SizedBox(height: 16),
        const Text('Opportunity Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: ['Full-time', 'Internship'].map((t) {
            final selected = _type == t;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(t),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceMuted,
                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide.none),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('Location', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        const TextField(decoration: InputDecoration(hintText: 'e.g. Bengaluru / Remote')),
        const SizedBox(height: 16),
        const Text('Salary / Stipend', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        const TextField(decoration: InputDecoration(hintText: 'e.g. ₹8–12 LPA')),
        const SizedBox(height: 16),
        const Text('Required Skills', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        const TextField(decoration: InputDecoration(hintText: 'e.g. SQL, Python, Power BI')),
        const SizedBox(height: 16),
        const Text('Job Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        const TextField(maxLines: 4, decoration: InputDecoration(hintText: 'Describe the role & responsibilities...')),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opportunity posted successfully!'), backgroundColor: AppColors.success),
            );
          },
          child: const Text('Post Opportunity'),
        ),
      ],
    );
  }
}
