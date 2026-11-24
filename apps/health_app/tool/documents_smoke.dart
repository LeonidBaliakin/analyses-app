// Synthetic integration probe against the explicitly configured local stack.
import 'dart:convert';
import 'dart:io';

import 'package:document_domain/document_domain.dart';
import 'package:drift/native.dart';
import 'package:local_store/local_store.dart';
import 'package:medical_domain/medical_domain.dart';

import 'package:health_app/data/documents/documents_http_gateway.dart';

Future<void> main() async {
  final lines = await File('../../infra/documents/.env').readAsLines();
  final env = {
    for (final line in lines)
      line.split('=').first: line.substring(line.indexOf('=') + 1),
  };
  final gateway = DocumentsHttpGateway(
    endpoint: Uri.parse('http://127.0.0.1:18088'),
    token: env['DOCUMENTS_DEV_TOKEN']!,
  );
  final directory = await Directory.systemTemp.createTemp(
    'analyses-original-smoke-',
  );
  final path = File('${directory.path}/originals.sqlite');
  var db = RecordsDatabase(NativeDatabase(path));
  try {
    await db.commit(
      const RecordMutation(
        operationId: 'profile',
        record: MedicalProfile(
          id: 'local-profile',
          name: 'Synthetic smoke profile',
        ),
        expectedRevision: 0,
      ),
    );
    final fixtures = {
      'pdf': base64Decode(
        'JVBERi0xLjcKMSAwIG9iago8PCAvVHlwZSAvQ2F0YWxvZyAvUGFnZXMgMiAwIFIgPj4KZW5kb2JqCjIgMCBvYmoKPDwgL1R5cGUgL1BhZ2VzIC9LaWRzIFszIDAgUl0gL0NvdW50IDEgPj4KZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgL1BhcmVudCAyIDAgUiAvTWVkaWFCb3ggWzAgMCAxMDAgMTAwXSAvQ29udGVudHMgNCAwIFIgPj4KZW5kb2JqCjQgMCBvYmoKPDwgL0xlbmd0aCAwID4+CnN0cmVhbQoKZW5kc3RyZWFtCmVuZG9iagp4cmVmCjAgNQowMDAwMDAwMDAwIDY1NTM1IGYgCjAwMDAwMDAwMDkgMDAwMDAgbiAKMDAwMDAwMDA1OCAwMDAwMCBuIAowMDAwMDAwMTE1IDAwMDAwIG4gCjAwMDAwMDAyMDIgMDAwMDAgbiAKdHJhaWxlcgo8PCAvU2l6ZSA1IC9Sb290IDEgMCBSID4+CnN0YXJ0eHJlZgoyNTEKJSVFT0YK',
      ),
      'png': base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP436EEAAQzAaqPLuUyAAAAAElFTkSuQmCC',
      ),
    };
    for (final entry in fixtures.entries) {
      final o = OriginalDocument(
        documentId: 'smoke-v2-document-${entry.key}',
        originalId: 'smoke-v2-original-${entry.key}',
        profileId: 'local-profile',
        fileName: 'synthetic.${entry.key}',
        mime: originalMime(entry.value),
        size: entry.value.length,
        sha256: originalSha256(entry.value),
        importedAt: DateTime.utc(2026, 11, 24),
        importSource: 'files',
      );
      await db.importOriginal(o, entry.value);
    }
    await db.close();
    db = RecordsDatabase(NativeDatabase(path));
    for (final o in await db.listOriginals('local-profile')) {
      final bytes = await db.readOriginal(o.profileId, o.originalId);
      await gateway.upload(o, bytes);
      await gateway.upload(o, bytes);
      final downloaded = await gateway.download(o);
      o.verify(downloaded);
      stdout.writeln(
        '${o.mime}: local restart + repeated upload + download SHA-256 verified (${o.size} bytes)',
      );
    }
  } finally {
    gateway.close();
    await db.close();
    await directory.delete(recursive: true);
  }
}
