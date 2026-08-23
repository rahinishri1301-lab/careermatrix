// lib/widgets/pdf_preview_viewer_stub.dart
//
// Default/native fallback for platforms without dart:html.
// Shows a message directing the user to use the download feature instead.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PdfPreviewViewer extends StatelessWidget {
  final Uint8List pdfBytes;
  const PdfPreviewViewer({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'PDF preview is only available on web.\nUse the download option to view on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
