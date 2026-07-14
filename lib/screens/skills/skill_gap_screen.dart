import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/score_gauge.dart';

class SkillGapScreen extends StatelessWidget {
  const SkillGapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gaps = MockData.skillMatrix.where((s) => s.isGap).length;
    return SimpleScreenScaffold(
      title: 'Skill Matrix',
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const ScoreGauge(score: 68, size: 62, color: AppColors.primary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Overall Skill\nCompletion', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.priority_high_rounded, color: AppColors.warning),
                          ),
                          const SizedBox(height: 10),
                          Text('$gaps Skill Gaps', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const Text('Detected for your goal', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              tabs: [Tab(text: 'Skill Matrix'), Tab(text: 'Recommended Courses')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    children: [
                      AppCard(
                        child: Column(
                          children: MockData.skillMatrix
                              .map((s) => SkillProgressBar(name: s.name, progress: s.progress, level: s.level, isGap: s.isGap))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(18)),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: AppColors.warning),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Focus on Machine Learning & System Design this month to unlock better career matches.',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    itemCount: MockData.recommendedCourses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final c = MockData.recommendedCourses[i];
                      return AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                              child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                  const SizedBox(height: 4),
                                  Text('${c.provider} · ${c.duration}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                                      Text(' ${c.rating}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
