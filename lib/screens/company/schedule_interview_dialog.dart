import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';

class ScheduleInterviewDialog extends StatefulWidget {
  final String candidateId;
  final String candidateName;
  final String? jobId;
  final String? internshipId;
  final String? opportunityTitle;

  const ScheduleInterviewDialog({
    super.key,
    required this.candidateId,
    required this.candidateName,
    this.jobId,
    this.internshipId,
    this.opportunityTitle,
  });

  @override
  State<ScheduleInterviewDialog> createState() => _ScheduleInterviewDialogState();
}

class _ScheduleInterviewDialogState extends State<ScheduleInterviewDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _linkCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _locationCtrl;

  String _interviewType = 'Technical';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  int _durationMinutes = 45;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final defaultTitle = widget.opportunityTitle != null && widget.opportunityTitle!.isNotEmpty
        ? 'Interview for ${widget.opportunityTitle}'
        : 'Interview with ${widget.candidateName}';
    _titleCtrl = TextEditingController(text: defaultTitle);
    _linkCtrl = TextEditingController(text: 'https://meet.google.com/abc-defg-hij');
    _notesCtrl = TextEditingController();
    _locationCtrl = TextEditingController(text: 'Online Video Call');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _notesCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      await BackendRepository.instance.scheduleInterview(
        candidateId: widget.candidateId,
        jobId: widget.jobId,
        internshipId: widget.internshipId,
        title: _titleCtrl.text.trim(),
        interviewType: _interviewType,
        scheduledDate: scheduledDateTime,
        durationMinutes: _durationMinutes,
        meetingLink: _linkCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Interview successfully scheduled with ${widget.candidateName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule interview: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
    final timeStr = _selectedTime.format(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Schedule Interview',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Candidate: ${widget.candidateName}', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Interview Title', hintText: 'e.g. Technical Round 1'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _interviewType,
                decoration: const InputDecoration(labelText: 'Interview Type'),
                items: const [
                  DropdownMenuItem(value: 'Technical', child: Text('Technical Round')),
                  DropdownMenuItem(value: 'HR', child: Text('HR Round')),
                  DropdownMenuItem(value: 'Managerial', child: Text('Managerial Round')),
                  DropdownMenuItem(value: 'Screening', child: Text('Screening Call')),
                  DropdownMenuItem(value: 'Final Round', child: Text('Final Round')),
                ],
                onChanged: (val) => setState(() => _interviewType = val ?? 'Technical'),
              ),
              const SizedBox(height: 12),

              // Date & Time Pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(dateStr, style: const TextStyle(fontSize: 12)),
                      onPressed: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time_rounded, size: 16),
                      label: Text(timeStr, style: const TextStyle(fontSize: 12)),
                      onPressed: _pickTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: _durationMinutes,
                decoration: const InputDecoration(labelText: 'Duration'),
                items: const [
                  DropdownMenuItem(value: 30, child: Text('30 Minutes')),
                  DropdownMenuItem(value: 45, child: Text('45 Minutes')),
                  DropdownMenuItem(value: 60, child: Text('1 Hour')),
                  DropdownMenuItem(value: 90, child: Text('1.5 Hours')),
                ],
                onChanged: (val) => setState(() => _durationMinutes = val ?? 45),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _linkCtrl,
                decoration: const InputDecoration(labelText: 'Meeting Link', hintText: 'Google Meet / Zoom URL'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes / Preparation Tips', hintText: 'Optional notes for candidate'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Schedule'),
        ),
      ],
    );
  }
}
