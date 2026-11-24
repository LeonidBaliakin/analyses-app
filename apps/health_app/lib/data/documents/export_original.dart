import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:document_domain/document_domain.dart';

Future<void> exportOriginal(OriginalDocument original, Uint8List bytes) async {
  original.verify(bytes);
  final name = original.fileName
      .split(RegExp(r'[/\\]'))
      .last
      .replaceAll(RegExp(r'[\x00-\x1f]'), '_');
  final file = XFile.fromData(bytes, mimeType: original.mime, name: name);
  if (kIsWeb) {
    await file.saveTo(name);
  } else {
    final destination = await getSaveLocation(suggestedName: name);
    if (destination != null) await file.saveTo(destination.path);
  }
}
