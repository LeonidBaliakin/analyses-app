import 'package:medical_domain/medical_domain.dart';

enum MatchStatus { unknown, unique, ambiguous }

enum MappingRelation { exact, broader, proposed }

enum MappingVerification { curated, proposed }

final class TerminologyLabel {
  const TerminologyLabel({required this.ru, required this.en});
  final String ru, en;
  String inLanguage(String language) => language == 'ru' ? ru : en;
}

final class IndicatorConcept {
  IndicatorConcept({
    required this.id,
    required this.label,
    required this.specimen,
    required Iterable<String> specimenNames,
    required Iterable<String> unitIds,
  }) : unitIds = Set.unmodifiable(unitIds),
       specimenNames = Set.unmodifiable(specimenNames);
  final String id;
  final TerminologyLabel label;
  final String specimen;
  final Set<String> unitIds;
  final Set<String> specimenNames;
}

final class UnitConcept {
  const UnitConcept({
    required this.id,
    required this.label,
    required this.symbol,
    required this.dimension,
  });
  final String id, symbol, dimension;
  final TerminologyLabel label;
}

/// Context is compared with explicit aliases, never inferred from similar text.
final class TermAlias {
  const TermAlias({
    required this.id,
    required this.text,
    required this.conceptId,
    this.sourceSystem,
    this.specimen,
    this.method,
    this.relation = MappingRelation.exact,
    this.verification = MappingVerification.curated,
  });
  final String id, text, conceptId;
  final String? sourceSystem, specimen, method;
  final MappingRelation relation;
  final MappingVerification verification;
  String get scope => sourceSystem == null ? 'global' : 'source';
}

final class TermMatch {
  TermMatch(Iterable<String> ids) : conceptIds = List.unmodifiable(ids.toSet());
  final List<String> conceptIds;
  MatchStatus get status => switch (conceptIds.length) {
    0 => MatchStatus.unknown,
    1 => MatchStatus.unique,
    _ => MatchStatus.ambiguous,
  };
}

String _key(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// A release is immutable and validates all references before becoming usable.
/// Release IDs must change whenever labels, aliases or concepts change.
final class TerminologyRelease {
  TerminologyRelease({
    required this.id,
    required this.source,
    required this.usage,
    this.schemaVersion = 1,
    required Iterable<IndicatorConcept> indicators,
    required Iterable<UnitConcept> units,
    required Iterable<TermAlias> indicatorAliases,
    required Iterable<TermAlias> unitAliases,
  }) : indicators = List.unmodifiable(indicators),
       units = List.unmodifiable(units),
       indicatorAliases = List.unmodifiable(indicatorAliases),
       unitAliases = List.unmodifiable(unitAliases) {
    if (schemaVersion != 1 ||
        id.trim().isEmpty ||
        source.trim().isEmpty ||
        usage.trim().isEmpty) {
      throw const FormatException(
        'Unsupported or incomplete terminology release',
      );
    }
    void uniqueIds(Iterable<String> ids) {
      final seen = <String>{};
      for (final id in ids) {
        if (id.trim().isEmpty || !seen.add(id)) {
          throw const FormatException('Empty or duplicate terminology ID');
        }
      }
    }

    uniqueIds([
      ...this.indicators.map((c) => c.id),
      ...this.units.map((c) => c.id),
    ]);
    uniqueIds([
      ...this.indicatorAliases.map((a) => a.id),
      ...this.unitAliases.map((a) => a.id),
    ]);
    for (final c in this.indicators) {
      if (c.label.ru.isEmpty ||
          c.label.en.isEmpty ||
          c.specimen.isEmpty ||
          c.specimenNames.isEmpty ||
          c.unitIds.isEmpty ||
          c.unitIds.any((id) => unit(id) == null)) {
        throw const FormatException('Invalid indicator');
      }
    }
    for (final u in this.units) {
      if (u.label.ru.isEmpty ||
          u.label.en.isEmpty ||
          u.symbol.isEmpty ||
          u.dimension.isEmpty) {
        throw const FormatException('Invalid unit');
      }
    }
    for (final (aliases, targets) in [
      (this.indicatorAliases, this.indicators.map((c) => c.id).toSet()),
      (this.unitAliases, this.units.map((c) => c.id).toSet()),
    ]) {
      for (final a in aliases) {
        if (a.text.trim().isEmpty ||
            !targets.contains(a.conceptId) ||
            (a.sourceSystem != null && a.sourceSystem!.trim().isEmpty) ||
            (a.specimen != null && a.specimen!.trim().isEmpty) ||
            (a.method != null && a.method!.trim().isEmpty)) {
          throw const FormatException('Invalid alias');
        }
      }
    }
  }

  final int schemaVersion;
  final String id, source, usage;
  final List<IndicatorConcept> indicators;
  final List<UnitConcept> units;
  final List<TermAlias> indicatorAliases, unitAliases;

  IndicatorConcept? indicator(String id) =>
      indicators.where((c) => c.id == id).firstOrNull;
  UnitConcept? unit(String id) => units.where((c) => c.id == id).firstOrNull;

  TermMatch findIndicators(
    String text, {
    String sourceSystem = '',
    String specimen = '',
    String method = '',
    String? unitId,
  }) {
    final aliases = indicatorAliases
        .where(
          (a) =>
              _key(a.text) == _key(text) &&
              a.relation == MappingRelation.exact &&
              a.verification == MappingVerification.curated &&
              (a.sourceSystem == null || a.sourceSystem == sourceSystem) &&
              (a.specimen == null || _key(a.specimen!) == _key(specimen)) &&
              (a.method == null || _key(a.method!) == _key(method)) &&
              (specimen.trim().isEmpty ||
                  indicator(a.conceptId)!.specimenNames
                      .any((s) => _key(s) == _key(specimen))) &&
              (unitId == null ||
                  indicator(a.conceptId)!.unitIds.contains(unitId)),
        )
        .toList();
    final scoped = aliases.where((a) => a.sourceSystem != null).toList();
    return TermMatch(
      (scoped.isEmpty ? aliases : scoped).map((a) => a.conceptId),
    );
  }

  /// Unit case and internal spacing are significant (mL is not ML).
  TermMatch findUnits(String text) => TermMatch(
    unitAliases
        .where(
          (a) =>
              a.text == text.trim() &&
              a.sourceSystem == null &&
              a.specimen == null &&
              a.method == null &&
              a.relation == MappingRelation.exact &&
              a.verification == MappingVerification.curated,
        )
        .map((a) => a.conceptId),
  );

  /// Only a user action creates an association. A unique search is a suggestion.
  LabResultCoding confirm({
    required String indicatorId,
    String? unitId,
    required String sourceName,
    required String sourceUnit,
    required String sourceLaboratory,
    required String sourceSpecimen,
    required String sourceMethod,
  }) {
    final concept = indicator(indicatorId);
    final knownUnits = findUnits(sourceUnit).conceptIds;
    if (concept == null ||
        sourceName.trim().isEmpty ||
        (unitId != null &&
            (sourceUnit.trim().isEmpty ||
                !concept.unitIds.contains(unitId) ||
                (knownUnits.isNotEmpty && !knownUnits.contains(unitId))))) {
      throw const InvalidRecord('coding');
    }
    return LabResultCoding(
      terminologyReleaseId: id,
      indicatorId: indicatorId,
      unitId: unitId,
      sourceName: sourceName,
      sourceUnit: sourceUnit,
      sourceLaboratory: sourceLaboratory,
      sourceSpecimen: sourceSpecimen,
      sourceMethod: sourceMethod,
    );
  }
}

/// Keeps old releases addressable; an update never edits a medical record.
final class TerminologyCatalog {
  TerminologyCatalog({
    required Iterable<TerminologyRelease> releases,
    required this.activeReleaseId,
  }) : releases = Map.unmodifiable({
         for (final release in releases) release.id: release,
       }) {
    if (this.releases.length != releases.length ||
        !this.releases.containsKey(activeReleaseId)) {
      throw const FormatException('Duplicate or missing terminology release');
    }
  }
  final Map<String, TerminologyRelease> releases;
  final String activeReleaseId;
  TerminologyRelease get active => releases[activeReleaseId]!;
}
