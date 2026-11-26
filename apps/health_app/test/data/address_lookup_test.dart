import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/device_access/photon_address_lookup.dart';
import 'package:health_app/data/preferences/location_repository.dart';
import 'package:health_app/platform/device_access.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'shared_preferences_repository_test.dart' show FakePreferences;

Map<String, Object?> feature({
  Map<String, Object?>? properties,
  List<num>? point,
}) => {
  'properties':
      properties ??
      {
        'city': 'Казань',
        'street': 'улица Баумана',
        'housenumber': '1',
        'country': 'Россия',
      },
  'geometry': {
    'type': 'Point',
    'coordinates': point ?? [49.12, 55.79],
  },
};

void main() {
  test(
    'geocoding identifies native clients and leaves browser headers alone',
    () async {
      final client = MockClient((request) async {
        final rejected = kIsWeb
            ? request.headers.containsKey('user-agent')
            : !(request.headers['user-agent'] ?? '').startsWith(
                'OrangeOfHealth/',
              );
        if (rejected) {
          return http.Response('Forbidden', 403);
        }
        return http.Response(
          jsonEncode({
            'features': [feature()],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final lookup = PhotonAddressLookup(client: client);
      expect(await lookup.search('Воронеж', language: 'ru'), isNotEmpty);
      expect(
        await lookup.reverse(
          const DeviceCoordinates(51.6, 39.2),
          language: 'ru',
        ),
        isNotNull,
      );
    },
  );
  test(
    'city, street and house completions keep the next part editable',
    () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['lang'], 'default');
        return http.Response(
          jsonEncode({
            'features': [
              feature(
                properties: {
                  'name': 'Воронеж',
                  'type': 'city',
                  'state': 'Воронежская область',
                  'country': 'Россия',
                },
              ),
              feature(
                properties: {
                  'name': 'улица Ленина',
                  'type': 'street',
                  'city': 'Воронеж',
                  'country': 'Россия',
                },
              ),
              feature(
                properties: {
                  'city': 'Воронеж',
                  'street': 'улица Ленина',
                  'housenumber': '10',
                  'country': 'Россия',
                },
              ),
            ],
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final results = await PhotonAddressLookup(client: client)
          .search('Воронеж', language: 'ru_RU');
      expect(results.map((r) => r.inputText), [
        'Воронеж, ',
        'Воронеж, улица Ленина, ',
        'Воронеж, улица Ленина 10',
      ]);
      expect(results.map((r) => r.level), [
        AddressLevel.city,
        AddressLevel.street,
        AddressLevel.building,
      ]);
      client.close();
    },
  );
  test('Photon suggestions format addresses and use longitude/latitude GeoJSON order', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/');
      expect(request.url.queryParameters['q'], 'Казань Бау');
      expect(request.url.queryParameters['lang'], 'default');
      expect(request.url.queryParameters['limit'], '5');
      return http.Response(
        jsonEncode({
          'features': [
            feature(),
            feature(),
            feature(point: [250, 150]),
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final results = await PhotonAddressLookup(client: client)
        .search('Казань Бау', language: 'ru');
    expect(results.single.address, 'Казань, улица Баумана 1, Россия');
    expect(results.single.coordinates!.latitude, 55.79);
    expect(results.single.coordinates!.longitude, 49.12);
    client.close();
  });

  test('reverse result retains actual GPS position and is not confirmed by adapter', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/reverse');
      expect(request.url.queryParameters['lat'], '55.8');
      expect(request.url.queryParameters['lon'], '49.1');
      return http.Response(
        jsonEncode({
          'features': [
            feature(properties: {'city': 'Kazan'}),
          ],
        }),
        200,
      );
    });
    final result = await PhotonAddressLookup(client: client)
        .reverse(const DeviceCoordinates(55.8, 49.1), language: 'en');
    expect(result!.address, 'Kazan');
    expect(result.coordinates!.latitude, 55.8);
    expect(result.source, LocationSource.gps);
    client.close();
  });

  test(
    'unavailable, malformed and empty provider responses are explicit',
    () async {
      for (final response in [
        http.Response('', 429),
        http.Response('{', 200),
        http.Response('{}', 200),
      ]) {
        final client = MockClient((_) async => response);
        await expectLater(
          PhotonAddressLookup(client: client).search('Москва', language: 'ru'),
          throwsFormatException,
        );
        client.close();
      }
      final client = MockClient(
        (_) async => http.Response('{"features":[]}', 200),
      );
      expect(
        await PhotonAddressLookup(client: client)
            .reverse(const DeviceCoordinates(0, 0), language: 'en'),
        isNull,
      );
      client.close();
    },
  );

  test('last address survives storage, while confirmation and GPS are not persisted', () async {
    final preferences = FakePreferences();
    final storage = SharedPreferencesLocationRepository(preferences);
    await storage.write(
      const DeviceLocation(
        address: 'Казань',
        coordinates: DeviceCoordinates(55.8, 49.1),
        source: LocationSource.gps,
      ),
    );
    final restored = await SharedPreferencesLocationRepository(preferences)
        .read();
    expect(restored!.address, 'Казань');
    expect(restored.source, LocationSource.gps);
    expect(restored.coordinates, isNull);
    expect(
      preferences.values[SharedPreferencesLocationRepository.storageKey],
      isNot(contains('55.8')),
    );
    for (final raw in [
      '{',
      '[]',
      '{}',
      '{"address":"","source":"manual"}',
      '{"address":"Kazan","source":"unknown"}',
    ]) {
      preferences.values[SharedPreferencesLocationRepository.storageKey] = raw;
      await expectLater(storage.read(), throwsFormatException);
    }
  });
}
