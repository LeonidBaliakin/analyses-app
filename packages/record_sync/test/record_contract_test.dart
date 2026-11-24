import 'package:medical_domain/medical_domain.dart';
import 'package:record_sync/record_sync.dart';
import 'package:test/test.dart';

void main() {
  test(
    'transport keeps source precision, calendar date and checked provenance',
    () {
      final r = LabResult(
        id: 'r',
        profileId: 'p',
        name: 'Synthetic',
        date: CalendarDate(2026, 11, 25),
        value: const SourceValue('< 0,0100', ResultValueKind.comparison),
        category: AnalysisCategory.blood,
        unit: 'unknown',
        reference: '0,001-0,020',
        documentSource: DocumentRecordSource(
          documentId: 'd',
          originalId: 'o',
          originalSha256: 'a' * 64,
          jobId: 'job',
          draftRevision: 2,
          rowId: 'row-0',
          fields: {'value': '< 0,0100'},
          versions: {'model': 'synthetic'},
        ),
      );
      final wire = Map<String, dynamic>.from(encodeRecord(r));
      final remote = RemoteRecord.fromJson({
        'payload': wire,
        'version': 5,
        'sequence': 12,
        'deleted': false,
        'deviceId': 'device',
        'operationId': 'operation',
      });
      final restored = remote.record as LabResult;
      expect(restored.value.raw, '< 0,0100');
      expect(restored.documentSource!.fields['value'], '< 0,0100');
      expect(restored.date, CalendarDate(2026, 11, 25));
      expect(
        () => RemoteRecord(
          payload: wire,
          version: 0,
          deleted: false,
          sequence: 1,
        ),
        throwsA(isA<SyncFailure>()),
      );
    },
  );
  test('unknown wire versions and invalid medical values cannot enter a remote record', () {
    final p = Map<String, dynamic>.from(
      encodeRecord(const MedicalProfile(id: 'p', name: 'Synthetic')),
    );
    expect(
      () => decodeRecord({...p, 'format': 99}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RemoteRecord(
        payload: {...p, 'name': ''},
        version: 1,
        deleted: false,
        sequence: 1,
      ),
      throwsA(isA<InvalidRecord>()),
    );
  });
}
