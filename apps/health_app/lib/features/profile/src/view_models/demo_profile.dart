import 'package:medical_domain/medical_domain.dart';

import '../../../../presentation/demo_catalog.dart';

/// Boundary adapter for the explicitly synthetic, read-only reference snapshot.
MedicalProfile demoProfile(DemoCatalog catalog) {
  final p = catalog.profile;
  const fields = {
    ProfileField.sex: 'sex',
    ProfileField.height: 'h',
    ProfileField.waist: 'waist',
    ProfileField.hips: 'hips',
    ProfileField.chest: 'chest',
    ProfileField.cycle: 'cycle',
    ProfileField.city: 'city',
    ProfileField.travel: 'travel',
    ProfileField.activity: 'act',
    ProfileField.sport: 'sportNote',
    ProfileField.foodNotes: 'foodNote',
    ProfileField.stress: 'stress',
    ProfileField.sleep: 'sleep',
    ProfileField.diet: 'food',
    ProfileField.smoking: 'smoke',
    ProfileField.packsPerDay: 'packsPerDay',
    ProfileField.alcohol: 'alc',
    ProfileField.alcoholAmount: 'alcv',
  };
  CalendarDate? date(Object? v) =>
      v is String && v.isNotEmpty ? CalendarDate.parse(v) : null;
  String displayValue(ProfileField key, String source) =>
      switch ((key, source)) {
        (ProfileField.smoking, 'Не курю') => 'never',
        (ProfileField.smoking, 'Курю') => 'current',
        (ProfileField.smoking, 'Бросил(а)') => 'former',
        (ProfileField.alcohol, 'Не пью') => 'never',
        (ProfileField.alcohol, 'Раньше пил(а)') => 'former',
        (ProfileField.alcohol, 'Реже раза в неделю') => 'rare',
        (ProfileField.alcohol, '1–3 раза в неделю') => 'weekly',
        (ProfileField.alcohol, 'Чаще') => 'often',
        (ProfileField.diet, 'Обычное') => 'regular',
        (ProfileField.stress, 'Нет') => 'no',
        (ProfileField.stress, 'Да, эпизодически') => 'sometimes',
        (ProfileField.stress, 'Да, почти постоянно') => 'often',
        _ => source,
      };
  return MedicalProfile(
    id: 'synthetic-preview',
    name: p['name'] as String,
    birthDate: date(p['dob']),
    details: ProfileDetails(
      fields: {
        for (final e in fields.entries)
          e.key: displayValue(e.key, p[e.value]?.toString() ?? ''),
      },
      history: [
        for (final (index, key) in ['dx', 'surg', 'fam', 'other'].indexed)
          if ((p[key]?.toString() ?? '').isNotEmpty)
            ProfileHistoryEntry(
              id: 'preview-history-$key',
              kind: ProfileHistoryKind.values[index],
              text: p[key] as String,
            ),
      ],
      events: [
        for (final (key, kind) in [
          ('cmp', ProfileEventKind.complaint),
          ('ill', ProfileEventKind.illness),
          ('hosp', ProfileEventKind.hospitalization),
        ])
          for (final (index, raw) in (catalog.events[key] as List).indexed)
            ProfileEvent(
              id: 'preview-$key-$index',
              kind: kind,
              name: raw['n'] as String,
              start: date(raw['f']),
              end: date(raw['t']),
              fields: {
                if (raw['tmax'] != null)
                  ProfileEventField.temperature: raw['tmax'] as String,
                if (raw['ab'] != null)
                  ProfileEventField.antibiotics: raw['ab'] as String,
                if (raw['w'] != null)
                  ProfileEventField.institution: raw['w'] as String,
                if (raw['results'] != null)
                  ProfileEventField.outcomes: raw['results'] as String,
              },
            ),
        for (final (index, raw) in (p['alls'] as List).indexed)
          ProfileEvent(
            id: 'preview-allergy-$index',
            kind: ProfileEventKind.allergy,
            name: raw['n'] as String,
            fields: {ProfileEventField.reaction: raw['r'] as String},
          ),
      ],
    ),
  );
}
