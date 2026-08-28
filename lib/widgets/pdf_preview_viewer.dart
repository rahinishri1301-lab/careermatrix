// lib/widgets/pdf_preview_viewer.dart
//
// Stub that selects the platform-specific implementation at compile time.
// On web → pdf_preview_viewer_web.dart  (iframe-based)
// On native → pdf_preview_viewer_native.dart  (placeholder message)

export 'pdf_preview_viewer_stub.dart'
    if (dart.library.html) 'pdf_preview_viewer_web.dart';
