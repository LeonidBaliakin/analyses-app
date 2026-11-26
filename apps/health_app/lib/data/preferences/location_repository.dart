import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../platform/device_access.dart';

final class SharedPreferencesLocationRepository implements LocationRepository {
  SharedPreferencesLocationRepository(this._preferences);
  static const storageKey = 'analyses.last-location.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<DeviceLocation?> read() async {
    final raw = await _preferences.getString(storageKey);
    if (raw == null) return null;
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value['address'] is! String ||
        (value['address'] as String).trim().isEmpty ||
        (value['address'] as String).length > 1000 ||
        !LocationSource.values.any((s) => s.name == value['source'])) {
      throw const FormatException('Invalid saved location');
    }
    // The address is sufficient for confirmation; no need to persist GPS.
    return DeviceLocation(
      address: value['address'] as String,
      source: LocationSource.values.byName(value['source'] as String),
    );
  }

  @override
  Future<void> write(DeviceLocation location) => _preferences.setString(
    storageKey,
    jsonEncode({'address': location.address, 'source': location.source.name}),
  );
}
