import 'package:flutter/foundation.dart';
import 'package:provider_directory/provider_directory.dart';

final class DirectoryViewModel extends ChangeNotifier {
  DirectoryViewModel({
    required this._catalog,
    this._openUrl,
    this.loadCachedCatalog,
    this.refreshCatalog,
  });
  ProviderCatalog _catalog;
  ProviderCatalog get catalog => _catalog;
  final Future<bool> Function(Uri)? _openUrl;
  final Future<ProviderCatalog?> Function()? loadCachedCatalog, refreshCatalog;
  bool isRefreshing = false, refreshFailed = false;

  Future<void> refresh() async {
    if (_disposed || isRefreshing) return;
    isRefreshing = true;
    refreshFailed = false;
    notifyListeners();
    void apply(ProviderCatalog? value) {
      if (value == null || _disposed) return;
      _catalog = value;
      _checkNetwork();
      final valid = catalog.testOptions(city).map((o) => o.id).toSet();
      _testIds.removeWhere((id) => !valid.contains(id));
      if (specialtyId != null &&
          !catalog.specialtyOptions(city).any((o) => o.id == specialtyId)) {
        specialtyId = null;
      }
      _checkCoverage();
      notifyListeners();
    }

    try {
      apply(await loadCachedCatalog?.call());
    } on Exception {
      /* bundled fallback */
    }
    if (!_disposed) {
      try {
        apply(await refreshCatalog?.call());
      } on Exception {
        refreshFailed = true;
      }
    }
    if (_disposed) return;
    isRefreshing = false;
    notifyListeners();
  }

  DirectoryCity city = DirectoryCity.spb;
  String labQuery = '', doctorQuery = '';
  String? specialtyId;
  final Set<String> _specialtyIds = {};
  Set<String> get specialtyIds => Set.unmodifiable(_specialtyIds);
  String? networkId;
  final Set<String> _testIds = {};
  Set<String> get testIds => Set.unmodifiable(_testIds);
  GeoPoint? origin;
  String? originLabel;
  bool outsideCoverage = false;
  bool linkFailed = false;

  List<DirectoryHit> hits({required bool doctors}) => outsideCoverage
      ? []
      : catalog
            .search(
              city: city,
              origin: origin,
              doctorsOnly: doctors,
              query: doctors ? doctorQuery : labQuery,
              testIds: doctors ? const {} : _testIds,
              specialtyId: null,
            )
            .where(
              (hit) =>
                  (networkId == null || hit.branch.network == networkId) &&
                  (!doctors ||
                      _specialtyIds.isEmpty ||
                      (hit.doctor != null &&
                          catalog
                              .doctorSpecialtyIds(hit.doctor!)
                              .any(_specialtyIds.contains))),
            )
            .toList();

  List<String> get availableNetworks =>
      (catalog.branches
          .where((b) => b.city == city)
          .map((b) => b.network)
          .toSet()
          .toList()
        ..sort((a, b) => networkLabel(a).compareTo(networkLabel(b))));

  String networkLabel(String id) => switch (id) {
    'invitro' => 'ИНВИТРО',
    'helix' => 'Хеликс',
    'smclinic' => 'СМ-Клиника',
    'scandinavia' => 'Скандинавия',
    'sova' => 'СОВА',
    'medexpert' => 'МедЭксперт',
    'csp' => 'ЦСП',
    _ => id,
  };

  void selectNetwork(String? id) {
    if (id != null && !availableNetworks.contains(id)) return;
    networkId = id;
    notifyListeners();
  }

  void _checkNetwork() {
    if (networkId != null && !availableNetworks.contains(networkId)) {
      networkId = null;
    }
  }

  List<DirectoryTestOption> availableTests(String language) =>
      (catalog.testOptions(city).toList()..sort(
        (a, b) => a.label
            .inLanguage(language)
            .compareTo(b.label.inLanguage(language)),
      ));

  void selectCity(DirectoryCity value) {
    city = value;
    _checkNetwork();
    _testIds.clear();
    specialtyId = null;
    _specialtyIds.clear();
    notifyListeners();
  }

  List<DirectoryTestOption> availableSpecialties(String language) =>
      (catalog.specialtyOptions(city).toList()..sort(
        (a, b) => a.label
            .inLanguage(language)
            .compareTo(b.label.inLanguage(language)),
      ));
  void selectSpecialty(String? id) {
    if (id != null && !catalog.specialtyOptions(city).any((o) => o.id == id)) {
      return;
    }
    specialtyId = id;
    _specialtyIds
      ..clear()
      ..addAll(id == null ? <String>[] : [id]);
    notifyListeners();
  }

  void toggleSpecialty(String id) {
    if (!catalog.specialtyOptions(city).any((o) => o.id == id)) return;
    if (!_specialtyIds.remove(id)) _specialtyIds.add(id);
    specialtyId = _specialtyIds.length == 1 ? _specialtyIds.single : null;
    notifyListeners();
  }

  List<DirectoryTestOption> suggestTests(
    String language,
  ) => availableTests(language)
      .where(
        (o) => directorySearchText(
          '${o.label.inLanguage(language)} ${catalog.terminology.searchText(o.id)}',
        ).contains(directorySearchText(labQuery)),
      )
      .toList();
  void selectBasicTests() {
    const wanted = [
      'Общий анализ крови',
      'АЛТ',
      'АСТ',
      'Билирубин общий',
      'Креатинин',
      'Общий анализ мочи',
      'Глюкоза',
      'Витамин D',
    ];
    for (final option in availableTests('ru')) {
      if (wanted.any((n) => option.label.inLanguage('ru').startsWith(n))) {
        _testIds.add(option.id);
      }
    }
    notifyListeners();
  }

  void setQuery(String value, {required bool doctors}) {
    if (doctors) {
      doctorQuery = value;
    } else {
      labQuery = value;
    }
    notifyListeners();
  }

  void toggleTest(String id) {
    if (!catalog.testOptions(city).any((t) => t.id == id)) return;
    if (!_testIds.remove(id)) _testIds.add(id);
    notifyListeners();
  }

  /// Location selection is owned by DeviceAccess. Every confirmed change
  /// replaces the previous point, including an address with no coordinates.
  void setOrigin(String? label, GeoPoint? point) {
    if (originLabel == label &&
        origin?.latitude == point?.latitude &&
        origin?.longitude == point?.longitude) {
      return;
    }
    originLabel = label;
    origin = point;
    _checkCoverage();
    notifyListeners();
  }

  void _checkCoverage() {
    final point = origin;
    outsideCoverage = false;
    if (point != null) {
      ProviderBranch? closest;
      var distance = double.infinity;
      for (final branch in catalog.branches) {
        if (branch.point == null) continue;
        final candidate = point.distanceTo(branch.point!);
        if (candidate < distance) {
          closest = branch;
          distance = candidate;
        }
      }
      // Coverage is a pilot search radius, not an inferred postal address.
      outsideCoverage = distance > 100000;
      if (closest != null && !outsideCoverage && city != closest.city) {
        city = closest.city;
        _checkNetwork();
        _testIds.clear();
        specialtyId = null;
      }
    }
  }

  Future<void> open(Uri uri) async {
    if (uri.scheme != 'https' && uri.scheme != 'tel') return;
    var opened = false;
    try {
      opened = await _openUrl?.call(uri) ?? false;
    } on Exception {
      /* UI fallback below. */
    }
    if (_disposed) return;
    linkFailed = !opened;
    notifyListeners();
  }

  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
