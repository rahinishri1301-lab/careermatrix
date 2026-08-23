import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late Future<List<CertificateItem>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = BackendRepository.instance.getMyCertificates();
  }

  void _reload() {
    setState(() => _future = BackendRepository.instance.getMyCertificates());
  }

  Future<void> _addCertificate() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;

    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Certificate Details'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File: ${file.name}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              const SizedBox(height: 12),
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Certificate name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: issuerCtrl,
                decoration: const InputDecoration(labelText: 'Issued by (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await BackendRepository.instance.addCertificate(
        bytes: file.bytes!,
        filename: file.name,
        title: titleCtrl.text.trim(),
        issuer: issuerCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate uploaded'), backgroundColor: AppColors.success),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(CertificateItem cert) async {
    setState(() => _busy = true);
    try {
      final path = await BackendRepository.instance.downloadCertificate(cert.id, cert.originalName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to $path — open it from your file manager.'), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CertificateItem cert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete certificate?'),
        content: Text('This will remove "${cert.title}" from your profile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await BackendRepository.instance.deleteCertificate(cert.id);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Certificates & Achievements',
      floatingActionButton: FloatingActionButton(
        onPressed: _busy ? null : _addCertificate,
        backgroundColor: AppColors.primary,
        child: _busy
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.add, color: Colors.white),
      ),
      body: FutureBuilder<List<CertificateItem>>(
        future: _future,
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
          final certs = snapshot.data ?? const [];
          if (certs.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              children: const [
                Center(
                  child: Text(
                    "You haven't uploaded any certificates yet.\nTap + to add your first one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: certs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = certs[i];
              return AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.warningSoft, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.emoji_events_rounded, color: AppColors.warning),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                          const SizedBox(height: 2),
                          if ((c.issuer ?? '').isNotEmpty)
                            Text(c.issuer!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
                          Text(c.originalName, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, size: 20),
                      onPressed: _busy ? null : () => _download(c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                      onPressed: () => _delete(c),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
