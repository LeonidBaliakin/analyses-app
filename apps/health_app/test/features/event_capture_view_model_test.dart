import 'package:document_processing/document_processing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/capture/src/event_capture_view_model.dart';
import 'package:health_app/features/capture/src/diary_view_model.dart';
import 'package:medical_domain/medical_domain.dart';

void main() {
  test('review does not save; retry reuses ids and operation and edit invalidates operation', () async {
    var n = 0;
    final calls = <(List<HealthRecord>, String)>[];
    final m = EventCaptureViewModel(
      profile: const MedicalProfile(id: 'p', name: 'Synthetic'),
      today: CalendarDate(2026, 1, 1),
      newId: () => 'id${n++}',
      save: (r, o) async {
        calls.add((r, o));
        return false;
      },
    );
    addTearDown(m.dispose);
    m.story = 'Болел вчера';
    m.review();
    expect(calls, isEmpty);
    expect(m.rows!.single.kind, CapturedEventKind.illness);
    await m.confirm();
    await m.confirm();
    expect(calls[0].$2, calls[1].$2);
    expect(
      (calls[0].$1.single as MedicalProfile).details!.events.single.id,
      (calls[1].$1.single as MedicalProfile).details!.events.single.id,
    );
    m.update(
      m.rows!.single.edit(fields: {...m.rows!.single.fields, 'name': 'Edited'}),
    );
    await m.confirm();
    expect(calls.last.$2, isNot(calls.first.$2));
  });
  test('pressure uses one batch, raw precision and offset remain explicit, retry ids stable', () async {
    var n = 0;
    final calls = <(List<HealthRecord>, String)>[];
    final m = DiaryViewModel(
      profileId: 'p',
      today: CalendarDate(2026, 1, 1),
      newId: () => 'id${n++}',
      save: (r, o) async {
        calls.add((r, o));
        return false;
      },
      names: const {
        DiaryKind.pressure: ['Systolic', 'Diastolic'],
      },
      units: const {
        DiaryKind.pressure: ['mmHg', 'mmHg'],
      },
    );
    addTearDown(m.dispose);
    m.select(DiaryKind.pressure);
    m.first = '120,00';
    m.second = '80';
    m.time = '10:30';
    expect(await m.submit(), isFalse);
    expect(calls, isEmpty);
    m.offset = '+03:00';
    m.changed();
    await m.submit();
    await m.submit();
    expect(calls, hasLength(2));
    expect(calls.first.$1, hasLength(2));
    expect(calls.first.$2, calls.last.$2);
    expect(calls.first.$1.map((r) => r.id), calls.last.$1.map((r) => r.id));
    final r = calls.first.$1.first as HomeMeasurement;
    expect(r.value.raw, '120,00');
    expect(r.minuteOfDay, 630);
    expect(r.utcOffsetMinutes, 180);
  });
}
