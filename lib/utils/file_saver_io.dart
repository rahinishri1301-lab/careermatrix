import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveAndOpenFile(List<int> bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}

void openUrlInNewTab(String url) {
  // No-op on mobile devices
}
