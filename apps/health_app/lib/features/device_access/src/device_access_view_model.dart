import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../platform/device_access.dart';

final class DeviceAccessViewModel extends ChangeNotifier {
  DeviceAccessViewModel({
    required this._gateway,
    this._addressLookup = const UnavailableAddressLookup(),
    this._locationRepository,
    this.introductionRequired = false,
    this._rememberIntroduction,
  });

  final DeviceAccessGateway _gateway;
  final AddressLookupGateway _addressLookup;
  final LocationRepository? _locationRepository;
  final Future<void> Function()? _rememberIntroduction;
  bool introductionRequired;
  bool isBusy = false;
  bool _disposed = false;
  bool _recovered = false;
  AccessIssue? attachmentIssue;
  AccessIssue? locationIssue;
  AccessIssue? introductionIssue;
  final List<SelectedAttachment> _attachments = [];
  List<SelectedAttachment> get attachments => List.unmodifiable(_attachments);
  DeviceLocation? location;
  DeviceLocation? lastLocation;
  DeviceLocation? pendingLocation;
  DeviceCoordinates? get coordinates => location?.coordinates;
  String? get manualLocation =>
      location?.source == LocationSource.manual ? location?.address : null;
  bool get locationConfirmed => location != null;
  bool _sessionLocationChecked = false;
  bool locationSelectionOpen = false;
  bool locationSaveFailed = false;
  bool addressLookupFailed = false;
  bool addressSearchFailed = false;
  bool addressSearchEmpty = false;
  bool isSearchingAddresses = false;
  List<DeviceLocation> addressSuggestions = const [];
  int _searchGeneration = 0;
  Timer? _searchTimer;
  Completer<List<DeviceLocation>>? _searchCompleter;
  bool get supportsCamera => _gateway.supportsCamera;
  bool get supportsSettings => _gateway.supportsSettings;

  Future<void> recoverAttachments() async {
    if (_recovered || isBusy || _disposed) return;
    _recovered = true;
    await _run(() async {
      _attachments.addAll(await _gateway.recoverAttachments());
    }, (issue) => attachmentIssue = issue);
  }

  Future<void> pick(AttachmentSource source) async {
    if (isBusy || _disposed) return;
    attachmentIssue = null;
    await _run(() async {
      final selected = await _gateway.pick(source);
      if (selected == null) {
        attachmentIssue = AccessIssue.cancelled;
      } else {
        _attachments.add(selected);
      }
    }, (issue) => attachmentIssue = issue);
  }

  void removeAttachment(SelectedAttachment attachment) {
    if (_disposed || isBusy) return;
    _attachments.remove(attachment);
    _notify();
  }

  Future<void> restoreLocation() async {
    try {
      lastLocation = await _locationRepository?.read();
    } on Exception {
      // A damaged preference must not prevent local work or manual entry.
      locationSaveFailed = true;
    }
  }

  /// Only already granted GPS permission is used on entering a directory.
  Future<void> prepareLocationForSession({required String language}) async {
    if (_disposed || locationConfirmed) return;
    if (_sessionLocationChecked) {
      pendingLocation ??= lastLocation;
      _notify();
      return;
    }
    _sessionLocationChecked = true;
    pendingLocation = lastLocation;
    await locate(language: language, requestPermission: false);
  }

  Future<void> locate({
    String language = 'ru',
    bool requestPermission = true,
  }) async {
    if (isBusy || _disposed) return;
    _sessionLocationChecked = true;
    if (!locationConfirmed) pendingLocation ??= lastLocation;
    locationIssue = null;
    addressLookupFailed = false;
    cancelAddressSearch();
    await _run(() async {
      final result = await _gateway.locate(
        requestPermission: requestPermission,
      );
      if (_disposed) return;
      DeviceLocation? address;
      try {
        address = await _addressLookup.reverse(result, language: language);
      } on Exception {
        addressLookupFailed = true;
      }
      if (_disposed) return;
      if (address == null) {
        addressLookupFailed = true;
        pendingLocation = lastLocation;
        return;
      }
      pendingLocation = address;
      await _rememberLocation(address);
    }, (issue) => locationIssue = issue);
  }

  Future<bool> setManualLocation(
    String value, {
    DeviceLocation? suggestion,
    String language = 'ru',
  }) async {
    if (isBusy || _disposed || value.trim().isEmpty) return false;
    return _selectLocation(
      suggestion != null && suggestion.inputText.trim() == value.trim()
          ? suggestion
          : DeviceLocation(address: value.trim()),
      language: language,
    );
  }

  Future<bool> confirmLocation({String language = 'ru'}) async {
    if (isBusy || _disposed || pendingLocation == null) return false;
    return _selectLocation(pendingLocation!, language: language);
  }

  Future<bool> _selectLocation(
    DeviceLocation selected, {
    required String language,
  }) async {
    final suggestions = addressSuggestions;
    cancelAddressSearch();
    var accepted = false;
    await _run(() async {
      if (selected.coordinates == null && selected.isAddressPoint) {
        var results = suggestions;
        if (_matchingAddress(selected.address, results) == null) {
          try {
            results = await _addressLookup
                .search(selected.address, language: language)
                .timeout(const Duration(seconds: 8));
          } on Exception {
            addressSearchFailed = true;
            results = const [];
          }
        }
        if (_disposed) return;
        final match = _matchingAddress(selected.address, results);
        if (match != null) {
          selected = match;
        } else {
          final points = results
              .where((r) => r.isAddressPoint && r.coordinates != null)
              .take(5)
              .toList();
          // A different or ambiguous address needs a separate user choice.
          if (points.isNotEmpty) {
            pendingLocation = points.length == 1 ? points.single : null;
            addressSuggestions = List.unmodifiable(points);
            return;
          }
        }
      }
      location = selected;
      pendingLocation = null;
      locationIssue = null;
      addressLookupFailed = false;
      await _rememberLocation(selected);
      accepted = true;
    }, (issue) => locationIssue = issue);
    return accepted;
  }

  DeviceLocation? _matchingAddress(
    String address,
    List<DeviceLocation> results,
  ) {
    String normalized(String value) => value
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'[,.\s]+'), ' ')
        .trim();
    final query = normalized(address);
    final matches = results.where(
      (r) =>
          r.isAddressPoint &&
          r.coordinates != null &&
          (normalized(r.address) == query || normalized(r.inputText) == query),
    );
    return matches.length == 1 ? matches.single : null;
  }

  Future<void> _rememberLocation(DeviceLocation selected) async {
    lastLocation = selected;
    locationSaveFailed = false;
    try {
      await _locationRepository?.write(selected);
    } on Exception {
      locationSaveFailed = true;
    }
  }

  void editLocation() {
    pendingLocation = null;
    locationIssue = null;
    addressLookupFailed = false;
    _notify();
  }

  Future<List<DeviceLocation>> searchAddresses(
    String query, {
    required String language,
  }) {
    cancelAddressSearch();
    addressSearchFailed = false;
    addressSearchEmpty = false;
    final text = query.trim();
    if (_disposed || text.length < 3) {
      _notify();
      return Future.value([]);
    }
    final generation = _searchGeneration;
    final completer = Completer<List<DeviceLocation>>();
    _searchCompleter = completer;
    isSearchingAddresses = true;
    _notify();
    _searchTimer = Timer(const Duration(milliseconds: 400), () async {
      var results = <DeviceLocation>[];
      try {
        results = (await _addressLookup.search(
          text,
          language: language,
        )).take(5).toList();
      } on Exception {
        if (!_disposed && generation == _searchGeneration) {
          addressSearchFailed = true;
        }
      }
      if (!_disposed && generation == _searchGeneration) {
        isSearchingAddresses = false;
        addressSuggestions = List.unmodifiable(results);
        addressSearchEmpty = results.isEmpty && !addressSearchFailed;
        if (!completer.isCompleted) completer.complete(results);
        _notify();
      } else if (!completer.isCompleted) {
        completer.complete([]);
      }
    });
    return completer.future;
  }

  void cancelAddressSearch() {
    _searchGeneration++;
    _searchTimer?.cancel();
    if (_searchCompleter case final completer? when !completer.isCompleted) {
      completer.complete([]);
    }
    _searchCompleter = null;
    isSearchingAddresses = false;
    addressSuggestions = const [];
    addressSearchEmpty = false;
    addressSearchFailed = false;
  }

  Future<void> openSettings({bool location = true}) async {
    if (isBusy || _disposed) return;
    await _run(
      () async {
        if (!await _gateway.openSettings(
          locationServices:
              location && locationIssue == AccessIssue.serviceDisabled,
        )) {
          throw const DeviceAccessException(AccessIssue.unsupported);
        }
      },
      (issue) {
        if (location) {
          locationIssue = issue;
        } else {
          attachmentIssue = issue;
        }
      },
    );
  }

  Future<bool> finishIntroduction() async {
    if (isBusy || _disposed) return false;
    introductionIssue = null;
    await _run(() async {
      await _rememberIntroduction?.call();
      introductionRequired = false;
    }, (issue) => introductionIssue = issue);
    return !introductionRequired;
  }

  Future<void> _run(
    Future<void> Function() action,
    void Function(AccessIssue) onIssue,
  ) async {
    isBusy = true;
    _notify();
    try {
      await action();
    } on DeviceAccessException catch (error) {
      onIssue(error.issue);
    } on Exception {
      onIssue(AccessIssue.failed);
    } finally {
      isBusy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    cancelAddressSearch();
    super.dispose();
  }
}
