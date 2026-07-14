import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Notifications',
      actions: [
        TextButton(onPressed: () {}, child: const Text('Mark all read')),
        const SizedBox(width: 8),
      ],
      body: MockData.notifications.isEmpty
          ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'No notifications yet', subtitle: 'You will see updates here')
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              itemCount: MockData.notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final n = MockData.notifications[i];
                return AppCard(
                  onTap: () {},
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _colorFor(n.type).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(_iconFor(n.type), color: _colorFor(n.type), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5))),
                                if (n.unread)
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(n.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
                            const SizedBox(height: 6),
                            Text(n.timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'job':
        return Icons.work_rounded;
      case 'mentor':
        return Icons.diversity_3_rounded;
      case 'community':
        return Icons.forum_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'job':
        return AppColors.success;
      case 'mentor':
        return AppColors.primary;
      case 'community':
        return AppColors.accentIndigo;
      default:
        return AppColors.warning;
    }
  }
}
