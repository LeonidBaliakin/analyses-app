import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../platform/device_access.dart';

/// Photon supports search-as-you-type, unlike the public Nominatim endpoint.
final class PhotonAddressLookup implements AddressLookupGateway {
  PhotonAddressLookup({required this._client, Uri? endpoint})
    : _endpoint = endpoint ?? Uri.parse('https://photon.komoot.io/');

  final http.Client _client;
  final Uri _endpoint;

  // The public Photon index accepts only default/de/en/fr. `default` keeps
  // local OSM names (including Russian addresses), whereas `ru` returns 400.
  String _language(String language) =>
      switch (language.split(RegExp('[-_]')).first) {
        'de' => 'de',
        'en' => 'en',
        'fr' => 'fr',
        _ => 'default',
      };

  @override
  Future<List<DeviceLocation>> search(
    String query, {
    required String language,
  }) =>
      _request('api/', {'q': query, 'lang': _language(language), 'limit': '5'});

  @override
  Future<DeviceLocation?> reverse(
    DeviceCoordinates coordinates, {
    required String language,
  }) async {
    final results = await _request('reverse', {
      'lat': '${coordinates.latitude}',
      'lon': '${coordinates.longitude}',
      'lang': _language(language),
      'limit': '1',
    });
    if (results.isEmpty) return null;
    return DeviceLocation(
      address: results.first.address,
      coordinates: coordinates,
      source: LocationSource.gps,
    );
  }

  Future<List<DeviceLocation>> _request(
    String path,
    Map<String, String> query,
  ) async {
    final response = await _client
        .get(
          _endpoint.resolve(path).replace(queryParameters: query),
          headers: {
            'Accept': 'application/json',
            // Photon rejects the generic Dart UA with HTTP 403. Identify our
            // native client; browsers manage their own User-Agent header.
            if (!kIsWeb) 'User-Agent': 'OrangeOfHealth/0.1 (address lookup)',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw const FormatException('Address lookup unavailable');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic> || body['features'] is! List) {
      throw const FormatException('Invalid address response');
    }
    final results = <DeviceLocation>[];
    final seen = <String>{};
    for (final feature in (body['features'] as List).take(5)) {
      if (feature is! Map<String, dynamic>) continue;
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      if (properties is! Map<String, dynamic> ||
          geometry is! Map<String, dynamic>) {
        continue;
      }
      final point = geometry['coordinates'];
      if (point is! List ||
          point.length < 2 ||
          point[0] is! num ||
          point[1] is! num) {
        continue;
      }
      final lon = (point[0] as num).toDouble(),
          lat = (point[1] as num).toDouble();
      if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180) {
        continue;
      }
      String part(String key) =>
          properties[key] is String ? (properties[key] as String).trim() : '';
      final street = [
        part('street'),
        part('housenumber'),
      ].where((s) => s.isNotEmpty).join(' ');
      final parts = <String>{
        part('city'),
        part('district'),
        if (part('name') != part('street')) part('name'),
        street,
        part('state'),
        part('country'),
      }..remove('');
      final address = parts.join(', ');
      if (address.isEmpty || address.length > 1000 || !seen.add(address)) {
        continue;
      }
      results.add(
        DeviceLocation(
          address: address,
          coordinates: DeviceCoordinates(lat, lon),
          isAddressPoint: part('housenumber').isNotEmpty,
          completion: _completion(properties),
          level: _level(properties),
        ),
      );
    }
    return results;
  }

  AddressLevel? _level(Map<String, dynamic> p) {
    if (p['housenumber'] is String) return AddressLevel.building;
    if (p['street'] is String ||
        p['type'] == 'street' ||
        p['osm_key'] == 'highway') {
      return AddressLevel.street;
    }
    if (p['type'] == 'city' ||
        (p['osm_key'] == 'place' &&
            const {
              'city',
              'town',
              'village',
              'hamlet',
              'locality',
              'suburb',
            }.contains(p['osm_value']))) {
      return AddressLevel.city;
    }
    return null;
  }

  String? _completion(Map<String, dynamic> p) {
    String part(String key) =>
        p[key] is String ? (p[key] as String).trim() : '';
    final level = _level(p);
    final city = part('city').isNotEmpty
        ? part('city')
        : level == AddressLevel.city
        ? part('name')
        : '';
    if (city.isEmpty) return null;
    final street = part('street').isNotEmpty
        ? part('street')
        : level == AddressLevel.street
        ? part('name')
        : '';
    final prefix = [city, if (street.isNotEmpty) street].join(', ');
    return switch (level) {
      AddressLevel.city => '$city, ',
      AddressLevel.street => '$prefix, ',
      AddressLevel.building => '$prefix ${part('housenumber')}',
      null => null,
    };
  }
}
