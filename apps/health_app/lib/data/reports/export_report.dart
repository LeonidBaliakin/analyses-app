import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

Future<bool> exportReport(String name, String html) async {
  final file = XFile.fromData(
    Uint8List.fromList(utf8.encode(html)),
    mimeType: 'text/html',
    name: name,
  );
  if (kIsWeb) {
    await file.saveTo(name);
    return true;
  }
  final destination = await getSaveLocation(suggestedName: name);
  if (destination == null) return false;
  await file.saveTo(destination.path);
  return true;
}

bool get canExportReportFile =>
    kIsWeb ||
    [
      TargetPlatform.macOS,
      TargetPlatform.linux,
      TargetPlatform.windows,
    ].contains(defaultTargetPlatform);
