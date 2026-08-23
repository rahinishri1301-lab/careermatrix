// lib/services/download_helper_web.dart
//
// Web implementation: triggers a browser file download using dart:html.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

Future<String> saveDownloadedFile(List<int> bytes, String filename) async {
  final blob = html.Blob([Uint8List.fromList(bytes)]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return filename; // on web, the browser's download manager handles the rest
}
