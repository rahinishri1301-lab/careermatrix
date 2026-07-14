import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class ResumeHubScreen extends StatelessWidget {
  const ResumeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Smart Resume Hub',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: 14),
                const Text('Aarav_Sharma_Resume.pdf', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                const Text('Uploaded 3 days ago · 248 KB', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                        label: const Text('Preview'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: const Text('Replace'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('AI Resume Analysis', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.successSoft, shape: BoxShape.circle),
                      child: const Text('84', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.success, fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resume Score: Strong', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                          Text('ATS-friendly, clear structure', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 6),
                const _AnalysisRow(icon: Icons.check_circle_rounded, color: AppColors.success, text: 'Strong action verbs used throughout'),
                const _AnalysisRow(icon: Icons.check_circle_rounded, color: AppColors.success, text: 'Well-structured project descriptions'),
                const _AnalysisRow(icon: Icons.warning_rounded, color: AppColors.warning, text: 'Add quantifiable achievements (e.g. % improved)'),
                const _AnalysisRow(icon: Icons.warning_rounded, color: AppColors.warning, text: 'Missing keywords: "Machine Learning", "A/B Testing"'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Portfolio', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 14),
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.accentIndigo.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.web_rounded, color: AppColors.accentIndigo),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Build your portfolio site', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                      Text('Showcase projects, certificates & achievements', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _AnalysisRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3))),
        ],
      ),
    );
  }
}
