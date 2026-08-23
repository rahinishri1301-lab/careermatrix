import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import 'company_messages_screen.dart';
import 'schedule_interview_dialog.dart';

class CompanyApplicationsScreen extends StatefulWidget {
  final String initialStatusFilter;
  const CompanyApplicationsScreen({super.key, this.initialStatusFilter = 'All'});

  @override
  State<CompanyApplicationsScreen> createState() => _CompanyApplicationsScreenState();
}

class _CompanyApplicationsScreenState extends State<CompanyApplicationsScreen> {
  late Future<List<OpportunityApplicant>> _appsFuture;
  late String _statusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter;
    _refresh();
  }

  void _refresh() {
    _appsFuture = BackendRepository.instance.getCompanyReceivedApplications();
  }

  Future<void> _updateStatus(OpportunityApplicant app, String newStatus) async {
    final isIntern = app.opportunityType == 'Internship';
    try {
      if (isIntern) {
        await BackendRepository.instance.updateInternshipApplicationStatus(app.id, newStatus);
      } else {
        await BackendRepository.instance.updateJobApplicationStatus(app.id, newStatus);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${app.name}\'s status updated to $newStatus!'), backgroundColor: AppColors.success),
      );
      setState(() => _refresh());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _viewResume(String? path) async {
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No resume uploaded by applicant'), backgroundColor: AppColors.warning),
      );
      return;
    }
    try {
      final downloadedPath = await BackendRepository.instance.downloadApplicantResume(path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resume saved to $downloadedPath'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _downloadCertificate(StudentCertificate cert) async {
    try {
      final downloadedPath = await BackendRepository.instance.downloadCertificate(cert.id, '${cert.title}.pdf');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${cert.title} downloaded to $downloadedPath'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  void _showProfileModal(OpportunityApplicant app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentProfileModalSheet(
        app: app,
        onViewResume: () => _viewResume(app.resumePath),
        onDownloadCertificate: _downloadCertificate,
      ),
    );
  }

  List<OpportunityApplicant> _filter(List<OpportunityApplicant> list) {
    return list.where((item) {
      if (_statusFilter != 'All') {
        if (_statusFilter == 'Pending' && (item.status != 'Applied' && item.status != 'Pending')) return false;
        if (_statusFilter == 'Shortlisted' && item.status != 'Shortlisted') return false;
        if (_statusFilter == 'Selected' && (item.status != 'Selected' && item.status != 'Hired')) return false;
        if (_statusFilter == 'Rejected' && item.status != 'Rejected') return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return item.name.toLowerCase().contains(q) ||
            item.email.toLowerCase().contains(q) ||
            item.opportunityTitle.toLowerCase().contains(q) ||
            item.skills.any((s) => s.toLowerCase().contains(q));
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Student Applications',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                AppSearchField(
                  hint: 'Search by student name, email, skills, opportunity...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All Applications', selected: _statusFilter == 'All', onTap: () => setState(() => _statusFilter = 'All')),
                      _FilterChip(label: 'Pending', selected: _statusFilter == 'Pending', onTap: () => setState(() => _statusFilter = 'Pending')),
                      _FilterChip(label: 'Shortlisted', selected: _statusFilter == 'Shortlisted', onTap: () => setState(() => _statusFilter = 'Shortlisted')),
                      _FilterChip(label: 'Selected', selected: _statusFilter == 'Selected', onTap: () => setState(() => _statusFilter = 'Selected')),
                      _FilterChip(label: 'Rejected', selected: _statusFilter == 'Rejected', onTap: () => setState(() => _statusFilter = 'Rejected')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<OpportunityApplicant>>(
              future: _appsFuture,
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
                          ElevatedButton(onPressed: () => setState(() => _refresh()), child: const Text('Retry')),
                        ],
                      ),
                    ),
                  );
                }
                final allApps = snapshot.data ?? const [];
                final filtered = _filter(allApps);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_ind_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text('No applications match your filter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => setState(() {
                            _statusFilter = 'All';
                            _searchQuery = '';
                          }),
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() => _refresh()),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final app = filtered[i];
                      return _ApplicationCard(
                        app: app,
                        onShortlist: () => _updateStatus(app, 'Shortlisted'),
                        onSelect: () => _updateStatus(app, 'Selected'),
                        onReject: () => _updateStatus(app, 'Rejected'),
                        onViewProfile: () => _showProfileModal(app),
                        onViewResume: () => _viewResume(app.resumePath),
                        onUpdateStatus: (val) => _updateStatus(app, val),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11.5, color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surfaceMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final OpportunityApplicant app;
  final VoidCallback onShortlist;
  final VoidCallback onSelect;
  final VoidCallback onReject;
  final VoidCallback onViewProfile;
  final VoidCallback onViewResume;
  final ValueChanged<String> onUpdateStatus;

  const _ApplicationCard({
    required this.app,
    required this.onShortlist,
    required this.onSelect,
    required this.onReject,
    required this.onViewProfile,
    required this.onViewResume,
    required this.onUpdateStatus,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Shortlisted':
        return AppColors.primary;
      case 'Selected':
      case 'Hired':
        return AppColors.success;
      case 'Rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'Shortlisted':
        return AppColors.primarySoft;
      case 'Selected':
      case 'Hired':
        return AppColors.successSoft;
      case 'Rejected':
        return AppColors.dangerSoft;
      default:
        return AppColors.warningSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(initials: app.initials, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                        AppTag(label: app.status, bg: _statusBg(app.status), fg: _statusColor(app.status)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(app.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.work_outline_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Applied for ${app.opportunityTitle} (${app.opportunityType})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Qualification: ${app.department}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              if (app.appliedAt != null)
                Text('Applied: ${app.appliedAt!.day}/${app.appliedAt!.month}/${app.appliedAt!.year}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
            ],
          ),
          if (app.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: app.skills.map((s) => AppTag(label: s, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary)).toList(),
            ),
          ],
          const Divider(height: 22),
          // Action Buttons: Shortlist, Select, Reject, View Profile, View Resume
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.person_outline_rounded, size: 14),
                label: const Text('Profile'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(65, 32), textStyle: const TextStyle(fontSize: 11.5)),
                onPressed: onViewProfile,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.description_outlined, size: 14),
                label: const Text('Resume'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(70, 32), textStyle: const TextStyle(fontSize: 11.5)),
                onPressed: onViewResume,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.star_outline_rounded, size: 14),
                label: const Text('Shortlist'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(80, 32), backgroundColor: AppColors.primary, textStyle: const TextStyle(fontSize: 11.5)),
                onPressed: onShortlist,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 14),
                label: const Text('Select'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(70, 32), backgroundColor: AppColors.success, textStyle: const TextStyle(fontSize: 11.5)),
                onPressed: onSelect,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.close_rounded, size: 14),
                label: const Text('Reject'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(70, 32), backgroundColor: AppColors.danger, textStyle: const TextStyle(fontSize: 11.5)),
                onPressed: onReject,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentProfileModalSheet extends StatelessWidget {
  final OpportunityApplicant app;
  final VoidCallback onViewResume;
  final ValueChanged<StudentCertificate> onDownloadCertificate;

  const _StudentProfileModalSheet({
    required this.app,
    required this.onViewResume,
    required this.onDownloadCertificate,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    InitialsAvatar(initials: app.initials, size: 54),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          Text(app.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Academic & Professional Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _InfoTile(label: 'Department / Course', value: app.department)),
                    Expanded(child: _InfoTile(label: 'Graduation Year', value: app.graduationYear)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _InfoTile(label: 'Current Status', value: app.currentPosition)),
                    Expanded(child: _InfoTile(label: 'Phone Contact', value: app.phone)),
                  ],
                ),
                if (app.bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('About Candidate', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(app.bio, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                ],
                const SizedBox(height: 16),
                const Text('Skills & Competencies', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                if (app.skills.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: app.skills.map((s) => AppTag(label: s)).toList(),
                  )
                else
                  const Text('No skills listed', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                if (app.coverLetter.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Submitted Cover Letter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
                    child: Text(app.coverLetter, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                  ),
                ],
                if (app.certificates.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Uploaded Certificates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 8),
                  Column(
                    children: app.certificates.map((cert) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cert.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text(cert.issuer, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.download_rounded, size: 14),
                              label: const Text('View', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(minimumSize: const Size(60, 30)),
                              onPressed: () => onDownloadCertificate(cert),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Message'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                recipientId: app.applicantId,
                                recipientName: app.name,
                                recipientRole: 'student',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Schedule Interview'),
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                        onPressed: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (_) => ScheduleInterviewDialog(
                              candidateId: app.applicantId,
                              candidateName: app.name,
                              opportunityTitle: app.opportunityTitle,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download Resume'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  onPressed: onViewResume,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}
