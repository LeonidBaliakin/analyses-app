import 'package:flutter/foundation.dart';
import 'package:medical_domain/medical_domain.dart';

enum ProfileSection {
  complaints,
  base,
  medication,
  weight,
  illness,
  hospitalization,
  allergy,
  history,
  lifestyle,
  documents,
}

final class HistoryEntryDraft {
  HistoryEntryDraft({
    required this.id,
    required this.kind,
    this.text = '',
    this.precision = HistoryDatePrecision.unknown,
    this.date = '',
    this.year = '',
  });
  factory HistoryEntryDraft.fromEntry(ProfileHistoryEntry e) =>
      HistoryEntryDraft(
        id: e.id,
        kind: e.kind,
        text: e.text,
        precision: e.precision,
        date: e.date?.toString() ?? '',
        year: e.year?.toString() ?? '',
      );
  final String id;
  final ProfileHistoryKind kind;
  String text, date, year;
  HistoryDatePrecision precision;
  ProfileHistoryEntry confirmed() => ProfileHistoryEntry(
    id: id,
    kind: kind,
    text: text,
    precision: precision,
    date: precision == HistoryDatePrecision.date
        ? CalendarDate.parse(date)
        : null,
    year:
        precision == HistoryDatePrecision.year ||
            (precision == HistoryDatePrecision.childhood && year.isNotEmpty)
        ? int.parse(year)
        : null,
  );
}

/// Owns the draft and invokes an injected local save command. No persistence
/// plugin, navigation or medical interpretation lives in this ViewModel.
final class ProfileEditorViewModel extends ChangeNotifier {
  ProfileEditorViewModel({
    required MedicalProfile profile,
    required this.saveProfile,
    required this.newId,
  }) : _source = profile,
       fields = Map.of(profile.details?.fields ?? {}),
       history = [
         for (final e in profile.details?.history ?? <ProfileHistoryEntry>[])
           HistoryEntryDraft.fromEntry(e),
       ],
       events = List.of(profile.details?.events ?? []),
       birthDate = profile.birthDate?.toString() ?? '' {
    _operationId = newId();
  }
  MedicalProfile _source;
  final Future<bool> Function(MedicalProfile, String) saveProfile;
  late String _operationId;
  void changed() {
    _operationId = newId();
    notifyListeners();
  }

  final String Function() newId;
  final Map<ProfileField, String> fields;
  final List<HistoryEntryDraft> history;
  final List<ProfileEvent> events;
  String? _pendingEventKey, _pendingEventId, _pendingEventOperation;
  final Map<String, String> _removeOperations = {};
  String birthDate;
  bool saving = false, failed = false, invalid = false, _disposed = false;
  String value(ProfileField field) => fields[field] ?? '';
  void setField(ProfileField field, String value) {
    fields[field] = value;
    changed();
  }

  void addHistory(ProfileHistoryKind kind) {
    history.add(HistoryEntryDraft(id: newId(), kind: kind));
    changed();
  }

  void removeHistory(String id) {
    history.removeWhere((e) => e.id == id);
    changed();
  }

  void updateHistory() {
    changed();
  }

  Future<bool> save() async {
    if (saving) return false;
    saving = true;
    failed = false;
    invalid = false;
    notifyListeners();
    try {
      final details = ProfileDetails(
        fields: fields,
        history: [
          for (final h in history)
            if (h.text.trim().isNotEmpty) h.confirmed(),
        ],
        events: events,
      );
      final profile = MedicalProfile(
        id: _source.id,
        name: _source.name,
        birthDate: birthDate.isEmpty ? null : CalendarDate.parse(birthDate),
        history: _source.history,
        allergies: _source.allergies,
        notes: _source.notes,
        details: details,
      );
      profile.validate();
      final saved = await saveProfile(profile, _operationId);
      failed = !saved;
      if (saved) {
        _source = profile;
        _operationId = newId();
      }
      return saved;
    } on FormatException {
      invalid = true;
      return false;
    } on InvalidRecord {
      invalid = true;
      return false;
    } catch (_) {
      failed = true;
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> addEvent({
    required ProfileEventKind kind,
    required String name,
    String start = '',
    String end = '',
    Map<ProfileEventField, String> fields = const {},
  }) async {
    if (saving) return false;
    try {
      final key = [
        kind.name,
        name,
        start,
        end,
        for (final key in ProfileEventField.values) fields[key] ?? '',
      ].join('\u0000');
      if (_pendingEventKey != key) {
        _pendingEventKey = key;
        _pendingEventId = newId();
        _pendingEventOperation = newId();
      }
      _operationId = _pendingEventOperation!;
      final e = ProfileEvent(
        id: _pendingEventId!,
        kind: kind,
        name: name,
        start: start.isEmpty ? null : CalendarDate.parse(start),
        end: end.isEmpty ? null : CalendarDate.parse(end),
        fields: fields,
      );
      if (!e.isValid) throw const InvalidRecord('event');
      events.add(e);
      if (await save()) {
        _pendingEventKey = null;
        return true;
      }
      events.remove(e);
      return false;
    } on FormatException {
      invalid = true;
      notifyListeners();
      return false;
    } on InvalidRecord {
      invalid = true;
      notifyListeners();
      return false;
    }
  }

  Future<void> removeEvent(String id) async {
    if (saving) return;
    final index = events.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final removed = events.removeAt(index);
    _operationId = _removeOperations.putIfAbsent(id, newId);
    if (!await save()) events.insert(index, removed);
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
