// lib/services/download_helper.dart
//
// Stub file for conditional import. Defines the function signature that
// the platform-specific implementations (web / native) must match.
// The conditional import in backend_repository.dart picks the right
// concrete implementation at compile time.

Future<String> saveDownloadedFile(List<int> bytes, String filename) =>
    throw UnsupportedError('saveDownloadedFile is not implemented on this platform');
