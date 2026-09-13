import 'package:share_plus/share_plus.dart';

import 'html_export_file_stub.dart'
    if (dart.library.io) 'html_export_file_io.dart';

Future<XFile> createHtmlExportFile({
  required String html,
  required String fileName,
}) => createHtmlExportFilePlatform(html: html, fileName: fileName);
