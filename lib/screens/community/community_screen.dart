import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Community', style: Theme.of(context).textTheme.headlineSmall),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Discussions, interview experiences & events', style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(gradient: AppColors.cyanGradient, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Career Matrix Hackathon — Registrations Open! Build an AI project in 48 hours.',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, height: 1.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Trending Discussions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 14),
            ...MockData.forumPosts.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ForumPostCard(post: p),
                )),
          ],
        ),
      ),
    );
  }
}

class _ForumPostCard extends StatelessWidget {
  final ForumPost post;
  const _ForumPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
                child: Text(post.author.substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                    Text(post.role, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
              Text(post.timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          Text(post.preview, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.favorite_border_rounded, size: 17, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text('${post.likes}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              const Icon(Icons.mode_comment_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text('${post.comments}', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              const Spacer(),
              const Icon(Icons.share_outlined, size: 17, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}
