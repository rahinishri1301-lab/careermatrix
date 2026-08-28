// lib/services/download_helper_native.dart
//
// Native (Android / iOS / Desktop) implementation: saves the file
// to the app's documents directory using dart:io + path_provider.

import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveDownloadedFile(List<int> bytes, String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
