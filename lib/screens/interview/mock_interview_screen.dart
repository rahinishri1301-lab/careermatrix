import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/score_gauge.dart';

class MockInterviewScreen extends StatelessWidget {
  const MockInterviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Mock Interview Arena',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          AppCard(
            color: AppColors.primaryDeep,
            child: Row(
              children: [
                const ScoreGauge(score: 76, size: 72, color: Colors.white, trackColor: Colors.white24, label: 'AVG'),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Average Interview Score', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text('Across ${MockData.interviewSessions.where((s) => s.lastScore > 0).length} completed sessions',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _TypeCard(
                  icon: Icons.terminal_rounded,
                  title: 'Technical',
                  subtitle: 'DSA, System Design, SQL',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TypeCard(
                  icon: Icons.forum_rounded,
                  title: 'HR Round',
                  subtitle: 'Behavioral & culture-fit',
                  color: AppColors.accentIndigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Practice Sessions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 14),
          ...MockData.interviewSessions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SessionCard(session: s),
              )),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _TypeCard({required this.icon, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final InterviewSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final completed = session.lastScore > 0;
    return AppCard(
      onTap: () => _startSession(context),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: session.type == 'Technical' ? AppColors.primarySoft : AppColors.accentIndigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              session.type == 'Technical' ? Icons.terminal_rounded : Icons.forum_rounded,
              color: session.type == 'Technical' ? AppColors.primary : AppColors.accentIndigo,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    AppTag(label: session.difficulty, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('${session.durationMins} min', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          if (completed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${session.lastScore}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 16)),
                const Text('last score', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            )
          else
            const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 30),
        ],
      ),
    );
  }

  void _startSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(session.title),
        content: Text(
          'You will get ${session.durationMins} minutes for this ${session.type} round. '
          'AI will score your responses on clarity, correctness & confidence.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Interview session started — good luck!'), backgroundColor: AppColors.primary),
              );
            },
            child: const Text('Start Now'),
          ),
        ],
      ),
    );
  }
}
