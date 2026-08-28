import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import 'alumni_profile_screen.dart';

/// Student-facing Alumni Directory. Loads real alumni (role=alumni users)
/// via GET /api/users/alumni. Tapping a card passes that alumni's real
/// User._id into AlumniProfileScreen, which fetches THAT person's profile —
/// never the logged-in student's own cached AppUser.
class AlumniDirectoryScreen extends StatefulWidget {
  const AlumniDirectoryScreen({super.key});

  @override
  State<AlumniDirectoryScreen> createState() => _AlumniDirectoryScreenState();
}

class _AlumniDirectoryScreenState extends State<AlumniDirectoryScreen> {
  String _query = '';
  late Future<List<AlumniProfile>> _alumniFuture;

  @override
  void initState() {
    super.initState();
    _alumniFuture = BackendRepository.instance.getAlumni();
  }

  void _reload() {
    setState(() => _alumniFuture = BackendRepository.instance.getAlumni());
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Alumni Directory',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: AppSearchField(
              hint: 'Search alumni by name or company...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<AlumniProfile>>(
              future: _alumniFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  );
                }
                var alumni = snapshot.data ?? const [];
                if (_query.trim().isNotEmpty) {
                  final q = _query.toLowerCase();
                  alumni = alumni
                      .where((a) => a.name.toLowerCase().contains(q) || a.company.toLowerCase().contains(q))
                      .toList();
                }
                if (alumni.isEmpty) {
                  return const EmptyState(
                    icon: Icons.diversity_3_outlined,
                    title: 'No alumni found',
                    subtitle: 'Check back later as more alumni join Career Matrix',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemCount: alumni.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final a = alumni[i];
                    return _AlumniCard(
                      alumnus: a,
                      onTap: a.id == null
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => AlumniProfileScreen(userId: a.id!, name: a.name)),
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

class _AlumniCard extends StatelessWidget {
  final AlumniProfile alumnus;
  final VoidCallback? onTap;
  const _AlumniCard({required this.alumnus, this.onTap});

  @override
  Widget build(BuildContext context) {
    final titleLine = [alumnus.currentPosition, alumnus.company].where((s) => s.isNotEmpty).join(' at ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            InitialsAvatar(initials: alumnus.initials, size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alumnus.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    titleLine.isNotEmpty ? titleLine : 'Career Matrix Alumni',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  if (alumnus.skills.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: alumnus.skills.take(3).map((s) => AppTag(label: s, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
