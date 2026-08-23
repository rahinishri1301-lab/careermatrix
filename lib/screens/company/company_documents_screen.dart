import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/backend_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/common_widgets.dart';

class CompanyDocumentsScreen extends StatefulWidget {
  const CompanyDocumentsScreen({super.key});

  @override
  State<CompanyDocumentsScreen> createState() => _CompanyDocumentsScreenState();
}

class _CompanyDocumentsScreenState extends State<CompanyDocumentsScreen> {
  late Future<List<CertificateItem>> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = BackendRepository.instance.getMyCertificates();
    });
  }

  Future<void> _addDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;

    final titleCtrl = TextEditingController(text: file.name.split('.').first);
    final categoryCtrl = TextEditingController(text: 'Company Registration');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Document Details', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File: ${file.name}', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              const SizedBox(height: 12),
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Document Title', hintText: 'e.g. Registration Certificate'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category / Issuer', hintText: 'e.g. Government, Tax, Compliance'),
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
            child: const Text('Upload Document'),
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
        issuer: categoryCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document successfully uploaded to MongoDB!'), backgroundColor: AppColors.success),
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(CertificateItem doc) async {
    setState(() => _busy = true);
    try {
      final path = await BackendRepository.instance.downloadCertificate(doc.id, doc.originalName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document saved to $path — accessible anytime.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CertificateItem doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to delete "${doc.title}"? This will purge it from MongoDB and server storage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Document'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BackendRepository.instance.deleteCertificate(doc.id);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted from MongoDB'), backgroundColor: AppColors.warning),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScreenScaffold(
      title: 'Company Documents',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _addDocument,
        backgroundColor: AppColors.primary,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: const Text('Upload Document', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                    Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text('Failed to load documents: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data ?? const [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_open_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text('No Company Documents Uploaded', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      'Upload your Company Registration, Tax/GST Certificates, or Proof of Business. Files are permanently stored in MongoDB.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i];
              return AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 3),
                          if ((d.issuer ?? '').isNotEmpty)
                            Text(
                              d.issuer!,
                              style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            d.originalName,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, size: 22, color: AppColors.primary),
                      onPressed: _busy ? null : () => _download(d),
                      tooltip: 'View / Download',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppColors.danger),
                      onPressed: _busy ? null : () => _delete(d),
                      tooltip: 'Delete Document',
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
