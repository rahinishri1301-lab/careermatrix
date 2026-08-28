import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/score_gauge.dart';

class SkillGapScreen extends StatefulWidget {
  const SkillGapScreen({super.key});

  @override
  State<SkillGapScreen> createState() => _SkillGapScreenState();
}

class _SkillGapScreenState extends State<SkillGapScreen> {
  late Future<List<SkillItem>> _skillsFuture;

  @override
  void initState() {
    super.initState();
    _skillsFuture = BackendRepository.instance.getMySkills();
  }

  void _reload() {
    setState(() => _skillsFuture = BackendRepository.instance.getMySkills());
  }

  Future<void> _skillDialog({SkillItem? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String level = existing?.level ?? 'Beginner';
    String category = existing?.category ?? 'Technical';
    final isEdit = existing != null;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(isEdit ? 'Edit Skill' : 'Add Skill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: 'e.g. Python Programming'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                items: const ['Technical', 'Soft Skill', 'Language', 'Tool', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => category = v ?? category),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: level,
                items: const ['Beginner', 'Intermediate', 'Advanced', 'Expert']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setDialogState(() => level = v ?? level),
                decoration: const InputDecoration(labelText: 'Proficiency'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEdit ? 'Save' : 'Add')),
          ],
        ),
      ),
    );

    if (saved != true || nameCtrl.text.trim().isEmpty) return;
    try {
      if (isEdit) {
        await BackendRepository.instance.updateSkill(
          existing.id!,
          skillName: nameCtrl.text.trim(),
          category: category,
          proficiencyLevel: level,
        );
      } else {
        await BackendRepository.instance.addSkill(
          skillName: nameCtrl.text.trim(),
          category: category,
          proficiencyLevel: level,
        );
      }
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Skill updated' : 'Skill added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  Future<void> _confirmDeleteSkill(SkillItem skill) async {
    if (skill.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete skill?'),
        content: Text('Remove "${skill.name}" from your Skill Matrix?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BackendRepository.instance.deleteSkill(skill.id!);
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
    return SimpleScreenScaffold(
      title: 'Skill Matrix',
      body: FutureBuilder<List<SkillItem>>(
        future: _skillsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString(), onRetry: _reload);
          }
          final skills = snapshot.data ?? const [];
          final gaps = skills.where((s) => s.isGap).length;

          return DefaultTabController(
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
                              ScoreGauge(
                                score: skills.isEmpty
                                    ? 0
                                    : (skills.map((s) => s.progress).reduce((a, b) => a + b) / skills.length * 100)
                                        .round(),
                                size: 62,
                                color: AppColors.primary,
                              ),
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
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        children: [
                          if (skills.isEmpty)
                            const _EmptyHint(text: "You haven't added any skills yet. Tap + to add your first one.")
                          else
                            AppCard(
                              child: Column(
                                children: skills
                                    .map((s) => InkWell(
                                          onTap: () => _skillDialog(existing: s),
                                          onLongPress: () => _confirmDeleteSkill(s),
                                          child: SkillProgressBar(name: s.name, progress: s.progress, level: s.level, isGap: s.isGap),
                                        ))
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
                                Expanded(
                                  child: Text(
                                    skills.isEmpty
                                        ? 'Add your skills above to get a real skill-gap analysis and course recommendations.'
                                        : gaps > 0
                                            ? 'Focus on your beginner-level skills this month to unlock better career matches.'
                                            : 'Great job — no major skill gaps detected right now.',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      FutureBuilder<List<CourseRecommendation>>(
                        future: BackendRepository.instance.getRecommendedCourses(),
                        builder: (context, courseSnapshot) {
                          if (courseSnapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (courseSnapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(courseSnapshot.error.toString(), style: const TextStyle(color: AppColors.textMuted)),
                            );
                          }
                          final courses = courseSnapshot.data ?? const [];
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                            children: [
                              const _EmptyHint(
                                text: 'Personalized based on the skills you marked as Beginner-level.',
                              ),
                              const SizedBox(height: 12),
                              if (courses.isEmpty)
                                const Text('No course suggestions right now — add a few skills first.',
                                    style: TextStyle(color: AppColors.textMuted))
                              else
                                ...courses.map(
                                  (c) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: AppCard(
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
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _skillDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
