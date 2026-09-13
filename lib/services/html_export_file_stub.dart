import 'dart:convert';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<XFile> createHtmlExportFilePlatform({
  required String html,
  required String fileName,
}) => XFile.fromData(
  Uint8List.fromList(utf8.encode(html)),
  mimeType: 'text/html',
  name: fileName,
);
