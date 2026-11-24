import 'package:flutter/foundation.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:medical_terminology/medical_terminology.dart';

/// The editor owns this draft. Search results never create saved associations.
final class ResultCodingViewModel extends ChangeNotifier {
  ResultCodingViewModel(this.catalog, {LabResultCoding? initial})
    : _coding = initial;
  final TerminologyCatalog catalog;
  LabResultCoding? _coding;
  LabResultCoding? get coding => _coding;
  String _name = '', _unit = '', _laboratory = '', _specimen = '', _method = '';
  bool invalidated = false;
  bool get canSelect => _name.trim().isNotEmpty;
  TerminologyRelease get release =>
      catalog.releases[_coding?.terminologyReleaseId] ?? catalog.active;
  TermMatch get matches => catalog.active.findIndicators(
    _name,
    sourceSystem: _laboratory,
    specimen: _specimen,
    method: _method,
    unitId: catalog.active.findUnits(_unit).conceptIds.singleOrNull,
  );
  List<UnitConcept> get units => [
    for (final id
        in release.indicator(_coding?.indicatorId ?? '')?.unitIds ?? <String>{})
      if (release.findUnits(_unit).conceptIds.isEmpty ||
          release.findUnits(_unit).conceptIds.contains(id))
        release.unit(id)!,
  ];

  void updateSource({
    required String name,
    required String unit,
    required String laboratory,
    required String specimen,
    required String method,
  }) {
    _name = name;
    _unit = unit;
    _laboratory = laboratory;
    _specimen = specimen;
    _method = method;
    if (_coding != null &&
        !_coding!.describes(
          name: name,
          unit: unit,
          laboratory: laboratory,
          specimen: specimen,
          method: method,
        )) {
      _coding = null;
      invalidated = true;
    }
    notifyListeners();
  }

  void selectIndicator(String id) {
    if (id == _coding?.indicatorId) return;
    _coding = id.isEmpty
        ? null
        : catalog.active.confirm(
            indicatorId: id,
            sourceName: _name,
            sourceUnit: _unit,
            sourceLaboratory: _laboratory,
            sourceSpecimen: _specimen,
            sourceMethod: _method,
          );
    invalidated = false;
    notifyListeners();
  }

  void selectUnit(String id) {
    if (_coding == null) return;
    _coding = release.confirm(
      indicatorId: _coding!.indicatorId,
      unitId: id.isEmpty ? null : id,
      sourceName: _name,
      sourceUnit: _unit,
      sourceLaboratory: _laboratory,
      sourceSpecimen: _specimen,
      sourceMethod: _method,
    );
    notifyListeners();
  }
}
