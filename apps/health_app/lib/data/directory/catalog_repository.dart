import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:provider_directory/provider_directory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DirectoryCatalogFailure implements Exception {
  const DirectoryCatalogFailure();
}

/// Public reference data only. Neither account credentials nor location are sent.
class DirectoryCatalogRepository {
  DirectoryCatalogRepository({
    required this.client,
    required this.preferences,
    required this.endpoint,
  });
  final http.Client client;
  final SharedPreferencesAsync preferences;
  final Uri endpoint;
  String get _key =>
      'analyses.provider-directory.v1.${endpoint.origin}${endpoint.path}';

  Future<ProviderCatalog?> cached() async {
    final payload = await preferences.getString(_key);
    return payload == null ? null : _decode(payload);
  }

  ProviderCatalog _decode(String payload) {
    try {
      return ProviderCatalog.decode(payload);
    } on TypeError {
      throw const FormatException('Invalid directory snapshot');
    } on ArgumentError {
      throw const FormatException('Invalid directory snapshot');
    }
  }

  Future<ProviderCatalog?> refresh() async {
    if (endpoint.scheme != 'https' &&
        !(endpoint.scheme == 'http' &&
            ['localhost', '127.0.0.1', '10.0.2.2'].contains(endpoint.host))) {
      throw const FormatException('Use HTTPS for the public directory');
    }
    final request = http.Request(
      'GET',
      endpoint.resolve('v1/directory/catalog'),
    )..followRedirects = false;
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) throw const DirectoryCatalogFailure();
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 10),
    )) {
      if (bytes.length + chunk.length > 8 * 1024 * 1024) {
        throw const FormatException('Directory too large');
      }
      bytes.addAll(chunk);
    }
    final payload = utf8.decode(bytes);
    final catalog = _decode(payload);
    try {
      await preferences.setString(_key, payload);
    } on Exception {
      // A full preferences store must not discard a usable network result.
    }
    return catalog;
  }
}
