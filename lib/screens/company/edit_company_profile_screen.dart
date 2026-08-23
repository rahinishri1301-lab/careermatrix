import 'package:flutter/material.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common_widgets.dart';
import 'company_documents_screen.dart';

class EditCompanyProfileScreen extends StatefulWidget {
  const EditCompanyProfileScreen({super.key});

  @override
  State<EditCompanyProfileScreen> createState() => _EditCompanyProfileScreenState();
}

class _EditCompanyProfileScreenState extends State<EditCompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _nameCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await BackendRepository.instance.getMyProfileRaw();
      final user = await BackendRepository.instance.getMyAppUser();
      if (mounted) {
        _nameCtrl.text = user.name != 'Guest User' ? user.name : (profile?['company'] as String? ?? '');
        if (profile != null) {
          _industryCtrl.text = profile['industry'] as String? ?? '';
          _descriptionCtrl.text = (profile['description'] as String?) ?? (profile['bio'] as String? ?? '');
          _websiteCtrl.text = profile['website'] as String? ?? '';
          _locationCtrl.text = (profile['address'] as String?) ?? '';
          _phoneCtrl.text = (profile['phone'] as String?) ?? '';
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final companyName = _nameCtrl.text.trim();
      final industry = _industryCtrl.text.trim();
      final description = _descriptionCtrl.text.trim();
      final website = _websiteCtrl.text.trim();
      final location = _locationCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      await BackendRepository.instance.saveProfile({
        'name': companyName,
        'company': companyName,
        'industry': industry,
        'description': description,
        'bio': description.length > 500 ? description.substring(0, 500) : description,
        'website': website,
        'address': location,
        'phone': phone,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
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
  void dispose() {
    _nameCtrl.dispose();
    _industryCtrl.dispose();
    _descriptionCtrl.dispose();
    _websiteCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            maxLines: maxLines,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Edit Company Profile',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 42, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      _field(
                        _nameCtrl,
                        'Company Name',
                        hint: 'e.g. Acme Corporation',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
                      ),
                      _field(
                        _industryCtrl,
                        'Industry / Domain',
                        hint: 'e.g. Information Technology & Services',
                      ),
                      _field(
                        _locationCtrl,
                        'Headquarters / Location',
                        hint: 'e.g. Bengaluru, Karnataka / Remote',
                      ),
                      _field(
                        _websiteCtrl,
                        'Company Website URL',
                        hint: 'e.g. https://www.acme.com',
                        keyboardType: TextInputType.url,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final uri = Uri.tryParse(v.trim());
                          if (uri == null || !uri.hasScheme) return 'Please enter a valid URL (e.g. https://...)';
                          return null;
                        },
                      ),
                      _field(
                        _phoneCtrl,
                        'Contact Phone',
                        hint: 'e.g. +91 9876543210',
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final ok = RegExp(r'^[0-9+\-\s()]{7,20}$').hasMatch(v.trim());
                          return ok ? null : 'Enter a valid phone number';
                        },
                      ),
                      _field(
                        _descriptionCtrl,
                        'About Company (Description)',
                        hint: 'Describe your company mission, culture, technologies, and hiring vision...',
                        maxLines: 5,
                        maxLength: 2000,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('Company Verification Documents'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CompanyDocumentsScreen()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                              )
                            : const Text('Save Profile Details'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
