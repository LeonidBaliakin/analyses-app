import 'terminology.dart';

final class MedicalSpecialtyConcept {
  MedicalSpecialtyConcept({
    required this.id,
    required this.label,
    Iterable<String> searchNames = const [],
  }) : searchNames = List.unmodifiable(searchNames);
  final String id;
  final TerminologyLabel label;
  final List<String> searchNames;
}

final class MedicalSpecialtyMapping {
  const MedicalSpecialtyMapping({
    required this.id,
    required this.sourceSystem,
    required this.sourceText,
    required this.conceptId,
    required this.source,
    required this.checkedAt,
    this.relation = MappingRelation.exact,
    this.verification = MappingVerification.curated,
  });
  final String id, sourceSystem, sourceText, conceptId;
  final Uri source;
  final DateTime checkedAt;
  final MappingRelation relation;
  final MappingVerification verification;
}

String _key(String value) => value
    .toLowerCase()
    .replaceAll('ё', 'е')
    .replaceAll(RegExp('[‐‑–—]'), '-')
    .replaceAll(RegExp(r'\s*-\s*'), '-')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Only reviewed source formulations assign a specialty to a doctor.
/// Search aliases do not grant an additional qualification or merge identities.
final class MedicalSpecialtyRelease {
  MedicalSpecialtyRelease({
    required this.id,
    required Iterable<MedicalSpecialtyConcept> concepts,
    required Iterable<MedicalSpecialtyMapping> mappings,
  }) : concepts = List.unmodifiable(concepts),
       mappings = List.unmodifiable(mappings) {
    final ids = this.concepts.map((c) => c.id).toSet();
    if (id.isEmpty ||
        ids.length != this.concepts.length ||
        ids.contains('') ||
        this.concepts.any((c) => c.label.ru.isEmpty || c.label.en.isEmpty) ||
        this.mappings.map((m) => m.id).toSet().length != this.mappings.length ||
        this.mappings.any(
          (m) =>
              m.id.isEmpty ||
              m.sourceSystem.isEmpty ||
              m.sourceText.isEmpty ||
              !ids.contains(m.conceptId) ||
              m.source.scheme != 'https' ||
              m.source.host.isEmpty ||
              m.source.userInfo.isNotEmpty,
        )) {
      throw const FormatException('Invalid specialty release');
    }
  }
  final String id;
  final List<MedicalSpecialtyConcept> concepts;
  final List<MedicalSpecialtyMapping> mappings;

  MedicalSpecialtyConcept? concept(String id) =>
      concepts.where((c) => c.id == id).firstOrNull;
  MedicalSpecialtyMapping? resolve({
    required String sourceSystem,
    required String sourceText,
  }) {
    final matches = mappings
        .where(
          (m) =>
              m.sourceSystem == sourceSystem &&
              _key(m.sourceText) == _key(sourceText) &&
              m.relation == MappingRelation.exact &&
              m.verification == MappingVerification.curated,
        )
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  String searchText(String id) {
    final c = concept(id);
    return c == null
        ? ''
        : [
            c.label.ru,
            c.label.en,
            ...c.searchNames,
            ...mappings
                .where(
                  (m) =>
                      m.conceptId == id &&
                      m.relation == MappingRelation.exact &&
                      m.verification == MappingVerification.curated,
                )
                .map((m) => m.sourceText),
          ].join(' ');
  }
}
