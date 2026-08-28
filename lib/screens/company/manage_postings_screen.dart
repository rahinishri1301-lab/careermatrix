import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import 'edit_job_dialog.dart';
import 'edit_internship_dialog.dart';

class ManagePostingsScreen extends StatefulWidget {
  const ManagePostingsScreen({super.key});

  @override
  State<ManagePostingsScreen> createState() => _ManagePostingsScreenState();
}

class _ManagePostingsScreenState extends State<ManagePostingsScreen> {
  late Future<List<JobListing>> _postingsFuture;
  String _typeFilter = 'All'; // 'All', 'Jobs', 'Internships'
  String _statusFilter = 'All'; // 'All', 'Open', 'Closed'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _postingsFuture = BackendRepository.instance.getMyPostings();
  }

  Future<void> _toggleStatus(JobListing job) async {
    if (job.id == null) return;
    final isIntern = job.type == 'Internship';
    try {
      if (isIntern) {
        await BackendRepository.instance.toggleInternshipStatus(job.id!, job.status);
      } else {
        await BackendRepository.instance.toggleJobStatus(job.id!, job.status);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(job.isOpen ? 'Deactivated (Closed)' : 'Activated (Open)'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() => _refresh());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _confirmDelete(JobListing job) async {
    if (job.id == null) return;
    final isIntern = job.type == 'Internship';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${isIntern ? 'Internship' : 'Job'}?'),
        content: Text('Are you sure you want to delete "${job.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        if (isIntern) {
          await BackendRepository.instance.deleteInternship(job.id!);
        } else {
          await BackendRepository.instance.deleteJob(job.id!);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isIntern ? 'Internship' : 'Job'} deleted permanently'), backgroundColor: AppColors.success),
        );
        setState(() => _refresh());
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _openEditDialog(JobListing job) async {
    final isIntern = job.type == 'Internship';
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => isIntern ? EditInternshipDialog(internship: job) : EditJobDialog(job: job),
    );
    if (updated == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${isIntern ? 'Internship' : 'Job'} updated successfully'), backgroundColor: AppColors.success),
      );
      setState(() => _refresh());
    }
  }

  void _showViewDetailsSheet(JobListing job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text(job.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                  AppTag(
                    label: job.isOpen ? 'Active (Open)' : 'Inactive (Closed)',
                    bg: job.isOpen ? AppColors.successSoft : AppColors.dangerSoft,
                    fg: job.isOpen ? AppColors.success : AppColors.danger,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${job.company} · ${job.location}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const Divider(height: 24),
              Text('Type: ${job.type} | Salary/Stipend: ${job.salary}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              Text('Qualification: ${job.qualification} | Experience/Duration: ${job.experience}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
              if (job.applicationDeadline != null) ...[
                const SizedBox(height: 6),
                Text('Deadline: ${job.applicationDeadline!.day}/${job.applicationDeadline!.month}/${job.applicationDeadline!.year}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 6),
              Text(job.description.isNotEmpty ? job.description : 'No description provided.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              const SizedBox(height: 16),
              if (job.tags.isNotEmpty) ...[
                const Text('Required Skills', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: job.tags.map((t) => AppTag(label: t)).toList(),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showApplicantsSheet(JobListing job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplicantsSheet(job: job),
    );
  }

  List<JobListing> _applyFilters(List<JobListing> list) {
    return list.where((item) {
      if (_typeFilter == 'Jobs' && item.type == 'Internship') return false;
      if (_typeFilter == 'Internships' && item.type != 'Internship') return false;

      if (_statusFilter == 'Open' && !item.isOpen) return false;
      if (_statusFilter == 'Closed' && !item.isClosed) return false;

      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return item.title.toLowerCase().contains(q) ||
            item.company.toLowerCase().contains(q) ||
            item.tags.any((t) => t.toLowerCase().contains(q));
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Manage Postings',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                AppSearchField(
                  hint: 'Search opportunities by title, skills...',
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: 'All Types', selected: _typeFilter == 'All', onTap: () => setState(() => _typeFilter = 'All')),
                      _FilterChip(label: 'Jobs Only', selected: _typeFilter == 'Jobs', onTap: () => setState(() => _typeFilter = 'Jobs')),
                      _FilterChip(label: 'Internships Only', selected: _typeFilter == 'Internships', onTap: () => setState(() => _typeFilter = 'Internships')),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 24, color: AppColors.border),
                      const SizedBox(width: 12),
                      _FilterChip(label: 'All Status', selected: _statusFilter == 'All', onTap: () => setState(() => _statusFilter = 'All')),
                      _FilterChip(label: 'Active (Open)', selected: _statusFilter == 'Open', onTap: () => setState(() => _statusFilter = 'Open')),
                      _FilterChip(label: 'Inactive (Closed)', selected: _statusFilter == 'Closed', onTap: () => setState(() => _statusFilter = 'Closed')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<JobListing>>(
              future: _postingsFuture,
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
                final allListings = snapshot.data ?? const [];
                final filtered = _applyFilters(allListings);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.work_history_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text('No opportunities match your filter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: () => setState(() {
                            _typeFilter = 'All';
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
                      final job = filtered[i];
                      return _OpportunityCard(
                        job: job,
                        onView: () => _showViewDetailsSheet(job),
                        onEdit: () => _openEditDialog(job),
                        onToggleStatus: () => _toggleStatus(job),
                        onDelete: () => _confirmDelete(job),
                        onViewApplications: () => _showApplicantsSheet(job),
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

class _OpportunityCard extends StatelessWidget {
  final JobListing job;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;
  final VoidCallback onViewApplications;

  const _OpportunityCard({
    required this.job,
    required this.onView,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
    required this.onViewApplications,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            job.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppTag(
                          label: job.isOpen ? 'Active (Open)' : 'Inactive (Closed)',
                          bg: job.isOpen ? AppColors.successSoft : AppColors.dangerSoft,
                          fg: job.isOpen ? AppColors.success : AppColors.danger,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.company} · ${job.location}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AppTag(label: job.type, bg: AppColors.primarySoft, fg: AppColors.primary),
              AppTag(label: job.salary, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary),
              if (job.qualification.isNotEmpty) AppTag(label: job.qualification, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary),
              if (job.experience.isNotEmpty) AppTag(label: job.experience, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary),
            ],
          ),
          const Divider(height: 24),
          // Actions Grid (View, Edit, Delete, Activate/Deactivate, Applications)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text('View'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(70, 32), textStyle: const TextStyle(fontSize: 11.5)),
                onPressed: onView,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(70, 32), textStyle: const TextStyle(fontSize: 11.5)),
                onPressed: onEdit,
              ),
              OutlinedButton.icon(
                icon: Icon(job.isOpen ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, size: 15, color: job.isOpen ? AppColors.success : AppColors.danger),
                label: Text(job.isOpen ? 'Deactivate' : 'Activate'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(95, 32), textStyle: const TextStyle(fontSize: 11.5)),
                onPressed: onToggleStatus,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.danger),
                label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(80, 32), textStyle: const TextStyle(fontSize: 11.5)),
                onPressed: onDelete,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.people_outline_rounded, size: 14),
                label: const Text('Applications'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(110, 32), textStyle: const TextStyle(fontSize: 11.5)),
                onPressed: onViewApplications,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ApplicantsSheet extends StatefulWidget {
  final JobListing job;
  const _ApplicantsSheet({required this.job});

  @override
  State<_ApplicantsSheet> createState() => _ApplicantsSheetState();
}

class _ApplicantsSheetState extends State<_ApplicantsSheet> {
  late Future<List<OpportunityApplicant>> _applicantsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    if (widget.job.id != null) {
      if (widget.job.type == 'Internship') {
        _applicantsFuture = BackendRepository.instance.getInternshipApplicants(widget.job.id!);
      } else {
        _applicantsFuture = BackendRepository.instance.getJobApplicants(widget.job.id!);
      }
    } else {
      _applicantsFuture = Future.value([]);
    }
  }

  Future<void> _updateStatus(OpportunityApplicant applicant, String newStatus) async {
    final isIntern = widget.job.type == 'Internship';
    try {
      if (isIntern) {
        await BackendRepository.instance.updateInternshipApplicationStatus(applicant.id, newStatus);
      } else {
        await BackendRepository.instance.updateJobApplicationStatus(applicant.id, newStatus);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus'), backgroundColor: AppColors.success),
      );
      setState(() => _refresh());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    }
  }

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
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.groups_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Applicants for ${widget.job.title}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<List<OpportunityApplicant>>(
                  future: _applicantsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(snapshot.error.toString(), style: const TextStyle(color: AppColors.textMuted)),
                      );
                    }
                    final applicants = snapshot.data ?? const [];
                    if (applicants.isEmpty) {
                      return const Center(
                        child: Text('No applications received for this posting yet.', style: TextStyle(color: AppColors.textMuted)),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: applicants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final a = applicants[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  InitialsAvatar(initials: a.initials, size: 42),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                        Text(a.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: ['Applied', 'Pending', 'Shortlisted', 'Selected', 'Hired', 'Rejected'].contains(a.status)
                                        ? a.status
                                        : 'Pending',
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: 'Pending', child: Text('Pending', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'Shortlisted', child: Text('Shortlisted', style: TextStyle(fontSize: 12, color: AppColors.primary))),
                                      DropdownMenuItem(value: 'Selected', child: Text('Selected', style: TextStyle(fontSize: 12, color: AppColors.success))),
                                      DropdownMenuItem(value: 'Rejected', child: Text('Rejected', style: TextStyle(fontSize: 12, color: AppColors.danger))),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) _updateStatus(a, v);
                                    },
                                  ),
                                ],
                              ),
                              if (a.coverLetter.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text('Cover Letter: ${a.coverLetter}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
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
      },
    );
  }
}
