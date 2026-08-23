import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

class ScheduledInterviewsScreen extends StatefulWidget {
  final bool isCompany;
  const ScheduledInterviewsScreen({super.key, this.isCompany = false});

  @override
  State<ScheduledInterviewsScreen> createState() => _ScheduledInterviewsScreenState();
}

class _ScheduledInterviewsScreenState extends State<ScheduledInterviewsScreen> {
  late Future<List<ScheduledInterviewItem>> _interviewsFuture;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _interviewsFuture = widget.isCompany
          ? BackendRepository.instance.getCompanyScheduledInterviews()
          : BackendRepository.instance.getCandidateScheduledInterviews();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return AppColors.primary;
      case 'Rescheduled':
        return Colors.orange;
      case 'Completed':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _updateStatus(ScheduledInterviewItem item, String newStatus) async {
    try {
      await BackendRepository.instance.updateScheduledInterview(id: item.id, status: newStatus);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Interview marked as $newStatus'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _cancelInterview(ScheduledInterviewItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Interview'),
        content: Text('Are you sure you want to cancel the interview "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel Interview'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await BackendRepository.instance.cancelScheduledInterview(item.id);
        _refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interview cancelled'), backgroundColor: AppColors.warning),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isCompany ? 'Company Scheduled Interviews' : 'My Scheduled Interviews',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: ['All', 'Scheduled', 'Rescheduled', 'Completed', 'Cancelled'].map((st) {
                final isSel = _statusFilter == st;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(st),
                    selected: isSel,
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    onSelected: (sel) {
                      if (sel) setState(() => _statusFilter = st);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Main List
          Expanded(
            child: FutureBuilder<List<ScheduledInterviewItem>>(
              future: _interviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                        const SizedBox(height: 12),
                        Text('Failed to load interviews: ${snapshot.error}', style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                final filtered = items.where((i) {
                  if (_statusFilter == 'All') return true;
                  return i.status.toLowerCase() == _statusFilter.toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          const Text('No Scheduled Interviews Found', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                          const SizedBox(height: 8),
                          Text(
                            widget.isCompany
                                ? 'Schedule interviews with candidates directly from the Student Applications or Candidate Search tabs.'
                                : 'You currently have no scheduled interviews.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final stColor = _statusColor(item.status);
                    final dateFormatted = '${item.scheduledDate.day}/${item.scheduledDate.month}/${item.scheduledDate.year} at ${TimeOfDay.fromDateTime(item.scheduledDate).format(context)}';

                    return AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: stColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.status.toUpperCase(),
                                  style: TextStyle(color: stColor, fontWeight: FontWeight.w800, fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.interviewType,
                                  style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 11),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${item.durationMinutes} mins',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(
                            widget.isCompany ? 'Candidate: ${item.candidateName}' : 'Company: ${item.companyName}',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(dateFormatted, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (item.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(item.location, style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                          if (item.notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Notes: ${item.notes}', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 14),

                          // Action Buttons
                          Row(
                            children: [
                              if (item.meetingLink.isNotEmpty && item.status != 'Cancelled') ...[
                                Expanded(
                                 child: ElevatedButton.icon(
                                   icon: const Icon(Icons.video_call_rounded, size: 18),
                                   label: const Text('Join Meeting'),
                                   onPressed: () {
                                     showDialog(
                                       context: context,
                                       builder: (ctx) => AlertDialog(
                                         title: const Text('Join Interview Meeting'),
                                         content: Column(
                                           mainAxisSize: MainAxisSize.min,
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             Text('Title: ${item.title}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                             const SizedBox(height: 8),
                                             const Text('Meeting Link:'),
                                             SelectableText(
                                               item.meetingLink.isNotEmpty ? item.meetingLink : 'No meeting link provided.',
                                               style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                             ),
                                           ],
                                         ),
                                         actions: [
                                           TextButton(
                                             onPressed: () => Navigator.of(ctx).pop(),
                                             child: const Text('Close'),
                                           ),
                                         ],
                                       ),
                                     );
                                   },
                                 ),
                               ),
                                const SizedBox(width: 8),
                              ],

                              if (widget.isCompany && item.status != 'Cancelled') ...[
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded),
                                  onSelected: (val) {
                                    if (val == 'cancel') {
                                      _cancelInterview(item);
                                    } else {
                                      _updateStatus(item, val);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: 'Completed', child: Text('Mark Completed ✅')),
                                    const PopupMenuItem(value: 'Rescheduled', child: Text('Mark Rescheduled 🔄')),
                                    const PopupMenuItem(value: 'cancel', child: Text('Cancel Interview ❌')),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
