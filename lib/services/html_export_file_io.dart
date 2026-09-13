import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<XFile> createHtmlExportFilePlatform({
  required String html,
  required String fileName,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(utf8.encode(html), flush: true);
  return XFile(file.path, mimeType: 'text/html', name: fileName);
}
