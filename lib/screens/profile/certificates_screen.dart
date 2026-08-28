import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';
import 'certificate_preview_screen.dart';

/// Certificates & Achievements — real upload/list/download/delete against
/// POST/GET/DELETE /api/certificates (see backend/controllers/certificateController.js).
class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  late Future<List<CertificateItem>> _future;
  bool _uploading = false;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _future = BackendRepository.instance.getMyCertificates();
  }

  void _reload() => setState(() => _future = BackendRepository.instance.getMyCertificates());

  Future<void> _uploadFlow() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;

    final titleCtrl = TextEditingController();
    final issuerCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Certificate details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'e.g. AWS Certified Cloud Practitioner')),
            const SizedBox(height: 12),
            TextField(controller: issuerCtrl, decoration: const InputDecoration(hintText: 'Issuer (optional), e.g. Amazon Web Services')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Upload')),
        ],
      ),
    );
    if (confirmed != true || titleCtrl.text.trim().isEmpty) return;

    setState(() => _uploading = true);
    try {
      await BackendRepository.instance.uploadCertificate(
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
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _download(CertificateItem cert) async {
    if (cert.id == null) return;
    setState(() => _busyId = cert.id);
    try {
      final path = await BackendRepository.instance.downloadCertificate(
        cert.id!,
        fallbackFilename: cert.originalName.isNotEmpty ? cert.originalName : '${cert.title}.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kIsWeb ? 'Downloaded $path' : 'Saved to $path — open it from your file manager.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to download certificate. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _view(CertificateItem cert) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CertificatePreviewScreen(certificate: cert),
      ),
    );
  }

  Future<void> _delete(CertificateItem cert) async {
    if (cert.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete certificate?'),
        content: Text('Remove "${cert.title}" from your profile?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busyId = cert.id);
    try {
      await BackendRepository.instance.deleteCertificate(cert.id!);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Certificates & Achievements',
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
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            children: [
              if (certs.isEmpty)
                const EmptyState(
                  icon: Icons.workspace_premium_outlined,
                  title: 'No certificates yet',
                  subtitle: 'Upload your certifications and achievements to showcase them on your profile',
                )
              else
                ...certs.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                  if (c.issuer.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(c.issuer, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    ),
                                ],
                              ),
                            ),
                            _busyId == c.id
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility_rounded, size: 20, color: AppColors.primary),
                                        onPressed: () => _view(c),
                                        tooltip: 'View Certificate',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.download_rounded, size: 20, color: AppColors.textSecondary),
                                        onPressed: () => _download(c),
                                        tooltip: 'Download Certificate',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                                        onPressed: () => _delete(c),
                                        tooltip: 'Delete Certificate',
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _uploadFlow,
        backgroundColor: AppColors.primary,
        icon: _uploading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.upload_rounded, color: Colors.white),
        label: const Text('Upload', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
