import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/profile/src/view_models/profile_editor_view_model.dart';
import 'package:medical_domain/medical_domain.dart';

void main() {
  test('retry keeps operation identity and raw draft, changed draft gets a new command', () async {
    final calls = <(MedicalProfile, String)>[];
    var id = 0, fail = true;
    final m = ProfileEditorViewModel(
      profile: const MedicalProfile(
        id: 'p',
        name: 'Synthetic',
        history: 'Original',
      ),
      newId: () => 'id-${id++}',
      saveProfile: (p, op) async {
        calls.add((p, op));
        return !fail;
      },
    );
    addTearDown(m.dispose);
    m.setField(ProfileField.height, '178,00');
    expect(await m.save(), false);
    fail = false;
    expect(await m.save(), true);
    expect(calls[0].$2, calls[1].$2);
    expect(calls[1].$1.details![ProfileField.height], '178,00');
    expect(calls[1].$1.history, 'Original');
    m.setField(ProfileField.height, '179,00');
    expect(await m.save(), true);
    expect(calls.last.$2, isNot(calls.first.$2));
  });
  test(
    'approximate year has no invented day and invalid year cannot be confirmed',
    () async {
      MedicalProfile? saved;
      var id = 0;
      final m = ProfileEditorViewModel(
        profile: const MedicalProfile(id: 'p', name: 'Synthetic'),
        newId: () => 'id-${id++}',
        saveProfile: (p, _) async {
          saved = p;
          return true;
        },
      );
      addTearDown(m.dispose);
      m.addHistory(ProfileHistoryKind.surgery);
      final draft = m.history.single;
      draft
        ..text = 'Original surgery'
        ..precision = HistoryDatePrecision.year
        ..year = '';
      expect(await m.save(), false);
      expect(m.invalid, true);
      expect(saved, isNull);
      draft.year = '2007';
      m.changed();
      expect(await m.save(), true);
      final history = saved!.details!.history.single;
      expect(history.year, 2007);
      expect(history.date, isNull);
    },
  );
  test(
    'event retry reuses event and operation IDs without a duplicate',
    () async {
      var fail = true, id = 0;
      final calls = <(MedicalProfile, String)>[];
      final m = ProfileEditorViewModel(
        profile: const MedicalProfile(id: 'p', name: 'Synthetic'),
        newId: () => 'id-${id++}',
        saveProfile: (p, op) async {
          calls.add((p, op));
          return !fail;
        },
      );
      addTearDown(m.dispose);
      expect(
        await m.addEvent(
          kind: ProfileEventKind.illness,
          name: 'Source',
          start: '2026-11-01',
        ),
        false,
      );
      expect(m.events, isEmpty);
      fail = false;
      expect(
        await m.addEvent(
          kind: ProfileEventKind.illness,
          name: 'Source',
          start: '2026-11-01',
        ),
        true,
      );
      expect(calls[0].$2, calls[1].$2);
      expect(
        calls[0].$1.details!.events.single.id,
        calls[1].$1.details!.events.single.id,
      );
      expect(m.events, hasLength(1));
    },
  );
}
