import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/directory/catalog_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'shared_preferences_repository_test.dart' show FakePreferences;

void main() {
  final payload = File('../../packages/provider_directory/data/catalog.json')
      .readAsStringSync();
  test(
    'public catalogue is validated and available in a new offline repository',
    () async {
      final prefs = FakePreferences();
      final endpoint = Uri.parse('https://directory.example.org/');
      final client = MockClient((r) async {
        expect(
          r.url.toString(),
          'https://directory.example.org/v1/directory/catalog',
        );
        expect(r.headers.containsKey('authorization'), isFalse);
        expect(r.url.hasQuery, isFalse);
        return http.Response(
          payload,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(client.close);
      final repository = DirectoryCatalogRepository(
        client: client,
        preferences: prefs,
        endpoint: endpoint,
      );
      final fresh = await repository.refresh();
      expect(
        fresh!.branches.where((b) => b.network == 'medexpert'),
        hasLength(14),
      );
      expect(fresh.branches.where((b) => b.network == 'csp'), hasLength(5));
      final offline = MockClient(
        (_) async => throw const SocketException('offline'),
      );
      addTearDown(offline.close);
      final restored = DirectoryCatalogRepository(
        client: offline,
        preferences: prefs,
        endpoint: endpoint,
      );
      expect((await restored.cached())!.version, fresh.version);
      await expectLater(restored.refresh(), throwsException);
      expect(
        (await restored.cached())!.branches,
        hasLength(fresh.branches.length),
      );
    },
  );
  test(
    'invalid schema or HTTP failure cannot overwrite last usable cache',
    () async {
      final prefs = FakePreferences(),
          endpoint = Uri.parse('https://directory.example.org/');
      var response = payload, status = 200;
      final client = MockClient(
        (_) async => http.Response(
          response,
          status,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      addTearDown(client.close);
      final repository = DirectoryCatalogRepository(
        client: client,
        preferences: prefs,
        endpoint: endpoint,
      );
      final initial = (await repository.refresh())!.version;
      response = jsonEncode({'schemaVersion': 2});
      await expectLater(repository.refresh(), throwsA(anything));
      status = 503;
      await expectLater(
        repository.refresh(),
        throwsA(isA<DirectoryCatalogFailure>()),
      );
      expect((await repository.cached())!.version, initial);
    },
  );
}
