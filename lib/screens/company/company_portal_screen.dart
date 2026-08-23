import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import 'edit_job_dialog.dart';
import 'edit_internship_dialog.dart';
import 'manage_postings_screen.dart';
import 'company_messages_screen.dart';
import 'schedule_interview_dialog.dart';

class CompanyPortalScreen extends StatefulWidget {
  final int initialTab;
  const CompanyPortalScreen({super.key, this.initialTab = 0});

  @override
  State<CompanyPortalScreen> createState() => _CompanyPortalScreenState();
}

class _CompanyPortalScreenState extends State<CompanyPortalScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    final clampedIndex = widget.initialTab.clamp(0, 2);
    _tab = TabController(length: 3, vsync: this, initialIndex: clampedIndex);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Company Portal',
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            tabs: const [
              Tab(text: 'My Postings'),
              Tab(text: 'Post Opportunity'),
              Tab(text: 'Find Candidates'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                const _MyPostingsTab(),
                _PostJobTab(onSuccess: () => _tab.animateTo(0)),
                const _CandidateSearchTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyPostingsTab extends StatefulWidget {
  const _MyPostingsTab();

  @override
  State<_MyPostingsTab> createState() => _MyPostingsTabState();
}

class _MyPostingsTabState extends State<_MyPostingsTab> {
  late Future<List<JobListing>> _postingsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _postingsFuture = BackendRepository.instance.getMyPostings();
  }

  Future<void> _togglePublishStatus(JobListing job) async {
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
          content: Text(job.isOpen ? 'Unpublished (Closed)' : 'Published (Open)'),
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
        title: Text('Delete ${isIntern ? 'Internship' : 'Job'} Posting?'),
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
          SnackBar(content: Text('${isIntern ? 'Internship' : 'Job'} posting deleted'), backgroundColor: AppColors.success),
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

  void _openViewDetails(JobListing job) {
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

  void _openApplicants(JobListing job) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManagePostingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<JobListing>>(
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
                  ElevatedButton(
                    onPressed: () => setState(() => _refresh()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final postings = snapshot.data ?? const [];
        if (postings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.work_outline_rounded, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 12),
                const Text('No postings created yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                const Text('Use the "Post Opportunity" tab to publish a job.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => setState(() => _refresh()),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            itemCount: postings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final job = postings[i];
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
                                    label: job.isOpen ? 'Published (Open)' : 'Unpublished (Closed)',
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
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                          onSelected: (val) {
                            if (val == 'edit') _openEditDialog(job);
                            if (val == 'toggle') _togglePublishStatus(job);
                            if (val == 'delete') _confirmDelete(job);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text('Edit Job'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(job.isOpen ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                                  const SizedBox(width: 10),
                                  Text(job.isOpen ? 'Unpublish Job' : 'Publish Job'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                                  SizedBox(width: 10),
                                  Text('Delete Job', style: TextStyle(color: AppColors.danger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppTag(label: job.type, bg: AppColors.primarySoft, fg: AppColors.primary),
                        AppTag(label: job.salary, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary),
                        if (job.qualification.isNotEmpty)
                          AppTag(label: job.qualification, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary),
                        if (job.experience.isNotEmpty)
                          AppTag(label: job.experience, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary),
                      ],
                    ),
                    if (job.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: job.tags
                            .map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border, width: 0.8),
                                  ),
                                  child: Text(t, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ))
                            .toList(),
                      ),
                    ],
                    const Divider(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_outlined, size: 14),
                          label: const Text('View'),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(65, 32), textStyle: const TextStyle(fontSize: 11.5)),
                          onPressed: () => _openViewDetails(job),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(65, 32), textStyle: const TextStyle(fontSize: 11.5)),
                          onPressed: () => _openEditDialog(job),
                        ),
                        OutlinedButton.icon(
                          icon: Icon(job.isOpen ? Icons.toggle_on_rounded : Icons.toggle_off_rounded, size: 15, color: job.isOpen ? AppColors.success : AppColors.danger),
                          label: Text(job.isOpen ? 'Deactivate' : 'Activate'),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(90, 32), textStyle: const TextStyle(fontSize: 11.5)),
                          onPressed: () => _togglePublishStatus(job),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.danger),
                          label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                          style: OutlinedButton.styleFrom(minimumSize: const Size(75, 32), textStyle: const TextStyle(fontSize: 11.5)),
                          onPressed: () => _confirmDelete(job),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.people_outline_rounded, size: 14),
                          label: const Text('Applications'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size(105, 32), textStyle: const TextStyle(fontSize: 11.5)),
                          onPressed: () => _openApplicants(job),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}class _PostJobTab extends StatefulWidget {
  final VoidCallback? onSuccess;
  const _PostJobTab({this.onSuccess});

  @override
  State<_PostJobTab> createState() => _PostJobTabState();
}

class _PostJobTabState extends State<_PostJobTab> {
  final _formKey = GlobalKey<FormState>();
  final _companyCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _salaryOrStipendCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController(text: 'B.Tech / MCA / Any Graduate');
  final _experienceCtrl = TextEditingController(text: '0-2 years');
  final _skillsCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '3 months');
  DateTime? _deadline;
  String _type = 'Full-time';
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    final name = AppState.instance.userName.value;
    _companyCtrl.text = name.isNotEmpty ? name : 'Company';
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _salaryOrStipendCtrl.dispose();
    _qualificationCtrl.dispose();
    _experienceCtrl.dispose();
    _skillsCtrl.dispose();
    _descriptionCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submit() async {
    if (_companyCtrl.text.trim().isEmpty) {
      final name = AppState.instance.userName.value;
      _companyCtrl.text = name.isNotEmpty ? name : 'Company';
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all required fields marked with *'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final skills = _skillsCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    setState(() => _posting = true);
    try {
      if (_type == 'Internship') {
        await BackendRepository.instance.createInternship(
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          company: _companyCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          duration: _durationCtrl.text.trim().isEmpty ? '3 months' : _durationCtrl.text.trim(),
          stipend: num.tryParse(_salaryOrStipendCtrl.text.trim()),
          skillsRequired: skills,
          qualification: _qualificationCtrl.text.trim(),
          applicationDeadline: _deadline,
        );
      } else {
        final salaryVal = int.tryParse(_salaryOrStipendCtrl.text.trim());
        await BackendRepository.instance.createJob(
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          company: _companyCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          jobType: _type,
          skillsRequired: skills,
          qualification: _qualificationCtrl.text.trim(),
          experienceRequired: _experienceCtrl.text.trim(),
          salaryMin: salaryVal,
          salaryMax: salaryVal != null ? (salaryVal * 1.25).toInt() : null,
          applicationDeadline: _deadline,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opportunity posted & saved permanently in MongoDB!'), backgroundColor: AppColors.success),
      );
      _titleCtrl.clear();
      _locationCtrl.clear();
      _salaryOrStipendCtrl.clear();
      _skillsCtrl.clear();
      _descriptionCtrl.clear();
      setState(() => _deadline = null);
      widget.onSuccess?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add_business_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Publish New Opportunity',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Fill out the form below to recruit talent from CareerMatrix.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Section 1: Basic Information
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.work_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Basic Information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
                const Divider(height: 24),
                const Text('Role Title *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Senior Software Engineer / Data Analyst'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Role title is required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Opportunity Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Full-time', 'Part-time', 'Contract', 'Remote', 'Internship'].map((t) {
                      final selected = _type == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w700)),
                          selected: selected,
                          onSelected: (_) => setState(() => _type = t),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceMuted,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide.none),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Company Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _companyCtrl,
                            decoration: const InputDecoration(hintText: 'e.g. Acme Corp'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Company name is required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Location *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _locationCtrl,
                            decoration: const InputDecoration(hintText: 'e.g. Bengaluru / Remote'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Section 2: Compensation & Qualifications
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Compensation & Qualifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_type == 'Internship' ? 'Stipend (monthly, ₹)' : 'Salary (annual min, ₹)', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _salaryOrStipendCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(hintText: _type == 'Internship' ? 'e.g. 15000' : 'e.g. 1000000'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_type == 'Internship' ? 'Duration' : 'Experience Required', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _type == 'Internship' ? _durationCtrl : _experienceCtrl,
                            decoration: InputDecoration(hintText: _type == 'Internship' ? 'e.g. 3 months' : 'e.g. 0-2 years'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Qualification Required', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _qualificationCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. B.Tech / MCA / Any Graduate'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Section 3: Skills & Deadline
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Skills & Application Deadline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Required Skills', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _skillsCtrl,
                            decoration: const InputDecoration(hintText: 'e.g. SQL, Python, Flutter'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Application Deadline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickDeadline,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _deadline != null
                                        ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                                        : 'Select Deadline',
                                    style: TextStyle(
                                      color: _deadline != null ? AppColors.textPrimary : AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Section 4: Role Description
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Job Description & Perks *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
                const Divider(height: 24),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(hintText: 'Describe the role responsibilities, team culture, candidate requirements, and key perks...'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Job description is required' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _posting ? null : _submit,
              icon: _posting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_posting ? 'Publishing...' : 'Post Opportunity', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateSearchTab extends StatefulWidget {
  const _CandidateSearchTab();

  @override
  State<_CandidateSearchTab> createState() => _CandidateSearchTabState();
}

class _CandidateSearchTabState extends State<_CandidateSearchTab> {
  late Future<List<CandidateProfile>> _future;
  String _searchQuery = '';
  String? _skillFilter;
  String? _domainFilter;
  String? _qualificationFilter;
  String? _experienceFilter;
  String? _locationFilter;
  String? _jobIdFilter;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  void _loadCandidates() {
    _future = BackendRepository.instance.getCandidates(
      search: _searchQuery,
      skill: _skillFilter,
      domain: _domainFilter,
      qualification: _qualificationFilter,
      experience: _experienceFilter,
      location: _locationFilter,
      jobId: _jobIdFilter,
    );
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _loadCandidates();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _skillFilter = null;
      _domainFilter = null;
      _qualificationFilter = null;
      _experienceFilter = null;
      _locationFilter = null;
      _jobIdFilter = null;
      _loadCandidates();
    });
  }

  void _openFilterDialog() {
    final skillCtrl = TextEditingController(text: _skillFilter ?? '');
    final domainCtrl = TextEditingController(text: _domainFilter ?? '');
    final expCtrl = TextEditingController(text: _experienceFilter ?? '');
    final locCtrl = TextEditingController(text: _locationFilter ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.filter_list_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Filter Candidates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: skillCtrl,
                  decoration: const InputDecoration(labelText: 'Required Skill', hintText: 'e.g. Flutter, React, Python, Node.js'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: domainCtrl,
                  decoration: const InputDecoration(labelText: 'Domain / Department', hintText: 'e.g. Computer Science, Data Science'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: expCtrl,
                  decoration: const InputDecoration(labelText: 'Experience Level / Position', hintText: 'e.g. Student, Intern, Full-stack'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Location / City', hintText: 'e.g. New York, Remote, London'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllFilters();
              },
              child: const Text('Reset All', style: TextStyle(color: AppColors.danger)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _skillFilter = skillCtrl.text.trim().isEmpty ? null : skillCtrl.text.trim();
                  _domainFilter = domainCtrl.text.trim().isEmpty ? null : domainCtrl.text.trim();
                  _experienceFilter = expCtrl.text.trim().isEmpty ? null : expCtrl.text.trim();
                  _locationFilter = locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim();
                  _loadCandidates();
                });
              },
              child: const Text('Apply Filters'),
            ),
          ],
        );
      },
    );
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _skillFilter != null ||
      _domainFilter != null ||
      _qualificationFilter != null ||
      _experienceFilter != null ||
      _locationFilter != null ||
      _jobIdFilter != null;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: AppSearchField(
                hint: 'Search by candidate name, skill, domain, location...',
                onChanged: _onSearch,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              icon: Icon(Icons.tune_rounded, color: _hasActiveFilters ? AppColors.primary : AppColors.textSecondary),
              tooltip: 'Advanced Filters',
              onPressed: _openFilterDialog,
            ),
          ],
        ),
        if (_hasActiveFilters) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (_skillFilter != null)
                  _ActiveFilterTag(label: 'Skill: $_skillFilter', onRemove: () => setState(() { _skillFilter = null; _loadCandidates(); })),
                if (_domainFilter != null)
                  _ActiveFilterTag(label: 'Domain: $_domainFilter', onRemove: () => setState(() { _domainFilter = null; _loadCandidates(); })),
                if (_experienceFilter != null)
                  _ActiveFilterTag(label: 'Exp: $_experienceFilter', onRemove: () => setState(() { _experienceFilter = null; _loadCandidates(); })),
                if (_locationFilter != null)
                  _ActiveFilterTag(label: 'Loc: $_locationFilter', onRemove: () => setState(() { _locationFilter = null; _loadCandidates(); })),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        FutureBuilder<List<CandidateProfile>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => setState(() => _loadCandidates()), child: const Text('Retry')),
                  ],
                ),
              );
            }
            final candidates = snapshot.data ?? const [];
            if (candidates.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.person_search_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    const Text('No candidates match your search filter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    if (_hasActiveFilters) ...[
                      const SizedBox(height: 8),
                      TextButton(onPressed: _clearAllFilters, child: const Text('Clear All Filters')),
                    ],
                  ],
                ),
              );
            }
            return Column(
              children: candidates
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CandidateCard(candidate: c),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ActiveFilterTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveFilterTag({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primarySoft,
        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
        onDeleted: onRemove,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final CandidateProfile candidate;
  const _CandidateCard({required this.candidate});

  void _showCandidateModal(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 16),
              Row(
                children: [
                  InitialsAvatar(initials: candidate.initials, size: 54),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(candidate.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                        Text(candidate.email, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                  AppTag(label: '${candidate.matchPercent}% Match', bg: AppColors.successSoft, fg: AppColors.success),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(child: _CandidateInfoItem(label: 'Department / Domain', value: candidate.department)),
                  Expanded(child: _CandidateInfoItem(label: 'Experience / Position', value: candidate.course)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _CandidateInfoItem(label: 'Location', value: candidate.location)),
                  Expanded(child: _CandidateInfoItem(label: 'Graduation Year', value: candidate.graduationYear)),
                ],
              ),
              if (candidate.bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Bio / Summary', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 6),
                Text(candidate.bio, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              ],
              const SizedBox(height: 16),
              const Text('Skills & Competencies', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 8),
              if (candidate.skills.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidate.skills.map((s) => AppTag(label: s)).toList(),
                )
              else
                const Text('No skills listed', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Direct Message'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              recipientId: candidate.id ?? '',
                              recipientName: candidate.name,
                              recipientRole: candidate.role,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            candidateId: candidate.id ?? '',
                            candidateName: candidate.name,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
              InitialsAvatar(initials: candidate.initials, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(candidate.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))),
                        AppTag(label: '${candidate.matchPercent}% Match', bg: AppColors.successSoft, fg: AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${candidate.department} · ${candidate.course}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📍 ${candidate.location}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (candidate.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: candidate.skills.map((s) => AppTag(label: s, bg: AppColors.surfaceMuted, fg: AppColors.textSecondary)).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_outline_rounded, size: 14),
                  label: const Text('View Profile'),
                  onPressed: () => _showCandidateModal(context),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(36), textStyle: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 14),
                  label: const Text('Invite Candidate'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invited ${candidate.name} to apply!'), backgroundColor: AppColors.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(36), textStyle: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CandidateInfoItem extends StatelessWidget {
  final String label;
  final String value;
  const _CandidateInfoItem({required this.label, required this.value});

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
