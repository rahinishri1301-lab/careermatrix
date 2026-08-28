import 'package:flutter/material.dart';
import '../../data/app_state.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';

/// Edit Profile — reads/writes the real Profile document via
/// GET /api/profile/me and POST|PUT /api/profile (BackendRepository already
/// picks POST vs PUT depending on whether a profile exists yet).
///
/// Field set is role-aware since the backend's single Profile schema is
/// shared across roles: students see academic fields, alumni/mentors see
/// professional fields, everyone sees the common ones (bio/phone/links).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _cgpaCtrl = TextEditingController();
  final _areaOfInterestCtrl = TextEditingController();
  final _careerGoalCtrl = TextEditingController();
  final _graduationYearCtrl = TextEditingController();
  final _currentPositionCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _githubCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  late final UserRole _role = AppState.instance.currentRole.value;
  bool get _isStudent => _role == UserRole.student;
  bool get _isProfessional => _role == UserRole.alumni || _role == UserRole.mentor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await BackendRepository.instance.getMyProfileRaw();
      if (profile != null) {
        _bioCtrl.text = profile['bio'] as String? ?? '';
        _phoneCtrl.text = profile['phone'] as String? ?? '';
        _addressCtrl.text = profile['address'] as String? ?? '';
        _departmentCtrl.text = profile['department'] as String? ?? '';
        _cgpaCtrl.text = (profile['cgpa'] as num?)?.toString() ?? '';
        _areaOfInterestCtrl.text = profile['areaOfInterest'] as String? ?? '';
        _careerGoalCtrl.text = profile['careerGoal'] as String? ?? '';
        _graduationYearCtrl.text = (profile['graduationYear'] as num?)?.toString() ?? '';
        _currentPositionCtrl.text = profile['currentPosition'] as String? ?? '';
        _companyCtrl.text = profile['company'] as String? ?? '';
        _linkedinCtrl.text = profile['linkedin'] as String? ?? '';
        _githubCtrl.text = profile['github'] as String? ?? '';
      }
    } catch (e) {
      _loadError = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _departmentCtrl.dispose();
    _cgpaCtrl.dispose();
    _areaOfInterestCtrl.dispose();
    _careerGoalCtrl.dispose();
    _graduationYearCtrl.dispose();
    _currentPositionCtrl.dispose();
    _companyCtrl.dispose();
    _linkedinCtrl.dispose();
    _githubCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _saving = true);
    try {
      await BackendRepository.instance.saveProfile({
        'bio': _bioCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_addressCtrl.text.trim().isNotEmpty) 'address': _addressCtrl.text.trim(),
        if (_departmentCtrl.text.trim().isNotEmpty) 'department': _departmentCtrl.text.trim(),
        if (_cgpaCtrl.text.trim().isNotEmpty) 'cgpa': double.tryParse(_cgpaCtrl.text.trim()),
        if (_areaOfInterestCtrl.text.trim().isNotEmpty) 'areaOfInterest': _areaOfInterestCtrl.text.trim(),
        if (_careerGoalCtrl.text.trim().isNotEmpty) 'careerGoal': _careerGoalCtrl.text.trim(),
        if (_graduationYearCtrl.text.trim().isNotEmpty) 'graduationYear': int.tryParse(_graduationYearCtrl.text.trim()),
        if (_currentPositionCtrl.text.trim().isNotEmpty) 'currentPosition': _currentPositionCtrl.text.trim(),
        if (_companyCtrl.text.trim().isNotEmpty) 'company': _companyCtrl.text.trim(),
        if (_linkedinCtrl.text.trim().isNotEmpty) 'linkedin': _linkedinCtrl.text.trim(),
        if (_githubCtrl.text.trim().isNotEmpty) 'github': _githubCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved'), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Edit Profile',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(_loadError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    children: [
                      _label('Bio'),
                      TextFormField(
                        controller: _bioCtrl,
                        maxLines: 3,
                        maxLength: 500,
                        decoration: const InputDecoration(hintText: 'A short introduction about yourself'),
                      ),
                      if (_isStudent) ...[
                        _label('Department'),
                        TextFormField(controller: _departmentCtrl, decoration: const InputDecoration(hintText: 'e.g. Computer Science')),
                        const SizedBox(height: 14),
                        _label('CGPA (0–10)'),
                        TextFormField(
                          controller: _cgpaCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = double.tryParse(v.trim());
                            if (n == null || n < 0 || n > 10) return 'Enter a value between 0 and 10';
                            return null;
                          },
                          decoration: const InputDecoration(hintText: 'e.g. 8.5'),
                        ),
                        const SizedBox(height: 14),
                        _label('Area of Interest'),
                        TextFormField(controller: _areaOfInterestCtrl, decoration: const InputDecoration(hintText: 'e.g. Machine Learning, Web Development')),
                        const SizedBox(height: 14),
                        _label('Career Goal'),
                        TextFormField(
                          controller: _careerGoalCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(hintText: 'e.g. Become a full-stack developer at a product company'),
                        ),
                        const SizedBox(height: 14),
                        _label('Graduation Year'),
                        TextFormField(
                          controller: _graduationYearCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 1950 || n > 2100) return 'Enter a valid year';
                            return null;
                          },
                          decoration: const InputDecoration(hintText: 'e.g. 2026'),
                        ),
                      ],
                      if (_isProfessional) ...[
                        _label('Current Position'),
                        TextFormField(controller: _currentPositionCtrl, decoration: const InputDecoration(hintText: 'e.g. Software Engineer')),
                        const SizedBox(height: 14),
                        _label('Company'),
                        TextFormField(controller: _companyCtrl, decoration: const InputDecoration(hintText: 'e.g. Acme Corp')),
                        const SizedBox(height: 14),
                        _label('Graduation Year'),
                        TextFormField(
                          controller: _graduationYearCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null;
                            final n = int.tryParse(v.trim());
                            if (n == null || n < 1950 || n > 2100) return 'Enter a valid year';
                            return null;
                          },
                          decoration: const InputDecoration(hintText: 'e.g. 2020'),
                        ),
                      ],
                      _label('Phone'),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final ok = RegExp(r'^[0-9+\-\s()]{7,20}$').hasMatch(v.trim());
                          return ok ? null : 'Enter a valid phone number';
                        },
                        decoration: const InputDecoration(hintText: '+91 98765 43210'),
                      ),
                      const SizedBox(height: 14),
                      _label('Address'),
                      TextFormField(controller: _addressCtrl, decoration: const InputDecoration(hintText: 'City, Country')),
                      const SizedBox(height: 14),
                      _label('LinkedIn'),
                      TextFormField(
                        controller: _linkedinCtrl,
                        keyboardType: TextInputType.url,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return Uri.tryParse(v.trim())?.hasScheme == true ? null : 'Must start with http:// or https://';
                        },
                        decoration: const InputDecoration(hintText: 'https://linkedin.com/in/you'),
                      ),
                      const SizedBox(height: 14),
                      _label('GitHub'),
                      TextFormField(
                        controller: _githubCtrl,
                        keyboardType: TextInputType.url,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return Uri.tryParse(v.trim())?.hasScheme == true ? null : 'Must start with http:// or https://';
                        },
                        decoration: const InputDecoration(hintText: 'https://github.com/you'),
                      ),
                      const SizedBox(height: 26),
                      LoadingElevatedButton(loading: _saving, onPressed: _save, child: const Text('Save Profile')),
                    ],
                  ),
                ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 14),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );
}
