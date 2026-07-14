import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../skills/skill_gap_screen.dart';

class CareerRecommendationScreen extends StatelessWidget {
  const CareerRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'AI Career Compass',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(22)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Based on your academics, skills & interests, here are careers matched just for you.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Your Top Career Matches', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 14),
          ...MockData.careerPaths.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _CareerPathCard(path: c),
              )),
          const SizedBox(height: 10),
          const Text('Career Path Visualization', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 6),
          const Text('See the milestones ahead for your top match — Data Analyst.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          const _CareerTimeline(),
        ],
      ),
    );
  }
}

class _CareerPathCard extends StatelessWidget {
  final CareerPath path;
  const _CareerPathCard({required this.path});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SkillGapScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                child: Icon(_iconFor(path.icon), color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(path.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${path.matchPercent}% skill match', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ],
                ),
              ),
              CircularPercentBadge(percent: path.matchPercent),
            ],
          ),
          const SizedBox(height: 12),
          Text(path.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: path.keySkills.map((s) => AppTag(label: s, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary)).toList(),
          ),
        ],
      ),
    );
  }
}

class CircularPercentBadge extends StatelessWidget {
  final int percent;
  const CircularPercentBadge({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 4,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          Text('$percent', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

IconData _iconFor(String key) {
  switch (key) {
    case 'insights':
      return Icons.insights_rounded;
    case 'code':
      return Icons.code_rounded;
    case 'trending_up':
      return Icons.trending_up_rounded;
    case 'cloud':
      return Icons.cloud_rounded;
    default:
      return Icons.star_rounded;
  }
}

class _CareerTimeline extends StatelessWidget {
  const _CareerTimeline();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Foundation', 'SQL, Python & Statistics basics', true),
      ('Applied Analytics', 'Real-world projects & Power BI dashboards', true),
      ('Specialization', 'Machine Learning & A/B Testing', false),
      ('Job Ready', 'Portfolio, mock interviews & placement', false),
    ];
    return AppCard(
      child: Column(
        children: List.generate(steps.length, (i) {
          final (title, desc, done) = steps[i];
          final isLast = i == steps.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: done ? AppColors.primary : AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                        border: done ? null : Border.all(color: AppColors.border, width: 1.4),
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                          : Center(child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted))),
                    ),
                    if (!isLast) Expanded(child: Container(width: 2, color: done ? AppColors.primary : AppColors.border)),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        const SizedBox(height: 3),
                        Text(desc, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
