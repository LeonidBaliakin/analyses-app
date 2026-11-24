/// A record-scoped association explicitly confirmed by the person entering it.
/// It does not assert that two results are medically comparable.
final class LabResultCoding {
  const LabResultCoding({
    required this.terminologyReleaseId,
    required this.indicatorId,
    this.unitId,
    required this.sourceName,
    required this.sourceUnit,
    required this.sourceLaboratory,
    required this.sourceSpecimen,
    required this.sourceMethod,
  });

  final String terminologyReleaseId, indicatorId;
  final String? unitId;
  final String sourceName,
      sourceUnit,
      sourceLaboratory,
      sourceSpecimen,
      sourceMethod;

  String get scope => 'record';
  String get relation => 'exact';
  String get matchMethod => 'userSelection';
  String get verification => 'userConfirmed';

  bool describes({
    required String name,
    required String unit,
    required String laboratory,
    required String specimen,
    required String method,
  }) =>
      terminologyReleaseId.trim().isNotEmpty &&
      indicatorId.trim().isNotEmpty &&
      (unitId == null ||
          (unitId!.trim().isNotEmpty && sourceUnit.trim().isNotEmpty)) &&
      sourceName == name &&
      sourceUnit == unit &&
      sourceLaboratory == laboratory &&
      sourceSpecimen == specimen &&
      sourceMethod == method;
}
