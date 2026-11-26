import 'terminology.dart';

/// An ordered investigation, separate from an indicator in a patient's result.
/// Sharing a discovery type does not assert identical methods or panel contents.
final class LaboratoryTestConcept {
  LaboratoryTestConcept({
    required this.id,
    required this.label,
    this.specimen,
    Iterable<String> searchNames = const [],
    Iterable<String> componentIds = const [],
  }) : searchNames = List.unmodifiable(searchNames),
       componentIds = Set.unmodifiable(componentIds);
  final String id;
  final TerminologyLabel label;
  final String? specimen;
  final List<String> searchNames;
  final Set<String> componentIds;
}

/// Published details of one source offering. Missing details stay unknown.
final class LaboratoryTestSpecification {
  LaboratoryTestSpecification({
    required this.source,
    required this.checkedAt,
    this.specimenText,
    this.methodText,
    Map<String, String> components = const {},
    this.note,
  }) : components = Map.unmodifiable(components);
  final Uri source;
  final DateTime checkedAt;
  final String? specimenText, methodText, note;
  final Map<String, String> components;
}

/// A reviewed source formulation, never applied to another source by similarity.
final class LaboratoryTestMapping {
  LaboratoryTestMapping({
    required this.id,
    required this.sourceSystem,
    required this.sourceText,
    required this.conceptId,
    required this.source,
    required this.checkedAt,
    this.sourceCode,
    this.specification,
    this.relation = MappingRelation.exact,
    this.verification = MappingVerification.curated,
  });
  final String id, sourceSystem, sourceText, conceptId;
  final String? sourceCode;
  final Uri source;
  final DateTime checkedAt;
  final MappingRelation relation;
  final MappingVerification verification;
  final LaboratoryTestSpecification? specification;
}

String _key(String value) => value
    .toLowerCase()
    .replaceAll('ё', 'е')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

final class LaboratoryTestRelease {
  LaboratoryTestRelease({
    required this.id,
    required Iterable<LaboratoryTestConcept> concepts,
    required Iterable<LaboratoryTestMapping> mappings,
  }) : concepts = List.unmodifiable(concepts),
       mappings = List.unmodifiable(mappings) {
    final ids = this.concepts.map((c) => c.id).toSet();
    if (id.isEmpty ||
        ids.length != this.concepts.length ||
        this.mappings.map((m) => m.id).toSet().length != this.mappings.length ||
        this.concepts.any(
          (c) => c.id.isEmpty || c.label.ru.isEmpty || c.label.en.isEmpty,
        ) ||
        this.mappings.any(
          (m) =>
              m.id.isEmpty ||
              m.sourceSystem.isEmpty ||
              m.sourceText.isEmpty ||
              !ids.contains(m.conceptId) ||
              m.source.scheme != 'https' ||
              m.source.host.isEmpty ||
              m.source.userInfo.isNotEmpty ||
              m.sourceCode == '',
        )) {
      throw const FormatException('Invalid laboratory test release');
    }
    for (final mapping in this.mappings) {
      final specification = mapping.specification;
      final expected = concept(mapping.conceptId)!.componentIds;
      if (specification != null &&
          (specification.source.scheme != 'https' ||
              specification.source.host.isEmpty ||
              specification.source.userInfo.isNotEmpty ||
              specification.components.entries.any(
                (e) => e.key.isEmpty || e.value.isEmpty,
              ))) {
        throw const FormatException('Invalid test specification');
      }
      if (mapping.relation == MappingRelation.exact &&
          mapping.verification == MappingVerification.curated &&
          expected.isNotEmpty &&
          (specification == null ||
              specification.components.length != expected.length ||
              !expected.every(specification.components.containsKey))) {
        throw const FormatException(
          'Exact panel mapping requires the complete component set',
        );
      }
    }
  }
  final String id;
  final List<LaboratoryTestConcept> concepts;
  final List<LaboratoryTestMapping> mappings;

  LaboratoryTestConcept? concept(String id) =>
      concepts.where((c) => c.id == id).firstOrNull;

  /// The original text must still agree, even when the provider has a code.
  /// Unknown, ambiguous, broader and proposed links stay unnormalised.
  LaboratoryTestMapping? resolve({
    required String sourceSystem,
    required String sourceText,
    String? sourceCode,
  }) {
    final matches = mappings
        .where(
          (m) =>
              m.sourceSystem == sourceSystem &&
              _key(m.sourceText) == _key(sourceText) &&
              m.sourceCode == sourceCode &&
              m.relation == MappingRelation.exact &&
              m.verification == MappingVerification.curated,
        )
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  String searchText(String conceptId) {
    final c = concept(conceptId);
    return c == null
        ? ''
        : [
            c.label.ru,
            c.label.en,
            ...c.searchNames,
            ...mappings
                .where(
                  (m) =>
                      m.conceptId == c.id &&
                      m.relation == MappingRelation.exact &&
                      m.verification == MappingVerification.curated,
                )
                .map((m) => m.sourceText),
          ].join(' ');
  }
}
