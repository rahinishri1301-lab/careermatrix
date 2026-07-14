import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/listing_cards.dart';

class MentorConnectScreen extends StatefulWidget {
  const MentorConnectScreen({super.key});

  @override
  State<MentorConnectScreen> createState() => _MentorConnectScreenState();
}

class _MentorConnectScreenState extends State<MentorConnectScreen> {
  String _filter = 'All';
  final _domains = const ['All', 'Data Science', 'Product', 'Web Development', 'Cloud Computing', 'Career Coaching'];

  @override
  Widget build(BuildContext context) {
    final mentors = _filter == 'All'
        ? MockData.mentors
        : MockData.mentors.where((m) => m.domain == _filter).toList();

    return SimpleScreenScaffold(
      title: 'Mentor Connect',
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: AppSearchField(hint: 'Search mentors by name or domain...'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _domains.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = _domains[i];
                final selected = d == _filter;
                return ChoiceChip(
                  label: Text(d),
                  selected: selected,
                  onSelected: (_) => setState(() => _filter = d),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceMuted,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide.none),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              itemCount: mentors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final m = mentors[i];
                return MentorCard(
                  mentor: m,
                  onTap: () => _showMentorProfile(context, m),
                  onBook: () => _bookSession(context, m),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMentorProfile(BuildContext context, MentorProfile m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text('${m.role} at ${m.company}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Text(
              '${m.name} has ${m.experienceYears}+ years of experience in ${m.domain} and has mentored 40+ students '
              'through Career Matrix, helping them land roles at top companies.',
              style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _bookSession(context, m);
              },
              child: const Text('Book a Session'),
            ),
          ],
        ),
      ),
    );
  }

  void _bookSession(BuildContext context, MentorProfile m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Session'),
        content: Text('Book a 30-min mentorship session with ${m.name}? You will receive a calendar invite.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Session request sent to ${m.name}!'), backgroundColor: AppColors.success),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
