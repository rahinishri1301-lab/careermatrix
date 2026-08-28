// lib/widgets/pdf_preview_viewer_web.dart
//
// Web implementation: renders the PDF inside the browser's built-in PDF
// viewer via an <iframe> with a blob: URL.  Zero external dependencies.
//
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class PdfPreviewViewer extends StatefulWidget {
  final Uint8List pdfBytes;
  const PdfPreviewViewer({super.key, required this.pdfBytes});

  @override
  State<PdfPreviewViewer> createState() => _PdfPreviewViewerState();
}

class _PdfPreviewViewerState extends State<PdfPreviewViewer> {
  late final String _viewType;
  String? _blobUrl;

  @override
  void initState() {
    super.initState();
    // Create a unique view type so multiple previews don't clash.
    _viewType = 'pdf-preview-${DateTime.now().millisecondsSinceEpoch}';

    // Build a blob URL from the PDF bytes.
    final blob = html.Blob([widget.pdfBytes], 'application/pdf');
    _blobUrl = html.Url.createObjectUrlFromBlob(blob);

    // Register a platform view factory that creates an <iframe>.
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = _blobUrl!
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..setAttribute('allowfullscreen', 'true');
      return iframe;
    });
  }

  @override
  void dispose() {
    // Revoke the blob URL to free memory.
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
