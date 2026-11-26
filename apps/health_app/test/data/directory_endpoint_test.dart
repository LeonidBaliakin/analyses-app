import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/data/directory/directory_endpoint.dart';

void main() {
  Uri? resolve({
    String configured = '',
    bool debug = true,
    bool web = true,
    bool android = false,
    String page = 'http://127.0.0.1:59201/',
  }) => directoryEndpoint(
    configuredUrl: configured,
    development: debug,
    web: web,
    android: android,
    page: Uri.parse(page),
  );
  test('local debug web connects to the directory on the same local host', () {
    expect(resolve().toString(), 'http://127.0.0.1:18086/');
    expect(
      resolve(page: 'http://localhost:7357/').toString(),
      'http://localhost:18086/',
    );
  });
  test('public and release builds do not infer a local server', () {
    expect(resolve(debug: false), isNull);
    expect(resolve(page: 'https://app.example.org/'), isNull);
    expect(
      resolve(
        configured: 'https://directory.example.org/api',
        debug: false,
      ).toString(),
      'https://directory.example.org/api/',
    );
  });
  test('native development distinguishes Android emulator from desktop', () {
    expect(
      resolve(web: false, android: true).toString(),
      'http://10.0.2.2:18086/',
    );
    expect(resolve(web: false).toString(), 'http://127.0.0.1:18086/');
  });
}
