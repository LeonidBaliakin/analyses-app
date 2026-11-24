import 'dart:convert';

import 'package:document_domain/document_domain.dart';
import 'package:test/test.dart';

void main() {
  final bytes = utf8.encode('%PDF-1.7\nSynthetic document\n%%EOF');
  OriginalDocument original({
    String? hash,
    int? size,
    String name = '../../untrusted.pdf',
  }) => OriginalDocument(
    documentId: 'doc',
    originalId: 'original',
    profileId: 'profile',
    fileName: name,
    mime: 'application/pdf',
    size: size ?? bytes.length,
    sha256: hash ?? originalSha256(bytes),
    importedAt: DateTime.utc(2026, 11, 24),
    importSource: 'files',
  );
  test('byte identity is independent of file name and file extension', () {
    original().verify(bytes);
    expect(originalMime(bytes), 'application/pdf');
    expect(
      originalSha256(utf8.encode('abc')),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
  test('corruption, empty, excessive and unsupported content fail', () {
    expect(
      () => original().verify([...bytes, 0]),
      throwsA(isA<OriginalFailure>()),
    );
    expect(
      () => original(hash: '0' * 64).verify(bytes),
      throwsA(isA<OriginalFailure>()),
    );
    expect(
      () => original(size: maxOriginalBytes + 1).validate(),
      throwsA(isA<OriginalFailure>()),
    );
    expect(() => originalMime([]), throwsA(isA<OriginalFailure>()));
    expect(
      () => originalMime(utf8.encode('renamed.pdf')),
      throwsA(isA<OriginalFailure>()),
    );
  });
}
