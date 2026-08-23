import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';

class EditJobDialog extends StatefulWidget {
  final JobListing job;
  const EditJobDialog({super.key, required this.job});

  @override
  State<EditJobDialog> createState() => _EditJobDialogState();
}

class _EditJobDialogState extends State<EditJobDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _companyCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _skillsCtrl;
  late final TextEditingController _qualificationCtrl;
  late final TextEditingController _experienceCtrl;
  late final TextEditingController _descriptionCtrl;
  late String _jobType;
  late String _status;
  DateTime? _deadline;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.job.title);
    _companyCtrl = TextEditingController(text: widget.job.company);
    _locationCtrl = TextEditingController(text: widget.job.location);
    _skillsCtrl = TextEditingController(text: widget.job.tags.join(', '));
    _qualificationCtrl = TextEditingController(text: widget.job.qualification);
    _experienceCtrl = TextEditingController(text: widget.job.experience);
    _descriptionCtrl = TextEditingController(text: widget.job.description);
    _jobType = widget.job.type.contains('Intern') ? 'Full-time' : widget.job.type;
    if (!['Full-time', 'Part-time', 'Contract', 'Remote'].contains(_jobType)) {
      _jobType = 'Full-time';
    }
    _status = widget.job.status;
    _deadline = widget.job.applicationDeadline;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _locationCtrl.dispose();
    _skillsCtrl.dispose();
    _qualificationCtrl.dispose();
    _experienceCtrl.dispose();
    _descriptionCtrl.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final skills = _skillsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() => _saving = true);

    try {
      if (widget.job.id != null) {
        await BackendRepository.instance.updateJob(
          id: widget.job.id!,
          data: {
            'title': _titleCtrl.text.trim(),
            'company': _companyCtrl.text.trim(),
            'location': _locationCtrl.text.trim(),
            'jobType': _jobType,
            'skillsRequired': skills,
            'qualification': _qualificationCtrl.text.trim(),
            'experienceRequired': _experienceCtrl.text.trim(),
            'description': _descriptionCtrl.text.trim(),
            'status': _status,
            if (_deadline != null) 'applicationDeadline': _deadline!.toIso8601String(),
          },
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Edit Job Details',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Job Title
                const Text('Job Title *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Senior Frontend Engineer'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 14),

                // Company Name
                const Text('Company Name *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _companyCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Google'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Company is required' : null,
                ),
                const SizedBox(height: 14),

                // Location & Job Type
                Row(
                  children: [
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Job Type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _jobType,
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                            items: const [
                              DropdownMenuItem(value: 'Full-time', child: Text('Full-time')),
                              DropdownMenuItem(value: 'Part-time', child: Text('Part-time')),
                              DropdownMenuItem(value: 'Contract', child: Text('Contract')),
                              DropdownMenuItem(value: 'Remote', child: Text('Remote')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _jobType = v);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Qualification & Experience
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Qualification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _qualificationCtrl,
                            decoration: const InputDecoration(hintText: 'e.g. B.Tech / MCA'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Experience', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _experienceCtrl,
                            decoration: const InputDecoration(hintText: 'e.g. 0-2 years'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Status & Deadline
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status (Publish/Unpublish)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                            items: const [
                              DropdownMenuItem(value: 'Open', child: Text('Open (Published)')),
                              DropdownMenuItem(value: 'Closed', child: Text('Closed (Unpublished)')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _status = v);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Deadline', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
                                        : 'Select Date',
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
                const SizedBox(height: 14),

                // Skills Required
                const Text('Required Skills', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _skillsCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Flutter, Dart, REST API (comma separated)'),
                ),
                const SizedBox(height: 14),

                // Description
                const Text('Job Description *', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Describe the role, responsibilities & perks...'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
