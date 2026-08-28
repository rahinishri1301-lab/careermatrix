// lib/widgets/pdf_preview_dialog.dart
//
// Full-screen dialog that shows a PDF preview using the browser's native
// PDF viewer (via an iframe with a blob: URL).  Works on Flutter Web.
// On native platforms this falls back to a plain "not supported" message
// because the widget relies on dart:html.  If native support is needed
// later, swap in a package like `pdfx` or `syncfusion_flutter_pdfviewer`.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'pdf_preview_viewer.dart';

/// Opens a full-screen modal dialog that renders [pdfBytes] inside an
/// embedded PDF viewer.  Pressing the X / back button returns the user to
/// the previous screen.
Future<void> showPdfPreviewDialog(
  BuildContext context, {
  required Uint8List pdfBytes,
  String title = 'Resume Preview',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PdfPreviewDialog(pdfBytes: pdfBytes, title: title),
  );
}

class _PdfPreviewDialog extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;
  const _PdfPreviewDialog({required this.pdfBytes, required this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // ── Title bar ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    tooltip: 'Close preview',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── PDF content area ──────────────────────────────────────
            Expanded(
              child: PdfPreviewViewer(pdfBytes: pdfBytes),
            ),
          ],
        ),
      ),
    );
  }
}
